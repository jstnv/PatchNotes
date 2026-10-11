## Synthetic accounting/integration fixtures, separate from legal route evidence.
extends "res://scripts/debug/verify_feature_store_cycle_purchase.gd"


func named() -> RunState:
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Finance fixture", &"action"), "Studio creates auditable funding")
	return run


func snapshot(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_studio_finance_snapshot(), run.get_studio_finance_report(), run.get_released_game_ids().map(func(id): return run.get_released_game_sales(id)), run.get_completed_contract_count()]


func reconcile(run: RunState) -> void:
	var report := run.get_studio_finance_report()
	check(report.get("available", false), "Checked finance provenance remains available")
	if not report.get("available", false): return
	var cash := 0
	var earned := 0
	var settled := 0
	for row: Dictionary in report.rows:
		check(row.opening_cash_cents == cash, "Monthly opening follows previous close")
		var revenue: int = row.sales_net_earned_cents + row.other_income_cents
		var costs: int = row.feature_play_cents + row.store_cents + row.campaign_cents + row.playtest_cents + row.other_expense_cents + row.interest_cents
		check(row.net_profit_cents == revenue - costs - row.rent_due_cents - row.payroll_due_cents, "Profit uses accrual rent and earned net, not cash settlement")
		cash += row.financing_in_cents + row.other_income_cents + row.sales_settled_cents - costs + row.interest_cents - row.interest_paid_cents - row.rent_paid_cents - row.principal_paid_cents - row.payroll_paid_cents
		check(row.closing_cash_cents == cash and row.cash_change_cents == cash - row.opening_cash_cents, "Monthly exact-cent cash movement reconciles")
		earned += int(row.sales_net_earned_cents)
		settled += int(row.sales_settled_cents)
	check(cash == run.get_cash_cents(), "Final cash equals all recorded receipts less actual payments")
	var native_earned := 0
	var native_settled := 0
	for id in run.get_released_game_ids():
		var sales := run.get_released_game_sales(id)
		native_earned += int(sales.entitlement_cents)
		native_settled += int(sales.settled_cents)
	check(earned == native_earned and settled == native_settled, "Portfolio earned/settled matches all authoritative titles without a second 70% share")
	var detached := run.get_studio_finance_snapshot()
	detached.cash_cents += 1
	check(not StudioFinanceLedger.report(detached, run.get_completed_run_cycles(), run.get_cash_cents()).available, "Tampered reconstruction returns unavailable")


