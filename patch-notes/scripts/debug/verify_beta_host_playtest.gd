## Separately invoked locked Beta Host Playtest verification.
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
	await _verify_planning_and_affordability()
	await _verify_selection_preservation()
	await _verify_pending_and_injection()
	await _verify_corrective_pass_resolution()
	await _verify_single_corrective_pass_resolution()
	if _failures == 0:
		print("Beta Host Playtest verification passed.")
	quit(_failures)


func _make_state() -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.finalize_design_bugs(false, 5, [], [])
	state.finalize_alpha(0, [], [])
	return state


func _make_beta(cash: int, begin: bool = true) -> Dictionary:
	var state := _make_state()
	var run := RunState.new()
	run.initialize_cash(cash)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state, run, _snapshots)
	if begin:
		beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
		_install_pool(beta, [&"search_for_bugs", &"debug", &"sign_flippers", &"posters", &"press_release", &"search_for_bugs", &"debug"])
	return {&"beta": beta, &"state": state, &"run": run}


func _install_pool(beta: BetaPhase, ids: Array[StringName]) -> void:
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
	beta.set("_injected_corrective_views", [] as Array[CardView])


func _select_count(beta: BetaPhase, count: int) -> void:
	for index in range(count):
		beta.call("_on_card_pressed", beta.get("_candidate_views")[index])


func _pool_identity(beta: BetaPhase) -> Array:
	var ids: Array[StringName] = []
	var instances: Array[int] = []
	for card: CardData in beta.get("_candidate_cards"):
		ids.append(card.id)
	for view: CardView in beta.get("_candidate_views"):
		instances.append(view.get_instance_id())
	return [ids, instances]


func _selection_identity(beta: BetaPhase) -> Array[int]:
	var result: Array[int] = []
	for view: CardView in beta.get_selected_candidate_views():
		result.append(view.get_instance_id())
	return result


func _verify_planning_and_affordability() -> void:
	var planning := await _make_beta(1000, false)
	_expect(not planning.beta.host_playtest(), "Planning rejects Beta Host Playtest")
	_expect(planning.run.get_cash() == 1000 and planning.state.get_current_cycle() == 0, "Planning rejection spends no cash and advances no cycle")
	planning.beta.queue_free()
	await process_frame

	var poor := await _make_beta(499)
	var pool_before := _pool_identity(poor.beta)
	_expect(not poor.beta.host_playtest(), "Cash below $500 rejects Host Playtest")
	_expect(poor.run.get_cash() == 499 and poor.state.get_current_cycle() == 0 and poor.beta.get_pending_corrective_pass_ids().is_empty() and _pool_identity(poor.beta) == pool_before, "Unaffordable action is fully atomic")
	poor.beta.queue_free()
	await process_frame


func _verify_selection_preservation() -> void:
	for count in range(5):
		var fixture := await _make_beta(1000)
		_select_count(fixture.beta, count)
		var pool_before := _pool_identity(fixture.beta)
		var selection_before := _selection_identity(fixture.beta)
		var priorities: Dictionary = fixture.beta.get_priority_distribution()
		var bugs := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_remaining_bugs()]
		_expect(fixture.beta.host_playtest(), "Active Host Playtest accepts %d selected cards" % count)
		_expect(_pool_identity(fixture.beta) == pool_before and _selection_identity(fixture.beta) == selection_before, "Host Playtest preserves pool and selection order with %d selections" % count)
		_expect(fixture.beta.get_priority_distribution() == priorities and [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_remaining_bugs()] == bugs, "Host Playtest preserves priorities and Bugs with %d selections" % count)
		_expect(fixture.run.get_cash() == 500 and fixture.state.get_current_cycle() == 1, "Host Playtest costs exactly $500 and one cycle with %d selections" % count)
		fixture.beta.queue_free()
		await process_frame


