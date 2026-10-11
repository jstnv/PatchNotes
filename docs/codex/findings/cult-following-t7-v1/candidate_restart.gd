extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var label: String=OS.get_cmdline_user_args()[0]
	var output: String=OS.get_cmdline_user_args()[1]
	var coordinator:=CheckpointCoordinator.new()
	coordinator.store=StudioCheckpointStore.new("user://cult-"+label,coordinator.adapter.validate)
	coordinator.store._writer=TCPServer.new()
	if coordinator.store._writer.listen(47846,"127.0.0.1")!=OK:quit(2);return
	root.add_child(coordinator)
	var before:=coordinator.store.inspect()
	var run:=coordinator.load_current()
	if run==null:push_error("Candidate Continue failed: "+coordinator.adapter.error);quit(1);return
	coordinator.entered_studio(true)
	var payload:=coordinator.adapter.capture(run)
	var expected:=FileAccess.get_file_as_string("user://cult-"+label+".sha256")
	var exact:=not payload.is_empty() and JSON.stringify(payload).sha256_text()==expected
	var fans:=run.get_fans()
	var duplicate_rejected:=not run.create_studio_with_traits("Duplicate",&"action",run.get_studio_traits().trait_ids)
	var broken:=payload.duplicate(true)
	broken.run.fanbase.initial_seed=str(int(broken.run.fanbase.initial_seed)+1)
	var corruption_rejected:=coordinator.adapter.hydrate(broken)==null
	var success: bool=exact and duplicate_rejected and corruption_rejected and run.get_fans()==fans and coordinator.store.inspect().payload==before.payload
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"label":label,"passed":success,"exact_payload":exact,"duplicate_creation_rejected":duplicate_rejected,"wrong_seed_rejected":corruption_rejected,"fanbase":run.get_fanbase_snapshot(),"cash_cents":run.get_cash_cents(),"cycle":run.get_completed_run_cycles()}))
	print("Candidate restart ",label," pass=",success," Fans=",fans)
	coordinator.store.release_writer()
	quit(0 if success else 1)
