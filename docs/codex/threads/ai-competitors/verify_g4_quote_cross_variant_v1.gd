## Analysis-only comparison capture. Run separately against frozen v3 and v4
## simulator projects; the companion Python wrapper compares the two captures.
extends SceneTree

const Factory = preload("res://scripts/simulation/run_factory.gd")
const Fixture = preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay = preload("res://scripts/simulation/development_replay.gd")

var checks := 0
var failures := 0
var errors: Array[String] = []


func expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		return
	failures += 1
	errors.append(label)
	push_error("G4 cross-quote: " + label)


func _initialize() -> void:
	await process_frame
	var output_path := OS.get_environment("PN_G4_CROSS_QUOTE_OUTPUT")
	if output_path.is_empty():
		push_error("PN_G4_CROSS_QUOTE_OUTPUT is required")
		quit(2)
		return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var cases: Array = []
	for specialty in ["action", "adventure"]:
		for seed in ["4417", "90210"]:
			cases.append(_capture_case(catalog, specialty, seed))
	var result := {"schema_version": 1, "study": "g4-cross-variant-current-hand-quotes",
		"checks": checks, "failures": failures, "errors": errors.duplicate(), "cases": cases}
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write cross-quote capture: " + output_path)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("G4_CROSS_QUOTE_CAPTURE cases=%d checks=%d failures=%d output=%s" % [cases.size(), checks, failures, output_path])
	quit(0 if failures == 0 else 1)


func _capture_case(catalog: RefCounted, specialty: String, seed: String) -> Dictionary:
	var case_id := "%s-%s" % [specialty, seed]
	var recipe := {"schema_version": 1, "studio_id": "g4-cross-%s" % case_id,
		"studio_name": "G4 Cross %s" % case_id, "specialty": specialty,
		"traits": ["family_funding", "cult_following"], "seed": seed}
	var session: RefCounted = Factory.create_fresh_session(recipe, catalog)
	expect(session != null, "%s fresh legal Studio" % case_id)
	if session == null:
		return {"case_id": case_id, "ok": false, "steps": [], "hands": []}
	var fixture: Callable = Fixture.factory({"genre": specialty, "theme": "fantasy",
		"name_prefix": "G4 Cross", "selection": "features_first",
		"hands": {"design": 2, "alpha": 2, "beta": 2}})
	expect(fixture.is_valid(), "%s finite fixture policy" % case_id)
	if not fixture.is_valid():
		return {"case_id": case_id, "ok": false, "steps": [], "hands": []}
	var steps: Array = []
	var hands: Array = []
	var completed := false
	var accepted := 0
	for step in range(45):
		if session.in_studio and session.run.get_released_game_ids().size() >= 1:
			completed = true
			break
		var before_state: String = Replay.digest(session.replay_state())
		var before_rng: Dictionary = session.run.random_streams.snapshot()
		var view: Dictionary = session.observation()
		var repeated: Dictionary = session.observation()
		expect(Replay.digest(session.replay_state()) == before_state,
			"%s step %d observation preserves full state" % [case_id, step])
		expect(session.run.random_streams.snapshot() == before_rng,
			"%s step %d observation preserves RNG" % [case_id, step])
		expect(repeated == view, "%s step %d repeated observation is exact" % [case_id, step])
		var phase: String = str(view.get("phase", ""))
		var current: Dictionary = view.get("development", {})
		var quote_moment: bool = phase in ["design", "alpha"] and current.get("active", false) and not current.get("finalized", false) and not current.get("confirmation_pending", false) and int(current.get("hand_revision", 0)) <= 2
		var hand: Dictionary = {}
		if quote_moment:
			hand = _capture_hand(case_id, step, phase, current, before_state, before_rng)
			hands.append(hand)
		var choice: Dictionary = fixture.call(view)
		expect(not choice.is_empty(), "%s step %d fixture supplies a choice" % [case_id, step])
		if choice.is_empty():
			break
		var result: Dictionary = session.execute(session.command(StringName(choice.type), choice.get("payload", {})))
		var accepted_action: bool = result.get("ok", false)
		expect(accepted_action, "%s step %d legal action accepted" % [case_id, step])
		if quote_moment and accepted_action:
			_check_selected_receipt(case_id, step, choice, hand, result, session)
		steps.append({"step": step, "phase": phase, "before_state": before_state,
			"before_rng": before_rng, "choice_digest": Replay.digest(choice),
			"result_digest": Replay.digest(result),
			"after_state": Replay.digest(session.replay_state()),
			"after_rng": session.run.random_streams.snapshot(), "accepted": accepted_action})
		if not accepted_action:
			break
		accepted += 1
	if not completed and session.in_studio and session.run.get_released_game_ids().size() >= 1:
		completed = true
	var phase_counts := {"design": 0, "alpha": 0}
	for hand: Dictionary in hands:
		phase_counts[hand.phase] = int(phase_counts.get(hand.phase, 0)) + 1
	expect(completed, "%s one legal release within 45 commands" % case_id)
	expect(phase_counts.design == 2 and phase_counts.alpha == 2,
		"%s two Design and two Alpha quote hands" % case_id)
	return {"case_id": case_id, "ok": completed and phase_counts.design == 2 and phase_counts.alpha == 2,
		"initial_state": steps[0].before_state if not steps.is_empty() else "",
		"initial_rng": steps[0].before_rng if not steps.is_empty() else {},
		"accepted_commands": accepted, "release_count": session.run.get_released_game_ids().size(),
		"steps": steps, "hands": hands}


