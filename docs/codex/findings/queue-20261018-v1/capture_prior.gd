extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
func _initialize() -> void:
	await process_frame
	var db = root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	var saves := {}
	for genre: StringName in StudioSpecialties.RULES:
		var session = Factory.create_fresh_session({"schema_version":1,"studio_id":"prior-"+str(genre),"studio_name":"Prior Studio","specialty":str(genre),"traits":[],"seed":"4417"},db)
		saves[genre] = adapter.capture(session.run)
	# Actual preceding-rule admission: a saved queue may legally lack its new parent.
	var session = Factory.create_fresh_session({"schema_version":1,"studio_id":"prior-queue","studio_name":"Prior Queue","specialty":"sports","traits":[],"seed":"4420"},db)
	assert(not session.run.owns_feature(&"simple_story") and not session.run.owns_feature(&"dialogue"))
	assert(session.run.finalize_starter_selection())
	assert(session.run.admit_feature_research(session.run.get_feature_research_quote(&"dialogue")))
	saves["queued"] = adapter.capture(session.run)
	FileAccess.open(OS.get_environment("PN_PRE_BRANCH_SAVES"),FileAccess.WRITE).store_string(JSON.stringify(saves,"\t"))
	print("PRIOR_BRANCH_CAPTURE eight specialties and actual parentless queue")
	quit()
