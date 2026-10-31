extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
var failures: Array=[]
func add(run: RunState,id: StringName) -> bool:
	if run.owns_feature(id):return true
	var graph=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	for parent: StringName in graph.parents[id]:
		if not add(run,parent):return false
	var quote=run.get_feature_research_quote(id)
	return quote.can_admit and run.admit_feature_research(quote) and run.research_feature(run.get_feature_research_quote(id))
func _initialize() -> void:
	await process_frame
	var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"era_fixture","studio_name":"Era fixture","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	var run: RunState=s.run
	assert(run.finalize_starter_selection())
	# Explicit mechanics fixture funding, not a career/balance or starting-capital trial.
	assert(run.add_cash_cents(5000000))
	while run.get_completed_run_cycles()<72:assert(run.complete_productive_action())
	assert(add(run,&"player_level_editor"))
	var adapter=StudioCheckpoint.new();var saved=adapter.capture(run)
	if saved.is_empty():failures.append(adapter.error)
	var restored=adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
	if restored==null:failures.append(adapter.error)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"cycles":run.get_completed_run_cycles(),"implemented":run.owns_feature(&"player_level_editor")}))
	quit(0 if failures.is_empty() else 1)
