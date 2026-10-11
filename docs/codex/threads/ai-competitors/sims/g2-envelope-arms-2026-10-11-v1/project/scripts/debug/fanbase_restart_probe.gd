extends "res://scripts/debug/verify_fanbase_checkpoint.gd"

func _run() -> void:
	var mode: String=OS.get_cmdline_user_args()[0]
	var coordinator:=CheckpointCoordinator.new()
	root.add_child(coordinator)
	coordinator.store._writer=TCPServer.new()
	expect(coordinator.store._writer.listen(47843,"127.0.0.1")==OK,"Dedicated restart writer")
	var run: RunState
	if mode=="launch":
		run=fan_run()
		expect(run.register_release(fan_project(run,7.0,"Strong restart fixture")),"Commit initial Fan launch")
		coordinator.attach(run)
		coordinator.entered_studio()
	else:
		run=coordinator.load_current()
		expect(run!=null,"Separate-process Continue")
		if run==null:
			print("Restore diagnostic: ",coordinator.store.inspect()," / ",coordinator.adapter.error)
			quit(1);return
		expect(JSON.stringify(coordinator.adapter.capture(run)).sha256_text()==FileAccess.get_file_as_string("user://fans.sha256"),"Exact saved Fan, finance, launch and RNG state; no replay")
		coordinator.entered_studio(true)
	if mode in ["first","second","weak_first","weak_second"]:
		for i in range(2): expect(run.complete_productive_action(),"Real productive earning cycle")
	elif mode=="weak":
		expect(run.register_release(fan_project(run,4.0,"Weak restart fixture")),"Weak launch freezes current Fans")
	elif mode=="later":
		expect(run.register_release(fan_project(run,7.0,"Later restart fixture")),"Later launch sees preserved current Fans")
	await process_frame
	expect(coordinator.flush() and coordinator.failure.is_empty(),"Studio auto-save succeeds")
	var payload:=coordinator.adapter.capture(run)
	expect(not payload.is_empty(),"Final capture validates")
	FileAccess.open("user://fans.sha256",FileAccess.WRITE).store_string(JSON.stringify(payload).sha256_text())
	FileAccess.open("user://fans-%s.json"%mode,FileAccess.WRITE).store_string(JSON.stringify({"mode":mode,"fans":run.get_fanbase_snapshot(),"releases":run._release_metadata,"finance":run.get_studio_finance_snapshot(),"checkpoint":payload}))
	print("Fanbase restart %s: %d failures"%[mode,failures])
	coordinator.store.release_writer()
	quit(0 if failures==0 else 1)
