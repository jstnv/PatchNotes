## Declared completed-release fixtures; native purchases, earnings and checkpoints.
extends "res://scripts/debug/verify_studio_checkpoint.gd"

func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var coordinator := CheckpointCoordinator.new()
	root.add_child(coordinator)
	coordinator.store._writer = TCPServer.new()
	if coordinator.store._writer.listen(47414,"127.0.0.1")!=OK: quit(2); return
	var run: RunState
	if mode=="initial":
		run = RunState.new()
		run.initialize_cash(0)
		expect(run.create_studio_with_traits("Portfolio restart",&"action",[]),"Create named current-trait Studio")
		expect(run.get_cash_cents()==570000 and run.get_completed_run_cycles()==0,"Current no-trait funding and clock")
		coordinator.attach(run)
		coordinator.entered_studio()
	else:
		run = coordinator.load_current()
		expect(run!=null,"Fresh process Continue restores full Studio")
		if run==null: quit(1); return
		expect(JSON.stringify(coordinator.adapter.capture(run)).sha256_text()==FileAccess.get_file_as_string("user://portfolio-expected.sha256"),"Exact all-field restore including finance, RNG and ordered releases")
		coordinator.entered_studio(true)
	if mode=="starter":
		var found := false
		for id: StringName in run._feature_definitions:
			var offer := run.get_primitive_reserve_offer(id)
			if offer.get("can_purchase",false):
				expect(run.purchase_starter_feature(id),"Native optional starter purchase")
				expect(run.get_completed_run_cycles()==0 and run.owns_feature(id),"Starter ownership with zero time")
				await process_frame
				var prior := coordinator.store.inspect()
				expect(not run.purchase_starter_feature(id),"Duplicate starter rejected")
				await process_frame
				expect(coordinator.store.inspect()==prior,"Rejected starter leaves generation bytes and sequence unchanged")
				found = true
				break
		expect(found,"Eligible starter fixture found")
	elif mode=="portfolio":
		run.finalize_starter_selection()
		for title in ["First accounting fixture","Second accounting fixture"]:
			var project := PrimitivePredevelopment.prepare_project(title,&"action",&"fantasy",run)
			_finish_project(project)
			expect(run.register_release(project),"Completed accounting fixture registered")
			expect(run.complete_productive_action(),"Overlapping portfolio earns native cycle")
		expect(run.complete_productive_action(),"Advance to odd boundary for purchase")
	elif mode in ["store","reserve","campaign"]:
		if run.get_completed_run_cycles()%2==0: expect(run.complete_productive_action(),"Prepare next normal month boundary")
		var before := run.get_completed_run_cycles()
		var committed := false
		if mode=="store": committed = ResearchTestActions.acquire(run,&"colored_text")
		elif mode=="reserve":
			for id: StringName in run._feature_definitions:
				if run.get_primitive_reserve_offer(id).get("can_purchase",false):
					committed = ResearchTestActions.acquire(run,id)
					break
		else:
			for id: StringName in run._released_games:
				if run.get_post_launch_campaign_offer(id).get("can_purchase",false):
					committed = run.purchase_post_launch_campaign(id,before)
					break
		expect(committed,mode+" native action accepted")
		expect(run.get_completed_run_cycles()==before+1,mode+" exactly one boundary cycle")
		expect(run.get_studio_finance_report().available,"Native journal reconciles all cash and bills")
		for sales: Dictionary in run._released_games.values():
			expect(sales.last_processed_run_cycle==before+1 and sales.last_settlement_run_cycle==before+1,"Every title earns and settles this boundary once")
	await process_frame
	expect(coordinator.flush(),"Committed Studio mutation durably publishes")
	var payload := coordinator.adapter.capture(run)
	expect(not payload.is_empty(),"Full valid portfolio DTO: "+coordinator.adapter.error)
	var prior := coordinator.store.inspect()
	for i in range(2):
		run.get_feature_store_offer(&"colored_text")
		run.get_studio_finance_report()
		coordinator.flush()
	expect(coordinator.store.inspect()==prior,"Passive quotes and repeated flush never publish")
	FileAccess.open("user://portfolio-expected.sha256",FileAccess.WRITE).store_string(JSON.stringify(payload).sha256_text())
	print("Portfolio process ",mode,": ",failures," failures")
	coordinator.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)
