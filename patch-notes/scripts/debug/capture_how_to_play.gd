extends "res://scripts/debug/verify_how_to_play.gd"

var captures: Array = []

func _initialize() -> void:
	await process_frame
	if DisplayServer.get_name() == "headless": quit(2); return
	create_timer(120).timeout.connect(func(): push_error("Guide capture timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var guide := hud.how_to_play
	game._active_phase.navigation.animate=false
	game._active_phase.get_node("CenterContainer/MenuLayout/HowToPlay").pressed.emit()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await settle()
		for i in range(guide.sections.size()):
			guide.select_folder(i)
			for j in range(guide.sections[i].topics.size()):
				guide.select_topic(j)
				await settle()
				check_layout(guide,resolution)
		for selection in [[0,0,"overview"],[1,2,"traits"],[2,3,"genre-standards"],[2,7,"synergies"],[4,0,"publishers"],[5,1,"sales"]]:
			guide.select_folder(selection[0])
			guide.select_topic(selection[1])
			await settle()
			await capture(selection[2],resolution)
	guide.close()
	game._on_studio_created("Guide capture Studio",&"action",[],game._active_phase)
	await settle()
	game.pause_menu.open()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		await settle()
		await capture("pause",resolution)
		game.pause_menu.how_to_play_button.grab_focus()
		await key(KEY_ENTER)
		guide.select_folder(6)
		guide.select_topic(3)
		await settle()
		expect(paused and guide.is_open(),"Paused guide visible")
		check_layout(guide,resolution)
		await capture("paused-bank-guide",resolution)
		await key(KEY_ESCAPE)
		expect(paused and not guide.is_open(),"Native Esc returns to Pause")
	game.pause_menu.close()
	game.queue_free()
	await settle()
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("GUIDE_RENDER checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)

func settle() -> void:
	await process_frame
	await process_frame

func check_layout(guide: HowToPlayGuide,resolution: Vector2i) -> void:
	var screen := Rect2(Vector2.ZERO,Vector2(resolution))
	var surface := guide.panel.get_global_rect()
	expect(screen.encloses(surface),"Guide panel fits native viewport")
	for button in guide.folder_buttons:
		expect(surface.encloses(button.get_global_rect()),"Folder fits "+button.text)
		expect(button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+18 <= button.size.x,"Folder label fits without truncation")
	for node in [guide.close_button,guide.page_title,guide.summary,guide.reader,guide.topic_scroll,guide.previous_button,guide.next_button]:
		expect(surface.encloses(node.get_global_rect()),"Guide element fits: "+node.name)
	expect(not guide.reader.get_global_rect().intersects(guide.topic_scroll.get_global_rect()),"Article clears topic navigation")
	expect(guide.reader.size.y >= 150,"Readable article area remains")
	expect(guide.reader.get_global_rect().end.y <= guide.next_button.get_global_rect().position.y,"Article never covers navigation")
	for button in guide.topic_buttons:
		expect(button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+18 <= button.size.x,"Topic label fits: "+button.text)

func capture(label: String,resolution: Vector2i) -> void:
	# Native resize can yield an empty backing texture for its first draw.
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	for attempt in range(10):
		if screenshot.get_pixel(50,50) != screenshot.get_pixel(0,0): break
		await create_timer(0.05).timeout
		await RenderingServer.frame_post_draw
		screenshot = root.get_texture().get_image()
	# Pause uses a centered panel; its top-left can legitimately equal the shade.
	var sample := Vector2i(resolution.x/2,resolution.y/2) if label == "pause" else Vector2i(50,50)
	expect(screenshot.get_pixelv(sample) != screenshot.get_pixel(0,0),"Capture contains rendered menu pixels")
	expect(screenshot.get_size() == resolution,"Native image dimensions verified")
	var path := OS.get_environment("PN_GUIDE_CAPTURE").path_join("%s-%dx%d.png" % [label,resolution.x,resolution.y])
	expect(screenshot.save_png(path) == OK,"Capture written")
	captures.append(path)
