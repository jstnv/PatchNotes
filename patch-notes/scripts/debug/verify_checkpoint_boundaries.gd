extends "res://scripts/debug/verify_annual_awards_gameplay.gd"

func go() -> void:
	var fixture := OS.get_environment("PN_AWARDS_UI_FIXTURE")
	check(not fixture.is_empty(), "A real paired awards fixture is required")
	if fixture.is_empty(): finish(); return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture))
	var game := await mount(data, "boundaries")
	if game == null: finish(); return
	game._awards_animate = false
	if not await wait_for(func(): return ready_ceremony(game,0), "Ceremony opens"):
		game.queue_free(); await settle(); finish(); return
	var owner: CheckpointCoordinator = game.checkpoints
	owner.entered_studio()
	check(await owner.wait_saved(), "Studio entry publishes a paired checkpoint")
	var publications := owner.completed_saves
	var frozen := var_to_bytes(game.rival_world.annual_awards.entries[0].result)
	var player := StudioCheckpoint.new().capture(game.run_state)
	game.annual_awards_ceremony.next_button.pressed.emit()
	check(ready_ceremony(game,1), "Next changes page immediately without a save wait")
	game.annual_awards_ceremony.next_button.pressed.emit()
	check(ready_ceremony(game,1), "Same-frame duplicate activation does not skip a page")
	await settle()
	check(not owner.is_saving() and owner.completed_saves == publications, "Next does not start a save")
	if "--red-only" in OS.get_cmdline_user_args():
		game.queue_free(); await settle(); finish(); return
	if "--quit-only" in OS.get_cmdline_user_args():
		game.tree_exiting.connect(func():
			check(owner.completed_saves == publications + 1 and stored_entry(game).stage == "1", "Actual game Quit publishes the latest ceremony page")
			check(not owner.is_saving(), "Quit waits until publication has completed")
			print("CHECKPOINT_BOUNDARIES_QUIT checks=%d failures=%d" % [checks, failures]))
		game._request_quit()
		return
	for stage in range(2,10):
		game.annual_awards_ceremony.next_button.pressed.emit()
		check(ready_ceremony(game,stage), "Immediate ceremony page %d" % stage)
		await settle()
	check(owner.completed_saves == publications and not owner.is_saving(), "All nine Next actions leave the checkpoint unchanged")
	check(stored_entry(game).stage == "0", "Only the Studio-entry stage is durable so far")
	game.annual_awards_ceremony.next_button.pressed.emit()
	await wait_for(func(): return not game.annual_awards_blocking(), "Ceremony Exit restores Studio")
	check(owner.completed_saves == publications and not owner.is_saving(), "Closing the overlay does not save the retained Studio again")
	check(StudioCheckpoint.new().capture(game.run_state) == player and var_to_bytes(game.rival_world.annual_awards.entries[0].result) == frozen, "Navigation preserves exact player and frozen award rewards")
	check(game.run_state.add_cash(1), "Ordinary Studio action succeeds")
	await settle()
	check(owner.pending and not owner.is_saving() and owner.completed_saves == publications, "Studio actions stay dirty without saving")
	check(owner.before_departure(), "Production departure is permitted")
	check(owner.completed_saves == publications, "Production departure does not save")
	owner.in_studio = false
	check(await owner.wait_saved() and owner.completed_saves == publications, "No mid-production checkpoint can publish")
	owner.entered_studio()
	check(await owner.wait_saved(), "Returning to Studio saves current state")
	check(owner.completed_saves == publications + 1 and stored_entry(game).complete, "Entry includes final ceremony state and Studio changes")
	publications = owner.completed_saves
	# Make a later change while a detached Studio-entry snapshot is in flight.
	check(game.run_state.add_cash(1), "Prepare a fresh Studio entry")
	owner.entered_studio()
	owner._request_save()
	var entry_cash: int = game.run_state.get_cash_cents()
	check(game.run_state.add_cash(1), "Studio remains interactive during the entry write")
	check(await owner.wait_for_requested_save(), "In-flight entry finishes")
	await settle()
	check(owner.completed_saves == publications + 1 and owner.pending and not owner.is_saving(), "Post-snapshot actions do not chain another autosave")
	check(owner.last_payload.run.cash_cents == str(entry_cash), "The entry snapshot stays frozen during later actions")
	publications = owner.completed_saves
	check(game.run_state.add_cash(1), "Prepare exit changes")
	owner.store.fault = &"before_write"
	check(not await owner.wait_saved(), "Exit save failure is reported")
	check(owner.completed_saves == publications and not game.run_state.checkpoint_mutations_allowed, "Failure preserves durable checkpoint and blocks mutations")
	owner.store.fault = &""
	check(await owner.retry_background(), "Explicit Retry saves the pending state")
	check(owner.completed_saves == publications + 1, "Retry publishes once")
	game._save_failure_dialog.hide()
	var expected_cash: int = game.run_state.get_cash_cents()
	game._continue_checkpoint()
	await wait_for(func(): return not game.annual_awards_blocking(), "Continue restores completed presentation")
	check(game.run_state.get_cash_cents() == expected_cash and game.rival_world.annual_awards.entries[0].complete, "Continue restores the exact latest boundary")
	check(var_to_bytes(game.rival_world.annual_awards.entries[0].result) == frozen, "Continue never reranks or repays awards")
	publications = owner.completed_saves
	check(game.run_state.add_cash(1), "Prepare an unsaved Studio action before production")
	check(game._begin_next_project(game._active_phase,"Boundary rollback",&"action",&"fantasy"), "Actual Studio begins production")
	await process_frame
	check(not owner.in_studio and owner.completed_saves == publications, "Actual production departure leaves the checkpoint unchanged")
	game.pause_menu.open()
	game._request_main_menu()
	check(game.pause_menu.confirming, "Production Main Menu requires rollback confirmation")
	game._resume_from_pause()
	game._request_quit()
	check(game._quit_dialog.visible and owner.completed_saves == publications, "Production Quit confirms rollback without saving mid-phase")
	game._hide_checkpoint_dialogs()
	game._continue_checkpoint()
	await settle()
	check(game._active_phase is StudioPhase and game.project_state == null and game.run_state.get_cash_cents() == expected_cash, "Continue rolls back production and earlier unsaved Studio actions")
	check(game.run_state.add_cash(1), "Prepare a Studio change before Main Menu")
	var menu_cash: int = game.run_state.get_cash_cents()
	game.tree_exiting.connect(func():
		check(owner.last_payload.run.cash_cents == str(menu_cash) and not owner.is_saving(), "Actual Main Menu waits for the latest Studio save"))
	current_scene = game
	game.pause_menu.open()
	game._request_main_menu()
	await game.tree_exited
	await settle()
	check(current_scene != null and current_scene._active_phase is MainMenu, "Main Menu transition completes")
	current_scene.queue_free()
	await settle()
	finish()
