extends SceneTree

const CARD_SCENE := preload("res://scenes/cards/card_view.tscn")
var failures := 0
var database: Node

class TrackingCard:
	extends CardView
	var shakes := 0
	func shake_no() -> void:
		shakes += 1
		super.shake_no()

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func snapshot(object: Object) -> Dictionary:
	var result := {}
	for property: Dictionary in object.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = object.get(property.name)
			result[property.name] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result

func install(phase: Control, cards: Array[CardData]) -> Array[CardView]:
	var hand := phase.get_node("%HandContainer")
	for view in hand.get_children():
		hand.remove_child(view)
		view.free()
	var views: Array[CardView] = []
	for card: CardData in cards:
		var view := CARD_SCENE.instantiate() as CardView
		view.set_script(TrackingCard)
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		hand.add_child(view)
		views.append(view)
	phase.set("_candidate_cards", cards.duplicate())
	phase.set("_selected_card_views", [] as Array[CardView])
	if phase is BetaPhase:
		phase.set("_candidate_views", views.duplicate())
		phase.set("_injected_corrective_views", [] as Array[CardView])
	phase.call("_refresh_redraw_controls")
	return views

func select(views: Array[CardView], indices: Array[int]) -> void:
	for index: int in indices: views[index].card_pressed.emit(views[index])

func _run() -> void:
	database = root.get_node("CardDatabase")
	for name: String in ["design", "alpha", "beta"]:
		await verify_phase(name)
	if failures == 0: print("Atomic selected redraw verification passed.")
	quit(0 if failures == 0 else 1)

