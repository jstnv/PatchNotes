extends "res://scripts/debug/candidate_route.gd"

func _run() -> void:
	var coordinator:=CheckpointCoordinator.new()
	coordinator.store=StudioCheckpointStore.new("user://cult-final",coordinator.adapter.validate)
	coordinator.store._writer=TCPServer.new()
	if coordinator.store._writer.listen(47846,"127.0.0.1")!=OK:quit(2);return
	root.add_child(coordinator)
	var run:=coordinator.load_current()
	if run==null:push_error("Neutral foundation restore rejected: "+coordinator.adapter.error);quit(1);return
	coordinator.entered_studio(true)
	var payload:=coordinator.adapter.capture(run)
	var exact:=JSON.stringify(payload).sha256_text()==FileAccess.get_file_as_string("user://cult-final.sha256")
	if not exact:push_error("Neutral foundation hash mismatch");quit(1);return
	# Finished the real restore. This bounded route uses explicit endpoint saves,
	# matching the original native driver; release the temporary store writer.
	coordinator.store.release_writer()
	coordinator.free()
	run.studio_departure_guard=Callable()
	run.checkpoint_before_mutation=Callable()
	era_policy="ordinary"
	var out:Dictionary={"actions":[],"cycles":[],"errors":[],"blockers":[],"stop":"","foundation_exact":exact,"foundation":payload}
	var game:Control=load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=run
	root.add_child(game)
	await process_frame
	out.initial=_state(game)
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	var accepted:=await _trial_contract(game,ContractState.CONTRACT_ID,out)
	out.final=_state(game)
	out.finance=run.get_studio_finance_snapshot()
	out.fanbase=run.get_fanbase_snapshot()
	out.sales=run._released_games
	out.metadata=run._release_metadata
	out.checkpoint=StudioCheckpoint.new().capture(run)
	out.final_saved=_save(run,"neutral-earned")
	out.valid=accepted and out.cycles.size()==2 and out.final_saved and not out.checkpoint.is_empty()
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("Neutral continuation passed=",out.valid," Fans=",run.get_fans()," cycle=",run.get_completed_run_cycles())
	game.queue_free();await process_frame
	quit(0 if out.valid else 1)
