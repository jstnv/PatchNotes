extends SceneTree

const CARD_SCENE := preload("res://scenes/cards/card_view.tscn")
var failures := 0
var completed := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func install(phase: Control, cards: Array[CardData]) -> Array[CardView]:
	var hand := phase.get_node("%HandContainer")
	for old_view in hand.get_children():
		hand.remove_child(old_view)
		old_view.free()
	var views: Array[CardView] = []
	for card: CardData in cards:
		var view := CARD_SCENE.instantiate() as CardView
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		hand.add_child(view)
		views.append(view)
	phase.set("_candidate_cards", cards.duplicate())
	phase.set("_selected_card_views", [] as Array[CardView])
	phase.call("_refresh_redraw_controls")
	return views


func _run() -> void:
	for name: String in ["design", "alpha"]:
		await verify_phase(name)
	check(completed == 2, "Both phase verifications must finish")
	if failures == 0:
		print("Design/Alpha redraw class parity verification passed.")
	quit(0 if failures == 0 else 1)


func verify_phase(name: String) -> void:
	var phase := load("res://scenes/phases/%s_phase.tscn" % name).instantiate() as Control
	var project := ProjectState.new(30)
	var run := RunState.new()
	run.initialize_cash(1000)
	root.add_child(phase)
	phase.call("setup", project, run)
	check(phase.call("begin_" + name), name + ": phase begins")
	var database := root.get_node("CardDatabase")
	var passes: Array[CardData] = phase.get("_pass_definitions")
	var sound: CardData = database.call("get_card", &"8_bit_sound" if name == "design" else &"power_ups")
	var other: CardData = database.call("get_card", &"text" if name == "design" else &"simple_story")
	var cards: Array[CardData] = []
	for index in range(7): cards.append(passes[0])
	var views := install(phase, cards)
	phase.set("_available_features", [sound, other] as Array[CardData])
	views[0].card_pressed.emit(views[0])
	var rng: RandomNumberGenerator = phase.get("_deal_rng")
	var rng_before := rng.state
	var feature_count := 0
	var pass_count := 0
	for index in range(100):
		var roll := (float(index) + 0.5) / 100.0
		var plan: Dictionary = phase.call("_plan_selected_redraw", [roll] as Array[float])
		check(plan.valid and plan.cards.size() == 1 and plan.cards[0].id != passes[0].id, name + ": controlled class plan is legal")
		if plan.valid and plan.cards.size() == 1:
			if plan.cards[0].card_type == &"feature": feature_count += 1
			else: pass_count += 1
	check(feature_count == 50 and pass_count == 50, name + ": equal class partitions ignore definition counts")
	check(rng.state == rng_before, name + ": controlled planning consumes no RNG")
	var first: Dictionary = phase.call("_plan_selected_redraw", [0.0] as Array[float])
	var last: Dictionary = phase.call("_plan_selected_redraw", [0.499999] as Array[float])
	check(first.cards[0].id != last.cards[0].id, name + ": class-half remapping reaches both weighted Feature definitions")
	check(phase.call("redraw_selected_cards", [0.0] as Array[float]), name + ": Pass can redraw to Feature")
	var hand := phase.get_node("%HandContainer")
	check(hand.get_child(0).card_data.card_type == &"feature" and phase.get("_selected_card_views").is_empty(), name + ": class crossing publishes one unselected Feature")
	if name == "design":
		check(not (phase.get("_available_features") as Array).has(first.cards[0]), name + ": Design reserves newly visible Feature")
	check(run.get_available_redraws() == 3 and run.get_completed_run_cycles() == 0 and project.get_current_scope() == 0, name + ": crossing spends one redraw and no time or Scope")
	# The just drawn Feature must return to Pass when finite alternatives are gone.
	var feature_view := hand.get_child(0) as CardView
	var exhausted_supply: Array[CardData] = []
	if name == "alpha": exhausted_supply.append(feature_view.card_data)
	phase.set("_available_features", exhausted_supply)
	feature_view.card_pressed.emit(feature_view)
	check(phase.call("redraw_selected_cards", [0.0] as Array[float]), name + ": exhausted Feature falls back to Pass")
	check(hand.get_child(0).card_data.card_type == &"pass" and run.get_available_redraws() == 2, name + ": fallback changes class and spends one redraw (got %s, %d)" % [hand.get_child(0).card_data.card_type, run.get_available_redraws()])
	if name == "design":
		check((phase.get("_available_features") as Array).has(feature_view.card_data), name + ": Design returns discarded Feature to finite supply")
	# An old Feature can also choose Pass directly when both classes are legal.
	cards[0] = other
	views = install(phase, cards)
	var direct_supply: Array[CardData] = [sound]
	if name == "alpha": direct_supply.append(other)
	phase.set("_available_features", direct_supply)
	views[0].card_pressed.emit(views[0])
	check(phase.call("redraw_selected_cards", [0.5] as Array[float]), name + ": Feature can redraw to Pass with both classes legal")
	check(hand.get_child(0).card_data.card_type == &"pass" and run.get_available_redraws() == 1, name + ": direct crossing keeps the shared allowance")
	if name == "design":
		check((phase.get("_available_features") as Array).has(other), name + ": Feature-to-Pass returns discarded definition")
	# Reserve the lone Feature once in an atomic two-card redraw; the second
	# class request falls back to a renewable Pass.
	run.refresh_redraws()
	cards[0] = passes[0]
	views = install(phase, cards)
	phase.set("_available_features", [sound] as Array[CardData])
	views[0].card_pressed.emit(views[0])
	views[1].card_pressed.emit(views[1])
	var emissions := [0]
	run.redraws_changed.connect(func(): emissions[0] += 1)
	check(phase.call("redraw_selected_cards", [0.0, 0.0] as Array[float]), name + ": two-card redraw reserves finite Feature then falls back")
	check(hand.get_child(0).card_data == sound and hand.get_child(1).card_data.card_type == &"pass", name + ": finite Feature appears only once")
	check(run.get_available_redraws() == 2 and emissions[0] == 1 and phase.get("_selected_card_views").is_empty(), name + ": atomic action deducts two once and clears selection")
	# Both-class absence is only a malformed fixture with today's renewable
	# Passes, but the attempted action must still reject without partial commit.
	views = install(phase, cards)
	phase.set("_available_features", [] as Array[CardData])
	phase.set("_pass_definitions", [] as Array[CardData])
	views[0].card_pressed.emit(views[0])
	var selected: Array = phase.get("_selected_card_views").duplicate()
	var budget := run.get_available_redraws()
	rng_before = rng.state
	check(not phase.call("redraw_selected_cards", [0.0] as Array[float]), name + ": both empty classes reject")
	check(phase.get("_candidate_cards") == cards and phase.get("_selected_card_views") == selected and run.get_available_redraws() == budget and rng.state == rng_before, name + ": rejection preserves pool, selection, budget and RNG")
	phase.set("_available_features", [sound] as Array[CardData])
	check(phase.call("redraw_selected_cards", [0.8] as Array[float]), name + ": synthetic no-Pass class falls back to Feature")
	check(hand.get_child(0).card_data == sound and run.get_available_redraws() == budget - 1, name + ": sole Feature class publishes one finite definition")
	phase.queue_free()
	await process_frame
	completed += 1