func _verify_pending_and_injection() -> void:
	var fixture := await _make_beta(1000)
	fixture.state.add_core_score(ProjectState.CoreScore.GRAPHICS, 5)
	fixture.state.add_core_score(ProjectState.CoreScore.SOUND, 1)
	fixture.state.add_core_score(ProjectState.CoreScore.TECHNOLOGY, 1)
	fixture.state.add_core_score(ProjectState.CoreScore.DESIGN, 3)
	_select_count(fixture.beta, 4)
	var values_before := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_marketing_output(), fixture.state.is_competitor_snapshot_revealed(), fixture.state.is_market_forecast_snapshot_revealed(), fixture.state.get_exhausted_beta_card_ids()]
	_expect(fixture.beta.host_playtest(), "Valid Active Development Host Playtest succeeds")
	_expect(fixture.beta.get_pending_corrective_pass_ids() == ([&"sound_pass", &"technology_pass"] as Array[StringName]), "Weakness ranking snapshots Sound then Technology using enum tie order")
	_expect([fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_marketing_output(), fixture.state.is_competitor_snapshot_revealed(), fixture.state.is_market_forecast_snapshot_revealed(), fixture.state.get_exhausted_beta_card_ids()] == values_before, "Activation changes no Bugs, Marketing, snapshots, or lifecycle")
	var pending: Array[StringName] = fixture.beta.get_pending_corrective_pass_ids()
	_expect(fixture.beta.set_priority_distribution({&"qa": 50, &"marketing": 45, &"insider": 5}), "Changed committed priorities succeed")
	_expect(fixture.state.get_current_cycle() == 2, "Host and priority commit each consume one cycle")
	fixture.state.add_core_score(ProjectState.CoreScore.SOUND, 100)
	fixture.beta.setup(fixture.state, fixture.run, _snapshots)
	_expect(fixture.beta.get_pending_corrective_pass_ids() == pending, "Priority, score changes, and UI reconstruction cannot alter pending IDs")
	_expect(not fixture.beta.host_playtest() and fixture.run.get_cash() == 500 and fixture.state.get_current_cycle() == 2, "Second callback while pending cannot double-charge or advance")
	_expect(fixture.beta.play_selected_hand([] as Array[int], [0.05, 0.15] as Array[float], [0.1, 0.2] as Array[float]), "Next successful hand prepares two ordinary candidates alongside two corrective Passes")
	var cards: Array[CardData] = fixture.beta.get("_candidate_cards")
	_expect(cards.size() == 7 and cards[3].id == &"sound_pass" and cards[4].id == &"technology_pass", "Replacement preserves three cards, then publishes queued Passes and two ordinary cards")
	for index in range(5, 7):
		_expect(cards[index].phase == CardData.PHASE_BETA and cards[index].card_type == &"beta", "Replacement ordinary slot %d remains a weighted Beta definition" % index)
	_expect(fixture.beta.get_pending_corrective_pass_ids().is_empty(), "Pending correction clears only after complete pool publication")
	_expect(fixture.state.get_current_cycle() == 3, "Host, priority commit, and production advance exactly three cycles")
	_expect(fixture.beta.get_node("%ActionFeedbackLabel").text.contains("Beta Host Playtest corrective Passes injected: Sound Pass, Technology Pass"), "Consumption feedback identifies both injected Passes")
	fixture.beta.set("_pending_corrective_pass_ids", [&"graphics_pass", &"design_pass"] as Array[StringName])
	var pending_before: Array[StringName] = fixture.beta.get_pending_corrective_pass_ids()
	fixture.beta.force_card_view_preparation_failure_for_verification()
	var state_before := [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_current_cycle(), fixture.run.get_cash(), _pool_identity(fixture.beta), _selection_identity(fixture.beta)]
	_select_count(fixture.beta, 4)
	state_before = [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_current_cycle(), fixture.run.get_cash(), _pool_identity(fixture.beta), _selection_identity(fixture.beta)]
	_expect(not fixture.beta.play_selected_hand(), "Forced corrective replacement failure rejects the production hand")
	_expect(fixture.beta.get_pending_corrective_pass_ids() == pending_before and [fixture.state.get_hidden_bugs(), fixture.state.get_known_bugs(), fixture.state.get_current_cycle(), fixture.run.get_cash(), _pool_identity(fixture.beta), _selection_identity(fixture.beta)] == state_before, "Failed production preserves pending correction, state, pool, and selection")
	fixture.beta.queue_free()
	await process_frame


