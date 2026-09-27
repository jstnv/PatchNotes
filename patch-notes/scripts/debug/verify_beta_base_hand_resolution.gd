## Separately invoked Primitive Beta base-hand resolution verification.
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
	await _verify_availability_and_empty_qa()
	await _verify_qa_order_and_clamping()
	await _verify_marketing_and_payout()
	await _verify_insight_boundaries()
	await _verify_lifecycle_and_replacement()
	await _verify_atomic_failures()
	_finish()


func _make_state(hidden_bugs: int = 0) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.finalize_design_bugs(false, hidden_bugs, [], [])
	state.finalize_alpha(0, [], [])
	return state


func _make_run(cash: int = 0) -> RunState:
	var run := RunState.new()
	run.initialize_cash(cash)
	return run


func _make_beta(ids: Array[StringName], hidden_bugs: int = 0, cash: int = 0) -> Dictionary:
	var state := _make_state(hidden_bugs)
	var run := _make_run(cash)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state, run, _snapshots)
	beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
	_install_controlled_pool(beta, ids)
	return {&"beta": beta, &"state": state, &"run": run}


func _install_controlled_pool(beta: BetaPhase, selected_ids: Array[StringName]) -> void:
	var all_ids := selected_ids.duplicate()
	for filler: StringName in [&"search_for_bugs", &"debug", &"sign_flippers"]:
		if all_ids.size() < 7: all_ids.append(filler)
	var old_views: Array = beta.get("_candidate_views")
	for view: CardView in old_views:
		if is_instance_valid(view):
			beta.get_node("%HandContainer").remove_child(view)
			view.free()
	var cards: Array[CardData] = []
	var views: Array[CardView] = []
	for id: StringName in all_ids:
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


func _verify_availability_and_empty_qa() -> void:
	var state := _make_state()
	var run := _make_run()
	var planning := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(planning)
	await process_frame
	planning.setup(state, run, _snapshots)
	_expect(not planning.play_selected_hand(), "Planning rejects Play Hand with zero effects")
	planning.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
	_expect(not planning.play_selected_hand(), "Zero selections reject")
	var pool := planning.get("_candidate_views") as Array
	for index in range(3): planning.call("_on_card_pressed", pool[index])
	_expect(not planning.play_selected_hand(), "One through three selections reject")
	planning.queue_free()
	await process_frame

	var fixture := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"])
	var beta: BetaPhase = fixture.beta
	_expect(beta.play_selected_hand(), "Search and Debug with no available work still resolve successfully")
	_expect(fixture.state.get_hidden_bugs() == 0 and fixture.state.get_known_bugs() == 0 and fixture.state.get_current_cycle() == 1, "Empty QA work changes no Bugs and advances exactly one cycle")
	beta.queue_free()
	await process_frame

	var mixed := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 1)
	_expect(mixed.beta.play_selected_hand(), "One Search and one Debug resolve sequentially in a mixed hand")
	_expect(mixed.state.get_hidden_bugs() == 0 and mixed.state.get_known_bugs() == 0 and mixed.state.get_fixed_bugs() == 1 and mixed.state.get_remaining_bugs() == 0, "Debug fixes the Bug found by Search even when the visible Known count returns to zero")
	_expect(mixed.beta.get_node("%KnownBugsLabel").text == "Known Bugs: 0 | Fixed Bugs: 1", "Mixed-hand UI exposes successful fixing when Known Bugs has no net change")
	mixed.beta.queue_free()
	await process_frame


func _verify_qa_order_and_clamping() -> void:
	var fixture := await _make_beta([&"search_for_bugs", &"search_for_bugs", &"debug", &"debug"], 10)
	var beta: BetaPhase = fixture.beta
	_expect(beta.play_selected_hand(), "Multiple renewable QA instances resolve as one base hand")
	_expect(fixture.state.get_hidden_bugs() == 3 and fixture.state.get_known_bugs() == 3 and fixture.state.get_remaining_bugs() == 6, "QA Specialization changes Final Card Value before sequential Search, then Debug fixes four")
	_expect(fixture.state.get_fixed_bugs() == 4, "Mixed Search and Debug records all four Bugs fixed after discovery")
	_expect(beta.get_node("%KnownBugsLabel").text == "Known Bugs: 3 | Fixed Bugs: 4", "Mixed Search and Debug refreshes both visible Beta Bug values")
	_expect(beta.get_node("%ActionFeedbackLabel").text.contains("Bugs discovered: 7") and beta.get_node("%ActionFeedbackLabel").text.contains("Known Bugs fixed: 4"), "Mixed hand feedback reports both actual operations")
	_expect(fixture.state.get_exhausted_beta_card_ids().is_empty(), "Renewable QA definitions do not exhaust")
	beta.queue_free()
	await process_frame


