extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
func _initialize() -> void:
	await process_frame
	var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"resourceful_fixture","studio_name":"Resourceful fixture","specialty":"action","traits":["resourceful","expensive_lease"],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	assert(s!=null)
	var r: RunState=s.run;assert(r.finalize_starter_selection())
	var q=r.get_feature_research_quote(&"colored_text");assert(q.can_admit and r.admit_feature_research(q))
	var head=r.get_feature_research_quote(&"colored_text")
	assert(head.saving_cents==10000 and head.due_cents==22500 and r.research_feature(head))
	var adapter=StudioCheckpoint.new();var saved=adapter.capture(r);assert(not saved.is_empty(),adapter.error)
	assert(adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))!=null,adapter.error)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"ok":true,"down_cents":q.down_cents,"saving_cents":head.saving_cents,"due_cents":head.due_cents}));quit(0)
