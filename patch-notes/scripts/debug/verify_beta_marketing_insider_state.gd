## Focused Beta Marketing and Insider state-foundation verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_beta_marketing_insider_state.gd
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	_verify_marketing_output_api()
	await _verify_beta_isolation(database)
	_finish()


func _verify_marketing_output_api() -> void:
	var state := ProjectState.new(30)
	_expect(state.get_marketing_output() == 0, "A new project initializes Marketing Output to the empty-sum value zero")
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(state.add_marketing_output(4), "A nonnegative integer Marketing Output addition succeeds")
	_expect(state.get_marketing_output() == 4 and emissions[0] == 1, "Marketing Output accumulates exactly and emits once")
	_expect(state.add_marketing_output(3), "A later Marketing Output addition succeeds")
	_expect(state.get_marketing_output() == 7 and emissions[0] == 2, "Marketing Output accumulates instead of resetting")
	_expect(state.add_marketing_output(0), "Zero Marketing Output is a valid no-op")
	_expect(state.get_marketing_output() == 7 and emissions[0] == 2, "Zero addition emits no misleading state signal")
	for invalid: Variant in [-1, 1.0, 0.5, "1", NAN, INF, -INF, null, true, [], {}]:
		var before := state.get_marketing_output()
		var emissions_before: int = emissions[0]
		_expect(not state.add_marketing_output(invalid), "Malformed Marketing Output rejects: %s" % [invalid])
		_expect(state.get_marketing_output() == before and emissions[0] == emissions_before, "Rejected Marketing Output is atomic")
	var overflow_state := ProjectState.new(30)
	_expect(overflow_state.add_marketing_output(9223372036854775807), "Uncapped documented accumulator accepts the largest representable integer")
	var overflow_emissions := [0]
	overflow_state.values_changed.connect(func() -> void: overflow_emissions[0] += 1)
	_expect(not overflow_state.add_marketing_output(1), "Marketing Output overflow rejects")
	_expect(overflow_state.get_marketing_output() == 9223372036854775807 and overflow_emissions[0] == 0, "Overflow rejection preserves state and emits nothing")


func _verify_beta_isolation(database: Node) -> void:
	var state := _make_finalized_state()
	state.add_marketing_output(6)
	var before := _snapshot(state)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(beta.setup(state), "Beta receives the finalized ProjectState with existing Marketing Output")
	_expect(_snapshot(state) == before, "Beta loading preserves Marketing Output and every existing project value")
	_expect(_conceals_unearned_information(beta), "Beta UI does not expose Awareness, Marketing Output, revenue, rival insight, or market trends")
	var category_rolls: Array[float] = [0.4, 0.4, 0.4, 0.8, 0.8, 0.8, 0.0]
	var definition_rolls: Array[float] = [0.0, 0.3, 0.6, 0.0, 0.4, 0.8, 0.0]
	_expect(beta.begin_beta(category_rolls, definition_rolls), "Beta dealing succeeds with Marketing and Insider candidates")
	var views: Array = beta.get("_candidate_views")
	for index in range(4):
		beta.call("_on_card_pressed", views[index])
	beta.call("_on_card_pressed", views[0])
	_expect(beta.set_priority_distribution({CardData.BETA_CATEGORY_QA: 25, CardData.BETA_CATEGORY_MARKETING: 50, CardData.BETA_CATEGORY_INSIDER: 25}), "Active Beta priorities remain editable through a valid atomic distribution")
	_expect(_snapshot(state) == before, "Begin, dealing, display, selection, deselection, and priority editing change no Marketing Output, Bugs, cycles, or project data")
	_expect(state.get_marketing_output() == 6, "Marketing cards are not resolved by planning or selection")
	_expect(not state.has_method("reveal_rival_insight") and not state.has_method("reveal_market_trend") and not state.has_method("add_cash"), "Unsupported intelligence payloads and finance ownership are not fabricated")
	beta.setup(state)
	_expect(state.get_marketing_output() == 6 and _snapshot(state) == before, "Beta reconstruction reads and preserves authoritative state")
	_expect(database.get_card_count() == 40 and database.get_cards_by_phase(CardData.PHASE_BETA).size() == 9, "State foundation leaves the 40-card ledger and nine Beta definitions unchanged")
	beta.queue_free()
	await process_frame


func _make_finalized_state() -> ProjectState:
	var state := ProjectState.new(30)
	state.finalize_design_bugs(false, 5, [&"text"], [&"sprites"])
	state.finalize_alpha(2, [&"controls"], [&"enemies"])
	state.discover_bugs(2)
	return state


func _snapshot(state: ProjectState) -> Array:
	return [state.get_marketing_output(), state.get_current_cycle(), state.get_current_scope(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(), state.get_implemented_design_feature_ids(), state.get_implemented_alpha_feature_ids()]


func _conceals_unearned_information(beta: Node) -> bool:
	var visible_text := ""
	for node: Node in _descendants(beta):
		if node is Label:
			visible_text += " " + (node as Label).text.to_lower()
	for concealed: String in ["awareness", "marketing output", "revenue", "cash", "rival insight", "market trend", "hidden bugs", "remaining bugs"]:
		if concealed in visible_text:
			return false
	return true


func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child: Node in node.get_children():
		result.append_array(_descendants(child))
	return result


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _finish() -> void:
	if _failures == 0:
		print("Beta Marketing and Insider state-foundation verification passed.")
	quit(_failures)
