extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize() -> void:go.call_deferred()
func go() -> void:
	root.size=Vector2i(1152,648)
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Visible Action",&"action",[])
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Action Engine"))
	var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var store:=FeatureStore.new();host.add_child(store);store.setup(run);store.open_store(created.engine_id)
	for frame in 5:await process_frame
	check(store._research_button.is_visible_in_tree(),"Top Implement is visible")
	check(not store._research_list.is_visible_in_tree(),"Queue dropdown remains absent")
	check(store._research_button.disabled,"Empty queue cannot complete")
	var studio: StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate();host.add_child(studio)
	await process_frame
	check(studio._hub.root_buttons.keys()==[&"studio_info",&"management",&"market",&"production"],"Four root groups in approved order")
	if studio._hub.groups.has(&"studio_info"):
		var labels:Array=[]
		for child in studio._hub.groups[&"studio_info"].get_children():
			if child is Button:labels.append(child.text)
		check(labels==["Studio Info","Post Game Summaries","Bank"],"Studio Info contains exact three destinations")
	else:check(false,"Studio Info group exists")
	studio.queue_free();host.queue_free();await process_frame;quit(failures)