func _verify_marketing_and_payout() -> void:
	var marketing := await _make_beta([&"sign_flippers", &"posters", &"press_release", &"press_interview"])
	var old_view: CardView = marketing.beta.get("_selected_card_views")[0]
	_expect(marketing.beta.play_selected_hand(), "All four Marketing definitions resolve with Marketing Specialization")
	_expect(marketing.state.get_marketing_output() == 10 and marketing.state.get_current_cycle() == 1, "Marketing contributes floor((1 + 1 + 2 + 3) × 1.5) once")
	_expect(marketing.state.is_beta_card_exhausted(&"press_interview") and marketing.state.get_exhausted_beta_card_ids().size() == 1, "Only finite Press Interview exhausts")
	var after := _snapshot(marketing.state, marketing.run, marketing.beta)
	old_view.card_pressed.emit(old_view)
	_expect(not marketing.beta.play_selected_hand() and _snapshot(marketing.state, marketing.run, marketing.beta) == after, "Retired references and repeated callbacks cannot replay a hand")
	marketing.beta.queue_free()
	await process_frame

	var payout := await _make_beta([&"playtest_rival_games", &"sign_flippers", &"posters", &"press_release"])
	_expect(payout.beta.play_selected_hand([10] as Array[int]), "Failed 10-percent insight roll remains a successful Playtest hand")
	_expect(payout.run.get_cash() == 1000 and not payout.state.is_competitor_snapshot_revealed() and payout.state.get_marketing_output() == 4, "Nonbalanced Playtest awards exactly $1,000 without insight at failure boundary 10")
	_expect(payout.state.is_beta_card_exhausted(&"playtest_rival_games") and payout.state.get_current_cycle() == 1, "Playtest exhausts and advances one cycle even when insight fails")
	payout.beta.queue_free()
	await process_frame


func _verify_insight_boundaries() -> void:
	var success := await _make_beta([&"playtest_rival_games", &"predict_market_trends", &"sign_flippers", &"debug"])
	_expect(success.beta.play_selected_hand([9, 29] as Array[int]), "Playtest roll 9 and Forecast roll 29 hit their exact success intervals")
	_expect(success.state.is_competitor_snapshot_revealed() and success.state.is_market_forecast_snapshot_revealed(), "Successful insight rolls reveal both existing snapshots")
	_expect(success.beta.get_node("%CompetitorInfoLabel").text == "Rival: Fast Follower — Target Release: Cycle 12", "Revealed rival UI shows exact name and project-relative cycle")
	_expect(success.beta.get_node("%ForecastInfoLabel").text == "Forecast: Market Surge — Launch Demand ×1.15", "Revealed forecast UI shows exact name and multiplier")
	success.beta.queue_free()
	await process_frame

	var failure := await _make_beta([&"study_competition", &"predict_market_trends", &"sign_flippers", &"posters"])
	_expect(failure.beta.play_selected_hand([30, 30] as Array[int]), "Study and Forecast rolls 30 are normal successful-card failures")
	_expect(not failure.state.is_competitor_snapshot_revealed() and not failure.state.is_market_forecast_snapshot_revealed() and failure.state.get_current_cycle() == 1, "Failed insight rolls preserve concealment but do not reject the hand")
	_expect(failure.beta.get_node("%ActionFeedbackLabel").text.contains("No rival insight gained") and failure.beta.get_node("%ActionFeedbackLabel").text.contains("No market forecast gained"), "Feedback distinguishes both failed insight outcomes")
	failure.beta.queue_free()
	await process_frame

	var revealed := await _make_beta([&"study_competition", &"predict_market_trends", &"sign_flippers", &"posters"])
	revealed.state.reveal_competitor_snapshot()
	revealed.state.reveal_market_forecast_snapshot()
	_expect(revealed.beta.play_selected_hand(), "Already revealed snapshots consume no unnecessary controlled insight rolls")
	_expect(revealed.state.get_current_cycle() == 1, "Idempotent informational cards still exhaust and complete the hand")
	revealed.beta.queue_free()
	await process_frame


func _verify_lifecycle_and_replacement() -> void:
	var fixture := await _make_beta([&"press_interview", &"study_competition", &"search_for_bugs", &"debug"], 3)
	var beta: BetaPhase = fixture.beta
	var priorities := {&"qa": 50, &"marketing": 45, &"insider": 5}
	beta.set_priority_distribution(priorities)
	_expect(beta.play_selected_hand([29] as Array[int]), "Finite and renewable mixed hand resolves")
	_expect(beta.get("_candidate_cards").size() == 7 and beta.get_selected_candidate_count() == 0, "Successful action publishes seven replacements and clears selection")
	for card: CardData in beta.get("_candidate_cards"):
		_expect(not fixture.state.is_beta_card_exhausted(card.id), "Replacement excludes every exhausted finite definition")
	_expect(beta.get_priority_distribution() == priorities, "Replacement uses and preserves the latest valid priorities")
	_expect(fixture.state.is_beta_card_exhausted(&"press_interview") and fixture.state.is_beta_card_exhausted(&"study_competition"), "Selected finite cards exhaust")
	beta.queue_free()
	await process_frame

	var depletion_state := _make_state()
	depletion_state.exhaust_beta_cards([&"playtest_rival_games", &"study_competition", &"predict_market_trends"])
	var depletion := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(depletion)
	await process_frame
	depletion.setup(depletion_state, _make_run(), _snapshots)
	var definitions: Array[CardData] = []
	definitions.assign(_database.call(&"get_cards_by_phase", CardData.PHASE_BETA))
	var deal: Dictionary = depletion.call("_build_candidate_definitions", definitions, {&"qa": 35, &"marketing": 35, &"insider": 30}, [0.99, 0.99, 0.99, 0.99, 0.99, 0.99, 0.99] as Array[float], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7] as Array[float], depletion_state.get_exhausted_beta_card_ids())
	_expect(deal.valid and deal.cards.size() == 7, "Fully exhausted Insider category renormalizes to a complete QA/Marketing pool")
	for card: CardData in deal.cards: _expect(card.beta_category != CardData.BETA_CATEGORY_INSIDER, "Depleted Insider definitions receive zero draw weight")
	depletion.queue_free()
	await process_frame


