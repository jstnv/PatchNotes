extends "res://scripts/debug/verify_studio_checkpoint.gd"

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if not args.is_empty() else "initial"
	var adapter := StudioCheckpoint.new()
	var store := StudioCheckpointStore.new("user://saves/studio",adapter.validate)
	# Optional isolated test lease; production keeps its application-wide port.
	var test_port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
	if not test_port.is_empty():
		store._writer = TCPServer.new()
		if store._writer.listen(int(test_port),"127.0.0.1")!=OK: quit(2); return
	var run: RunState
	if mode=="initial":
		run = RunState.new()
		run.initialize_cash(0)
		run.create_studio_with_traits("Restart Studio",&"action",[])
	else:
		var inspected := store.inspect()
		expect(inspected.status==&"valid","Separate process validates finalized generation")
		if inspected.status!=&"valid": quit(1); return
		run = adapter.hydrate(inspected.payload)
		expect(run!=null,"Detached restore")
		if run==null: quit(1); return
		var restored := adapter.capture(run)
		expect(JSON.stringify(restored).sha256_text()==FileAccess.get_file_as_string("user://expected-checkpoint.sha256"),"Every persisted field matches prior process")
	match mode:
		"loan":
			run.finalize_starter_selection()
			var first := PrimitivePredevelopment.prepare_project("Banking fixture",&"action",&"fantasy",run)
			_finish_project(first)
			expect(run.register_release(first),"Frozen sales fixture registers")
			for i in range(4): expect(run.complete_productive_action(),"Native sales settlement")
			expect(run.accept_bank_loan(run.get_bank_quote(50000,12)),"Native accepted Bank loan")
			expect(run.hire_production_specialist(run.get_production_hire_quote()),"Native payroll hire")
		"installment":
			for i in range(3): expect(run.complete_productive_action(),"Native dated installment and payroll")
			expect(run._studio_finance.bank_loans[0].issued==1,"One scheduled installment issued")
		"payoff":
			var loan: Dictionary = run._studio_finance.bank_loans[0]
			expect(run.pay_off_bank_loan(run.get_bank_payoff_quote(loan.loan_id)),"Native early payoff")
			expect(run._studio_finance.bank_loans[0].closed,"Closed loan retained")
		"unsaved_contract":
			var state := run.accept_primitive_contract()
			expect(state!=null,"Unsaved acceptance has advance in memory")
			expect(adapter.capture(run).is_empty(),"Active Contract cannot replace Studio save")
			store.release_writer()
			print("Process ",mode,": ",failures," failures")
			quit(0 if failures==0 else 1)
			return
		"contract":
			expect(run.get_primitive_contract()==null,"Unsaved acceptance rolled back")
			var state := run.accept_primitive_contract()
			var cards: Array[CardData] = []
			for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
			for i in range(2):
				var plan := state.plan_hand(cards)
				expect(commit_native_hand(run,state,cards,plan.remainder_cents),"Native Contract completion")
		"check":
			expect(run._studio_finance.bank_loans[0].closed and run.get_primitive_contract().is_payout_committed(),"Closed loan and paid Contract survive restart")
			expect(run.accept_primitive_contract()==null,"Completed offer cannot pay again")
	var payload := adapter.capture(run)
	expect(not payload.is_empty(),"Capture complete Studio: "+adapter.error)
	if not payload.is_empty():
		expect(store.save(payload).status==&"saved","Publish complete Studio generation")
		var file := FileAccess.open("user://expected-checkpoint.sha256",FileAccess.WRITE)
		file.store_string(JSON.stringify(payload).sha256_text())
		file.close()
	store.release_writer()
	print("Process ",mode,": ",failures," failures")
	quit(0 if failures==0 else 1)
