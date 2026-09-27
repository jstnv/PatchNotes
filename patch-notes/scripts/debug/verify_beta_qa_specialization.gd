## Separately invoked locked Beta QA Specialization verification.
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

var _database: Node
var _snapshots: PrimitiveSnapshotDatabase
var _failures := 0


func _initialize() -> void:
	await process_frame
	_database = root.get_node("CardDatabase")
	_snapshots = PrimitiveSnapshotDatabase.new()
	_snapshots.load_ledgers()
	await _verify_trigger()
	await _verify_search_only()
	await _verify_debug_only_and_zero()
	await _verify_search_before_debug()
	await _verify_mixed_hands_and_isolation()
	await _verify_atomic_failure()
	if _failures == 0:
		print("Beta QA Specialization verification passed.")
	quit(_failures)


func _make_state(hidden_bugs: int) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.finalize_design_bugs(false, hidden_bugs, [], [])
	state.finalize_alpha(0, [], [])
	return state


func _make_beta(ids: Array[StringName], hidden_bugs: int = 0) -> Dictionary:
	var state := _make_state(hidden_bugs)
	var run := RunState.new()
	run.initialize_cash(0)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state, run, _snapshots)
	beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
	_install_pool(beta, ids)
	return {&"beta": beta, &"state": state, &"run": run}


func _install_pool(beta: BetaPhase, selected_ids: Array[StringName]) -> void:
	var ids := selected_ids.duplicate()
	for filler: StringName in [&"search_for_bugs", &"debug", &"sign_flippers"]:
		if ids.size() < 7:
			ids.append(filler)
	for old_view: CardView in beta.get("_candidate_views"):
		beta.get_node("%HandContainer").remove_child(old_view)
		old_view.free()
	var cards: Array[CardData] = []
	var views: Array[CardView] = []
	for id: StringName in ids:
		var card: CardData = _database.call(&"get_card", id)
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		view.set_card(card)
		view.card_pressed.connect(Callable(beta, "_on_card_pressed"))
		beta.get_node("%HandContainer").add_child(view)
		cards.append(card)
		views.append(view)
	beta.set("_candidate_cards", cards)
	beta.set("_candidate_views", views)
	beta.set("_selected_card_views", [] as Array[CardView])
	for index in range(4):
		beta.call("_on_card_pressed", views[index])


func _verify_trigger() -> void:
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	var search: CardData = _database.call(&"get_card", &"search_for_bugs")
	var debug: CardData = _database.call(&"get_card", &"debug")
	var marketing: CardData = _database.call(&"get_card", &"sign_flippers")
	_expect(beta.call("_qualifies_for_qa_specialization", [search, debug] as Array[CardData]), "Two QA cards are the documented minimum trigger")
	_expect(not beta.call("_qualifies_for_qa_specialization", [search] as Array[CardData]), "One QA card is below the documented trigger minimum")
	_expect(beta.call("_qualifies_for_qa_specialization", [search, search, debug, debug] as Array[CardData]), "Duplicate renewable QA instances participate normally")
	_expect(not beta.call("_qualifies_for_qa_specialization", [search, debug, debug, marketing] as Array[CardData]), "One played off-category card cancels QA Specialization")
	beta.queue_free()
	await process_frame


func _verify_search_only() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"search_for_bugs", &"search_for_bugs", &"search_for_bugs"], 20)
	_expect(fixture.beta.play_selected_hand(), "Four Search instances resolve a specialized hand")
	_expect(fixture.beta.get_workspace().synergy_notification.banner.visible and fixture.beta.get_workspace().synergy_notification.title_label.text == "QA Specialization!", "QA specialization displays an in-game notification")
	_expect(fixture.state.get_hidden_bugs() == 1 and fixture.state.get_known_bugs() == 19, "Specialized Search applies V 1.5 per card, floors each formula, sequences, and clamps")
	_expect(fixture.beta.get_node("%ActionFeedbackLabel").text.contains("QA Specialization! Card Value ×1.50"), "Qualifying feedback names QA Specialization and its exact value modifier")
	_expect(fixture.state.get_current_cycle() == 1 and fixture.beta.get("_candidate_cards").size() == 7, "Specialization adds no cycle and preserves seven-card replacement")
	fixture.beta.queue_free()
	await process_frame


