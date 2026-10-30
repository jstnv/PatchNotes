extends "res://scripts/debug/verify_studio_checkpoint.gd"

class ContendingStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(47830,"127.0.0.1") != OK: return false
		_writer = server
		return true

func visible_dialogs(game: Control) -> Array[Window]:
	var result: Array[Window] = []
	for child in game.get_children():
		if child is Window and child.visible: result.append(child)
	return result

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

func settle_continue(game: Control) -> void:
	while game._loading_checkpoint: await process_frame
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
		if game.guided_tutorial != null:
			game.guided_tutorial.experienced_button.pressed.emit()
			game.guided_tutorial.skip_button.pressed.emit()
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		expect(game._begin_next_project(game._active_phase,"Discardable",&"action",&"fantasy"),"Real unsaved development")
		await process_frame
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		await process_frame
		expect(game._quit_dialog.visible and game._quit_dialog.get_cancel_button().has_focus(),"Quit explains rollback with Cancel focus")
		expect(game._quit_dialog.dialog_text.contains("cycle 0"),"Quit names original committed boundary")
		expect(game._quit_dialog.borderless and game._quit_dialog.has_node("QuitCopy/Header/Heading") and game._quit_dialog.get_node("QuitCopy/Header/Heading").get_theme_font("font") == FolderUI.THEME.get_font("font","FolderHeading"),"Quit uses the shared heading without the default window chrome")
		expect(game._quit_dialog.get_ok_button().text == "Quit" and game._quit_dialog.get_cancel_button().custom_minimum_size.y >= 44,"Quit has explicit, menu-sized action controls")
		expect(game._quit_dialog.dialog_autowrap,"Quit warning wraps within a bounded menu surface")
		await create_timer(0.3).timeout
		expect(game._quit_dialog.size.x <= size.x - 80 and game._quit_dialog.size.y <= size.y - 80,"Quit confirmation fits the supported viewport")
		expect(game._quit_dialog.transparent_bg,"Quit has transparent clipped corners")
		if DisplayServer.get_name() != "headless":
			expect(game._quit_dialog.position == (size - game._quit_dialog.size) / 2,"Quit slide lands centered in the native viewport")
		var capture := OS.get_environment("PN_CARD_FRAME_OUTPUT")
		if not capture.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture.get_basename()+"-%d.png"%size.x)
		await escape()
		expect(not game._quit_dialog.visible and game.checkpoints.store.inspect().payload==baseline.payload,"Keyboard Cancel preserves run checkpoint")
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		game._quit_dialog.get_node("QuitCopy/Header/Close").pressed.emit()
		await process_frame
		expect(not game._quit_dialog.visible and game.checkpoints.store.inspect().payload==baseline.payload,"Themed close button cancels without quitting or changing the checkpoint")
		game._continue_checkpoint()
		await process_frame
		# Explicitly Skip the save-opening invitation before recovery testing.
		if game.guided_tutorial != null:
			game.guided_tutorial.experienced_button.pressed.emit()
			game.guided_tutorial.skip_button.pressed.emit()
		# Hold the real isolated TCP writer lease while Continue tries to acquire it.
		var owner: StudioCheckpointStore = game.checkpoints.store
		game.checkpoints.store = ContendingStore.new(owner.directory,owner.validator)
		game._continue_checkpoint()
		await process_frame
		for retry in range(3):
			var visible := visible_dialogs(game)
			expect(visible.size()==1 and visible[0].title=="Saved Studio recovery","Busy Continue has exactly one recovery modal")
			expect(not game._save_failure_dialog.visible,"Load failure does not open a competing save-failure modal")
			# Test the real AcceptDialog OK-button callback ordering.
			var recovery: AcceptDialog = game.get_children()[-1]
			recovery.get_ok_button().pressed.emit()
			await settle_continue(game)
		game._checkpoint_status()
		expect(visible_dialogs(game).size()==1,"Repeated status does not compete with recovery")
		var recovery_count := 0
		for child in game.get_children():
			if child is Window and child.title=="Saved Studio recovery": recovery_count += 1
		expect(recovery_count==1,"Retry replaces old recovery windows without accumulating them")
		for window in visible_dialogs(game): window.hide()
		game._confirm_return_checkpoint()
		await process_frame
		var return_dialog: ConfirmationDialog = game.get_children()[-1]
		return_dialog.get_ok_button().pressed.emit()
		await process_frame
		expect(visible_dialogs(game).size()==1 and visible_dialogs(game)[0].title=="Saved Studio recovery","Failed confirmed return hands off to recovery")
		owner.release_writer()
		var recovery: AcceptDialog = game.get_children()[-1]
		recovery.get_ok_button().pressed.emit()
		await settle_continue(game)
		expect(visible_dialogs(game).is_empty() and game.checkpoints.failure.is_empty(),"Retry after lease release restores Studio without stale dialogs")
		expect(game.checkpoints.store.inspect().payload==baseline.payload,"All failed retries preserve the saved generation")
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
		game.checkpoints.failure = "Synthetic save-write failure"
		game._checkpoint_status()
		expect(game._save_failure_dialog.visible,"Ordinary save failure still prompts Retry")
		game._show_checkpoint_recovery()
		expect(visible_dialogs(game).size()==1 and not game._save_failure_dialog.visible,"Direct recovery replaces a visible save-failure dialog")
		game._request_quit()
		expect(visible_dialogs(game).size()==1 and game._quit_dialog.visible,"Quit replaces recovery without modal collision")
		await escape()
		expect(visible_dialogs(game).is_empty() and FileAccess.get_file_as_bytes(current.path)==bytes,"Quit Cancel leaves original save bytes untouched")
		game.queue_free()
		await process_frame
	print("Checkpoint recovery UI: %d failures" % failures)
	quit(0 if failures==0 else 1)
