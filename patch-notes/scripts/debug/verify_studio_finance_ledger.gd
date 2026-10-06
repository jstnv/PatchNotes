extends SceneTree

## Synthetic pure-accounting fixtures, not played routes or approved loans.
## godot --headless --path . --script res://scripts/debug/verify_studio_finance_ledger.gd
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
var failures := 0
var checks := 0


func _initialize() -> void:
	_verify_months_and_settlement()
	_verify_arrears_and_recovery()
	_verify_accounting_categories()
	_verify_reconstruction()
	_verify_overflow()
	print("Studio finance ledger verification: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func step(ledger: Dictionary, cycle: int, delta: int, kind: StringName,
		earned: int = 0, settled: int = 0, productive: bool = false) -> Dictionary:
	var before := ledger.duplicate(true)
	var result := F.plan(ledger, cycle, ledger.cash_cents, delta, kind, earned, settled, productive, &"synthetic-fixture")
	check(not result.is_empty(), "Synthetic planned action accepted: %s at cycle %d" % [kind, cycle])
	check(ledger == before, "Planning preserves input ledger: %s at cycle %d" % [kind, cycle])
	return result.get("ledger", ledger)


func _verify_months_and_settlement() -> void:
	var ledger := F.create(550000)
	var initial := ledger.duplicate(true)
	var result := F.report(ledger, 0, 550000)
	var row: Dictionary = result.rows[0]
	check(row.opening_cash_cents == 0 and row.financing_in_cents == 550000 and row.closing_cash_cents == 550000, "Initial funding has a reconcilable cash receipt")
	check(row.operating_revenue_cents == 0 and row.net_profit_cents == 0, "Initial funding is excluded from operating revenue and profit")
	check(result.rows.size() == 1 and row.partial and result.next_due_cycle == 2 and result.credit_inputs.completed_months == 0, "Initial current-month report shows no fabricated completed month")
	ledger = step(ledger, 1, -10000, &"feature_play", 12345, 0, true)
	check(ledger.cash_cents == 540000 and F.get_unpaid(ledger) == 0, "First half charges Feature cost without rent or early settlement")
	ledger = step(ledger, 2, 0, &"calendar", 12346, 24691, true)
	check(ledger.cash_cents == 514691 and F.get_unpaid(ledger) == 0, "Second half settles exactly 24691 cents before paying 50000 rent")
	result = F.report(ledger, 2, 514691)
	row = result.rows[0]
	check(result.rows.size() == 2 and not row.partial and result.rows[1].partial and result.rows[1].opening_cash_cents == 514691, "Completed month and newly entered partial month remain distinct")
	check(row.sales_net_earned_cents == 24691 and row.sales_settled_cents == 24691 and row.rent_due_cents == 50000 and row.rent_paid_cents == 50000 and row.rent_unpaid_cents == 0, "Exact sales earned, sales paid, rent due and rent paid are separate fields")
	check(row.net_profit_cents == -35309 and row.cash_change_cents == 514691, "Accrual profit excludes funding and matches sales minus play cost minus rent due")
	check(result.credit_inputs == {"completed_months": 1, "paid_on_time_months": 1, "late_months": 0}, "Credit input facts count actual completed paid-on-time rent months")
	var kinds: Array = ledger.transactions.map(func(transaction: Dictionary): return transaction.kind)
	check(kinds == [&"starting_funding", &"feature_play", &"sales_earned", &"calendar", &"sales_earned", &"sales_settlement", &"rent_due", &"rent_payment"], "Trace preserves direct action, noncash earning, cash settlement, rent due, then rent payment ordering")
	check(ledger.transactions[-1].month == 1 and ledger.transactions[-1].cycle == 2, "Boundary rent belongs to the month just completed")
	check(F.plan(ledger, 2, 514691, 0, &"calendar", 0, 0, true).is_empty(), "Repeated productive cycle rejects without recharging rent")
	check(F.plan(ledger, 4, 514691, 0, &"calendar", 0, 0, true).is_empty(), "Skipped productive cycle cannot fabricate intervening months")
	check(F.plan(ledger, 3, 514690, 0, &"calendar", 0, 0, true).is_empty(), "Mismatched live cash rejects before journal mutation")
	check(F.plan(ledger, 3, 514691, 0, &"calendar", 0, 1, true).is_empty(), "Cash settlement cannot exceed net earned entitlement")
	check(F.report(ledger, 2, 514691).rows[1].sales_settled_cents == 0 and initial.cash_cents == 550000, "Forecasts and future earnings are never fabricated into current report rows")
	ledger = step(ledger, 3, 0, &"contract_hand", 1001, 0, true)
	ledger = step(ledger, 4, 25000, &"publisher_receipt", 1002, 2003, true)
	result = F.report(ledger, 4, 491694)
	check(result.available and result.rows[1].other_income_cents == 25000 and result.rows[1].net_profit_cents == -22997, "Contract cash receipt is operating income, distinct from sales and rent")
	check(result.rows[1].publisher_income_cents == 25000 and result.rows[1].beta_income_cents == 0 and result.rows[1].miscellaneous_income_cents == 0, "Publisher receipts have a separate report category")
	check(result.credit_inputs.completed_months == 2 and result.credit_inputs.paid_on_time_months == 2 and result.next_due_cycle == 6, "Second month bills exactly once on the same calendar")