func _verify_corrective_pass_resolution() -> void:
	var fixture := await _make_beta(1500)
	fixture.state.add_core_score(ProjectState.CoreScore.GRAPHICS, 5)
	fixture.state.add_core_score(ProjectState.CoreScore.SOUND, 1)
	fixture.state.add_core_score(ProjectState.CoreScore.TECHNOLOGY, 1)
	fixture.state.add_core_score(ProjectState.CoreScore.DESIGN, 3)
	_select_count(fixture.beta, 4)
	fixture.beta.host_playtest()
	fixture.beta.play_selected_hand([] as Array[int], [0.05, 0.15] as Array[float], [0.1, 0.2] as Array[float])
	var views: Array[CardView] = fixture.beta.get("_candidate_views").duplicate()
	for index in [3, 4, 5, 6]:
		fixture.beta.call("_on_card_pressed", views[index])
	_expect(fixture.beta.get_workspace().get("_synergy_help_title") == "Corrective Pass selected", "Beta tooltip explains that corrective Passes do not grant synergy")
	var sound_before: int = fixture.state.get_core_score(ProjectState.CoreScore.SOUND)
	var technology_before: int = fixture.state.get_core_score(ProjectState.CoreScore.TECHNOLOGY)
	_expect(fixture.beta.play_selected_hand(), "Two corrective Passes can resolve with two ordinary Beta cards")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before + 2 and fixture.state.get_core_score(ProjectState.CoreScore.TECHNOLOGY) == technology_before + 2, "Each selected corrective Pass adds exactly +2 to its matching Core Score")
	var feedback: String = fixture.beta.get_node("%ActionFeedbackLabel").text
	_expect(feedback.contains("Corrective Pass gains: Sound +2, Technology +2") and not feedback.contains("QA Specialization") and not feedback.contains("Balanced Operations"), "Corrective Pass feedback reports gains and cancels both Beta synergies")
	_expect(not fixture.state.is_beta_card_exhausted(&"sound_pass") and not fixture.state.is_beta_card_exhausted(&"technology_pass"), "Corrective Pass definitions never exhaust")
	for card: CardData in fixture.beta.get("_candidate_cards"):
		_expect(card.card_type == &"beta", "Later ordinary pool contains no expired corrective Pass opportunity")
	_expect(fixture.beta.host_playtest(), "A later Host Playtest may queue another correction after consumption")
	fixture.beta.queue_free()
	await process_frame


func _verify_single_corrective_pass_resolution() -> void:
	var fixture := await _make_beta(1000)
	_select_count(fixture.beta, 4)
	_expect(fixture.beta.host_playtest(), "Host Playtest queues a controlled single-Pass fixture")
	_expect(fixture.beta.play_selected_hand([] as Array[int], [0.05, 0.15] as Array[float], [0.1, 0.2] as Array[float]), "Controlled hand publishes corrective Pass opportunities")
	var views: Array[CardView] = fixture.beta.get("_candidate_views").duplicate()
	fixture.beta.call("_on_card_pressed", views[3])
	for index in range(3):
		fixture.beta.call("_on_card_pressed", views[index])
	var graphics_before: int = fixture.state.get_core_score(ProjectState.CoreScore.GRAPHICS)
	var sound_before: int = fixture.state.get_core_score(ProjectState.CoreScore.SOUND)
	_expect(fixture.beta.play_selected_hand(), "One corrective Pass can resolve with three ordinary Beta cards")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.GRAPHICS) == graphics_before + 2, "Selected corrective Pass applies exactly +2")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before, "Unselected corrective Pass applies no effect")
	_expect(views[4] in fixture.beta.get("_candidate_views") and views[4] in fixture.beta.get("_injected_corrective_views"), "Unplayed corrective Pass retains its instance and corrective eligibility")
	var next_views: Array[CardView] = fixture.beta.get("_candidate_views")
	for index in range(4): fixture.beta.call("_on_card_pressed", next_views[index])
	_expect(fixture.beta.play_selected_hand(), "Retained corrective Pass remains playable in the following hand")
	_expect(fixture.state.get_core_score(ProjectState.CoreScore.SOUND) == sound_before + 2 and views[4] not in fixture.beta.get("_candidate_views"), "Retained corrective Pass grants its +2 exactly once when played")
	fixture.beta.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
