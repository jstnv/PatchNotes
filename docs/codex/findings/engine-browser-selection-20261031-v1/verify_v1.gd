extends SceneTree
func _initialize() -> void:
	await process_frame
	var r=RunState.new();assert(r.initialize_cash(0) and r.create_studio_with_traits("Engines",&"action",[]))
	var setup=PredevelopmentOverlay.new();root.add_child(setup);setup.market_run=r;setup.open()
	var failures: Array=[]
	if setup.find_child("EnginePicker",true,false)==null:failures.append("Game setup must expose an engine picker")
	var scene=load("res://scenes/phases/studio_phase.tscn").instantiate();root.add_child(scene);scene._run_state=r
	scene._open_engines()
	if scene.find_child("EngineList",true,false)==null:failures.append("Engine browser must expose a left engine list")
	scene._ensure_contract_detail()
	if scene._contract_detail.find_child("EnginePicker",true,false)==null:failures.append("Contract setup must expose an engine picker")
	setup.queue_free();scene.queue_free();await process_frame
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"failures":failures}));quit(0 if failures.is_empty() else 1)