func _verify_arrears_and_recovery() -> void:
	var ledger := step(F.create(10000), 1, 0, &"development", 0, 0, true)
	ledger = step(ledger, 2, 0, &"development", 0, 0, true)
	var blocked := ledger.duplicate(true)
	var result := F.report(ledger, 2, 0)
	check(result.financially_blocked and F.get_unpaid(ledger) == 40000 and result.rows[0].rent_paid_cents == 10000, "Insufficient rent pays available cash and records exact unpaid balance")
	check(result.credit_inputs.late_months == 1 and result.credit_inputs.paid_on_time_months == 0, "Partially paid due month is late immediately")
	check(F.plan(ledger, 3, 0, 0, &"development", 0, 0, true).is_empty(), "Unresolved arrears block ordinary productive actions")
	check(F.plan(ledger, 3, 0, 39999, &"beta_income", 0, 0, true).is_empty(), "One-cent-short productive recovery rejects entirely")
	var recovery := F.plan(ledger, 3, 0, 40000, &"beta_income", 0, 0, true)
	check(not recovery.is_empty() and recovery.cash_cents == 0 and F.get_unpaid(recovery.ledger) == 0, "An exact legal productive receipt can resolve the obligation")
	check(F.report(recovery.ledger, 3, 0).rows[1].beta_income_cents == 40000 and F.report(recovery.ledger, 3, 0).rows[1].publisher_income_cents == 0, "Beta recovery income remains distinct from Publisher receipts")
	check(F.plan(ledger, 2, 0, -1, &"store").is_empty(), "External expense cannot spend from a blocked zero-cash account")
	ledger = step(ledger, 2, 10000, &"publisher_receipt")
	result = F.report(ledger, 2, 0)
	check(F.get_unpaid(ledger) == 30000 and result.rows[0].rent_unpaid_cents == 30000 and result.rows[1].rent_paid_cents == 10000, "Later partial receipt updates old unpaid rent while payment belongs to the current month")
	check(result.rows[0].net_profit_cents == -50000 and result.rows[1].net_profit_cents == 10000, "Later payment does not expense already accrued rent twice")
	check(ledger.last_cycle == 2 and ledger.obligations[0].payments == [{"cycle": 2, "month": 1, "cents": 10000}, {"cycle": 2, "month": 2, "cents": 10000}], "Passive recovery spends no time and records boundary-month versus current-month payments")
	ledger = step(ledger, 2, 50000, &"publisher_receipt")
	result = F.report(ledger, 2, 20000)
	check(result.available and not result.financially_blocked and F.get_unpaid(ledger) == 0 and result.rows[0].rent_unpaid_cents == 0, "Receipt fully resolves debt and leaves its exact remainder as cash")
	check(result.credit_inputs.late_months == 1 and result.credit_inputs.paid_on_time_months == 0 and not ledger.obligations[0].paid_on_time, "A late obligation never becomes on-time after recovery")
	check(F.get_unpaid(blocked) == 40000 and blocked.cash_cents == 0, "Alternative recovery plans preserve the original blocked fixture")
	ledger = step(ledger, 3, 0, &"development", 0, 0, true)
	ledger = step(ledger, 4, 0, &"development", 0, 0, true)
	result = F.report(ledger, 4, 0)
	check(F.get_unpaid(ledger) == 30000 and result.rows[1].rent_unpaid_cents == 30000 and result.rows[0].rent_unpaid_cents == 0, "A later month's new rent remains a separate obligation")
	check(result.credit_inputs.completed_months == 2 and result.credit_inputs.late_months == 2, "Repeated shortfalls produce factual late-month inputs without an invented score")
	var before := ledger.duplicate(true)
	F.report(ledger, 4, 0)
	F.get_unpaid(ledger)
	check(ledger == before, "Passive report and arrears queries cannot charge rent or move cash")


