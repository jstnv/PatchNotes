extends "res://scripts/debug/verify_feature_store_radial.gd"

func settled(map: FeatureStoreMap) -> void:
	var deadline:=Time.get_ticks_msec()+5000
	while map.focusing or (map._menu_tween!=null and map._menu_tween.is_running()):
		if Time.get_ticks_msec()>deadline:
			expect(false,"Focus finishes within bounded wait"); return
		await process_frame
	for frame in 3: await process_frame

func _verify() -> void:
	var dimensions:=Vector2i(1280,720)
	for arg in OS.get_cmdline_user_args():
		if arg=="--size=900": dimensions=Vector2i(900,600)
		if arg=="--size=1152": dimensions=Vector2i(1152,648)
	root.size=dimensions;root.content_scale_size=dimensions
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game);await process_frame
	root.min_size=Vector2i.ZERO;root.size=dimensions;root.content_scale_size=dimensions
	var menu: MainMenu=game.get("_active_phase")
	menu.navigation.animate=false
	var ready_deadline:=Time.get_ticks_msec()+60000
	while (menu.checkpoint_info.get("status")==&"checking" or menu._boot_entrance or menu.navigation.busy) and Time.get_ticks_msec()<ready_deadline:
		await process_frame
	if menu.checkpoint_info.get("status")==&"checking" or menu._boot_entrance or menu.navigation.busy:
		print("SETUP_TIMEOUT status=",menu.checkpoint_info.get("status"));quit(2);return
	print("SETUP_READY status=",menu.checkpoint_info.get("status"))
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	if is_instance_valid(menu._replace_dialog) and menu._replace_dialog.visible:
		menu._replace_dialog.hide();menu._replace_dialog.confirmed.emit()
	menu._name_input.text="Grid acceptance"
	menu._specialty.select(1);menu._play.pressed.emit()
	menu.call("_open_folder",&"traits");menu.call("_show_review");menu.call("_confirm_studio")
	await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
	var studio: StudioPhase=game.get("_active_phase")
	var actions:=preload("res://scripts/debug/ui_test_actions.gd")
	var engine_id: StringName=actions.create_feature_engine(game.run_state,"Grid Engine")
	var store: FeatureStore=await actions.open_feature_implementation(studio,engine_id)
	var map:=store._map
	game.get_node("%GameplayHUD").contextual_tip.dismiss()
	for frame in 5: await process_frame
	var before:=_passive_snapshot(game.run_state)
	for id: StringName in [&"split_screen",&"branching_dialogue",&"character_development",&"multi_directional_scrolling",&"recorded_sounds",&"difficulty_levels",&"character_skill_checks"]:
		map._focus_node(id);await settled(map)
		expect(map._map_rect().encloses(store._nodes[id].get_global_rect()) and map._map_rect().encloses(store._nodes[id].get_node("FeatureName").get_global_rect()),"Focused card visible "+str(id))
		expect(store._body.get_global_rect().encloses(map.popup.get_global_rect()),"Focused details visible "+str(id))
		expect(map.popup.visible and store._selected==id,"Correct focused selection "+str(id))
		await _capture("focus-"+str(id),dimensions.x)
	expect(before==_passive_snapshot(game.run_state),"All focused browsing is passive")
	game.queue_free();await process_frame
	print("Store grid focused views: %d failures"%failures);quit(failures)
