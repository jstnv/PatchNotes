extends SceneTree
const Launch := preload("res://scripts/simulation/launch_settlement.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
var traces: Array = []

func expect(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func fixture(seed_value: int, scenario: int) -> Dictionary:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Launch parity",&"action",[&"studio_buzz",&"unknown_name"] if scenario == 2 else [])
	run._bank_run_id = &"launch_parity"
	run._employees = EmployeeRoster.create(&"launch_parity")
	run._fanbase = StudioFanbase.create(597 if scenario == 2 else 93)
	if scenario == 2: run._promotion_awards[&"prior_offer"] = 8
	for id in RunRandom.STREAMS: run.random_streams.stream(id).seed = seed_value + RunRandom.STREAMS.find(id)
	var project := PrimitivePredevelopment.prepare_project("Repeated title",&"action",&"fantasy",run)
	project._release_id = &"launch_parity:project:1"
	project.initialize_snapshots(&"fast_follower",&"stable_market" if scenario == 0 else &"market_surge")
	project.add_core_scores_and_scope({0:40,1:26,2:40,3:26},30 if scenario == 0 else 21)
	run.record_resolved_feature(project,&"text",&"design")
	project.finalize_design_bugs(false,0 if scenario == 0 else 4,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.add_marketing_output(scenario*5)
	if scenario == 2:
		project.reveal_competitor_snapshot()
		project.reveal_market_forecast_snapshot()
	project.finalize_beta()
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	return {"project":project,"run":run,"snapshots":snapshots}

func capture(f: Dictionary,events: Array) -> Dictionary:
	return {"project":Replay.freeze(f.project),"run":Replay.freeze(f.run),"events":events.duplicate(true)}

func _initialize() -> void:
	await process_frame
	var oracle_path := ProjectSettings.globalize_path("res://../docs/codex/threads/simulation-engine/m3a-v1/gameplay_oracle.gd")
	var oracle: Script = load(oracle_path)
	for seed_value in [1104,4417,90210]:
		for scenario in range(3):
			var outcomes: Array = []
			for mode in ["original","live","headless"]:
				var f := fixture(seed_value,scenario)
				var events: Array = []
				f.project.values_changed.connect(func() -> void: events.append("project_values"))
				for signal_name in ["sales_changed","fans_changed","publishers_changed","redraws_changed"]:
					f.run.connect(signal_name,func() -> void: events.append(signal_name))
				var before := [f.run.get_cash_cents(),f.run.get_completed_run_cycles(),f.project.get_current_cycle()]
				if mode == "headless":
					var settlement := Launch.new(f.project,f.run,f.snapshots)
					expect(settlement.settle().ok,"Headless settlement")
				else:
					var game: Control = oracle.new() if mode == "original" else load("res://scripts/gameplay.gd").new()
					game.project_state = f.project
					game.run_state = f.run
					game._snapshot_database = f.snapshots
					game._review_rng = f.run.random_streams.stream(&"review")
					for stage in Launch.STAGES: expect(game.call("_ensure_"+stage+"_result"),mode+" freeze "+stage)
					expect(f.run.register_release(f.project),mode+" registration")
					game.free()
				f.run.refresh_redraws()
				expect(before == [f.run.get_cash_cents(),f.run.get_completed_run_cycles(),f.project.get_current_cycle()],"Launch has zero cash/cycle cost")
				var frozen := capture(f,events)
				expect(Launch.new(f.project,f.run,f.snapshots).settle().ok and frozen == capture(f,events),"Duplicate settlement changes no result, award, RNG or notification")
				outcomes.append(frozen)
			expect(outcomes[0] == outcomes[1] and outcomes[1] == outcomes[2],"Original/live/headless exact launch parity")
			traces.append({"seed":seed_value,"scenario":scenario,"original":outcomes[0],"live":outcomes[1],"headless":outcomes[2]})
	# Deliberately constructed invalid state: reject before any freeze/RNG/event.
	for failure_kind in ["snapshot","awareness","fanbase","checkpoint"]:
		var f := fixture(4417,2)
		if failure_kind == "snapshot": f.project._market_forecast_snapshot_id = &"missing"
		if failure_kind == "awareness": f.project._marketing_output = ProjectState.MAX_SIGNED_INT
		if failure_kind == "fanbase": f.run._fanbase.releases[f.project.get_release_id()] = {}
		if failure_kind == "checkpoint": f.run.checkpoint_mutations_allowed = false
		var events: Array = []
		f.project.values_changed.connect(func() -> void: events.append("project"))
		var before := capture(f,events)
		expect(not Launch.new(f.project,f.run,f.snapshots).settle().ok and before == capture(f,events),failure_kind+" rejected without partial freeze")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
	print("Launch extraction verification: %d failures; 9 original/live/headless fixtures" % failures)
	quit(1 if failures else 0)
