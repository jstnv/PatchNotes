## Controlled arithmetic/lifecycle fixtures, not campaign affordability evidence.
extends "res://scripts/debug/verify_design_command.gd"

var comparisons := 0

func _initialize() -> void:
	_run_boost.call_deferred()

func _run_boost() -> void:
	var database := root.get_node("CardDatabase")
	for alpha in [false, true]:
		for raw in [[2,2,2,2], [2,2,3,2], [5,5,5,6], [17,20,20,23]]:
			var live := await exercise(database, alpha, raw, false)
			var headless := await exercise(database, alpha, raw, true)
			_expect(live == headless, "Exact live/headless state, refill RNG and ordered signals: %s %s" % ["Alpha" if alpha else "Design", raw])
			comparisons += 1
	print("BALANCED_BOOST_PARITY comparisons=%d failures=%d" % [comparisons, _failures])
	quit(1 if _failures else 0)

func exercise(database: Node, alpha: bool, raw: Array, headless: bool) -> Dictionary:
	var project := ProjectState.new(30)
	project.set("_release_id", &"boost_parity")
	var run := RunState.new()
	run.initialize_cash(0)
	_expect(run.create_studio_with_traits("Boost parity", &"action", []), "Fixture studio initializes")
	historical_v2_roster(run)
	# Constructed cards test resolution, not real price/catalog admission.
	run.set("_first_studio_economy", false)
	run.set("_bank_run_id", &"boost_parity_studio")
	run._publisher_relationships = RunState.RelationshipLedger.create(run._bank_run_id)
	run._contract_search = RunState.ContractSearch.create(run._bank_run_id)
	run.set("_employees", EmployeeRoster.create(&"boost_parity_studio"))
	for id in RunRandom.STREAMS:
		run.random_streams.stream(id).seed = 4417 + RunRandom.STREAMS.find(id)
	var phase: Object
	var phase_id := "alpha" if alpha else "design"
	if headless:
		phase = load("res://scripts/simulation/" + phase_id + "_hand_command.gd").new()
		phase._project_state = project
		phase._run_state = run
		phase._deal_rng = run.random_streams.stream(StringName(phase_id + "_deal"))
		phase.active = true
		phase.priorities = PriorityAllocation.new().get_priority_distribution()
	else:
		phase = load("res://scenes/phases/" + phase_id + "_phase.tscn").instantiate()
		phase.setup(project, run)
		root.add_child(phase)
		await process_frame
		phase.set("_phase_state", 1)
	var cards: Array[CardData] = []
	for category in range(4):
		var card := _make_fixture(StringName("boost_" + str(category)), [&"graphics",&"sound",&"technology",&"design"][category], raw[category], &"", 0, 1)
		if alpha:
			card.phase = CardData.PHASE_ALPHA
			card.department = &"gameplay"
		cards.append(card)
	cards.append_array(_cards(database, [&"graphics_pass", &"sound_pass", &"design_pass"]))
	if headless:
		phase._candidate_cards.assign(cards)
		phase.candidate_ids.assign([0,1,2,3,4,5,6])
		phase.next_candidate_id = 7
	else:
		_set_exact_candidates(phase, cards)
		phase.get("_selected_card_views").assign(phase.get_node("%HandContainer").get_children().slice(0,4))
	var available: Array[CardData] = []
	available.assign(database.get_cards_by_phase_and_types(CardData.PHASE_ALPHA if alpha else CardData.PHASE_DESIGN, [&"feature"] as Array[StringName]))
	if alpha:
		available.append_array(cards.slice(0,4))
	else:
		for card in cards: available.erase(card)
	phase.set("_available_features", available)
	phase.set("_pass_definitions", database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	var events: Array = []
	for id in [&"values_changed", &"cycle_changed"]:
		project.connect(id, func() -> void: events.append(str(id)))
	for id in [&"cash_changed", &"calendar_changed", &"redraws_changed", &"features_changed", &"sales_changed", &"contracts_changed", &"publishers_changed", &"finance_changed", &"fans_changed", &"employees_changed"]:
		run.connect(id, func() -> void: events.append(str(id)))
	if headless:
		var request: Dictionary = phase.command(phase.candidate_ids.slice(0,4))
		var outcome: Dictionary = phase.execute(request)
		_expect(outcome.ok, "Headless Balanced hand commits")
		var after := snapshot(phase,project,run)
		_expect(not phase.execute(request).ok and snapshot(phase,project,run) == after, "Headless duplicate cannot award bonus twice")
	else:
		phase.call("_on_play_alpha_hand_pressed" if alpha else "_on_play_card_pressed")
		phase.get_workspace().hand_motion.cancel()
	@warning_ignore("integer_division")
	var boosted: int = (int(raw[0])+int(raw[1])+int(raw[2])+int(raw[3])) * 5 / 4
	for category in range(4):
		@warning_ignore("integer_division")
		var expected := boosted / 4 + (1 if category < boosted % 4 else 0)
		_expect(project.get_core_score(category) == expected, "Committed exact boosted category")
	_expect(project.get_current_cycle() == 1 and project.get_current_scope() == 4, "One cycle and printed Scope")
	_expect(events.count("values_changed") == 1 and events.count("cycle_changed") == 1, "One authoritative production notification")
	var result := {"state": snapshot(phase,project,run), "events": events.duplicate()}
	if not headless: phase.free()
	return result