func verify_phase(name: String) -> void:
	var phase := load("res://scenes/phases/%s_phase.tscn" % name).instantiate() as Control
	var project := ProjectState.new(30)
	var run := RunState.new()
	run.initialize_cash(1000)
	if name == "beta":
		project.initialize_snapshots(&"fast_follower", &"market_surge")
		project.finalize_design_bugs(false, 0, [], [])
		project.finalize_alpha(0, [], [])
	root.add_child(phase)
	if name == "beta":
		var snapshots := PrimitiveSnapshotDatabase.new()
		snapshots.load_ledgers()
		phase.call("setup", project, run, snapshots)
	else:
		phase.call("setup", project, run)
	check(phase.call("begin_" + name), name + " begins")
	var button := phase.get_node("%RedrawButton") as Button
	var play := phase.get_node("%" + {"design": "PlayCardButton", "alpha": "PlayAlphaHandButton", "beta": "PlayHandButton"}[name]) as Button
	var cards: Array[CardData] = []
	var features: Array[CardData] = []
	if name == "beta":
		var renewable: CardData = database.call("get_card", &"debug")
		for index in range(7): cards.append(renewable)
	else:
		var passes: Array[CardData] = phase.get("_pass_definitions")
		features.assign(database.call("get_cards_by_phase_and_types", CardData.PHASE_DESIGN if name == "design" else CardData.PHASE_ALPHA, [&"feature"] as Array[StringName]))
		for index in range(7): cards.append(passes[0])
	var views := install(phase, cards)
	check(button.disabled, name + ": empty selection disables")
	select(views, [4])
	check(not button.disabled, name + ": one selection enables")
	select(views, [1, 5, 2])
	check(not button.disabled, name + ": four selections enable")
	check(not play.disabled, name + ": four-card Play remains enabled")
	var commit_disabled: bool = phase.get_node("%CommitPrioritiesButton").disabled
	run.consume_redraw()
	check(button.disabled and not play.disabled, name + ": over budget disables only Redraw")
	check(phase.get_node("%CommitPrioritiesButton").disabled == commit_disabled, name + ": commit availability unchanged")
	var before := snapshot(project)
	var rng: RandomNumberGenerator = phase.get("_deal_rng")
	var rng_before := rng.state
	check(not phase.call("redraw_selected_cards"), name + ": over-budget rejects")
	check(phase.get("_selected_card_views") == [views[4], views[1], views[5], views[2]], name + ": selection order stable")
	run.refresh_redraws()
	check(not button.disabled and rng.state == rng_before, name + ": budget refresh immediate and preview consumes no RNG")
	var emissions := [0]
	run.redraws_changed.connect(func(): emissions[0] += 1)
	check(phase.call("redraw_selected_cards", [0.2, 0.4, 0.6, 0.8] as Array[float]), name + ": multi-card redraw succeeds")
	check(run.get_available_redraws() == 0 and emissions[0] == 1, name + ": exact deduction in one notification")
	check(snapshot(project) == before and run.get_completed_run_cycles() == 0, name + ": no effects, exhaustion or time")
	check(phase.get("_selected_card_views").is_empty() and button.disabled, name + ": success clears selection")
	var hand := phase.get_node("%HandContainer")
	check(hand.get_child_count() == 7, name + ": slot count stable")
	var finite: Array[StringName] = []
	for index in range(7):
		var view := hand.get_child(index) as CardView
		if index in [4, 1, 5, 2]:
			check(view.card_data.id != cards[index].id and not view.is_selected(), name + ": same definition excluded and replacement unselected")
			if name != "beta": check(view.card_data.card_type == &"pass" and view.card_data.primary_stat != cards[index].primary_stat, name + ": different Pass type")
		else:
			check(view == views[index], name + ": untouched slot preserves view")
		if not view.card_data.renewable:
			check(not finite.has(view.card_data.id), name + ": finite replacement never reused")
			finite.append(view.card_data.id)
	run.refresh_redraws()
	# The one-selected-card case follows the same shared action.
	var single := hand.get_child(0) as CardView
	single.card_pressed.emit(single)
	button.pressed.emit()
	check(run.get_available_redraws() == 3 and hand.get_child(0) != single, name + ": shared button performs single redraw")

	if name != "beta":
		cards[0] = features[0]
		cards[1] = features[1]
		views = install(phase, cards)
		phase.set("_available_features", [features[2]] as Array[CardData])
		select(views, [0, 2, 1])
		check(button.disabled, name + ": insufficient finite replacements disable")
		var lifecycle: Array = phase.get("_available_features").duplicate()
		var exhausted: Variant = phase.get("_exhausted_card_ids")
		if exhausted is Dictionary: exhausted = exhausted.duplicate()
		var selected: Array = phase.get("_selected_card_views").duplicate()
		var budget := run.get_available_redraws()
		rng_before = rng.state
		check(not phase.call("redraw_selected_cards", [0.5, 0.5, 0.5] as Array[float]), name + ": finite collision fails atomically")
		check(phase.get("_candidate_cards") == cards and phase.get("_selected_card_views") == selected, name + ": failure preserves pool and selection")
		check(phase.get("_available_features") == lifecycle and phase.get("_exhausted_card_ids") == exhausted, name + ": failure preserves lifecycle")
		check(run.get_available_redraws() == budget and rng.state == rng_before and snapshot(project) == before, name + ": failure preserves budget RNG and effects")
		check(phase.get_node("%RedrawFeedbackLabel").text == "No more Feature cards", name + ": exact Feature failure text")
		check(views[0].get("shakes") == 0 and views[1].get("shakes") == 1 and views[2].get("shakes") == 0, name + ": only unreplaceable Feature shakes")
		phase.set("_available_features", [] as Array[CardData])
		check(not phase.call("redraw_selected_cards"), name + ": completely exhausted Features reject")
		check(views[0].get("shakes") == 1 and views[1].get("shakes") == 2 and views[2].get("shakes") == 0, name + ": all affected Features shake, valid Pass does not")
		phase.set("_available_features", [features[2], features[3]] as Array[CardData])
		phase.call("_refresh_redraw_controls")
		check(not button.disabled, name + ": enough finite replacements enable")
		check(phase.call("redraw_selected_cards", [0.5, 0.5, 0.5] as Array[float]), name + ": finite multi replacement succeeds")
		check(hand.get_child(0).card_data.id != hand.get_child(1).card_data.id, name + ": reserved Features unique")
		check(snapshot(project) == before, name + ": Feature redraw does not exhaust or resolve")
	else:
		views = install(phase, cards)
		run.refresh_redraws()
		select(views, [0, 2])
		var beta_before := snapshot(project)
		var beta_rng_before := rng.state
		phase.call("force_card_view_preparation_failure_for_verification")
		check(not phase.call("redraw_selected_cards", [0.99, 0.99] as Array[float]), "Beta: preparation failure rejects full action")
		check(phase.get("_candidate_cards") == cards and phase.get("_candidate_views") == views and phase.get("_selected_card_views") == [views[0], views[2]], "Beta: preparation failure preserves views, cards and selection")
		check(snapshot(project) == beta_before and rng.state == beta_rng_before and run.get_available_redraws() == 4, "Beta: preparation failure preserves lifecycle, RNG and budget")
		phase.set("_force_card_view_failure", false)
		cards[1] = database.call("get_card", &"sound_pass")
		views = install(phase, cards)
		phase.set("_injected_corrective_views", [views[1]] as Array[CardView])
		select(views, [0, 1, 2, 3])
		check(button.disabled, "Beta: corrective selection disables Redraw")
		check(not play.disabled, "Beta: corrective Pass remains playable")
		check(not phase.call("redraw_selected_cards"), "Beta: corrective selection rejects")
		check(run.get_available_redraws() == 4 and phase.get("_candidate_cards") == cards and phase.get("_selected_card_views").size() == 4, "Beta: corrective rejection preserves complete state")
	phase.queue_free()
	await process_frame
