## Separately invoked locked Beta Balanced Operations verification.
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
	await _verify_compositions()
	await _verify_two_qa_distribution()
	await _verify_two_marketing_distribution()
	await _verify_two_insider_distribution()
	await _verify_boundaries_and_precedence()
	await _verify_atomicity()
	if _failures == 0:
		print("Beta Balanced Operations verification passed.")
	quit(_failures)


func _card(id: StringName) -> CardData:
	return _database.call(&"get_card", id)


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
		var card := _card(id)
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


func _qualifies(beta: BetaPhase, ids: Array[StringName]) -> bool:
	var cards: Array[CardData] = []
	for id: StringName in ids:
		cards.append(_card(id))
	return beta.call("_qualifies_for_balanced_operations", cards)


func _verify_compositions() -> void:
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(_qualifies(beta, [&"search_for_bugs", &"debug", &"sign_flippers", &"study_competition"]), "2 QA / 1 Marketing / 1 Insider qualifies")
	_expect(_qualifies(beta, [&"debug", &"sign_flippers", &"posters", &"predict_market_trends"]), "1 QA / 2 Marketing / 1 Insider qualifies")
	_expect(_qualifies(beta, [&"search_for_bugs", &"press_release", &"study_competition", &"predict_market_trends"]), "1 QA / 1 Marketing / 2 Insider qualifies")
	_expect(not _qualifies(beta, [&"search_for_bugs", &"debug", &"debug", &"sign_flippers"]), "3 QA / 1 Marketing fails without Insider")
	_expect(not _qualifies(beta, [&"search_for_bugs", &"debug", &"debug", &"study_competition"]), "3 QA / 1 Insider fails without Marketing")
	_expect(not _qualifies(beta, [&"search_for_bugs", &"sign_flippers", &"posters", &"press_release"]), "1 QA / 3 Marketing fails without Insider")
	_expect(not _qualifies(beta, [&"sign_flippers", &"posters", &"study_competition", &"predict_market_trends"]), "Marketing and Insider without QA fails")
	_expect(not _qualifies(beta, [&"search_for_bugs", &"debug", &"search_for_bugs"]), "A three-card composition cannot qualify")
	beta.queue_free()
	await process_frame


func _verify_two_qa_distribution() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"playtest_rival_games"], 10)
	_expect(fixture.beta.play_selected_hand([12] as Array[int]), "Balanced 2/1/1 hand resolves at the Playtest success boundary")
	_expect(fixture.beta.get_workspace().synergy_notification.banner.visible and fixture.beta.get_workspace().synergy_notification.title_label.text == "Balanced Operations!", "Balanced Beta action displays an in-game notification")
	_expect(fixture.state.get_hidden_bugs() == 6 and fixture.state.get_known_bugs() == 1 and fixture.state.get_remaining_bugs() == 7, "Base Search 3 becomes ceil(3.75)=4, then base Debug 2 becomes ceil(2.5)=3")
	_expect(fixture.state.get_marketing_output() == 2, "Aggregate Marketing 1 becomes ceil(1.25)=2")
	_expect(fixture.run.get_cash() == 1000 and fixture.state.is_competitor_snapshot_revealed(), "Fixed payout remains $1,000 and balanced Playtest chance succeeds through roll 12")
	_expect(fixture.beta.get_node("%ActionFeedbackLabel").text.contains("Balanced Operations! Output ×1.25") and not fixture.beta.get_node("%ActionFeedbackLabel").text.contains("QA Specialization"), "Feedback reports only Balanced Operations")
	_expect(fixture.state.get_current_cycle() == 1 and fixture.beta.get("_candidate_cards").size() == 7, "Balanced hand advances one cycle and publishes seven replacements")
	_expect(fixture.state.is_beta_card_exhausted(&"playtest_rival_games") and not fixture.state.is_beta_card_exhausted(&"search_for_bugs"), "Balanced Operations preserves finite and renewable lifecycle")
	fixture.beta.queue_free()
	await process_frame


