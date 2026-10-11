extends "res://scripts/debug/verify_design_command.gd"

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const SCENARIOS := ["mixed", "qa", "marketing", "balanced", "insiders", "revealed", "depleted", "pending", "retained_corrective", "corrective", "unauthorized_pass", "invalid_snapshot", "duplicate_finite", "exhausted", "foreign_card", "cycle_ceiling", "cash_overflow", "marketing_overflow", "core_overflow", "bad_insight", "refill_reject", "view_reject", "run_ceiling", "bad_pending", "finance_reject", "insight_success", "insight_failure", "controlled_refill"]
const REJECTIONS := ["unauthorized_pass", "invalid_snapshot", "duplicate_finite", "exhausted", "foreign_card", "cycle_ceiling", "cash_overflow", "marketing_overflow", "core_overflow", "bad_insight", "refill_reject", "view_reject", "run_ceiling", "bad_pending", "finance_reject"]

func _initialize() -> void:
	await process_frame
	mode = OS.get_environment("PN_BETA_COMMAND_MODE")
	var modes := [mode] if not mode.is_empty() else ["live", "headless"]
	for selected_mode in modes:
		mode = selected_mode
		traces.clear()
		await run_cases(root.get_node("CardDatabase"))
	quit(1 if _failures else 0)

func snapshot(phase: Object, project: ProjectState, run: RunState) -> Dictionary:
	var injected: Array = []
	if mode == "headless":
		for id in phase.candidate_ids: injected.append(id in phase.injected_candidate_ids)
	else:
		for view in phase.get("_candidate_views"): injected.append(view in phase.get("_injected_corrective_views"))
	return {"project":freeze(project), "run":freeze(run), "candidates":freeze(phase.get("_candidate_cards")), "pending":freeze(phase.get("_pending_corrective_pass_ids")), "injected":injected, "priorities":freeze(phase.call("get_priority_distribution"))}