func _capture_hand(case_id: String, step: int, phase: String, current: Dictionary,
		before_state: String, before_rng: Dictionary) -> Dictionary:
	var raw_quotes: Array = current.get("hand_quotes", [])
	expect(raw_quotes.size() == 35, "%s step %d has 35 four-card quotes" % [case_id, step])
	var quotes: Array = []
	var identities: Dictionary = {}
	var prices: Dictionary = {}
	var invalid_costs := 0
	var visible: Dictionary = {}
	for candidate: Dictionary in current.get("candidates", []):
		visible[int(candidate.get("token", -1))] = true
	expect(visible.size() == 7, "%s step %d has seven distinct visible candidates" % [case_id, step])
	for raw: Variant in raw_quotes:
		expect(raw is Dictionary, "%s step %d quote is a dictionary" % [case_id, step])
		if not raw is Dictionary:
			continue
		for field in ["candidate_ids", "cost_cents", "cash_preflight_ok", "next_cash_cents", "settlement_cents", "bills_paid_cents"]:
			expect(raw.has(field), "%s step %d quote has %s" % [case_id, step, field])
		var ids: Array = raw.get("candidate_ids", []).duplicate()
		ids.sort()
		expect(ids.size() == 4, "%s step %d quote has four IDs" % [case_id, step])
		for id: int in ids:
			expect(visible.has(id), "%s step %d quote ID is visible" % [case_id, step])
		identities[str(ids)] = true
		var cost := int(raw.get("cost_cents", -1))
		if cost >= 0:
			prices[cost] = true
		else:
			invalid_costs += 1
		var keys: Array = raw.keys()
		keys.sort()
		quotes.append({"raw": raw.duplicate(true), "keys": keys, "candidate_ids": ids, "cost_cents": cost,
			"cash_preflight_ok": bool(raw.get("cash_preflight_ok", false)),
			"next_cash_cents": int(raw.get("next_cash_cents", -1)),
			"settlement_cents": int(raw.get("settlement_cents", -1)),
			"bills_paid_cents": int(raw.get("bills_paid_cents", -1)),
			"reason": str(raw.get("unavailable_reason", raw.get("preflight_reason", raw.get("reason", ""))))})
	expect(identities.size() == raw_quotes.size(), "%s step %d quote IDs are unique" % [case_id, step])
	return {"step": step, "phase": phase, "hand_revision": int(current.get("hand_revision", -1)),
		"before_state": before_state, "before_rng": before_rng,
		"quotes": quotes, "unique_cost_count": prices.size(),
		"invalid_cost_count": invalid_costs}


func _check_selected_receipt(case_id: String, step: int, choice: Dictionary,
		hand: Dictionary, result: Dictionary, session: RefCounted) -> void:
	var request: Dictionary = choice.get("payload", {}).get("request", {})
	var selected: Array = request.get("payload", {}).get("candidate_ids", []).duplicate()
	selected.sort()
	var matched: Dictionary = {}
	for quote: Dictionary in hand.quotes:
		if quote.candidate_ids == selected:
			matched = quote
			break
	expect(not matched.is_empty(), "%s step %d selected quote exists" % [case_id, step])
	if matched.is_empty():
		return
	expect(matched.cash_preflight_ok, "%s step %d selected cash preflight available" % [case_id, step])
	var receipt: Dictionary = {}
	for event: Dictionary in result.get("events", []):
		if event.get("type") == "productive_cycle" and event.has("play_cost_cents"):
			receipt = event
	expect(not receipt.is_empty(), "%s step %d accepted Feature receipt exists" % [case_id, step])
	if receipt.is_empty():
		return
	expect(int(receipt.play_cost_cents) == int(matched.cost_cents),
		"%s step %d exact Feature price equals receipt" % [case_id, step])
	expect(int(receipt.cash_cents) == int(matched.next_cash_cents),
		"%s step %d next cash equals receipt" % [case_id, step])
	expect(int(session.run.get_cash_cents()) == int(matched.next_cash_cents),
		"%s step %d next cash equals RunState" % [case_id, step])
