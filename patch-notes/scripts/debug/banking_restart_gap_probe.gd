## Accounting fixture plus real scene/Bank UI; not a legal balance playthrough.
extends "res://scripts/debug/verify_studio_checkpoint.gd"

func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var coordinator: CheckpointCoordinator = game.checkpoints
	var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
	if not port.is_empty():
		coordinator.store._writer = TCPServer.new()
		if coordinator.store._writer.listen(int(port),"127.0.0.1")!=OK: quit(2); return
	if mode=="setup":
		game._on_studio_created("Bank restart fixture",&"action",[],game._active_phase)
		var run: RunState = game.run_state
		run.finalize_starter_selection()
		var first := PrimitivePredevelopment.prepare_project("Bank accounting fixture",&"action",&"fantasy",run)
		_finish_project(first)
		expect(run.register_release(first),"Frozen release fixture registers")
		for i in range(4): expect(run.complete_productive_action(),"Actual settled sales qualify")
	else:
		var inspected := coordinator.store.inspect()
		expect(inspected.status==&"valid","Separate process validates finalized generation")
		if inspected.status!=&"valid": quit(1); return
		var detached := coordinator.adapter.hydrate(inspected.payload)
		expect(detached!=null,"Detached full restore")
		if detached==null: quit(1); return
		var restored := coordinator.adapter.capture(detached)
		expect(JSON.stringify(restored).sha256_text()==FileAccess.get_file_as_string("user://bank-expected.sha256"),"All persisted fields match prior process exactly")
		game._continue_checkpoint()
		await process_frame
		expect(game._active_phase is StudioPhase,"Continue opens Studio")
		expect(game.run_state.get_studio_finance_snapshot()==detached.get_studio_finance_snapshot(),"Scene Continue preserves exact finance and credit journal")
	var run: RunState = game.run_state
	game.get_node("%GameplayHUD").tutorial_overlay.close()
	if mode=="unsaved":
		# Capture after any predeparture pending Studio acknowledgment is flushed.
		expect(game._begin_next_project(game._active_phase,"Unsaved loan",&"action",&"fantasy"),"Native Studio departure")
		await process_frame
		var saved := coordinator.store.inspect()
		var canonical: Dictionary = saved.payload.duplicate(true)
		canonical.sequence = "1"
		write_expected(canonical)
		var cash := run.get_cash_cents()
		var menu: StudioFinances = game.get_node("%GameplayHUD").studio_finances
		menu.open()
		menu.open_bank()
		menu._preview_quote()
		menu._confirm_accept()
		expect(menu._confirm.visible,"Midphase Bank requires confirmation")
		menu._confirm.hide()
		menu._confirm_transaction()
		expect(run._studio_finance.bank_loans.size()==1 and run.get_cash_cents()==cash+50000,"Confirmed midphase loan funds memory once")
		await process_frame
		var unchanged := coordinator.store.inspect()
		expect(unchanged.path==saved.path and unchanged.payload==saved.payload,"Loan and departure do not publish midphase save")
	elif mode=="rollback":
		expect(run._studio_finance.bank_loans.is_empty(),"Separate-process Continue discards unsaved loan and receipt")
		expect(game.project_state==null and run.get_completed_run_cycles()==4,"Entire unsaved development action rolls back")
		expect(run.accept_bank_loan(run.get_bank_quote(50000,120)),"Fresh restored quote accepts once in new timeline")
	elif mode=="arrears":
		# Keep accepted debt alive until native declining sales fall below rent.
		# Drain cash with a journaled fixture expense, never edit a bill or loan.
		var reached := false
		for i in range(200):
			var plan := run._plan_productive_cycle(0,&"")
			if run.get_completed_run_cycles()%2==1 and int(plan.get("payable",50101))<=50100:
				var reserve: int = 50100-int(plan.payable)
				expect(run.spend_cash_cents(run.get_cash_cents()-reserve),"Journaled liquidity fixture leaves rent plus 100 cents")
				expect(run.complete_productive_action(),"Native settlement creates partial bank bill")
				reached = true
				break
			expect(run.complete_productive_action(),"Native sales decay and scheduled debt")
		expect(reached,"Reach bounded partial-payment case")
		var bill: Dictionary = run._studio_finance.obligations[-1]
		expect(bill.expense_type==&"bank_installment" and bill.interest_paid_cents==100 and bill.principal_paid_cents==0 and bill.late,"Rent priority then partial bank interest")
	elif mode=="partial":
		var before := run.get_studio_finance_snapshot()
		var bill: Dictionary = before.obligations[-1]
		expect(run.add_cash_cents(100),"Native partial recovery receipt")
		var after := run.get_studio_finance_snapshot()
		expect(after.obligations[-1].due_cycle==bill.due_cycle and after.obligations[-1].interest_paid_cents==200,"Partial recovery retains original due and interest-first service")
		expect(after.credit==before.credit and interest_total(after)==interest_total(before),"Receipt does not repeat credit update or interest expense")
	elif mode=="recovered":
		var before := run.get_studio_finance_snapshot()
		expect(before.obligations[-1].interest_paid_cents==200,"Partial payment survives process restart")
		var bill: Dictionary = before.obligations[-1]
		expect(run.add_cash_cents(bill.due_cents-bill.paid_cents),"Recover remaining original bill")
		var after := run.get_studio_finance_snapshot()
		expect(after.obligations[-1].due_cycle==bill.due_cycle and after.obligations[-1].late and after.obligations[-1].paid_cents==bill.due_cents,"Full recovery keeps due and late history")
		expect(after.credit==before.credit,"Recovery cannot farm credit")
	elif mode=="check":
		var bill: Dictionary = run._studio_finance.obligations[-1]
		expect(bill.late and bill.paid_cents==bill.due_cents,"Recovered late bill survives restart")
	if mode!="unsaved":
		await process_frame
		expect(coordinator.flush(),"Studio automatic checkpoint publishes")
		var payload := coordinator.adapter.capture(run)
		expect(not payload.is_empty(),"Complete valid Studio capture: "+coordinator.adapter.error)
		write_expected(payload)
	print("Bank gap process ",mode,": ",failures," failures; cycle ",run.get_completed_run_cycles())
	game.queue_free()
	await process_frame
	quit(0 if failures==0 else 1)

func write_expected(payload: Dictionary) -> void:
	var file := FileAccess.open("user://bank-expected.sha256",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload).sha256_text())
	file.close()

func interest_total(ledger: Dictionary) -> int:
	var total := 0
	for row: Dictionary in ledger.monthly_rows: total += int(row.interest_cents)
	return total

