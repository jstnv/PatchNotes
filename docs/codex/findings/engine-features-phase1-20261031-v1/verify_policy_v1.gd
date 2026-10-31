extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Decision=preload("res://scripts/market/rival_career_decision.gd")
func _initialize() -> void:
	await process_frame
	var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"policy_fixture","studio_name":"Policy fixture","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	var r: RunState=s.run
	assert(r.finalize_starter_selection() and r._register_proprietary_engine(&"b","Policy B") and r.select_engine(&"b"))
	assert(r.admit_feature_research(r.get_feature_research_quote(&"text")) and r.research_feature(r.get_feature_research_quote(&"text")))
	var d=Decision.new(s,{})
	var view=d.observation(s);var choice=d.choose(view,d);var failures: Array=[]
	if choice.type!=&"stage_engine_features":failures.append("Optimized rival observation must request explicit staging")
	else:
		assert(s.execute(s.command(choice.type,choice.payload)).ok)
		choice=d.choose(d.observation(s),d)
		if choice.type!=&"commit_engine_configuration":failures.append("Rival must commit staged implementation before shopping/production")
		else:assert(s.execute(s.command(choice.type,choice.payload)).ok)
	if r.get_future_project_feature_ids()!=[&"text"]:failures.append("Rival configured pool must contain newly implemented card")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
