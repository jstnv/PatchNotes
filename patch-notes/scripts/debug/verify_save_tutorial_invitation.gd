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
	for preference in ["unanswered", "skipped", "completed"]:
		await open_game()
		if preference == "unanswered": game._onboarding.path = "user://never-answered.cfg"
		if preference == "completed": expect(game._onboarding.finish(), "Fixture remembers a completed tutorial")
		expect(game._active_phase is MainMenu, "Save opens through the actual Main Menu")
		game._active_phase.continue_requested.emit()
		expect(game.guided_tutorial == null and game._loading_checkpoint, "Invitation waits until the save loading overlay has finished")
		game._active_phase.continue_requested.emit()
		while game._loading_checkpoint: await process_frame
		await settle()
		expect(game.guided_tutorial == null and game._active_phase is StudioPhase and game._active_phase.visible, "Continue opens Studio without the tutorial with preference " + preference)
		expect(game.get_node_or_null("ContinueLoading") == null, "Loading overlay is removed")
		expect(state() == original and disk() == saved, "Continue preserves every Studio/world/RNG field and disk generation")
		if preference == "completed":
			expect(game._start_guided_practice(), "Returning players can still start optional practice")
			expect(game.guided_tutorial != null and not game.guided_tutorial.asking, "Manual practice skips the invitation")
			game._close_guided_tutorial(false)
			expect(state() == original and disk() == saved, "Practice exit preserves restored state and save bytes")
		await close_game()
	await open_game()
	game._continue_checkpoint()
	await settle()
	expect(game.guided_tutorial == null and game._active_phase is StudioPhase, "Synchronous restore also opens without an invitation")
	expect(state() == original and disk() == saved, "Synchronous restore preserves the Studio and saves")
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
