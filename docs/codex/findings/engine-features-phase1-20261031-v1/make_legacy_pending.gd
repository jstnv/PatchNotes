extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
func _initialize() -> void:
	await process_frame
	var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"engine_old","studio_name":"Old queue","specialty":"action","seed":"4417","traits":[]},root.get_node("CardDatabase").get_development_catalog())
	assert(session!=null)
	var run: RunState=session.run
	assert(run.finalize_starter_selection())
	var quote=run.get_feature_research_quote(&"colored_text")
	assert(quote.can_admit and run.admit_feature_research(quote))
	var adapter=StudioCheckpoint.new();var saved=adapter.capture(run)
	assert(not saved.is_empty(),adapter.error)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(saved))
	quit(0)