func _verify_accounting_categories() -> void:
	var ledger := F.create(10000)
	ledger = step(ledger, 0, 4000, &"other_income")
	ledger = step(ledger, 0, -1000, &"principal_paid")
	ledger = step(ledger, 0, -500, &"interest")
	ledger = step(ledger, 0, -500, &"store")
	ledger = step(ledger, 0, -100, &"campaign")
	ledger = step(ledger, 0, -200, &"playtest")
	ledger = step(ledger, 0, -300, &"other_expense")
	ledger = step(ledger, 0, 2000, &"financing_in")
	var result := F.report(ledger, 0, 13400)
	var row: Dictionary = result.rows[0]
	check(result.available and row.financing_in_cents == 12000 and row.principal_paid_cents == 1000, "Synthetic financing and principal repayment change cash only; no lending system is implemented")
	check(row.other_income_cents == 4000 and row.operating_expenses_cents == 1600 and row.net_profit_cents == 2400, "Interest and each cash operating cost affect profit while principal does not")
	check(row.miscellaneous_income_cents == 4000 and row.beta_income_cents == 0 and row.publisher_income_cents == 0, "Miscellaneous receipts remain distinct and financing is not operating income")
	check(row.interest_cents == 500 and row.store_cents == 500 and row.campaign_cents == 100 and row.playtest_cents == 200 and row.other_expense_cents == 300, "Expenses retain exact category attribution")
	check(F.plan(ledger, 0, 13400, 1, &"unknown").is_empty() and F.plan(ledger, 0, 13400, 1, &"store").is_empty() and F.plan(ledger, 0, 13400, -1, &"other_income").is_empty(), "Unknown or wrong-signed cash kinds reject rather than misclassifying receipts")
	check(F.plan(ledger, 0, 13400, 0, &"calendar", 1, 0).is_empty() and F.plan(ledger, 0, 13400, 0, &"calendar", 0, 1).is_empty(), "Passive cash actions cannot earn or settle sales")
	ledger = step(F.create(100), 1, 0, &"calendar", 200, 0, true)
	check(F.plan(ledger, 2, 100, -101, &"store", 0, 200, true).is_empty(), "Later settlement cannot fund an initially unaffordable direct purchase")
	ledger = step(F.create(0), 1, 0, &"calendar", 50000, 0, true)
	ledger = step(ledger, 2, 0, &"calendar", 0, 50000, true)
	check(ledger.cash_cents == 0 and F.get_unpaid(ledger) == 0 and F.report(ledger, 2, 0).credit_inputs.paid_on_time_months == 1, "Previously earned revenue settling at the due boundary can exactly cover rent")


