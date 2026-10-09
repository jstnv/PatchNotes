extends "res://scripts/debug/verify_publisher_connections.gd"

func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var coordinator := CheckpointCoordinator.new()
	root.add_child(coordinator)
	coordinator.store._writer = TCPServer.new()
	if coordinator.store._writer.listen(47431,"127.0.0.1")!=OK: quit(2); return
	var run: RunState
	if mode=="initial":
		run = ready_run([&"publisher_connections"])
		coordinator.attach(run)
		coordinator.entered_studio()
	else:
		run = coordinator.load_current()
		expect(run!=null,"Separate-process Continue")
		if run==null: quit(1); return
		expect(JSON.stringify(coordinator.adapter.capture(run)).sha256_text()==FileAccess.get_file_as_string("user://connections.sha256"),"Exact saved state, no extra receipt")
		coordinator.entered_studio(true)
	if mode=="unsaved":
		var state := run.accept_primitive_contract()
		expect(state!=null and state.get_advance_cents()==55000,"Unsaved first acceptance gets $550")
		expect(coordinator.adapter.capture(run).is_empty(),"Active Contract remains outside checkpoint boundary")
		coordinator.store.release_writer()
		quit(failures)
		return
	if mode=="complete":
		expect(run.get_primitive_contract()==null,"Continue rolled unsaved acceptance back")
		var before := run.get_cash_cents()
		var state := run.accept_primitive_contract()
		expect(run.get_cash_cents()==before+55000,"Replay pays one receipt in restored timeline")
		finish_contract(run,state)
	elif mode=="inspect":
		expect(run.get_primitive_contract().get_advance_cents()==55000 and run.accept_primitive_contract()==null,"Completed identity survives; cannot reaccept")
	await process_frame
	expect(coordinator.flush() and coordinator.failure.is_empty(),"Committed Studio checkpoint saves")
	var payload := coordinator.adapter.capture(run)
	expect(not payload.is_empty(),"Final capture valid")
	var file := FileAccess.open("user://connections.sha256",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload).sha256_text())
	file.close()
	print("Connections restart %s: %d failures" % [mode,failures])
	coordinator.store.release_writer()
	quit(failures)
