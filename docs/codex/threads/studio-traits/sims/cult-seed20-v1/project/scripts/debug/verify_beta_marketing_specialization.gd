## Focused Primitive Beta Marketing Specialization verification.
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
	await _verify_marketing_hand()
	await _verify_aggregate_floor_and_renewable_duplicates()
	await _verify_off_category_hand()
	await _verify_overflow_rollback()
	if _failures == 0:
		print("Beta Marketing Specialization verification passed.")
	quit(_failures)


func _make_beta(ids: Array[StringName]) -> Dictionary:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.finalize_design_bugs(false, 0, [], [])
	state.finalize_alpha(0, [], [])
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


func _verify_marketing_hand() -> void:
	var fixture := await _make_beta([&"sign_flippers", &"posters", &"press_release", &"press_interview"])
	_expect(fixture.state.get_marketing_output() == 0 and fixture.state.get_current_cycle() == 0, "Selection is passive")
	_expect(fixture.beta.play_selected_hand(), "Four Marketing cards resolve")
	_expect(fixture.state.get_marketing_output() == 10, "Printed values 1+1+2+3 gain floor(7×1.5)=10 Marketing")
	_expect(fixture.state.get_current_cycle() == 1 and fixture.run.get_completed_run_cycles() == 1 and fixture.run.get_cash_cents() == 0, "Specialized hand advances one productive cycle without cash")
	_expect(fixture.state.is_beta_card_exhausted(&"press_interview") and not fixture.state.is_beta_card_exhausted(&"posters"), "Only finite Marketing card exhausts")
	_expect(fixture.beta.get_workspace().synergy_notification.banner.visible and fixture.beta.get_workspace().synergy_notification.title_label.text == "Marketing Specialization!", "In-game synergy banner appears")
	var feedback: String = fixture.beta.get_node("%ActionFeedbackLabel").text
	_expect(feedback.contains("Marketing Specialization! Card Value ×1.50") and feedback.contains("Marketing Output gained: 10") and not feedback.contains("Balanced Operations"), "Feedback reports actual specialized gain only")
	fixture.beta.queue_free()
	await process_frame


func _verify_aggregate_floor_and_renewable_duplicates() -> void:
	var fixture := await _make_beta([&"sign_flippers", &"sign_flippers", &"sign_flippers", &"press_release"])
	_expect(fixture.beta.play_selected_hand(), "Four renewable Marketing instances resolve")
	_expect(fixture.state.get_marketing_output() == 7, "Aggregate value 5 rounds floor(7.5)=7 once")
	fixture.beta.queue_free()
	await process_frame


func _verify_off_category_hand() -> void:
	var fixture := await _make_beta([&"sign_flippers", &"posters", &"press_release", &"debug"])
	_expect(fixture.beta.play_selected_hand(), "Three Marketing plus QA resolves without specialization")
	_expect(fixture.state.get_marketing_output() == 4 and not fixture.beta.get_workspace().synergy_notification.banner.visible, "Off-category card cancels Marketing Specialization")
	fixture.beta.queue_free()
	await process_frame


func _verify_overflow_rollback() -> void:
	var fixture := await _make_beta([&"sign_flippers", &"posters", &"press_release", &"press_interview"])
	fixture.state.add_marketing_output(ProjectState.MAX_SIGNED_INT - 9)
	var before := [fixture.state.get_marketing_output(), fixture.state.get_current_cycle(), fixture.run.get_completed_run_cycles(), fixture.run.get_cash_cents(), fixture.beta.get_selected_candidate_count()]
	_expect(not fixture.beta.play_selected_hand(), "Specialized Marketing overflow rejects")
	_expect([fixture.state.get_marketing_output(), fixture.state.get_current_cycle(), fixture.run.get_completed_run_cycles(), fixture.run.get_cash_cents(), fixture.beta.get_selected_candidate_count()] == before and not fixture.state.is_beta_card_exhausted(&"press_interview"), "Rejected hand preserves all authoritative state and selection")
	fixture.beta.queue_free()
	await process_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
