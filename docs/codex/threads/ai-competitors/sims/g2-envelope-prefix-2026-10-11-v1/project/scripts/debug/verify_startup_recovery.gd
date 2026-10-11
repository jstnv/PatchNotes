extends "res://scripts/debug/verify_studio_checkpoint.gd"
func _run() -> void:
	var database := root.get_node("CardDatabase")
	expect(StartupDataCheck.inspect(database).is_empty(),"Current package data valid")
	for path in StartupDataCheck.PATHS:
		expect(StartupDataCheck.inspect(database,{path:"user://absent-ledger.json"}).contains("Missing"),"Missing required ledger rejected")
		FileAccess.open("user://bad-ledger.json",FileAccess.WRITE).store_string("{")
		expect(StartupDataCheck.inspect(database,{path:"user://bad-ledger.json"}).contains("Invalid JSON"),"Malformed required ledger rejected")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = RunState.new()
	root.add_child(game)
	await process_frame
	# Exercise the recovery panel with the same failure entry point; real missing
	# package files are covered separately in an isolated export/source copy.
	var previous: Control = game._active_phase
	previous.hide()
	game._active_phase = null
	var before := [game.run_state.get_cash_cents(),game.run_state.random_streams.snapshot()]
	game._show_startup_failure("Missing or unreadable game data: res://data/card_ledger.json")
	await process_frame
	expect(game._startup_panel != null,"Failure provides visible recovery controls")
	var buttons: Array[Node] = game._startup_panel.find_children("*","Button",true,false)
	expect(buttons.size()==3 and buttons[0].has_focus(),"Retry/diagnostic/Quit with visible keyboard focus")
	buttons[1].pressed.emit()
	expect(FileAccess.file_exists("user://startup-diagnostic.txt"),"Local diagnostic saved")
	expect(before==[game.run_state.get_cash_cents(),game.run_state.random_streams.snapshot()],"Failure and diagnostic preserve run and RNG")
	buttons[0].pressed.emit()
	await process_frame
	expect(game._startup_panel==null and game._active_phase is MainMenu,"Retry opens menu after valid data")
	previous.queue_free()
	game.queue_free()
	await process_frame
	print("Startup recovery: %d failures" % failures)
	quit(0 if failures==0 else 1)
