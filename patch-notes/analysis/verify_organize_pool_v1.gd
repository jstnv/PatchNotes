extends SceneTree
func _initialize() -> void:
	check.call_deferred()
func check() -> void:
	var game = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30)
	game.run_state = RunState.new()
	game.run_state.initialize_cash(10000)
	root.add_child(game)
	await process_frame
	var phase = game.get("_active_phase")
	phase.get_workspace().overlay.commit_draft()
	await process_frame
	var fan = phase.get_node("%HandContainer")
	var original = fan.get_children()
	original[0].input_button.pressed.emit()
	var selected = phase.get_selected_candidate_views().duplicate()
	var before = HandPresentation.project_snapshot(game.project_state,game.run_state)
	var cash = game.run_state.get_cash_cents()
	phase.get_workspace().organize_button.pressed.emit()
	assert(fan.get_children() == original)
	assert(selected == phase.get_selected_candidate_views())
	assert(before == HandPresentation.project_snapshot(game.project_state,game.run_state))
	assert(cash == game.run_state.get_cash_cents())
	var keys = [&"graphics",&"sound",&"technology",&"design"]
	var previous = -1
	for view in fan.ordered_cards():
		var rank = keys.find(view.card_data.primary_stat)
		if rank < 0: rank = 4
		assert(rank >= previous)
		previous = rank
	var first = fan.ordered_cards()
	phase.get_workspace().organize_button.pressed.emit()
	assert(fan.ordered_cards() == first)
	print("PASS: grouping stable; selected cards, authoritative slots, cash, cycles and redraws unchanged")
	game.queue_free()
	await process_frame
	quit()
