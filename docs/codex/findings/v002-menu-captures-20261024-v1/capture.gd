extends SceneTree
var output := ""
func _initialize() -> void: _run.call_deferred()
func settle() -> void:
	await create_timer(.65).timeout
	for i in 4: await process_frame
func capture(label: String) -> void:
	Input.parse_input_event(InputEventMouseMotion.new())
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label+".png")) == OK)
	print("CAPTURED ",label," ",root.size)
func click(button: Button) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await settle()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game); current_scene = game
	await settle()
	var menu: MainMenu = game.get("_active_phase")
	assert(menu != null)
	await capture("main-menu")
	await click(menu.get_node("CenterContainer/MenuLayout/HowToPlay"))
	var guide: HowToPlayGuide = game.get_node("%GameplayHUD").how_to_play
	assert(guide.is_open())
	await capture("how-to-play")
	await click(guide.close_button)
	await click(menu.get_node("CenterContainer/MenuLayout/StartGame"))
	assert(menu._setup.visible)
	await capture("studio-creation")
	game.queue_free(); await process_frame
	quit()
