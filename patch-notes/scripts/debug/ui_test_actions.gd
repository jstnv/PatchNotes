extends RefCounted
## Drive the real asynchronous new-save path in isolated UI fixtures.
## Rival hydration and durable publication are setup, not ordinary UI actions.
const NEW_SAVE_TIMEOUT_MSEC := 60000
static func finish_new_save(game: Node) -> void:
	var started := Time.get_ticks_msec()
	var deadline := started + NEW_SAVE_TIMEOUT_MSEC
	var next_report := started + 10000
	while game.get("_transition_in_progress") and Time.get_ticks_msec() < deadline:
		if Time.get_ticks_msec() >= next_report:
			print("NEW_SAVE_WAIT elapsed_ms=%d phase=%s" % [Time.get_ticks_msec()-started,_new_save_phase(game)])
			next_report += 10000
		await game.get_tree().process_frame
	assert(not game.get("_transition_in_progress"), "New-save transition timed out after%dms (phase=%s)" % [Time.get_ticks_msec()-started,_new_save_phase(game)])
	print("NEW_SAVE_READY waited_ms=%d" % (Time.get_ticks_msec()-started))
	assert(game.get("_active_phase") is StudioPhase)
	if game.get("guided_tutorial") != null:
		game.guided_tutorial.choice.emit(true, false)
	await game.get_tree().process_frame

static func _new_save_phase(game: Node) -> String:
	var phase: Node = game.get("_active_phase")
	return str(phase.name) if is_instance_valid(phase) else "none"

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
