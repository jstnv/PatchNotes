extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
	await process_frame
	var r=RunState.new();r.initialize_cash(0);r.create_studio_with_traits("Hub",&"action",[])
	var phase=load("res://scenes/phases/studio_phase.tscn").instantiate();root.add_child(phase);phase.setup(null,r,PrimitiveSnapshotDatabase.new())
	var hub=phase.find_child("StudioHub",true,false)
	if hub==null:failures.append("Persistent left StudioHub absent")
	phase._open_management()
	for name in ["MarketInfoButton","StudioManagementButton","StartProductionButton"]:
		if not phase.get_node("%"+name).is_visible_in_tree():failures.append("Root hidden with companion: "+name)
	var motion=MenuTransitions.new();motion.automatic_entrances=false;root.add_child(motion)
	if not motion.has_method("push_from_bottom"):failures.append("Shared bottom-entry destination motion absent")
	phase.queue_free();motion.queue_free();await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures}));quit(1 if failures else 0)