func _verify_reconstruction() -> void:
	var ledger := step(F.create(550000), 1, -10000, &"feature_play", 17, 0, true)
	var copy := ledger.duplicate(true)
	check(F.report(copy, 1, 540000).available and F.get_unpaid(copy) == 0, "Defensive reconstruction preserves valid provenance")
	var result := F.report(ledger, 1, 540000)
	result.rows[0].sales_net_earned_cents = 999
	result.credit_inputs.late_months = 999
	check(F.report(ledger, 1, 540000).rows[0].sales_net_earned_cents == 17 and F.report(ledger, 1, 540000).credit_inputs.late_months == 0, "Mutating returned report rows or facts cannot mutate authoritative history")
	check(not F.report({}, 0, 0).available and F.get_unpaid({}) == -1 and F.create(-1).is_empty(), "Missing provenance and negative starting cash remain unavailable")
	for key: String in ["schema_version", "initial_cash_cents", "last_cycle", "cash_cents", "unsettled_sales_net_cents"]:
		for malformed in [null, "0", 0.0, true, [], {}, -1]:
			copy = ledger.duplicate(true)
			copy[key] = malformed
			check(not F.report(copy, 1, 540000).available, "Malformed primitive field safely unavailable: " + key + " / " + str(malformed))
	for key: String in ["monthly_rows", "obligations", "transactions", "actions"]:
		copy = ledger.duplicate(true)
		copy[key] = "missing"
		check(not F.report(copy, 1, 540000).available, "Malformed collection safely unavailable: " + key)
	for key: String in ["cycle", "cash_before", "direct_delta", "sales_earned", "settled", "productive", "kind", "source_id"]:
		copy = ledger.duplicate(true)
		copy.actions[0][key] = null
		check(not F.report(copy, 1, 540000).available, "Malformed action safely unavailable: " + key)
	copy = ledger.duplicate(true); copy.monthly_rows[0].net_profit_cents = 0
	check(not F.report(copy, 1, 540000).available, "Tampered derived profit cannot reconstruct")
	copy = ledger.duplicate(true); copy.transactions.pop_back()
	check(not F.report(copy, 1, 540000).available, "Missing transaction cannot reconstruct")
	copy = ledger.duplicate(true); copy.transactions[0].sequence = 2
	check(not F.report(copy, 1, 540000).available, "Altered transaction sequence cannot reconstruct")
	copy = ledger.duplicate(true); copy.actions[0] = 17
	check(not F.report(copy, 1, 540000).available, "Non-dictionary journal action safely unavailable")
	copy = ledger.duplicate(true); copy.obligations.append({"unpaid_cents": -1})
	check(not F.report(copy, 1, 540000).available, "Invented malformed obligation safely unavailable")
	check(not F.report(ledger, 2, 540000).available and not F.report(ledger, 1, 540001).available, "Wrong live calendar or cash cannot present a falsely reconciled report")


func _verify_overflow() -> void:
	var ledger := F.create(F.MAX_INT)
	check(F.report(ledger, 0, F.MAX_INT).available, "Exact maximum starting cash is representable")
	check(F.plan(ledger, 1, F.MAX_INT, 1, &"beta_income", 0, 0, true).is_empty(), "Direct income overflow rejects before rent")
	check(F.plan(ledger, 1, F.MAX_INT, -9223372036854775807 - 1, &"store", 0, 0, true).is_empty(), "Minimum signed delta rejects without unsafe negation")
	ledger = step(ledger, 1, -1, &"store", 0, 0, true)
	check(F.plan(ledger, 2, F.MAX_INT - 1, 1, &"other_income", 0, 0, true).is_empty(), "Monthly aggregate receipt overflow rejects despite representable cash")
	ledger = step(F.create(F.MAX_INT - 5), 1, 0, &"calendar", 10, 0, true)
	check(F.plan(ledger, 2, F.MAX_INT - 5, 0, &"calendar", 0, 10, true).is_empty(), "Intermediate settlement overflow rejects even when subsequent rent would lower cash")
	ledger = step(F.create(0), 1, 0, &"calendar", F.MAX_INT, 0, true)
	check(F.plan(ledger, 2, 0, 0, &"calendar", 1, 0, true).is_empty(), "Unsettled net entitlement aggregate overflow rejects")
	ledger = step(F.create(F.MAX_INT), 1, 0, &"calendar", 0, 0, true)
	ledger = step(ledger, 2, 0, &"calendar", 0, 0, true)
	ledger = step(ledger, 3, 0, &"calendar", F.MAX_INT, 0, true)
	check(F.plan(ledger, 3, F.MAX_INT - 50000, 1, &"other_income").is_empty(), "Operating revenue aggregate overflow rejects with sufficient cash capacity")
	ledger = step(F.create(F.MAX_INT), 1, 0, &"calendar", 0, 0, true)
	ledger = step(ledger, 2, 0, &"calendar", 0, 0, true)
	ledger = step(ledger, 2, -(F.MAX_INT - 50000), &"other_expense")
	ledger = step(ledger, 2, F.MAX_INT, &"financing_in")
	check(F.plan(ledger, 2, F.MAX_INT, -50001, &"interest").is_empty(), "Operating expense aggregate overflow rejects with sufficient cash to pay")
	check(F.plan(ledger, 2, F.MAX_INT, 0, &"calendar", -1, 0).is_empty() and F.plan(ledger, 2, F.MAX_INT, 0, &"calendar", 0, -1).is_empty(), "Negative sales amounts reject without mutation")
