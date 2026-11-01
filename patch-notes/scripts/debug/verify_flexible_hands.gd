## Consumer-boundary regression: short hands, quota and Playtest overflow.
extends SceneTree
const Design = preload("res://scripts/simulation/design_hand_command.gd")
const Alpha = preload("res://scripts/simulation/alpha_hand_command.gd")
const Beta = preload("res://scripts/simulation/beta_hand_command.gd")
const Actions = preload("res://scripts/simulation/development_actions.gd")
const Production = preload("res://scripts/simulation/production_hand.gd")
var checks := 0
var failures := 0
var db: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func core_hand(script: Script, count: int = 7) -> RefCounted:
	var h = script.new()
	h._project_state = ProjectState.new(30)
	h._deal_rng = RandomNumberGenerator.new()
	h._deal_rng.seed = 4417
	h.active = true
	h.priorities = PriorityAllocation.new().get_priority_distribution()
	h._pass_definitions.assign(db.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	for i in count:
		h._candidate_cards.append(db.get_card(&"graphics_pass"))
		h.candidate_ids.append(i)
	h.next_candidate_id = count
	return h

func beta_hand() -> RefCounted:
	var h = Beta.new()
	h._project_state = ProjectState.new(30)
	h._project_state.initialize_snapshots(&"fast_follower", &"market_surge")
	h._project_state.finalize_design_bugs(false, 5, [], [])
	h._project_state.finalize_alpha(0, [], [])
	h._run_state = RunState.new()
	h._run_state.initialize_cash(5000)
	h._snapshot_database = PrimitiveSnapshotDatabase.new()
	h._snapshot_database.load_ledgers()
	h._deal_rng = h._run_state.random_streams.stream(&"beta_deal")
	h._insight_rng = h._run_state.random_streams.stream(&"beta_insight")
	h.priorities = BetaPriorityAllocation.new().get_distribution()
	h._beta_definitions.assign(db.get_cards_by_phase_and_types(CardData.PHASE_BETA, [&"beta"] as Array[StringName]))
	for card: CardData in h._beta_definitions: h._definitions_by_id[card.id] = card
	for id in [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"]: h._definitions_by_id[id] = db.get_card(id)
	for i in 7:
		h._candidate_cards.append(db.get_card(&"search_for_bugs"))
		h.candidate_ids.append(i)
	h.next_candidate_id = 7
	h.active = true
	return h

func actions(h: RefCounted, phase: StringName) -> RefCounted:
	var a = Actions.new()
	a.hand = h
	a.phase = phase
	a.catalog = db.get_development_catalog()
	return a

func _initialize() -> void:
	await process_frame
	db = root.get_node("CardDatabase")
	for script in [Design, Alpha]:
		for n in [1, 2, 3]:
			var h = core_hand(script, n)
			var before = h._deal_rng.state
			var result: Dictionary = h.execute(h.command(h.candidate_ids.duplicate()))
			check(result.ok, "%s accepts %d current cards" % [script.resource_path, n])
			if not result.ok: continue
			check(h._project_state.get_current_cycle() == 1 and h._budget_spent == n, "Short hand spends actual Passes and exactly one cycle")
			check(h._project_state.get_core_score(0) == 2 * n, "Short hand earns printed Core without Specialization")
			check(h._candidate_cards.size() == mini(7, 10 - n), "Short pool refills only to seven and respects remaining quota")
			check(h.pass_budget_available() == 10 - n, "Each new phase has eight additional starting Passes")
		for n in [0, 5]:
			var h = core_hand(script)
			var rng = h._deal_rng.state
			var result: Dictionary = h.execute(h.command(h.candidate_ids.slice(0, n)))
			check(not result.ok and h._project_state.get_current_cycle() == 0 and h._deal_rng.state == rng and h._budget_spent == 0, "Empty/overlarge hand is atomic")
		var old = core_hand(script, 2)
		old._project_state._pass_budget_version = 1
		check(old.pass_budget_available() == 2, "Existing active version1 retains its two starting Passes")
		var stale = core_hand(script)
		check(not stale.execute(stale.command([0, 0] as Array[int])).ok and not stale.execute(stale.command([999] as Array[int])).ok, "Duplicate and stale short selection reject")
	var balanced: Dictionary = {0:2, 1:2, 2:2, 3:2}
	check(not Production.calculate([{&"primary_stat":&"graphics"}], balanced, true).balanced_production, "A short mixed Feature cannot trigger Balanced Production")
	# Real Alpha definitions: no synthetic source or unaffordable grants.
	var a = core_hand(Alpha, 0)
	a._available_features.assign(db.get_cards_by_phase_and_types(CardData.PHASE_ALPHA, [&"feature"] as Array[StringName]))
	a._candidate_cards.assign(a._available_features.slice(0, 7))
	for i in 7: a.candidate_ids.append(i)
	a.next_candidate_id = 7
	var alpha_ops = actions(a, &"alpha")
	var alpha_rng = a._deal_rng.state
	check(alpha_ops.host_playtest(), "Alpha Playtest commits")
	check(a._candidate_cards.size() == 9 and a.injected_candidate_ids.size() == 2 and a._project_state.get_current_cycle() == 1, "Alpha corrections appear immediately above seven for one cycle")
	check(a._deal_rng.state == alpha_rng and a._pending_playtest_categories.is_empty(), "Alpha Playtest draws no random replacement and leaves no deferred injection")
	check(alpha_ops.valid_pool(), "Protected Alpha overflow is valid")
	if a._candidate_cards.size() == 9:
		var retained_tokens: Array[int] = a.candidate_ids.slice(1)
		var played: Dictionary = a.execute(a.command([a.candidate_ids[0]] as Array[int]))
		check(played.ok and a.candidate_ids == retained_tokens and a._deal_rng.state == alpha_rng, "Eight retained Alpha cards prevent ordinary refill/RNG")
		var injection: Array[int] = a.injected_candidate_ids.duplicate()
		check(not alpha_ops.valid_redraw([a.candidate_ids.find(injection[0])] as Array[int], [] as Array[float]), "Immediate corrective Pass stays protected from redraw")
	# Beta overflow can persist across several hands; retained IDs never disappear.
	for n in [1, 2, 3]:
		var h = beta_hand()
		var result: Dictionary = h.execute(h.command(h.candidate_ids.slice(0, n)))
		check(result.ok and h._candidate_cards.size() == 7 and h._run_state.get_completed_run_cycles() == 1, "Beta short hand refills gap and advances once")
		if result.ok: check(not result.preflight.qa_specialization, "Beta partial hand gets no four-card QA bonus")
	var b = beta_hand()
	var ops = actions(b, &"beta")
	var cash: int = b._run_state.get_cash_cents()
	var rng = b._deal_rng.state
	check(ops.host_playtest(), "Beta Playtest commits")
	check(b._candidate_cards.size() == 9 and b.injected_candidate_ids.size() == 2 and b._run_state.get_cash_cents() == cash - 50000 and b._run_state.get_completed_run_cycles() == 1, "Beta Passes appear now and existing500/one-cycle cost is exact")
	check(b._deal_rng.state == rng and b._pending_corrective_pass_ids.is_empty() and ops.valid_pool(), "Beta overflow is valid with no deal RNG or pending duplicate")
	if b._candidate_cards.size() == 9:
		check(ops.host_playtest() and b._candidate_cards.size() == 11, "Another paid Playtest appends without deleting existing cards")
		var keep = b.candidate_ids.slice(4)
		var first: Dictionary = b.execute(b.command(b.candidate_ids.slice(0, 4)))
		check(first.ok and b.candidate_ids == keep and b._deal_rng.state == rng, "Exactly seven retained Beta cards draw nothing")
		var second: Dictionary = b.execute(b.command([b.candidate_ids[0]] as Array[int]))
		check(second.ok and b._candidate_cards.size() == 7 and second.preflight.next_cards.size() == 1, "Below seven Beta draws exactly the gap")
	var contract := ContractState.new([&"text"] as Array[StringName])
	var plan := contract.plan_hand([db.get_card(&"text")] as Array[CardData])
	check(not plan.is_empty() and plan.specialization_stat == &"", "Contract accepts one Feature without specialization")
	print("FLEXIBLE_HANDS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
