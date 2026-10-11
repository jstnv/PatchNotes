extends "res://scripts/debug/starwave_native_route.gd"

var restart_failures:=0
func verify(ok:bool,label:String)->void:
	if not ok:restart_failures+=1;push_error("FAIL: "+label)
	else:print("PASS: "+label)

func _run()->void:
	var mode:=_arg("--mode=","")
	var directory:=_arg("--directory=","")
	var adapter:=StudioCheckpoint.new()
	if mode=="seed":
		var store:=StudioCheckpointStore.new("user://saves/studio",adapter.validate)
		store._writer=TCPServer.new()
		verify(store._writer.listen(47921,"127.0.0.1")==OK,"Isolated restart writer")
		verify(store.inspect().status==&"empty","Fresh profile for genuine earned foundation")
		var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("before-starwave.payload.json")))
		verify(store.save(payload).status==&"saved","Store accepts genuine native foundation")
		FileAccess.open("user://starwave-baseline.json",FileAccess.WRITE).store_string(JSON.stringify(store.inspect().payload))
		store.release_writer()
	else:
		var game:Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.checkpoints.store._writer=TCPServer.new()
		verify(game.checkpoints.store._writer.listen(47921,"127.0.0.1")==OK,"Isolated restart writer")
		var initial:Dictionary=game.checkpoints.store.inspect()
		verify(initial.status==&"valid","Separate process finds valid saved generation")
		if initial.status!=&"valid":quit(1);return
		var digest:=FileAccess.get_sha256(initial.path)
		game._continue_checkpoint()
		await process_frame
		verify(game._active_phase is StudioPhase,"Actual Continue enters Studio")
		var run:RunState=game.run_state
		var trace:Dictionary={"mode":mode,"before":_state(game),"hands":[]}
		if mode.begins_with("rollback") or mode=="complete":
			var baseline:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://starwave-baseline.json"))
			verify(initial.payload==baseline,"Uncommitted timelines leave exact baseline bytes")
			var starwave:=pending_for(run,PublisherCatalog.STARWAVE)
			verify(not starwave.is_empty(),"Restored first offer is available")
			var banked:=run.get_pending_promotion_awards()
			var studio:StudioPhase=game._active_phase
			studio.get_node("%Contracts").pressed.emit()
			for i in range(studio._contract_chooser.item_count):
				if studio._contract_chooser.get_item_metadata(i)==starwave:
					studio._contract_chooser.select(i);studio._contract_chooser.item_selected.emit(i)
			studio._contract_detail.find_child("AcceptContractButton",true,false).pressed.emit()
			await process_frame
			verify(game._active_phase is ContractPhase,"Native restored acceptance")
			var phase:ContractPhase=game._active_phase
			var state:=run.get_active_contract()
			var count:=3 if mode=="complete" else int(mode.trim_prefix("rollback"))
			for number in range(count):
				var cards:=phase.get_candidate_cards()
				var indices:=_choose_contract(cards,state,"optimizer")
				var selected:Array=[]
				for i in indices:
					selected.append(str(cards[i].id));(phase._candidate_row.get_children()[i] as CardView).input_button.pressed.emit()
				verify(phase._play_selected_hand(),"Restored native hand %d"%(number+1))
				trace.hands.append({"draw":_ids(cards),"selected":selected,"after":_state(game),"rng":run.random_streams.snapshot()})
			verify(run.get_pending_promotion_awards()==banked and not run._promotion_awards.has(starwave),"Existing award survives every hand and completion")
			verify(game.checkpoints.store.inspect().payload==baseline and FileAccess.get_sha256(initial.path)==digest,"Acceptance/hands/completion before dismissal do not save")
			if mode=="complete":
				phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
				await process_frame
				verify(game._active_phase is StudioPhase and game.checkpoints.flush(),"Dismissal commits completed Studio checkpoint")
				verify(run.get_completed_contract_count()==4 and pending_for(run,PublisherCatalog.STARWAVE).is_empty(),"Paid identity is distinct and offer is not reissued")
				FileAccess.open("user://starwave-completed.json",FileAccess.WRITE).store_string(JSON.stringify(adapter.capture(run)))
				trace.checkpoint=adapter.capture(run)
			elif mode=="rollback3":
				var signature:=JSON.stringify(trace.hands)
				if FileAccess.file_exists("user://starwave-replay.json"):
					verify(FileAccess.get_file_as_string("user://starwave-replay.json")==signature,"Independent cold timeline exactly repeats actual cards, cash, Fans, finance and RNG")
				else:FileAccess.open("user://starwave-replay.json",FileAccess.WRITE).store_string(signature)
		elif mode in ["continued","launch","launched"]:
			var expected_path:="user://starwave-launched.json" if mode=="launched" else "user://starwave-completed.json"
			var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(expected_path))
			verify(adapter.capture(run)==expected,"Cold Continue restores all typed fields, receipt, Fan exposure and future RNG exactly")
			verify(pending_for(run,PublisherCatalog.STARWAVE).is_empty() and run.get_completed_contract_count()==4,"No offer reissue or duplicate completion after restart")
			for field in ["hands","identity","terms","receipt"]:
				var broken:=expected.duplicate(true)
				for pair in broken.run.publisher_offers:
					if pair.value.publisher_id!="starwave":continue
					if field=="hands":pair.value.state.hands="2"
					elif field=="identity":pair.value.state.offer_id="forged"
					elif field=="terms":pair.value.state.trial_terms.cash_cents="224001"
					else:pair.value.state.result.remainder="1"
				verify(adapter.hydrate(broken)==null and FileAccess.get_sha256(initial.path)==digest,"Corrupt "+field+" rejects whole restore without touching good generation")
			if mode=="launch":
				trace.actions=[];trace.errors=[];trace.blockers=[];trace.stop=""
				project_number=3;declared_seed=1104;random_inputs.seed=declared_seed;era_policy="synergy";release_band="early";store_arm="none";neon_policy=false
				var old_awards:=run.get_pending_promotion()
				verify(_begin_game(game,"Starwave restart launch",&"action",trace),"Legal next project departure")
				verify(await _develop_game(game,era_policy,"mixed","qa",1501104,4,trace),"Legal next release after cold Starwave completion")
				verify(game._active_phase is StudioPhase and run.get_pending_promotion()==0 and run.get_release_promotion(game.project_state.get_release_id())==old_awards,"Native next launch consumes existing Promotion once")
				verify(game.checkpoints.flush(),"Next launch publishes durable checkpoint")
				FileAccess.open("user://starwave-launched.json",FileAccess.WRITE).store_string(JSON.stringify(adapter.capture(run)))
			trace.checkpoint=adapter.capture(run)
		trace.after=_state(game)
		trace.finance=run.get_studio_finance_snapshot()
		trace.fanbase=run.get_fanbase_snapshot()
		FileAccess.open(directory.path_join("restart-"+mode+".json"),FileAccess.WRITE).store_string(JSON.stringify(trace))
		game.queue_free()
		await process_frame
	print("STARWAVE RESTART ",mode," failures=",restart_failures)
	quit(0 if restart_failures==0 else 1)
