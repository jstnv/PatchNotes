extends "res://scripts/debug/verify_pause_menu.gd"

func _initialize() -> void:
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("Pause render NOT RUN: requires graphical rendering")
		quit(2)
		return
	create_timer(45).timeout.connect(func(): push_error("Pause render timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game._on_studio_created("Pause Menu", &"action", [], game._active_phase)
	await create_timer(0.4).timeout
	for size in [Vector2i(1280,720), Vector2i(1152,648)]:
		root.size = size
		await create_timer(0.1).timeout
		await key(KEY_ESCAPE)
		await capture("pause", size)
		game.pause_menu.settings_button.pressed.emit()
		await capture("settings", size)
		await key(KEY_ESCAPE)
		await key(KEY_ESCAPE)
	expect(game._begin_next_project(game._active_phase,"Unsaved project",&"action",&"fantasy"),"Render development route")
	await create_timer(0.4).timeout
	await key(KEY_ESCAPE)
	game.pause_menu.main_menu_button.pressed.emit()
	for size in [Vector2i(1280,720), Vector2i(1152,648)]:
		root.size = size
		await capture("confirm", size)
	game.queue_free()
	await process_frame
	print("PAUSE_RENDER checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)

func capture(label: String, size: Vector2i) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var view := Rect2(Vector2.ZERO, Vector2(size))
	var buttons: Array = [game.pause_menu.resume_button,game.pause_menu.settings_button,game.pause_menu.main_menu_button]
	if label == "settings": buttons = game.get_node("%GameplayHUD").settings_menu._focusable()
	for button: Control in buttons:
		if button.is_visible_in_tree():
			expect(view.encloses(button.get_global_rect()), "Visible %s control fits %s" % [button.name,size])
	var path := OS.get_environment("PN_PAUSE_CAPTURE").path_join("%s-%dx%d.png" % [label,size.x,size.y])
	expect(root.get_texture().get_image().save_png(path) == OK, "Rendered " + path)
