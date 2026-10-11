extends "res://scripts/debug/verify_publisher_trial_promotion.gd"

func _run() -> void:
	var mode := OS.get_cmdline_user_args()[0]
	var adapter := StudioCheckpoint.new()
	var store := StudioCheckpointStore.new("user://saves/studio",adapter.validate)
	# Optional isolated test lease; production keeps its application-wide port.
	var test_port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
	if not test_port.is_empty():
		store._writer = TCPServer.new()
		if store._writer.listen(int(test_port),"127.0.0.1")!=OK: quit(2); return
	var run: RunState
	if mode=="initial":
		run = trial_run()
	else:
		var saved := store.inspect()
		expect(saved.status==&"valid","Separate process validates save")
		if saved.status!=&"valid": quit(1); return
		run = adapter.hydrate(saved.payload)
		expect(run!=null,"Detached full restore")
		if run==null: quit(1); return
		expect(JSON.stringify(adapter.capture(run)).sha256_text()==FileAccess.get_file_as_string("user://expected.sha256"),"All fields survive process restart")
	if mode.begins_with("rollback"):
		var state := run.accept_publisher_contract(offer_for(run,PublisherCatalog.CROWN_QUILL))
		expect(state!=null,"Accept Crown in unfinished timeline")
		if mode!="rollback_accept":
			var cards: Array[CardData] = []
			for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
			for i in range(2 if mode=="rollback_complete" else 1):
				var plan := state.plan_hand(cards)
				expect(commit_native_hand(run,state,cards,plan.remainder_cents),"Uncheckpointed native hand")
		if not state.is_completed(): expect(adapter.capture(run).is_empty(),"No active Contract checkpoint")
		# No Studio return/dismissal: deliberately do not publish this timeline.
	elif mode=="complete":
		expect(run.get_pending_publisher_offer_ids().size()==2 and run.get_pending_promotion()==0,"Advance, hands and reward rolled back")
		finish_contract(run,PublisherCatalog.CROWN_QUILL)
		finish_contract(run,PublisherCatalog.NEON_CIRCUIT)
		expect(run.get_completed_contract_count()==2,"Distinct trial completions")
	elif mode=="launch":
		expect(run.get_pending_promotion()>0 and run.get_pending_publisher_offer_ids().is_empty(),"Paid results and bank restored once")
		var release := finished(run,"Promotion restart",0)
		expect(run.register_release(release),"Native frozen launch consumes bank")
	elif mode=="check":
		expect(run.get_pending_promotion()==0 and run._promotion_consumed.size()==2 and run.get_completed_contract_count()==2,"Consumed IDs and results survive")
		expect(run.get_pending_publisher_offer_ids().is_empty(),"No reissued first offers")
	if not mode.begins_with("rollback"):
		var payload := adapter.capture(run)
		expect(not payload.is_empty(),"Full capture: "+adapter.error)
		if not payload.is_empty():
			var broken := payload.duplicate(true)
			broken.run.publisher_offers[0].value.publisher_id = "unknown"
			expect(adapter.hydrate(broken)==null,"Corrupt Contract rejects whole restore")
			if payload.run.publisher_offers[0].value.state!=null:
				broken = payload.duplicate(true)
				broken.run.publisher_offers[0].value.state.trial_terms.scope = "10"
				expect(adapter.hydrate(broken)==null,"Changed frozen Crown terms reject")
				broken = payload.duplicate(true)
				broken.run.promotion_awards = []
				expect(adapter.hydrate(broken)==null,"Lost completed award rejects")
				broken = payload.duplicate(true)
				broken.run.promotion_consumed = [{"key":payload.run.publisher_offers[0].key,"value":payload.run.publisher_offers[0].value.source_release_id}]
				expect(adapter.hydrate(broken)==null,"Promotion attached to its earlier source release rejects")
			expect(store.save(payload).status==&"saved","Publish Studio generation")
			var file := FileAccess.open("user://expected.sha256",FileAccess.WRITE)
			file.store_string(JSON.stringify(payload).sha256_text())
			file.close()
	store.release_writer()
	print("Publisher restart ",mode,": ",failures," failures")
	quit(0 if failures==0 else 1)
