extends "res://scripts/debug/verify_research_integration.gd"

func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var coordinator := CheckpointCoordinator.new()
	root.add_child(coordinator)
	coordinator.store._writer = TCPServer.new()
	if coordinator.store._writer.listen(47430,"127.0.0.1")!=OK: quit(2); return
	var run: RunState
	if mode=="initial":
		run = fresh([&"resourceful"])
		coordinator.attach(run)
		coordinator.entered_studio()
	else:
		run = coordinator.load_current()
		expect(run!=null,"Separate process Continue succeeds")
		if run==null: quit(1); return
		expect(JSON.stringify(coordinator.adapter.capture(run)).sha256_text()==FileAccess.get_file_as_string("user://research-expected.sha256"),"Exact saved state restored without repeated payments")
		coordinator.entered_studio(true)
	if mode=="admit":
		expect(run.admit_feature_research(run.get_feature_research_quote(&"colored_text")),"Native admission")
		# Explicit constructed future-duration fixture; live admissions remain one.
		run._feature_research[0].actions = 2
		var second: StringName
		for item: Dictionary in FeatureStoreCatalog.starting_features():
			if not run.owns_feature(StringName(item.id)): second=StringName(item.id); break
		expect(run.admit_feature_research(run.get_feature_research_quote(second)),"Second queued entry")
	elif mode in ["partial","complete"]:
		var q := run.get_feature_research_quote(&"colored_text")
		expect(run.research_feature(q),"Native installment "+mode)
		expect(not run.research_feature(q),"Old installment callback rejected")
		expect(run.owns_feature(&"colored_text")== (mode=="complete"),"Ownership only at final completion")
	await process_frame
	expect(coordinator.flush() and coordinator.failure.is_empty(),"Automatic Studio checkpoint committed")
	var payload := coordinator.adapter.capture(run)
	expect(not payload.is_empty(),"Capture after committed action")
	var file := FileAccess.open("user://research-expected.sha256",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload).sha256_text())
	file.close()
	print("Research restart %s: %d failures" % [mode,failures])
	coordinator.store.release_writer()
	quit(failures)
