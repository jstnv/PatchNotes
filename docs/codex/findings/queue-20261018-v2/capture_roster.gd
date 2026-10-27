extends "res://scripts/debug/verify_primitive_branches.gd"
func settle() -> void:
	for i in 6: await process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var event := InputEventKey.new(); event.keycode=code;event.pressed=down
		root.push_input(event,true)
func picture(label: String, resolution: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("PN_ROSTER_OUTPUT").path_join("final-%s-%dx%d.png"%[label,resolution.x,resolution.y]))
func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution
		var menu:=MainMenu.new();root.add_child(menu)
		await settle()
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		menu._name_input.text="Roster Compatibility Studio"
		for genre: StringName in [&"strategy",&"simulation",&"sports",&"adventure"]:
			for index in range(1,menu._specialty.item_count):
				if menu._specialty.get_item_metadata(index)==genre:
					menu._specialty.select(index);menu._specialty.item_selected.emit(index);break
			menu._open_folder(&"genre");await settle()
			var preview:=StudioSpecialties.preview(genre)
			check(menu._preview.text.contains(", ".join(preview.names)),"exact visible roster "+str(genre))
			check(menu._preview.get_global_rect().end.y <= menu._preview.get_parent().get_global_rect().end.y,"preview lines fit "+str(genre))
			check(menu._preview.text.contains("Starts with Levels")==(genre in StudioSpecialties.LEVELS_SWAP),"swap note only changed starts")
			await picture(str(genre)+"-preview",resolution)
		menu._specialty.select(4);menu._specialty.item_selected.emit(4)
		menu._folder_buttons[&"traits"].grab_focus();key(KEY_ENTER);await settle()
		check(menu._folder_buttons[&"traits"].button_pressed,"keyboard Traits")
		menu._folder_buttons[&"overview"].grab_focus();key(KEY_ENTER);await settle()
		check(menu._folder_buttons[&"overview"].button_pressed and menu._review.text.contains("Starts with Levels"),"keyboard Overview truthful note")
		check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(menu._play.get_global_rect()),"confirmation fits")
		await picture("overview",resolution)
		menu.queue_free();await settle()
		for old in [false,true]:
			var run: RunState
			if old:
				var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_ROSTER_PRIOR")))
				run=StudioCheckpoint.new().hydrate(prior.saves.strategy)
			else: run=fresh(&"strategy").run
			var store:=FeatureStore.new();root.add_child(store);store.setup(run)
			await settle();store._select_node(&"maps");await create_timer(0.8).timeout
			check(store._map.popup.visible,"Maps details shown")
			check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(store._map.popup.get_global_rect()),"Maps details fit")
			check(store._details.text.contains("Owned") if old else store._map.price.text.contains("450"),"old ownership / new exact price shown")
			await picture("old-maps" if old else "new-maps",resolution)
			store.queue_free();await settle()
	print("ROSTER_NATIVE checks=%d failures=%d"%[checks,failures]);quit(failures)