func _verify_debug_only_and_zero() -> void:
	var fixture := await _make_beta([&"debug", &"debug", &"debug", &"debug"], 3)
	fixture.state.discover_bugs(3)
	_expect(fixture.beta.play_selected_hand(), "Four Debug instances resolve a specialized hand")
	_expect(fixture.state.get_known_bugs() == 0 and fixture.state.get_hidden_bugs() == 0, "Specialized Debug floors each floor(1 + 1.5) result and clamps at zero")
	fixture.beta.queue_free()
	await process_frame

	var empty := await _make_beta([&"debug", &"debug", &"search_for_bugs", &"search_for_bugs"])
	_expect(empty.beta.play_selected_hand(), "Qualifying zero-Bug QA hand completes normally")
	_expect(empty.beta.get_node("%ActionFeedbackLabel").text.contains("QA Specialization!") and empty.state.get_remaining_bugs() == 0, "Zero-Bug hand reports the synergy without negative state")
	empty.beta.queue_free()
	await process_frame


func _verify_search_before_debug() -> void:
	var fixture := await _make_beta([&"debug", &"search_for_bugs", &"debug", &"search_for_bugs"], 10)
	_expect(fixture.beta.play_selected_hand(), "Mixed Search/Debug QA composition qualifies regardless selected ordering")
	_expect(fixture.state.get_hidden_bugs() == 3 and fixture.state.get_known_bugs() == 3 and fixture.state.get_remaining_bugs() == 6, "Specialized Searches discover seven before specialized Debug fixes four")
	fixture.beta.queue_free()
	await process_frame


func _verify_mixed_hands_and_isolation() -> void:
	var marketing := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 10)
	_expect(marketing.beta.play_selected_hand(), "QA plus Marketing resolves without Specialization")
	_expect(marketing.state.get_hidden_bugs() == 7 and marketing.state.get_known_bugs() == 1 and marketing.state.get_marketing_output() == 2, "Disqualified QA uses base formulas and Marketing is not multiplied")
	_expect(not marketing.beta.get_node("%ActionFeedbackLabel").text.contains("QA Specialization"), "Nonqualifying hand shows no false synergy feedback")
	marketing.beta.queue_free()
	await process_frame

	var insider := await _make_beta([&"search_for_bugs", &"debug", &"debug", &"playtest_rival_games"], 10)
	_expect(insider.beta.play_selected_hand([10] as Array[int]), "Nonbalanced QA and Insider hand retains base action behavior")
	_expect(insider.run.get_cash() == 1000 and insider.state.get_marketing_output() == 0 and not insider.state.is_competitor_snapshot_revealed(), "QA Specialization does not alter payout or the base 10-percent insight boundary")
	_expect(insider.state.is_beta_card_exhausted(&"playtest_rival_games") and not insider.state.is_beta_card_exhausted(&"search_for_bugs"), "Specialization does not alter finite or renewable lifecycle")
	insider.beta.queue_free()
	await process_frame


func _verify_atomic_failure() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"search_for_bugs", &"debug", &"debug"], 10)
	var before := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_current_cycle(), fixture.beta.get_selected_candidate_count()]
	_expect(not fixture.beta.play_selected_hand([] as Array[int], [0.1] as Array[float], [0.1] as Array[float]), "Forced replacement failure rejects specialized hand")
	_expect([fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_current_cycle(), fixture.beta.get_selected_candidate_count()] == before, "Failed specialized preflight preserves Bugs, cycle, and selection")
	fixture.beta.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
