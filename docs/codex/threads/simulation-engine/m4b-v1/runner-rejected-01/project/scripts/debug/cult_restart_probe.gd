extends "res://scripts/debug/verify_fanbase_checkpoint.gd"
func _run() -> void:
	var mode := OS.get_environment("PN_CULT_MODE")
	var input := OS.get_environment("PN_CULT_INPUT")
	var c := CheckpointCoordinator.new(); root.add_child(c)
	c.store._writer = TCPServer.new()
	expect(c.store._writer.listen(48973,"127.0.0.1") == OK,"Dedicated test writer")
	var run: RunState
	if mode == "seed":
		var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input))
		run = c.adapter.hydrate(payload)
		expect(run != null,"Input native checkpoint validates")
		if run == null: quit(1); return
		c.attach(run); c.entered_studio()
	elif mode == "old":
		run = RunState.new(); run.initialize_cash_cents(0)
		expect(run._commit_studio_creation("Historical preview",&"action",StudioTraits.evaluate_traits([&"cult_following"],6)),"Historical fixture")
		var payload := c.adapter.capture(run)
		payload.content_revision = c.adapter._rules_revision(StudioCheckpoint.PRE_CULT_RULES)
		expect(c.store.save(payload).status == &"saved","Save supported prior revision")
		c.attach(run)
	else:
		var inspected := c.store.inspect()
		var hash_before := FileAccess.get_sha256(inspected.path)
		run = c.load_current()
		expect(run != null,"Independent process Continue")
		if run == null: quit(1); return
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://cult-expected.json"))
		expect(c.adapter.capture(run) == expected,"Exact Fans, finance, metadata, traits and RNG preserved")
		c.entered_studio(true)
		expect(FileAccess.get_sha256(inspected.path) == hash_before and not c.pending,"Passive Continue preserves bytes")
		for field: String in ["fans","seed"]:
			var broken := c.adapter.capture(run); broken.run.fanbase[field] = "999"
			expect(c.store.save(broken).status != &"saved" and FileAccess.get_sha256(inspected.path) == hash_before,"Tampering cannot replace good generation")
		if mode == "old_check": expect(run.get_fans() == 0 and run.get_cash_cents() == 570000 and run.get_studio_traits().version == 6,"Inactive preview isolation")
		if mode == "neutral":
			var before := run.get_fans()
			expect(run.register_release(fan_project(run,5.0,"Neutral constructed boundary")),"Neutral first launch")
			for i in range(2): expect(run.complete_productive_action(),"Neutral monthly accounting")
			expect(run.get_fans() == before,"Seed stays exactly neutral")
			c.pending = true
	if mode != "old": expect(c.flush() and c.failure.is_empty(),"Checkpoint write/flush")
	var payload := c.adapter.capture(run)
	expect(not payload.is_empty(),"Final provenance valid")
	FileAccess.open("user://cult-expected.json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	FileAccess.open(OS.get_environment("PN_CULT_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"mode":mode,"failures":failures,"payload":payload}))
	c.store.release_writer()
	print("CULT RESTART ",mode," failures=",failures)
	quit(0 if failures == 0 else 1)
