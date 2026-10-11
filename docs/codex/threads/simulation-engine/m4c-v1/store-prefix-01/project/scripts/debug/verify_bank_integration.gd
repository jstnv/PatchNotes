## Frozen release accounting fixtures; not a played balance route.
extends "res://scripts/debug/verify_studio_finance_integration.gd"

func _run() -> void:
	snapshots.load_ledgers()
	check(BankLoan.parse_dollars("500.01") == 50001 and BankLoan.parse_dollars("500.1") == 50010,"Exact decimal inputs")
	for invalid in ["", "500.001", "5e2", "-500", "+500", "NaN", "500.", "500..0", "92233720368547758.08"]:
		check(BankLoan.parse_dollars(invalid) == -1,"Reject invalid exact dollars: "+invalid)
	check(BankLoan.parse_dollars("92233720368547758.07") == RunState.MAX_SIGNED_INT,"Exact input boundary")
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var run := named()
		check(run.register_release(_released_project(751)),"Frozen fixture release")
		for i in range(4): check(run.complete_productive_action(),"Native settled-sales earning")
		var quote := run.get_bank_quote(50000,12)
		check(quote.get("accepted",false),"Two actual native sales settlements qualify")
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = run
		root.add_child(game)
		await create_timer(0.3).timeout
		var hud: GameplayHUD = game.get_node("%GameplayHUD")
		var menu: StudioFinances = hud.studio_finances
		menu.open()
		menu.open_bank()
		await create_timer(0.3).timeout
		check(menu.amount_input.size.y < 60 and menu.quote_details.size.y >= 130 and menu.bank_history.size.y >= 60,"Readable Bank input and report heights")
		var before := snapshot(run)
		menu._preview_quote()
		check(snapshot(run) == before and not menu.accept_button.disabled,"UI preview is passive")
		for control in [menu.amount_input,menu.term_input,menu.accept_button,menu.payoff_button,menu.quote_details,menu.bank_history]:
			check(menu.dialog.get_global_rect().encloses(control.get_global_rect()),"Bank control fits %s" % resolution)
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/codex/findings/banking-implementation-v1/bank-%d.png" % resolution.x))
		menu._confirm_accept()
		check(snapshot(run) == before and menu._confirm.visible,"Acceptance waits for explicit confirmation")
		menu._confirm.hide()
		var observer := func(): check(not run.accept_bank_loan(quote),"Bank signal reentry rejects")
		run.finance_changed.connect(observer)
		menu._confirm_transaction()
		run.finance_changed.disconnect(observer)
		check(run.get_cash_cents() == before[0]+50000 and run.get_completed_run_cycles() == before[1],"Confirmed UI funds native run without time")
		check(not run.accept_bank_loan(quote),"Native duplicate loan rejects")
		reconcile(run)
		for i in range(3):
			check(run.complete_productive_action(),"Native loan bill and sales settlement")
			reconcile(run)
		var loan: Dictionary = run.get_studio_finance_snapshot().bank_loans[0]
		check(loan.issued == 1 and loan.principal_paid_cents == 4167 and loan.interest_paid_cents == 500,"Scheduled native payment remains signed despite later sales")
		menu.open_bank()
		check(not menu.payoff_button.disabled and menu.quote_details.text.contains("Payoff now"),"Active loan and exact payoff visible")
		menu._confirm_payoff()
		menu._confirm.hide()
		menu._confirm_transaction()
		check(run.get_studio_finance_snapshot().bank_loans[0].closed,"UI payoff closes native loan")
		reconcile(run)
		check(menu.expense_details.text.contains("Principal") and menu.expense_details.text.contains("Cycle 6"),"Paid bank bill payment history retained")
		menu.close()
		game.queue_free()
		await process_frame
	var run := named()
	check(run.register_release(_released_project(751)),"Midphase fixture release")
	for i in range(4): check(run.complete_productive_action(),"Midphase sales history")
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	game.project_state = ProjectState.new(30)
	root.add_child(game)
	await process_frame
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	for title in ["Design","Alpha","Beta"]:
		var phase: Control = game.get("_active_phase")
		var project: ProjectState = game.project_state
		check(phase.get_workspace().overlay.commit_draft(),title+" initializes phase")
		await create_timer(0.4).timeout
		var before := [project.get_current_cycle(),project.get_current_scope(),project.get_known_bugs(),run.get_available_redraws(),run.get_completed_run_cycles()]
		check(hud.show_finances(),title+" Cash opens finance overlay")
		var menu: StudioFinances = hud.studio_finances
		menu.open_bank()
		menu._preview_quote()
		menu._confirm_accept()
		menu._confirm.hide()
		menu._confirm_transaction()
		check(not menu._payoff.is_empty(),title+" loan accepted midphase")
		menu._confirm_payoff()
		menu._confirm.hide()
		menu._confirm_transaction()
		check([project.get_current_cycle(),project.get_current_scope(),project.get_known_bugs(),run.get_available_redraws(),run.get_completed_run_cycles()] == before,title+" banking preserves project and clock")
		menu.close()
		if title == "Design":
			phase.get("_exhausted_card_ids")[&"text"] = true
			phase.get_node("%ProceedToAlphaButton").pressed.emit()
		elif title == "Alpha":
			project.add_scope(30)
			check(phase.call("_finalize_alpha",0.0,0.5),"Fixture advances to Beta")
		await process_frame
	game.queue_free()
	await process_frame
	print("Bank integration: %d failures" % failures)
	quit(failures)
