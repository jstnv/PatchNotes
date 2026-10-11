extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
var checks := 0
var failures := 0
func expect(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: "+label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var config: Dictionary = JSON.parse_string(OS.get_environment("PN_CULT20_CONFIG"))
	var mode := OS.get_environment("PN_CULT20_MODE")
	var c := CheckpointCoordinator.new(); root.add_child(c)
	c.store._writer = TCPServer.new()
	expect(c.store._writer.listen(48973,"127.0.0.1") == OK,"Isolated fixture writer")
	var run: RunState
	var commands := 0
	if mode == "write":
		if config.has("historical_version"):
			run = RunState.new(); run.initialize_cash_cents(0)
			expect(run._commit_studio_creation("Historical preview",&"action",StudioTraits.evaluate_traits([&"cult_following"],int(config.historical_version))),"Construct inactive historical fixture")
		else:
			var recipe := {"schema_version":1,"studio_id":"cult20-"+str(config.id),"studio_name":"Cult adoption fixture","specialty":"action","traits":config.traits,"seed":"4417"}
			var session: RefCounted = Factory.create({"recipe":recipe},root.get_node("CardDatabase").get_development_catalog())
			expect(session != null,"Legal recipe initializes")
			if session == null: quit(1); return
			var policy := Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Cult adoption","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
			while session.run.get_released_game_ids().size() < int(config.releases) and commands < 100:
				var decision: Dictionary = policy.call(session.observation())
				var result: Dictionary = session.execute(session.command(StringName(decision.type),decision.get("payload",{})))
				expect(result.ok,"Legal route command "+str(commands))
				if not result.ok: break
				commands += 1
			expect(session.in_studio and session.run.get_released_game_ids().size() == int(config.releases),"Declared release horizon completes at Studio")
			run = session.run
		var payload := c.adapter.capture(run)
		if config.has("historical_version"): payload.content_revision = c.adapter._rules_revision(StudioCheckpoint.PRE_CULT_RULES)
		expect(not payload.is_empty() and c.store.save(payload).status == &"saved","Write genuine storage generation with old/new runtime")
		FileAccess.open("user://cult20-expected.json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	else:
		var inspected := c.store.inspect()
		expect(inspected.status == &"valid","Stored generation validates before Continue")
		if inspected.status != &"valid": quit(1); return
		var original_hash := FileAccess.get_sha256(inspected.path)
		run = c.load_current()
		expect(run != null,"Actual coordinator Continue in independent process")
		if run == null: quit(1); return
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://cult20-expected.json"))
		expected.content_revision = c.adapter.revision()
		expect(c.adapter.capture(run) == expected,"All saved traits, Fan history, finance, releases and RNG unchanged")
		c.entered_studio(true)
		expect(not c.pending and FileAccess.get_sha256(inspected.path) == original_hash,"Passive Continue preserves original save bytes")
		var stable := c.adapter.capture(run)
		for field in ["fans","seed"]:
			var broken := stable.duplicate(true); broken.run.fanbase[field] = str(int(broken.run.fanbase[field])+1)
			expect(c.store.save(broken).status != &"saved" and FileAccess.get_sha256(inspected.path) == original_hash,"Tampered "+field+" cannot replace good save")
		if "cult_following" in config.get("traits",[]):
			var broken := stable.duplicate(true); broken.run.studio_traits.version = "8" if int(broken.run.studio_traits.version) == 7 else "7"
			expect(c.store.save(broken).status != &"saved" and FileAccess.get_sha256(inspected.path) == original_hash,"Trait restamp cannot reinterpret saved seed")
		var unsupported := stable.duplicate(true); unsupported.content_revision = c.adapter.previous_revision()
		expect(c.store.save(unsupported).status != &"saved" and FileAccess.get_sha256(inspected.path) == original_hash,"Unsupported pre-Fanbase revision preserves good save")
		expect(c.adapter.capture(run) == stable,"Failed loads/writes leave attached authority unchanged")
		if mode == "upgrade":
			c.pending = true
			expect(c.flush() and c.failure.is_empty(),"Explicit next save upgrades content revision")
			expect(c.store.inspect().payload.content_revision == c.adapter.revision(),"Next generation uses new revision")
			expect(c.adapter.capture(run) == stable,"Saving does not reseed or restamp traits")
			FileAccess.open("user://cult20-expected.json",FileAccess.WRITE).store_string(JSON.stringify(stable))
	var final := c.adapter.capture(run)
	expect(not final.is_empty(),"Final provenance valid")
	expect(int(final.run.studio_traits.version) == int(config.version) and int(final.run.fanbase.seed) == int(config.seed_fans),"Expected historical or new trait/seed pair")
	FileAccess.open(OS.get_environment("PN_CULT20_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"ok":failures == 0,"checks":checks,"failures":failures,"mode":mode,"commands":commands,"payload":final}))
	c.store.release_writer()
	print("CULT20 RESTART checks=",checks," failures=",failures)
	quit(0 if failures == 0 else 1)
