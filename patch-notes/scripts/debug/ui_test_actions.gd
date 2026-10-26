extends RefCounted
## Drive the real asynchronous new-save path in isolated UI fixtures.
static func finish_new_save(game: Node) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while game.get("_transition_in_progress") and Time.get_ticks_msec() < deadline:
		await game.get_tree().process_frame
	assert(not game.get("_transition_in_progress"), "New-save transition timed out")
	assert(game.get("_active_phase") is StudioPhase)
	if game.get("guided_tutorial") != null:
		game.guided_tutorial.choice.emit(true, false)
	await game.get_tree().process_frame