func _run() -> void:
	snapshots.load_ledgers()
	var run := named()
	check(run.get_cash_cents() == 550000 and run.get_studio_finance_report().unpaid_rent_cents == 0, "Creation charges no rent")
	for cycle in range(1, 5):
		check(run.complete_productive_action(Callable(), 0, cycle - 1), "Productive action commits once")
		check(run.get_cash_cents() == 550000 - (cycle / 2) * 50000, "Cycles 1/2/3/4 charge only completed months")
		var before := snapshot(run)
		check(not run.complete_productive_action(Callable(), 0, cycle - 1) and snapshot(run) == before, "Repeated expected-cycle callback cannot charge twice")
		reconcile(run)
	var state := snapshot(run)
	check(not run.complete_productive_action(func(): return false, -1) and snapshot(run) == state, "Failed callback preserves money, obligations, sales and redraws")
	var observer := func(): check(not run.complete_productive_action(), "Publication callback cannot reenter action")
	run.finance_changed.connect(observer)
	check(run.complete_productive_action(), "Finance notifications follow whole transaction")
	run.finance_changed.disconnect(observer)
	var fixture := named()
	check(fixture.spend_cash_cents(115000, &"feature_play"), "Explicit arithmetic fixture records $1,150 Feature costs")
	for i in range(14): check(fixture.complete_productive_action(), "Arithmetic fixture cycle")
	check(fixture.get_cash_cents() == 85000, "14-cycle / $1,150 cost fixture leaves exactly $850 (not a played route)")
	reconcile(fixture)
	var poor := named()
	check(poor.spend_cash_cents(537655) and poor.complete_productive_action() and poor.complete_productive_action(), "Boundary accepts action and services partial rent")
	check(poor.get_cash_cents() == 0 and poor.get_studio_finance_report().unpaid_rent_cents == 37655, "$123.45 pays rent; $376.55 remains due")
	state = snapshot(poor)
	check(not poor.complete_productive_action() and not poor.complete_productive_action(Callable(), 37654) and snapshot(poor) == state, "Ordinary production and insufficient income reject without free time or duplicate debt")
	check(poor.add_cash_cents(10000, &"publisher_receipt") and poor.get_cash_cents() == 0 and poor.get_studio_finance_report().unpaid_rent_cents == 27655, "External income services old rent even when spendable cash remains zero")
	check(poor.complete_productive_action(Callable(), 27655, 2, &"", &"beta_income"), "Legal productive income can clear old rent in the next half")
	check(poor.get_financial_block_reason().is_empty() and poor.get_completed_run_cycles() == 3, "Recovery removes block without forgivable debt")
	reconcile(poor)
	for alignment in [0, 1]:
		var sales_run := named()
		if alignment == 1: check(sales_run.complete_productive_action(), "Second-half release alignment")
		var a := _released_project(751)
		var b := _released_project(113)
		check(sales_run.register_release(a) and sales_run.register_release(b), "Concurrent frozen release fixtures register")
		var frozen := sales_run.get_release_metadata(a.get_release_id())
		for cycle in range(6):
			check(sales_run.complete_productive_action(), "Concurrent earning boundary commits")
			reconcile(sales_run)
		check(frozen == sales_run.get_release_metadata(a.get_release_id()), "Rent never mutates frozen release inputs")
		var before_cash := sales_run.get_cash_cents()
		var before_sales: int = sales_run.get_released_game_sales(a.get_release_id()).settled_cents + sales_run.get_released_game_sales(b.get_release_id()).settled_cents
		var before_cycle := sales_run.get_completed_run_cycles()
		check(sales_run.purchase_post_launch_campaign(a.get_release_id(), before_cycle), "Eligible campaign uses one central cycle")
		var after_sales: int = sales_run.get_released_game_sales(a.get_release_id()).settled_cents + sales_run.get_released_game_sales(b.get_release_id()).settled_cents
		check(sales_run.get_cash_cents() == before_cash - 10000 + after_sales - before_sales - (50000 if before_cycle % 2 == 1 else 0), "Campaign fee, baseline portfolio settlement and boundary rent are separate")
		state = snapshot(sales_run)
		check(not sales_run.purchase_post_launch_campaign(a.get_release_id(), before_cycle) and snapshot(sales_run) == state, "Repeated campaign callback preserves complete finance state")
		reconcile(sales_run)
	var contract_run := named()
	check(contract_run.register_release(_released_project(751)), "Contract fixture releases at cycle zero")
	var contract := contract_run.accept_primitive_contract()
	check(contract != null and contract_run.get_cash_cents() == 590000 and contract_run.get_completed_run_cycles() == 0, "Ironclad guarantee is identified publisher income without time/rent")
	state = snapshot(contract_run)
	check(contract_run.accept_primitive_contract() == null and snapshot(contract_run) == state, "Contract guarantee is paid once")
	var database := root.get_node("CardDatabase")
	var pass_card: CardData = database.get_card(&"graphics_pass")
	var cards: Array[CardData] = [pass_card, pass_card, pass_card, pass_card]
	for hand in range(2):
		var plan := contract.plan_hand(cards)
		var remainder := int(plan.remainder_cents)
		var commit := func(): return contract_run.commit_contract_hand(contract, cards, remainder)
		check(contract_run.complete_productive_action(commit, remainder, hand, &"", &"publisher_receipt" if remainder > 0 else &"contract_hand", contract.get_offer_id()), "Contract hand uses one productive boundary")
		reconcile(contract_run)
	check(contract.is_completed() and contract_run.get_completed_run_cycles() == 2 and contract_run.get_completed_contract_count() == 1, "Two hands, one month rent and one authoritative completion")
	state = snapshot(contract_run)
	check(not contract_run.complete_productive_action(func(): return contract_run.commit_contract_hand(contract, cards, 0)) and snapshot(contract_run) == state, "Repeated completion callback cannot change ledger or payout")
	var legacy := RunState.new()
	legacy.initialize_cash(10)
	check(not legacy.get_studio_finance_report().available, "Legacy unknown expenses are unavailable, not fabricated")
	print("Studio finance integration: %d failures" % failures)
	quit(failures)