func run_cases(database: Node) -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	_expect(snapshots.load_ledgers(), "Snapshot definitions load")
	for seed_value in [1104,4417,90210]:
		for scenario in SCENARIOS:
			var project := ProjectState.new(30)
			project.set("_release_id", &"m2c_project")
			project.initialize_snapshots(&"fast_follower", &"market_surge")
			project.finalize_design_bugs(false,20,[],[])
			project.finalize_alpha(0,[],[])
			var run := RunState.new()
			run.initialize_cash(0)
			_expect(run.create_studio_with_traits("M2c", &"action", []), "Studio fixture initializes")
			run.set("_bank_run_id", &"m2c_studio")
			run.set("_employees", EmployeeRoster.create(&"m2c_studio"))
			for id in RunRandom.STREAMS: run.random_streams.stream(id).seed = seed_value + RunRandom.STREAMS.find(id)
			var phase: Object
			if mode == "headless":
				phase = load("res://scripts/simulation/beta_hand_command.gd").new()
				phase._project_state = project
				phase._run_state = run
				phase._snapshot_database = snapshots
				phase._deal_rng = run.random_streams.stream(&"beta_deal")
				phase._insight_rng = run.random_streams.stream(&"beta_insight")
				phase.active = true
				phase.priorities = BetaPriorityAllocation.new().get_distribution()
				for card in database.get_cards_by_phase(CardData.PHASE_BETA):
					phase._definitions_by_id[card.id] = card
					phase._beta_definitions.append(card)
				for id in [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"]: phase._definitions_by_id[id] = database.get_card(id)
			else:
				phase = BETA_SCENE.instantiate()
				if mode == "oracle": phase.set_script(load(ProjectSettings.globalize_path("res://../docs/codex/threads/simulation-engine/m2c-v1/beta_phase_oracle.gd")))
				root.add_child(phase)
				await process_frame
				_expect(phase.setup(project,run,snapshots), "Beta setup accepted")
				phase.set("_phase_state",1)
			var ids: Array[StringName] = [&"debug", &"search_for_bugs", &"posters", &"press_release", &"sign_flippers", &"debug", &"search_for_bugs"]
			match scenario:
				"qa": ids.assign([&"search_for_bugs", &"debug", &"search_for_bugs", &"debug", &"posters", &"sign_flippers", &"press_release"])
				"marketing", "marketing_overflow": ids.assign([&"sign_flippers", &"posters", &"press_release", &"press_interview", &"search_for_bugs", &"debug", &"posters"])
				"balanced": ids.assign([&"debug", &"search_for_bugs", &"sign_flippers", &"study_competition", &"press_interview", &"posters", &"debug"])
				"insiders", "revealed", "cash_overflow", "bad_insight", "insight_success", "insight_failure", "refill_reject", "view_reject": ids.assign([&"predict_market_trends", &"study_competition", &"playtest_rival_games", &"debug", &"press_interview", &"posters", &"search_for_bugs"])
				"corrective", "core_overflow", "unauthorized_pass": ids.assign([&"graphics_pass", &"sound_pass", &"search_for_bugs", &"debug", &"press_interview", &"posters", &"search_for_bugs"])
				"retained_corrective": ids[4] = &"graphics_pass"; ids[5] = &"sound_pass"
				"duplicate_finite": ids[0] = &"press_interview"; ids[1] = &"press_interview"
				"exhausted": ids[0] = &"press_interview"
			var cards := _cards(database,ids)
			if scenario == "foreign_card":
				var forged := CardData.new()
				for property in cards[0].get_property_list():
					if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE: forged.set(property.name,cards[0].get(property.name))
				cards[0] = forged
			if mode == "headless":
				phase._candidate_cards.assign(cards)
				phase.candidate_ids.assign([0,1,2,3,4,5,6])
				phase.next_candidate_id = 7
				if scenario in ["corrective","core_overflow"]: phase.injected_candidate_ids.assign([0,1])
				if scenario == "retained_corrective": phase.injected_candidate_ids.assign([4,5])
			else:
				install_pool(phase,cards)
				if scenario in ["corrective","core_overflow"]: phase._injected_corrective_views.assign(phase._candidate_views.slice(0,2))
				if scenario == "retained_corrective": phase._injected_corrective_views.assign(phase._candidate_views.slice(4,6))
			if scenario == "revealed": project.reveal_competitor_snapshot(); project.reveal_market_forecast_snapshot()
			if scenario == "depleted": project.exhaust_beta_cards([&"playtest_rival_games", &"study_competition", &"predict_market_trends"])
			if scenario in ["pending","bad_pending"]: phase._pending_corrective_pass_ids.assign([&"graphics_pass", &"sound_pass" if scenario == "pending" else &"graphics_pass"])
			if scenario == "invalid_snapshot": project.set("_competitor_snapshot_id",&"unknown")
			if scenario == "exhausted": project.exhaust_beta_cards([&"press_interview"])
			if scenario == "cycle_ceiling": project.set("_current_cycle",ProjectState.MAX_SIGNED_INT)
			if scenario == "run_ceiling": run.set("_completed_run_cycles",RunState.MAX_SIGNED_INT)
			if scenario == "cash_overflow": run.set("_cash_cents",RunState.MAX_SIGNED_INT)
			if scenario == "marketing_overflow": project.set("_marketing_output",ProjectState.MAX_SIGNED_INT)
			if scenario == "core_overflow": project.set("_core_scores",{0:ProjectState.MAX_SIGNED_INT,1:0,2:0,3:0} as Dictionary[ProjectState.CoreScore,int])
			if scenario == "finance_reject": run.set("_studio_finance",{})
			if scenario == "view_reject" and mode != "headless": phase.force_card_view_preparation_failure_for_verification()
			var events: Array = []
			for id in [&"values_changed", &"cycle_changed"]: project.connect(id,func() -> void: events.append(str(id)))
			for id in [&"cash_changed", &"calendar_changed", &"redraws_changed", &"features_changed", &"sales_changed", &"contracts_changed", &"publishers_changed", &"finance_changed", &"fans_changed", &"employees_changed"]: run.connect(id,func() -> void: events.append(str(id)))
			if mode != "oracle" and scenario == "mixed": project.values_changed.connect(func() -> void: check_reentry(phase,project,run))
			var steps: Array = []
			for step in range(3):
				if mode != "headless":
					phase.get_workspace().hand_motion.cancel()
					phase._selected_card_views.assign(phase._candidate_views.slice(0,4))
				var before := snapshot(phase,project,run)
				events.clear()
				var insight: Array[int] = []
				var categories: Array[float] = []
				var definitions: Array[float] = []
				if scenario == "bad_insight": insight = [100]
				if scenario == "refill_reject": categories = [0.1]
				if scenario == "insight_success" and step == 0: insight = [9,29]
				if scenario == "insight_failure" and step == 0: insight = [10,30,30]
				if scenario == "controlled_refill" and step == 0: categories = [0.1,0.5,0.9,0.1]; definitions = [0.2,0.4,0.6,0.8]
				var accepted: bool
				if mode == "headless":
					var request: Dictionary = phase.command(phase.candidate_ids.slice(0,4))
					var retained_ids: Array = phase.candidate_ids.slice(4)
					var command_before: Variant = freeze(phase)
					for invalid in [{}, {"candidate_ids":[-1,-2,-3,-4]}, {"candidate_ids":[request.candidate_ids[0],request.candidate_ids[0],request.candidate_ids[1],request.candidate_ids[2]]}, {"project_id":&"wrong"}, {"revision":-1}, {"revision":0.0}, {"schema_version":2}, {"project_cycle":request.project_cycle+1}, {"run_cycle":request.run_cycle+1}]:
						var rejected: Dictionary = request.duplicate(true)
						if invalid.is_empty(): rejected = {}
						else: rejected.merge(invalid,true)
						var rejection: Dictionary = phase.execute(rejected)
						_expect(not rejection.ok and rejection.events.is_empty() and freeze(phase)==command_before,"Malformed/stale Beta command rejects without mutation")
					var readiness: Callable = func(_cards: Array) -> bool: return false
					var result: Dictionary = phase.execute(request,insight,categories,definitions,readiness if scenario == "view_reject" else Callable())
					accepted = result.ok
					if accepted:
						var after := snapshot(phase,project,run)
						_expect(not phase.execute(request).ok and snapshot(phase,project,run)==after,"Replaying a successful Beta command rejects unchanged")
						_expect(result.events[-1].type=="refill", "Refill is the final command event")
						_expect(phase.candidate_ids.slice(0,3)==retained_ids,"Retained instance tokens are stable")
						var debug_seen := false
						for event in result.events:
							if event.type=="debug": debug_seen=true
							if event.type=="search": _expect(not debug_seen and event.actual>=0,"Ordered command events preserve Search before Debug")
					else: _expect(snapshot(phase,project,run)==before,"Rejected command preserves all state and RNG")
				else:
					accepted = phase.play_selected_hand(insight,categories,definitions)
					phase.get_workspace().hand_motion.cancel()
				var after_state := snapshot(phase,project,run)
				_expect(accepted == (scenario not in REJECTIONS),"Intended Beta acceptance: " + scenario)
				check_invariants(before,after_state,scenario,step,project,phase)
				steps.append({"before":before,"after":after_state,"accepted":accepted,"events":events.duplicate()})
			traces.append({"seed":seed_value,"scenario":scenario,"steps":steps})
			if mode != "headless": phase.free()
	var digests: Array = []
	for trace in traces: digests.append({"seed":trace.seed,"scenario":trace.scenario,"sha256":JSON.stringify(trace).sha256_text()})
	var expected_path := "res://scripts/debug/fixtures/beta_command_oracle_digests.json"
	if mode != "oracle":
		_expect(FileAccess.file_exists(expected_path),"Pinned Beta oracle digests exist")
		if FileAccess.file_exists(expected_path): _expect(JSON.parse_string(JSON.stringify(digests))==JSON.parse_string(FileAccess.get_file_as_string(expected_path)),mode+" complete Beta trace matches original")
	var output_path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output_path.is_empty():
		FileAccess.open(output_path+"."+mode,FileAccess.WRITE).store_string(JSON.stringify(traces,"\t"))
		FileAccess.open(output_path+"."+mode+".digests.json",FileAccess.WRITE).store_string(JSON.stringify(digests,"\t"))
	print("Beta command trace capture: %d scenarios (%s)" % [traces.size(),mode])

func install_pool(phase: Node,cards: Array[CardData]) -> void:
	for view in phase._candidate_views: phase.get_node("%HandContainer").remove_child(view); view.free()
	phase._candidate_views.clear()
	phase._candidate_cards.assign(cards)
	for card in cards:
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(phase,"_on_card_pressed"))
		phase.get_node("%HandContainer").add_child(view)
		phase._candidate_views.append(view)

