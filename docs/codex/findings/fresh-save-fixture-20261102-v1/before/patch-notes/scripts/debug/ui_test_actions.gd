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

static func create_feature_engine(run: RunState,label: String) -> StringName:
	var quote:=run.get_proprietary_engine_creation_quote(label)
	assert(not quote.is_empty(),"Engine fixture needs an affordable creation quote")
	var result:=run.create_proprietary_engine(quote)
	assert(result.get("ok",false),"Engine fixture creation failed")
	return result.engine_id

static func open_feature_implementation(studio: StudioPhase,engine_id: StringName) -> FeatureStore:
	studio._open_engines(engine_id)
	await studio.get_tree().create_timer(0.45).timeout
	studio._engine_browser.configure_button.pressed.emit()
	await studio.get_tree().create_timer(0.45).timeout
	assert(studio._feature_store!=null and studio._feature_store.visible,"Engine implementation did not open")
	return studio._feature_store