func _verify_atomic_failures() -> void:
	var invalid_snapshot := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 4)
	invalid_snapshot.state.set("_competitor_snapshot_id", &"unknown_competitor")
	var before := _snapshot(invalid_snapshot.state, invalid_snapshot.run, invalid_snapshot.beta)
	_expect(not invalid_snapshot.beta.play_selected_hand() and _snapshot(invalid_snapshot.state, invalid_snapshot.run, invalid_snapshot.beta) == before, "Unknown assigned snapshot rejects atomically")
	invalid_snapshot.beta.queue_free()
	await process_frame

	var uninitialized_cash := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 4)
	var empty_run := RunState.new()
	uninitialized_cash.beta.set("_run_state", empty_run)
	before = _snapshot(uninitialized_cash.state, empty_run, uninitialized_cash.beta)
	_expect(not uninitialized_cash.beta.play_selected_hand() and _snapshot(uninitialized_cash.state, empty_run, uninitialized_cash.beta) == before, "Uninitialized RunState rejects atomically")
	uninitialized_cash.beta.queue_free()
	await process_frame

	var invalid_lifecycle := await _make_beta([&"press_interview", &"search_for_bugs", &"debug", &"sign_flippers"], 4)
	invalid_lifecycle.state.exhaust_beta_cards([&"press_interview"])
	before = _snapshot(invalid_lifecycle.state, invalid_lifecycle.run, invalid_lifecycle.beta)
	_expect(not invalid_lifecycle.beta.play_selected_hand() and _snapshot(invalid_lifecycle.state, invalid_lifecycle.run, invalid_lifecycle.beta) == before, "Already exhausted selected finite definition rejects atomically")
	invalid_lifecycle.beta.queue_free()
	await process_frame

	var cycle_overflow := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 4)
	cycle_overflow.state.set("_current_cycle", ProjectState.MAX_SIGNED_INT)
	before = _snapshot(cycle_overflow.state, cycle_overflow.run, cycle_overflow.beta)
	_expect(not cycle_overflow.beta.play_selected_hand() and _snapshot(cycle_overflow.state, cycle_overflow.run, cycle_overflow.beta) == before, "Cycle overflow rejects atomically")
	cycle_overflow.beta.queue_free()
	await process_frame

	var cash_overflow := await _make_beta([&"playtest_rival_games", &"sign_flippers", &"posters", &"debug"], 0, 0)
	cash_overflow.run.set("_cash_cents", RunState.MAX_SIGNED_INT - 99999)
	before = _snapshot(cash_overflow.state, cash_overflow.run, cash_overflow.beta)
	_expect(not cash_overflow.beta.play_selected_hand([0] as Array[int]) and _snapshot(cash_overflow.state, cash_overflow.run, cash_overflow.beta) == before, "Cash overflow rejects with complete state, pool, selection, and cycle preservation")
	cash_overflow.beta.queue_free()
	await process_frame

	var replacement := await _make_beta([&"search_for_bugs", &"debug", &"sign_flippers", &"posters"], 4)
	before = _snapshot(replacement.state, replacement.run, replacement.beta)
	_expect(not replacement.beta.play_selected_hand([] as Array[int], [0.1] as Array[float], [0.1] as Array[float]) and _snapshot(replacement.state, replacement.run, replacement.beta) == before, "Forced replacement-generation failure is atomic")
	replacement.beta.force_card_view_preparation_failure_for_verification()
	_expect(not replacement.beta.play_selected_hand() and _snapshot(replacement.state, replacement.run, replacement.beta) == before, "Forced CardView preparation failure is atomic")
	replacement.beta.queue_free()
	await process_frame


func _snapshot(state: ProjectState, run: RunState, beta: BetaPhase) -> Array:
	var ids: Array[StringName] = []
	for card: CardData in beta.get("_candidate_cards"): ids.append(card.id)
	var selected: Array[int] = []
	for view: CardView in beta.get("_selected_card_views"): selected.append(view.get_instance_id())
	return [state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_marketing_output(), state.get_current_cycle(), state.get_exhausted_beta_card_ids(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed(), run.get_cash(), run.get_cash_cents(), ids, selected, beta.get_priority_distribution()]


func _expect(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0: print("Beta base hand resolution verification passed.")
	quit(_failures)
