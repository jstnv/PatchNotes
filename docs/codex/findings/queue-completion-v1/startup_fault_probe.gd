extends SceneTree
var failed := false
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	failed = failed or not ok
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	root.size = Vector2i(int(args[1]),int(args[2]))
	root.content_scale_size = root.size
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	root.size = Vector2i(int(args[1]),int(args[2]))
	root.content_scale_size = root.size
	await process_frame
	game.checkpoints.store._writer = TCPServer.new()
	check(game.checkpoints.store._writer.listen(47732,"127.0.0.1")==OK,"Isolated fixture lease")
	if args[0]=="prepare":
		game._on_studio_created("Recovery acceptance",&"action",[],game._active_phase)
		check(game.checkpoints.flush(),"Valid checkpoint baseline")
	else:
		check(game._startup_panel!=null and game._active_phase==null,"Actual cold startup data failure")
		if game._startup_panel!=null:
			var buttons: Array[Node] = game._startup_panel.find_children("*","Button",true,false)
			check(buttons.size()==3 and buttons[0].has_focus(),"Visible recovery and keyboard focus")
			buttons[1].pressed.emit()
			check(FileAccess.file_exists("user://startup-diagnostic.txt"),"Diagnostic written locally")
			await process_frame
			if not DisplayServer.get_name()=="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(args[5])
			FileAccess.open(args[3],FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes(args[4]))
			buttons[0].pressed.emit()
			await process_frame
			check(game._active_phase is MainMenu and game._startup_panel==null,"Retry after physical package repair")
			game._continue_checkpoint()
			await process_frame
			check(game._active_phase is StudioPhase and game.run_state.get_cash_cents()==570000 and game.run_state.get_completed_run_cycles()==0,"Original valid Studio resumes unchanged")
	game.queue_free()
	await process_frame
	quit(1 if failed else 0)
