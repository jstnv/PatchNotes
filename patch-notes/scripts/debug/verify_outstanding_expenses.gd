extends SceneTree

## Future bill types and time-jumped age cases below are synthetic policy fixtures.
## Native rent routes are recorded separately; these never enable a Wait action.
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
const B := preload("res://scripts/finance/outstanding_expenses.gd")
var checks := 0
var failures := 0
var traces: Array = []


func _initialize() -> void:
	_creation_and_months()
	_typed_ages_and_recovery()
	_provenance_and_overflow()
	var file := FileAccess.open("res://design-logs/task33-v1/credit-fixtures.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(traces, "\t"))
	print("Outstanding expenses: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func step(l: Dictionary, cycle: int, delta := 0, kind: StringName = &"calendar", productive := true, earned := 0, settled := 0) -> Dictionary:
	var before := l.duplicate(true)
	var p := F.plan(l, cycle, l.cash_cents, delta, kind, earned, settled, productive)
	check(not p.is_empty() and l == before, "Atomic immutable finance plan at cycle %d" % cycle)
	return p.get("ledger", l)


func _creation_and_months() -> void:
	var l := F.create(550000)
	check(l.credit == B.create_credit() and l.credit.score == 600 and l.credit.history.is_empty(), "Creation has score 600 and neutral history")
	for profit in [-1, 0, 1]:
		var branch := step(l, 1, 0, &"calendar", true, 50000 + profit)
		branch = step(branch, 2, 0, &"calendar", true, 0, 50000 + profit)
		check(branch.credit.score == (603 if profit > 0 else 600), "Clean profit/loss/break-even month %d" % profit)
		check(branch.credit.last_processed_month == 1 and branch.credit.history.size() == 1, "Monthly credit processes exactly once")
		check(F.plan(branch, 2, branch.cash_cents, 0, &"calendar", 0, 0, true).is_empty(), "Duplicate boundary rejects")
		traces.append(branch)
	l = step(F.create(10000), 1)
	l = step(l, 2)
	check(l.credit.score == 595 and l.obligations[0].bill_id == &"rent:1", "Newly missed due penalizes at zero age with stable original rent ID")
	check(F.outstanding(l, 2).bills[0].overdue_cycles == 0 and F.outstanding(l, 2).bills[0].unpaid_cents == 40000, "Read-only outstanding query shows exact remaining cents and zero-cycle miss")
	var before := l.duplicate(true)
	check(F.plan(l, 3, 0, 0, &"calendar", 0, 0, true).is_empty() and l == before, "Arrears block preserved; age cannot advance with a free Wait")
	check(F.plan(l, 2, 0, -100, &"campaign").is_empty() and F.plan(l, 2, 0, -1, &"store").is_empty() and l == before, "Unaffordable optional actions create no bill or credit loss")
	l = step(l, 2, 12345, &"publisher_receipt", false)
	check(l.obligations[0].due_cycle == 2 and l.obligations[0].unpaid_cents == 27655 and l.credit == before.credit, "Exact partial payment does not reset original date or immediately change credit")
	l = step(l, 3, 27655, &"beta_income")
	check(l.obligations[0].late and l.obligations[0].settled_cycle == 3 and l.obligations[0].recovery_overdue_cycles == 1, "Half-month legal recovery preserves closed late age")
	l = step(l, 4, 70000, &"beta_income")
	check(l.credit.score == 590 and l.credit.history[-1].reasons[0].overdue_cycles == 1, "Half-month recovery retains closing-period debit despite profitable recovered month")
	l = step(l, 5, 50001, &"beta_income")
	l = step(l, 6)
	check(l.credit.score == 593, "Following clean profitable month resumes gain with no past-bill debit")
	traces.append(l)
	# A zero-cycle recovery at the already-processed opening boundary adds no second miss.
	l = step(before, 2, 90001, &"publisher_receipt", false)
	l = step(l, 3)
	l = step(l, 4)
	check(l.credit.score == 598, "Same opening-boundary recovery retains first debit without inventing a second elapsed period")
	# Settling earned sales at original due is still fully on time.
	l = step(F.create(0), 1, 0, &"calendar", true, 50001)
	l = step(l, 2, 0, &"calendar", true, 0, 50001)
	check(l.cash_cents == 1 and l.credit.score == 603 and not l.obligations[0].late, "Sales settle before rent and credit at the due boundary")
	# Financing cannot fabricate profitable months; principal is not operating cost.
	l = step(F.create(100000), 1, 100000, &"financing_in")
	l = step(l, 2, -100000, &"principal_paid")
	check(l.credit.score == 600 and l.monthly_rows[0].net_profit_cents == -50000, "Borrow/repay fixture earns no profit or credit")


func _typed_ages_and_recovery() -> void:
	var bills: Array = []
	for type: StringName in B.PENALTIES:
		var bill := B.create_bill(StringName(str(type) + ":1"), &"synthetic", type, 2, 10001)
		check(B.service(bill, 1, 2, 1), "Typed fixture initial service: " + str(type))
		bills.append(bill)
	var credit := B.create_credit()
	for month in [1, 2, 3]:
		credit = B.close_month(credit, bills, month, 999999)
		check(credit.history[-1].requested_change == [-25, -50, -85][month - 1], "Distinct types add correct age tiers in synthetic month %d" % month)
		check(credit.history[-1].reasons.size() == 4, "Profitable month with penalties earns no clean bonus")
	check(credit.score == 440, "Typed additive defaults measured 600 to 440 over three missed months")
	traces.append({"synthetic_types": bills, "credit": credit})
	for c in [2, 3, 4, 6]:
		check(B.describe(bills[0], c).penalty == [5, 5, 10, 20][[2, 3, 4, 6].find(c)], "Rent tier at cycle %d" % c)
	var split := bills.duplicate(true)
	var bank := B.create_bill(&"bank_component:2", &"same_installment_fixture", &"bank_installment", 2, 500)
	B.service(bank, 0, 2, 1)
	split.append(bank)
	check(B.close_month(B.create_credit(), split, 1, 0).history[0].requested_change == -25, "Multiple invoices or split installment components cannot multiply category penalties")
	split.append(bank.duplicate(true))
	check(B.close_month(B.create_credit(), split, 1, 0).is_empty(), "Duplicate obligation identity rejects")
	var rent: Dictionary = bills[0].duplicate(true)
	check(B.service(rent, 3333, 3, 2) and rent.unpaid_cents == 6667 and rent.due_cycle == 2, "Odd-cent partial payment preserves age")
	check(B.service(rent, 6667, 4, 2) and rent.recovery_overdue_cycles == 2 and rent.late, "Closing-boundary recovery freezes real age")
	var first := B.close_month(B.create_credit(), [bills[0]], 1, 0)
	var second := B.close_month(first, [rent], 2, 100000)
	check(second.score == 585 and second.history[1].reasons[0].points == -10, "Closing-boundary repayment cannot erase age-tier debit")
	check(B.close_month(second, [rent], 3, 1).score == 588, "Cleared late bill stops future debit")
	check(B.close_month(second, [rent], 2, 1).is_empty(), "Repeated credit callback rejects")
	check(not B.service(rent, 1, 4, 2) and not B.service(bills[0].duplicate(true), -1, 3, 2), "Payment/refund/overpayment farming rejects")
	var capped := B.create_credit()
	for month in range(1, 101): capped = B.close_month(capped, [], month, 1)
	check(capped.score == 850 and capped.history[-1].change == 0 and capped.history[-1].requested_change == 3, "Upper clamp retains full reason history")
	capped = B.create_credit()
	for month in range(1, 21): capped = B.close_month(capped, bills, month, 1)
	check(capped.score == 300 and capped.history[-1].change == 0, "Lower clamp retains debit history without cash effects")


func _provenance_and_overflow() -> void:
	var l := step(step(F.create(10000), 1), 2)
	var encoded := var_to_bytes(l)
	var decoded: Dictionary = bytes_to_var(encoded)
	check(F.report(decoded, 2, 0).available and decoded == l, "Typed checkpoint roundtrip preserves IDs, credit and all exact records; not a disk save")
	for field in ["bill_id", "source_id", "expense_type", "due_cycle", "settled_cycle", "payments"]:
		var damaged := l.duplicate(true)
		damaged.obligations[0][field] = null
		check(not F.report(damaged, 2, 0).available, "Tampered bill provenance rejects: " + field)
	for field in ["policy_version", "score", "history", "last_processed_month"]:
		var damaged := l.duplicate(true)
		damaged.credit[field] = null
		check(not F.report(damaged, 2, 0).available, "Tampered credit provenance rejects: " + field)
	var legacy := l.duplicate(true)
	legacy.schema_version = 1
	legacy.erase("credit")
	for bill: Dictionary in legacy.obligations:
		for key in ["bill_id", "source_id", "expense_type", "settled_cycle", "recovery_overdue_cycles"]: bill.erase(key)
	check(F.upgrade_v1(legacy) == l, "Explicit v1 migration reconstructs existing rent identity without charging cash again")
	legacy.obligations[0].due_cycle = 4
	check(F.upgrade_v1(legacy).is_empty(), "V1 altered historical due fails migration")
	check(B.create_bill(&"x", &"x", &"invalid", 2, 1).is_empty() and B.create_bill(&"", &"x", &"rent", 2, 1).is_empty(), "Unknown type or missing identity rejects")
	check(B.close_month(B.create_credit(), [], B.MAX_INT, 1).is_empty(), "Credit boundary multiplication overflow rejects")
	var huge := B.create_bill(&"huge", &"fixture", &"rent", 2, B.MAX_INT)
	check(B.service(huge, B.MAX_INT, 2, 1) and huge.unpaid_cents == 0, "Maximum exact-cent bill services without sum overflow")
	check(F.plan(F.create(F.MAX_INT), 1, F.MAX_INT, 1, &"other_income", 0, 0, true).is_empty(), "Income overflow leaves credit and ledger untouched")