func check_reentry(phase: Object,project: ProjectState,run: RunState) -> void:
	var before := snapshot(phase,project,run)
	if mode=="headless":
		var result: Dictionary = phase.execute(phase.command(phase.candidate_ids.slice(0,4)))
		_expect(not result.ok and result.events.is_empty(),"Reentrant Beta command rejected")
	else: _expect(not phase.play_selected_hand(),"Reentrant live Beta hand rejected")
	_expect(snapshot(phase,project,run)==before,"Production signals cannot apply a second hand")

func check_invariants(before: Dictionary,after: Dictionary,scenario: String,step: int,project: ProjectState,_phase: Object) -> void:
	if scenario in REJECTIONS: _expect(before==after,"Atomic rejection: "+scenario); return
	_expect(int(after.project._current_cycle.integer)==int(before.project._current_cycle.integer)+1,"Exactly one project cycle")
	_expect(int(after.run._completed_run_cycles.integer)==int(before.run._completed_run_cycles.integer)+1,"Exactly one run cycle")
	_expect(after.candidates.slice(0,3)==before.candidates.slice(4),"Three unplayed candidate instances retained in order")
	var bugs_before := int(before.project._hidden_bugs.integer)+int(before.project._known_bugs.integer)+int(before.project._fixed_bugs.integer)
	_expect(project.get_hidden_bugs()+project.get_known_bugs()+project.get_fixed_bugs()==bugs_before,"QA conserves total discovered/hidden/fixed Bugs")
	_expect(after.injected.slice(0,3)==before.injected.slice(4),"Unplayed corrective instance authorization survives refill")
	if step==0:
		if scenario=="qa": _expect(project.get_hidden_bugs()==8 and project.get_known_bugs()==8 and project.get_fixed_bugs()==4,"QA applies sequential Search before Debug despite selection order")
		if scenario=="marketing": _expect(project.get_marketing_output()==10,"Marketing rounds the total once")
		if scenario=="mixed": _expect(project.get_hidden_bugs()==15 and project.get_fixed_bugs()==2 and project.get_known_bugs()==3,"Mixed Search resolves before selected-first Debug")
		if scenario=="insight_success": _expect(project.is_competitor_snapshot_revealed() and project.is_market_forecast_snapshot_revealed(),"Controlled insight boundary hits both snapshots")
		if scenario=="insight_failure": _expect(not project.is_competitor_snapshot_revealed() and not project.is_market_forecast_snapshot_revealed(),"Controlled failures still commit payout/finite exhaustion")
		if scenario=="corrective": _expect(project.get_core_score(0)==2 and project.get_core_score(1)==2,"Only authorized corrective instances grant Core points")
		if scenario=="pending": _expect(after.candidates[3]=="graphics_pass" and after.candidates[4]=="sound_pass" and after.pending.is_empty(),"Queued corrective Passes enter once in order")
	var old_streams: Dictionary = before.run.random_streams.streams
	var new_streams: Dictionary = after.run.random_streams.streams
	if scenario=="revealed" or (scenario in ["insight_success","insight_failure"] and step==0):
		_expect(old_streams.beta_insight==new_streams.beta_insight,"Revealed or controlled insight consumes no random draw")
	for id in RunRandom.STREAMS:
		if id not in [&"beta_deal",&"beta_insight"]: _expect(old_streams[str(id)]==new_streams[str(id)],"Other RNG streams unchanged")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(old_streams.beta_deal.seed)
	rng.state = int(old_streams.beta_deal.state)
	var draws := 0 if scenario=="controlled_refill" and step==0 else (4 if scenario=="pending" and step==0 else 8)
	for i in range(draws): rng.randf()
	_expect(str(rng.state)==new_streams.beta_deal.state,"Exact two-draw-per-replacement RNG budget")
