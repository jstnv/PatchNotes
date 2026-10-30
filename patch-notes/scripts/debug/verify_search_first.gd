extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	verify.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func ids(views: Array) -> Array:
	return views.map(func(view): return view.card_data.id)

func verify() -> void:
	var fan := CardFan.new()
	root.add_child(fan)
	fan.size = Vector2(1152, 450)
	var original: Array[CardView] = []
	for id in [&"debug", &"posters", &"search_for_bugs", &"search_for_bugs", &"sign_flippers"]:
		var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(root.get_node("CardDatabase").get_card(id))
		fan.add_child(view)
		original.append(view)
	# Both Search instances are selected after Debug and Marketing.
	for index in [0, 1, 3, 2]: original[index].set_selected(true)
	fan.arrange(true)
	expect(original[2].position.x < original[3].position.x and original[3].position.x < original[0].position.x and original[0].position.x < original[1].position.x, "Selected Search instances lead the upper fan, preserving order within both groups")
	expect(fan.card_views() == original and fan.ordered_cards() == original, "Search ordering preserves authoritative candidate slots and underlying organization")
	var motion := HandPresentation.new()
	root.add_child(motion)
	motion.set_process(false)
	motion.clock_source = func(): return 0.0
	var state := {"_cycle": 0, &"discovered": 0, &"fixed": 0, &"marketing": 0}
	var calls := [0]
	var action := func():
		calls[0] += 1
		state._cycle = 1
		state[&"discovered"] = 2
		state[&"fixed"] = 1
		state[&"marketing"] = 1
	var selected: Array = [original[0], original[1], original[3], original[2]]
	expect(motion.play("play", fan, selected, action, func(): return state.duplicate(), Callable(), Callable()), "Selected hand presentation starts")
	expect(ids(motion._hand) == [&"search_for_bugs", &"search_for_bugs", &"debug", &"posters"], "Playback shows Search first with stable remaining card order")
	var now := 0.0
	while motion.trace.filter(func(row): return row.event == "score").size() < 4 and now < 4.0:
		now += 0.05
		motion.advance_music(now)
	expect(calls[0] == 1 and state._cycle == 1, "Music-grid playback does not replay the action")
	expect(motion.display_values[&"discovered"] == 0 and motion.display_values[&"fixed"] == 0 and motion.display_values[&"marketing"] == 0,"Floating values hold the HUD before the music-grid deposit")
	while not motion.trace.any(func(row):return row.event=="hud_deposit") and now<6.0:
		now+=0.05
		motion.advance_music(now)
	expect(motion.display_values[&"discovered"] == 2 and motion.display_values[&"fixed"] == 1 and motion.display_values[&"marketing"] == 1, "Displayed totals match the single committed result")
	expect(motion.trace.filter(func(row): return row.event == "score").size() == 4, "Every selected instance scores once")
	expect(fan.card_views() == original, "Playback does not remap candidate slots")
	motion.cancel()
	for view in original: view.set_selected(false)
	original[0].set_selected(true)
	original[1].set_selected(true)
	fan.arrange(true)
	expect(original[0].position.x < original[1].position.x and fan.ordered_cards() == original, "Deselecting Search restores ordinary selected order without moving the pool")
	motion.free()
	fan.free()
	await process_frame
	await process_frame
	# Allow the audio mixer to release stopped SFX after the freed presenter.
	await create_timer(0.10).timeout
	print("Search-first verification: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