func _verify_two_marketing_distribution() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"sign_flippers", &"press_release", &"predict_market_trends"], 10)
	_expect(fixture.beta.play_selected_hand([37] as Array[int]), "Balanced 1/2/1 hand resolves at forecast success boundary 37")
	_expect(fixture.state.get_hidden_bugs() == 6 and fixture.state.get_known_bugs() == 4, "Balanced Search floors base request before applying and ceiling the multiplier")
	_expect(fixture.state.get_marketing_output() == 4, "Aggregate Marketing 3 becomes ceil(3.75)=4 rather than per-card rounding")
	_expect(fixture.state.is_market_forecast_snapshot_revealed(), "Balanced forecast chance is 38 percent")
	fixture.beta.queue_free()
	await process_frame


func _verify_two_insider_distribution() -> void:
	var fixture := await _make_beta([&"debug", &"sign_flippers", &"study_competition", &"predict_market_trends"], 4)
	fixture.state.discover_bugs(4)
	_expect(fixture.beta.play_selected_hand([37, 37] as Array[int]), "Balanced 1/1/2 hand resolves both 38-percent insight boundaries")
	_expect(fixture.state.get_known_bugs() == 1 and fixture.state.get_marketing_output() == 2, "Balanced Debug fixes three and Marketing one rounds upward to two")
	_expect(fixture.state.is_competitor_snapshot_revealed() and fixture.state.is_market_forecast_snapshot_revealed(), "Study and Predict independently reveal their assigned snapshots")
	fixture.beta.queue_free()
	await process_frame


func _verify_boundaries_and_precedence() -> void:
	var failure := await _make_beta([&"search_for_bugs", &"sign_flippers", &"posters", &"playtest_rival_games"], 2)
	_expect(failure.beta.play_selected_hand([13] as Array[int]), "Balanced Playtest roll 13 is a normal insight failure")
	_expect(failure.run.get_cash() == 1000 and not failure.state.is_competitor_snapshot_revealed() and failure.state.get_current_cycle() == 1, "Insight failure preserves payout, exhaustion, and one-cycle success")
	failure.beta.queue_free()
	await process_frame

	var study_failure := await _make_beta([&"debug", &"sign_flippers", &"study_competition", &"predict_market_trends"])
	_expect(study_failure.beta.play_selected_hand([38, 38] as Array[int]), "Balanced Study and Predict failure begins at roll 38")
	_expect(not study_failure.state.is_competitor_snapshot_revealed() and not study_failure.state.is_market_forecast_snapshot_revealed(), "Failure boundaries reveal neither snapshot")
	study_failure.beta.queue_free()
	await process_frame

	var qa := await _make_beta([&"search_for_bugs", &"search_for_bugs", &"debug", &"debug"], 10)
	_expect(qa.beta.play_selected_hand(), "Four-QA hand retains QA Specialization")
	var feedback: String = qa.beta.get_node("%ActionFeedbackLabel").text
	_expect(feedback.contains("QA Specialization! Card Value ×1.50") and not feedback.contains("Balanced Operations"), "QA Specialization precedence prevents stacking")
	qa.beta.queue_free()
	await process_frame


func _verify_atomicity() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"playtest_rival_games"], 10)
	var before := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_marketing_output(), fixture.state.get_current_cycle(), fixture.run.get_cash(), fixture.beta.get_selected_candidate_count()]
	_expect(not fixture.beta.play_selected_hand([12] as Array[int], [0.1] as Array[float], [0.1] as Array[float]), "Forced replacement failure rejects a qualifying Balanced hand")
	_expect(not fixture.beta.get_workspace().synergy_notification.banner.visible, "Rejected action never displays a synergy notification")
	_expect([fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_marketing_output(), fixture.state.get_current_cycle(), fixture.run.get_cash(), fixture.beta.get_selected_candidate_count()] == before, "Rejected Balanced hand preserves all observed state and selection")
	fixture.beta.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
