extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.checkpoints.store._writer = TCPServer.new()
	if game.checkpoints.store._writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")), "127.0.0.1") != OK:
		push_error("Quit probe writer collision"); quit(1); return
	game._on_studio_created("Quit probe", &"action", [], game._active_phase)
	await process_frame
	if game.guided_tutorial != null:
		game.guided_tutorial.experienced_button.pressed.emit()
		game.guided_tutorial.skip_button.pressed.emit()
	if not game._begin_next_project(game._active_phase, "Unsaved project", &"action", &"fantasy"):
		push_error("Quit probe project failed"); quit(1); return
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if not game._quit_dialog.visible:
		push_error("OS-close notification did not show confirmation"); quit(1); return
	print("QUIT_PROBE activating actual confirmation button; exit0 required before fallback")
	game._quit_dialog.get_ok_button().pressed.emit()
	await create_timer(1.0).timeout
	push_error("Quit confirmation failed to exit")
	quit(1)
