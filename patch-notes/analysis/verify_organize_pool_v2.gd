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
	phase.get_workspace().organize_button.pressed.emit()
	assert(phase.get_workspace().organize_button.text == "Sort by Category")
	var last_scope = 2147483647
	for view in fan.ordered_cards():
		assert(view.card_data.scope <= last_scope)
		last_scope = view.card_data.scope
	assert(fan.get_children() == original)
	assert(selected == phase.get_selected_candidate_views())
	assert(before == HandPresentation.project_snapshot(game.project_state,game.run_state))
	assert(cash == game.run_state.get_cash_cents())
	var button = phase.get_workspace().organize_button
	var redraw = phase.get_node("%RedrawButton")
	assert(button.get_parent() == redraw.get_parent() and button.get_index() == redraw.get_index() + 1)
	button.pressed.emit()
	assert(button.text == "Sort by Scope")
	print("PASS: grouping stable; selected cards, authoritative slots, cash, cycles and redraws unchanged")
	game.queue_free()
	await process_frame
	quit()
