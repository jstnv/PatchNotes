extends "res://scripts/debug/verify_guided_tutorial_ui.gd"

func open_game() -> void:
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()

func close_game() -> void:
	game.queue_free()
	await process_frame
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = root.size
	node_added.connect(_replace_store)
	await open_game()
	expect(game._onboarding.answer(true), "Fixture remembers an experienced player's previous Skip")
	game._on_studio_created("Save tutorial invitation", &"action", [], game._active_phase)
	await settle()
	expect(game.guided_tutorial == null, "Ordinary Studio entry respects the answered preference")
	var original := state()
	var saved := disk()
	var inspected: Dictionary = game.checkpoints.store.inspect()
	expect(inspected.status == &"valid", "Fixture creates a real Studio/world save")
	var bytes := FileAccess.get_file_as_bytes(inspected.path)
	await close_game()
	for completed in [false, true]:
		await open_game()
		if completed: expect(game._onboarding.finish(), "Fixture remembers a completed tutorial")
		expect(game._active_phase is MainMenu, "Save opens through the actual Main Menu")
		game._active_phase.continue_requested.emit()
		expect(game.guided_tutorial == null and game._loading_checkpoint, "Invitation waits until the save loading overlay has finished")
		game._active_phase.continue_requested.emit()
		while game._loading_checkpoint: await process_frame
		await settle()
		var view: GuidedProductionTutorial = game.guided_tutorial
		expect(view != null and view.asking, "Opening a save offers the tutorial after previous " + ("completion" if completed else "Skip"))
		expect(game.get_node_or_null("ContinueLoading") == null, "Invitation appears after the loader is removed")
		expect(state() == original and disk() == saved, "Save invitation preserves every Studio/world/RNG field and disk generation")
		if view != null:
			game._offer_guided_tutorial()
			expect(game.guided_tutorial == view, "Repeated requests cannot stack invitations")
			await click(view.experienced_button)
			if completed:
				await click(view.start_button)
				expect(not view.asking and view.model.pool.size() == 4, "Returning players can start isolated practice from their save")
				await click(view.exit_button)
			else:
				await click(view.skip_button)
			expect(game.guided_tutorial == null and game._active_phase.visible, "Skip or Exit reveals the restored Studio")
			game._offer_guided_tutorial()
			expect(game.guided_tutorial == null, "Ordinary Studio navigation does not repeat the invitation")
			expect(state() == original and disk() == saved, "Skip and practice Exit preserve restored state and save bytes")
		await close_game()
	await open_game()
	game._continue_checkpoint()
	await settle()
	expect(game.guided_tutorial != null and game.guided_tutorial.asking, "Synchronous save restore also offers the tutorial")
	if game.guided_tutorial != null: game._close_guided_tutorial(false)
	expect(state() == original and disk() == saved, "Synchronous restore invitation preserves the Studio and saves")
	await close_game()
	await open_game()
	FileAccess.open(inspected.path, FileAccess.WRITE).store_string("{broken-after-preview")
	game._active_phase.continue_requested.emit()
	while game._loading_checkpoint: await process_frame
	await settle()
	expect(game.guided_tutorial == null and game._active_phase is MainMenu and game._recovery_dialog.visible, "Failed save loading shows recovery without a tutorial")
	FileAccess.open(inspected.path, FileAccess.WRITE).store_buffer(bytes)
	await close_game()
	print("Save tutorial invitation: %d checks, %d failures" % [checks, failures])
	quit(failures)
