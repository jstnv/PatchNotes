extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
var failures: Array=[]
func _initialize() -> void:
	await process_frame
	var output=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"native_store","studio_name":"Native Studio","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	var run: RunState=session.run
	assert(run.finalize_starter_selection() and run._register_proprietary_engine(&"b","Proprietary B") and run.select_engine(&"b"))
	assert(run.admit_feature_research(run.get_feature_research_quote(&"text")) and run.research_feature(run.get_feature_research_quote(&"text")) and run.stage_engine_features([&"text"] as Array[StringName]))
	var host=Control.new();host.theme=load("res://resources/ui/workspace_theme.tres");root.add_child(host)
	var store=FeatureStore.new();host.add_child(store);store.setup(run)
	var bounds: Array=[]
	for dimensions: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;host.size=dimensions
		store.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await process_frame;await process_frame
		store._select_node(&"text")
		await process_frame;await RenderingServer.frame_post_draw
		var selector: Rect2=store._engine_selector.get_global_rect();var commit: Rect2=store._configuration_commit.get_global_rect();var viewport=Rect2(Vector2.ZERO,dimensions)
		if not viewport.encloses(selector) or not viewport.encloses(commit) or selector.intersects(commit):failures.append("Toolbar bounds "+str(dimensions))
		if store._configuration_commit.disabled or store._buy.text!="Unstage":failures.append("Staging surface "+str(dimensions))
		var capture=output.get_base_dir()+"/store-%d.png"%dimensions.x
		root.get_texture().get_image().save_png(capture)
		bounds.append({"size":str(dimensions),"selector":str(selector),"commit":str(commit),"image":capture})
	store._engine_selector.item_selected.emit(0)
	if run.get_selected_engine_id()!=&"legacy_engine" or run.get_engine_feature_state().engines[&"b"].staged!=[&"text"]:failures.append("Native selector preserves staged B")
	host.queue_free();await process_frame
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"failures":failures,"bounds":bounds},"\t"));quit(0 if failures.is_empty() else 1)
