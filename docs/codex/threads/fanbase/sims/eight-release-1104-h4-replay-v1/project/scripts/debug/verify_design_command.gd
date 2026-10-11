extends "res://scripts/debug/verify_design_phase.gd"

const DESIGN_SCENE := preload("res://scenes/phases/design_phase.tscn")
const COMMAND := preload("res://scripts/simulation/design_hand_command.gd")
var traces: Array = []
var mode := OS.get_environment("PN_DESIGN_COMMAND_MODE")


func freeze(value: Variant) -> Variant:
	if value is int: return {"integer": str(value)}
	if value is float: return {"float_bits":var_to_bytes(value).hex_encode()}
	if value is StringName: return str(value)
	if value is RandomNumberGenerator: return {"seed":str(value.seed), "state":str(value.state)}
	if value is CardData: return str(value.id)
	if value is Array:
		return value.map(func(item: Variant) -> Variant: return freeze(item))
	if value is Dictionary:
		var result := {}
		for key in value: result[str(key)] = freeze(value[key])
		return result
	if value is Object:
		var result := {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				result[property.name] = freeze(value.get(property.name))
		return result
	return value

func snapshot(phase: Object, project: ProjectState, run: RunState) -> Dictionary:
	return {"project":freeze(project), "run":freeze(run), "candidates":freeze(phase.get("_candidate_cards")), "available":freeze(phase.get("_available_features")), "exhausted":freeze(phase.get("_exhausted_card_ids")), "priorities":freeze(phase.call("get_priority_distribution"))}

func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	var modes := [mode] if not mode.is_empty() else ["live", "headless"]
	for selected_mode in modes:
		mode = selected_mode
		traces.clear()
		await run_cases(database)
	quit(1 if _failures else 0)

func run_cases(database: Node) -> void:
	for seed_value in [1104, 4417, 90210]:
		for scenario in ["mixed", "passes", "specialized", "cash_reject", "refill_reject", "overflow_reject", "economy", "lean", "employee", "employee_choice", "tutorial", "balanced", "production_overflow", "finance_reject", "commit_reject"]:
			var project := ProjectState.new(30)
			project.set("_release_id", &"m2a_project")
			var run := RunState.new()
			run.initialize_cash(0)
			_expect(run.create_studio_with_traits("M2a", &"action", [&"lean_production"] if scenario == "lean" else []), "Studio fixture initializes")
			run.set("_bank_run_id", &"m2a_studio")
			run.set("_employees", EmployeeRoster.create(&"m2a_studio"))
			if scenario in ["employee", "employee_choice"]:
				var roster := EmployeeRoster.hire(run.get_employees(), &"employee_a", 0)
				if scenario == "employee_choice":
					roster = EmployeeRoster.plan_hand(roster, &"earlier_project", &"design", 0, 0, _cards(database, [&"sprites", &"graphics_pass", &"graphics_pass", &"graphics_pass"]), {0:25,1:25,2:25,3:25})
				run.set("_employees", roster)
			if scenario == "cash_reject": _expect(run.spend_cash_cents(run.get_cash_cents()), "Spend fixture cash")
			if scenario == "finance_reject": run.set("_studio_finance", {})
			if scenario == "tutorial":
				_expect(project.configure_predevelopment("M2a", &"action", &"fantasy", run.get_owned_feature_ids()), "Tutorial identity")
				_expect(run.begin_first_game_tutorial(project), "Tutorial initialized")
			if scenario == "commit_reject": project.set("_has_beta_finalization", true)
			if scenario == "production_overflow": project.set("_core_scores", {0:ProjectState.MAX_SIGNED_INT,1:0,2:0,3:0} as Dictionary[ProjectState.CoreScore,int])
			for id in RunRandom.STREAMS: run.random_streams.stream(id).seed = seed_value + RunRandom.STREAMS.find(id)
			var phase: Object
			if mode == "headless":
				phase = COMMAND.new()
				phase._project_state = project
				phase._run_state = run
				phase._deal_rng = run.random_streams.stream(&"design_deal")
				phase.active = true
				phase.priorities = PriorityAllocation.new().get_priority_distribution()
			else:
				phase = DESIGN_SCENE.instantiate()
				if mode == "oracle": phase.set_script(load(ProjectSettings.globalize_path("res://../docs/codex/threads/simulation-engine/m2a-v1/design_phase_oracle.gd")))
				phase.setup(project, run)
				root.add_child(phase)
				await process_frame
				phase.set("_phase_state", 1)
			var cards := _cards(database, [&"split_screen", &"text", &"graphics_pass", &"graphics_pass", &"sprites", &"sound_pass", &"design_pass"])
			if scenario == "passes": cards = _cards(database, [&"graphics_pass", &"graphics_pass", &"graphics_pass", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"])
			if scenario == "specialized": cards = _cards(database, [&"sprites", &"4_color_palette", &"graphics_pass", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"])
			if scenario == "balanced":
				cards = [_make_fixture(&"balanced_gfx",&"graphics",5,&"",0,1), _make_fixture(&"balanced_sound",&"sound",5,&"",0,1), _make_fixture(&"balanced_tech",&"technology",5,&"",0,1), _make_fixture(&"balanced_design",&"design",6,&"",0,1), database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"design_pass")]
				# Constructed arithmetic cards have no real price; use the legacy no-economy fixture.
				run.set("_first_studio_economy", false)
			if mode == "headless":
				phase._candidate_cards.assign(cards)
				phase.candidate_ids.assign([0,1,2,3,4,5,6])
				phase.next_candidate_id = 7
			else: _set_exact_candidates(phase, cards)
			var available: Array[CardData] = []
			available.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"feature"] as Array[StringName]))
			for card in cards: available.erase(card)
			phase.set("_available_features", available)
			var passes: Array[CardData] = []
			passes.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
			phase.set("_pass_definitions", passes.slice(0,3) if scenario == "refill_reject" else passes)
			if scenario == "overflow_reject": project.set("_current_cycle", ProjectState.MAX_SIGNED_INT)
			# _ready randomizes only standalone RNGs; run-owned streams stay pinned.
			var events: Array = []
			for id in [&"values_changed", &"cycle_changed"]:
				project.connect(id, func() -> void: events.append(str(id)))
			for id in [&"cash_changed", &"calendar_changed", &"redraws_changed", &"features_changed", &"sales_changed", &"contracts_changed", &"publishers_changed", &"finance_changed", &"fans_changed", &"employees_changed"]:
				run.connect(id, func() -> void: events.append(str(id)))
			var steps: Array = []
			for step in range(3):
				if mode != "headless":
					phase.get_workspace().hand_motion.cancel()
					var selected: Array = phase.get("_selected_card_views")
					selected.assign(phase.get_node("%HandContainer").get_children().slice(0,4))
				var before := snapshot(phase, project, run)
				events.clear()
				var choice := {0:40,1:20,2:20,3:20} if scenario == "employee_choice" and step == 0 else {}
				if mode == "headless":
					var request: Dictionary = phase.command(phase.candidate_ids.slice(0,4), choice)
					var command_before: Variant = freeze(phase)
					for invalid in [{}, {"candidate_ids":[-1,-2,-3,-4]}, {"candidate_ids":[request.candidate_ids[0],request.candidate_ids[0],request.candidate_ids[1],request.candidate_ids[2]]}, {"project_id":&"wrong_project"}, {"revision":-1}, {"revision":0.0}, {"employee_priorities":[]}, {"schema_version":2}]:
						var rejected: Dictionary = request.duplicate(true)
						if invalid.is_empty(): rejected = {}
						else: rejected.merge(invalid, true)
						_expect(not phase.execute(rejected).ok and freeze(phase) == command_before, "Malformed/stale command leaves complete state unchanged")
					var result: Dictionary = phase.execute(request)
					var after := snapshot(phase,project,run)
					if result.ok:
						_expect(project.get_current_cycle() == int(before.project._current_cycle.integer)+1, "One project cycle")
						_expect(not phase.execute(request).ok and snapshot(phase,project,run) == after, "Replay rejected without mutation")
						_expect(result.events[0].type == "production" and result.events[-1].type == "refill", "Ordered command events")
					else: _expect(after == before, "Rejected command preserves all captured state")
				else:
					phase.set("_employee_priority_choice", choice)
					phase.call("_on_play_card_pressed")
					phase.set("_employee_priority_choice", {})
					phase.get_workspace().hand_motion.cancel()
				var after_state := snapshot(phase,project,run)
				check_invariants(before, after_state, scenario, step, project, phase)
				steps.append({"before":before, "after":after_state, "events":events.duplicate()})
			traces.append({"seed":seed_value,"scenario":scenario,"steps":steps})
			if mode != "headless": phase.free()
	var digests: Array = []
	for trace in traces:
		digests.append({"seed":trace.seed,"scenario":trace.scenario,"sha256":JSON.stringify(trace).sha256_text()})
	var expected_path := "res://scripts/debug/fixtures/design_command_oracle_digests.json"
	if mode != "oracle": _expect(FileAccess.file_exists(expected_path), "Pinned oracle digests exist")
	if mode != "oracle" and FileAccess.file_exists(expected_path):
		var expected = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
		# The user authorized correcting the legacy overflow case. Keep the old
		# oracle immutable; compare every other case and assert rejection above.
		expected = expected.filter(func(row: Dictionary) -> bool: return row.scenario != "production_overflow")
		var unchanged_digests := digests.filter(func(row: Dictionary) -> bool: return row.scenario != "production_overflow")
		_expect(JSON.parse_string(JSON.stringify(unchanged_digests)) == expected, "%s full state/RNG/signal trace matches pre-extraction oracle" % mode)
	var output_path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output_path.is_empty():
		var output := FileAccess.open(output_path, FileAccess.WRITE)
		output.store_string(JSON.stringify(traces, "\t"))
		var digest_file := FileAccess.open(output_path + ".digests.json", FileAccess.WRITE)
		digest_file.store_string(JSON.stringify(digests,"\t"))
	print("Design command trace capture: %d scenarios (%s)" % [traces.size(),mode])

func check_invariants(before: Dictionary, after: Dictionary, scenario: String, step: int, project: ProjectState, phase: Object) -> void:
	if step == 0:
		var should_reject: bool = scenario in ["cash_reject", "refill_reject", "overflow_reject", "commit_reject", "finance_reject", "production_overflow"]
		_expect((after == before) == should_reject, "Intended acceptance outcome: " + scenario)
		if scenario == "production_overflow":
			_expect(after == before, "Authorized overflow correction rejects without mutation")
		if scenario == "balanced":
			_expect(_values(project) == [6,5,5,5,4], "Balanced conserves 21 points")
		if scenario == "passes":
			_expect(project.get_current_scope() == 0 and project.get_accumulated_bug_pressure() == 0.0 and phase.get("_exhausted_card_ids").is_empty(), "Pass lifecycle unchanged")
	var old_streams: Dictionary = before["run"]["random_streams"]["streams"]
	var new_streams: Dictionary = after["run"]["random_streams"]["streams"]
	for id: StringName in RunRandom.STREAMS:
		if id != &"design_deal": _expect(old_streams[str(id)] == new_streams[str(id)], "Other streams unchanged")
