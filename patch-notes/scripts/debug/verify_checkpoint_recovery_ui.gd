extends "res://scripts/debug/verify_studio_checkpoint.gd"

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		root.size = size
		root.content_scale_size = size
		game.checkpoints.store.directory = ProjectSettings.globalize_path("user://ui-recovery-%d" % size.x)
		game.checkpoints.store._writer = TCPServer.new()
		expect(game.checkpoints.store._writer.listen(47830,"127.0.0.1")==OK,"Isolated UI checkpoint writer")
		game._on_studio_created("Recovery UI",&"action",[],game._active_phase)
		await process_frame
		var baseline: Dictionary = game.checkpoints.store.inspect()
		expect(baseline.status==&"valid","Initial valid Studio")
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		expect(game._begin_next_project(game._active_phase,"Discardable",&"action",&"fantasy"),"Real unsaved development")
		await process_frame
		game._request_quit()
		await process_frame
		expect(game._quit_dialog.visible and game._quit_dialog.get_cancel_button().has_focus(),"Quit explains rollback with Cancel focus")
		expect(game._quit_dialog.dialog_text.contains("cycle 0"),"Quit names original committed boundary")
		await escape()
		expect(not game._quit_dialog.visible and game.checkpoints.store.inspect().payload==baseline.payload,"Keyboard Cancel preserves run checkpoint")
		game._continue_checkpoint()
		await process_frame
		# A duplicate valid generation creates a backup without a gameplay grant.
		expect(game.checkpoints.store.save(baseline.payload).status==&"saved","Second valid storage generation fixture")
		var current: Dictionary = game.checkpoints.store.inspect()
		FileAccess.open(current.path,FileAccess.WRITE).store_string("{broken-ui-fixture")
		var bytes := FileAccess.get_file_as_bytes(current.path)
		game._show_checkpoint_recovery()
		await process_frame
		var dialog: ConfirmationDialog = game.get_children()[-1]
		expect(dialog.visible and dialog.get_cancel_button().has_focus(),"Recovery opens with Cancel focus")
		expect(dialog.size.x<=size.x and dialog.size.y<=size.y,"Recovery fits supported viewport")
		await escape()
		expect(not dialog.visible and FileAccess.get_file_as_bytes(current.path)==bytes,"Keyboard recovery Cancel preserves corrupt bytes")
		game._show_checkpoint_recovery()
		await process_frame
		dialog = game.get_children()[-1]
		dialog.get_cancel_button().pressed.emit()
		# Button pressed emission does not emulate mouse coordinates, but invokes
		# the same native button path; exported mouse verification is separate.
		await process_frame
		expect(FileAccess.get_file_as_bytes(current.path)==bytes,"Recovery button path is read-only on Cancel")
		dialog.hide()
		game.queue_free()
		await process_frame
	print("Checkpoint recovery UI: %d failures" % failures)
	quit(0 if failures==0 else 1)
