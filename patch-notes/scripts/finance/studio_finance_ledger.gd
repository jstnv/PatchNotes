class_name StudioFinanceLedger
extends RefCounted

## Pure run-finance journal. Calendar/cash remain owned by RunState; this class
## only plans value snapshots and rebuilds reports from checked provenance.
const SCHEMA_VERSION := 5
const Bank := preload("res://scripts/finance/bank_loan.gd")
const Bills := preload("res://scripts/finance/outstanding_expenses.gd")
const MAX_INT: int = 9223372036854775807
const MONTHLY_RENT_CENTS := 50000
const EXPENSE_FIELDS := {
	&"feature_play": "feature_play_cents", &"store": "store_cents",
	&"campaign": "campaign_cents", &"playtest": "playtest_cents",
	&"other_expense": "other_expense_cents", &"principal_paid": "principal_paid_cents",
	&"interest": "interest_cents"}
const INCOME_KINDS: Array[StringName] = [&"publisher_receipt", &"beta_income", &"other_income", &"financing_in"]
const FREE_KINDS: Array[StringName] = [&"development", &"priority_change", &"contract_hand", &"calendar"]
const NONNEGATIVE_ROW_FIELDS: Array[String] = ["opening_cash_cents", "closing_cash_cents",
	"sales_net_earned_cents", "sales_settled_cents", "other_income_cents", "publisher_income_cents",
	"beta_income_cents", "miscellaneous_income_cents", "feature_play_cents",
	"store_cents", "campaign_cents", "playtest_cents", "other_expense_cents", "rent_due_cents",
	"rent_paid_cents", "rent_unpaid_cents", "operating_revenue_cents", "operating_expenses_cents",
	"financing_in_cents", "principal_paid_cents", "interest_cents", "interest_paid_cents", "payroll_due_cents", "payroll_paid_cents", "payroll_unpaid_cents"]


static func create(cash_cents: int, monthly_rent_cents: int = MONTHLY_RENT_CENTS) -> Dictionary:
	if cash_cents < 0 or monthly_rent_cents not in [50000, 51500]: return {}
	var row := _new_row(1, 0)
	row.financing_in_cents = cash_cents
	row.closing_cash_cents = cash_cents
	row.cash_change_cents = cash_cents
	var ledger := {"schema_version": SCHEMA_VERSION, "initial_cash_cents": cash_cents, "monthly_rent_cents": monthly_rent_cents,
		"last_cycle": 0, "cash_cents": cash_cents, "unsettled_sales_net_cents": 0,
		"monthly_rows": [row], "obligations": [], "transactions": [], "actions": [],
		"credit": Bills.create_credit(), "bank_loans": [], "employees": []}
	_append_transaction(ledger, 0, 1, &"starting_funding", cash_cents, cash_cents, 0, cash_cents, &"")
	return ledger


static func plan(ledger: Dictionary, cycle: int, cash_before: int, direct_delta: int,
		kind: StringName, sales_earned: int = 0, settled: int = 0, productive: bool = false,
		source_id: StringName = &"") -> Dictionary:
	if not _is_valid(ledger) or ledger.cash_cents != cash_before: return {}
	return _apply(ledger, cycle, cash_before, direct_delta, kind, sales_earned, settled, productive, source_id)



static func _unpaid_category(ledger: Dictionary, category: StringName) -> int:
	var amount := 0
	for bill: Dictionary in ledger.obligations:
		if bill.expense_type == category: amount += int(bill.unpaid_cents)
	return amount


static func bank_quote(ledger: Dictionary, principal: Variant, months: Variant, run_id: StringName) -> Dictionary:
	if not _is_valid(ledger): return {}
	return Bank.quote(ledger, principal, months, run_id, ledger.monthly_rent_cents, _monthly_payroll(ledger))


static func accept_loan(ledger: Dictionary, quote: Dictionary, run_id: StringName) -> Dictionary:
	if not _is_valid(ledger) or quote.get("run_id") != run_id or typeof(quote.get("loan_id")) != TYPE_STRING_NAME: return {}
	var operation := {"type": &"accept", "quote": quote.duplicate(true)}
	if typeof(quote.get("schedule")) != TYPE_DICTIONARY: return {}
	var principal: Variant = quote.schedule.get("principal_cents")
	if typeof(principal) != TYPE_INT: return {}
	return _apply(ledger, ledger.last_cycle, ledger.cash_cents, principal, &"financing_in", 0, 0, false, quote.get("loan_id", &""), true, operation)


static func _payoff_unchecked(ledger: Dictionary, loan_id: StringName) -> Dictionary:
	for loan: Dictionary in ledger.bank_loans:
		if loan.loan_id != loan_id or loan.closed: continue
		var interest := 0
		for bill: Dictionary in ledger.obligations:
			if bill.source_id == loan_id:
				interest += int(bill.interest_cents) - int(bill.interest_paid_cents)
		var principal: int = loan.schedule.principal_cents - loan.principal_paid_cents
		if interest > MAX_INT - principal: return {}
		return {"type": &"payoff", "loan_id": loan_id, "revision": ledger.actions.size(),
			"principal_cents": principal, "interest_cents": interest, "total_cents": principal + interest}
	return {}


static func payoff_quote(ledger: Dictionary, loan_id: StringName) -> Dictionary:
	return _payoff_unchecked(ledger, loan_id) if _is_valid(ledger) else {}


static func pay_off(ledger: Dictionary, quote: Dictionary) -> Dictionary:
	if not _is_valid(ledger) or typeof(quote.get("loan_id")) != TYPE_STRING_NAME: return {}
	return _apply(ledger, ledger.last_cycle, ledger.cash_cents, 0, &"calendar", 0, 0, false, quote.loan_id, true, quote)


static func _bank_operation_valid(ledger: Dictionary, operation: Dictionary, delta: int, kind: StringName, source_id: StringName) -> bool:
	if operation.get("type") == &"hire":
		if typeof(operation.get("run_id")) != TYPE_STRING_NAME: return false
		var expected := _hire_quote_unchecked(ledger,operation.run_id)
		return not expected.is_empty() and operation == expected and delta == -10000 and kind == &"other_expense" and source_id == expected.employee_id
	if operation.get("type") == &"accept":
		if typeof(operation.get("quote")) != TYPE_DICTIONARY: return false
		var quote: Dictionary = operation.quote
		if typeof(quote.get("schedule")) != TYPE_DICTIONARY or typeof(quote.get("run_id")) != TYPE_STRING_NAME: return false
		var expected := Bank.quote(ledger, quote.schedule.get("principal_cents"), quote.schedule.get("term_months"), quote.run_id, ledger.monthly_rent_cents, _monthly_payroll(ledger))
		return expected.get("accepted", false) and quote == expected and delta == expected.schedule.principal_cents and kind == &"financing_in" and source_id == expected.loan_id
	if operation.get("type") == &"payoff":
		if typeof(operation.get("loan_id")) != TYPE_STRING_NAME: return false
		var expected := _payoff_unchecked(ledger, operation.loan_id)
		if expected.is_empty() or operation != expected or delta != 0 or kind != &"calendar" or source_id != operation.loan_id: return false
		var prior := _unpaid_category(ledger, &"rent") + _unpaid_category(ledger, &"payroll")
		return prior <= ledger.cash_cents and expected.total_cents <= ledger.cash_cents - prior
	return false


static func get_unpaid(ledger: Dictionary) -> int:
	return _unpaid_unchecked(ledger) if _is_valid(ledger) else -1


static func report(ledger: Dictionary, current_cycle: int, current_cash: int) -> Dictionary:
	if not _is_valid(ledger) or ledger.last_cycle != current_cycle or ledger.cash_cents != current_cash:
		return {"available": false}
	var rows: Array = ledger.monthly_rows.duplicate(true)
	var current_month := current_cycle / 2 + 1
	if rows.is_empty() or rows[-1].month < current_month:
		rows.append(_new_row(current_month, current_cash))
	for row: Dictionary in rows:
		row.partial = row.month == current_month
	var on_time := 0
	var late := 0
	for obligation: Dictionary in ledger.obligations:
		if obligation.paid_on_time: on_time += 1
		if obligation.late: late += 1
	var unpaid := _unpaid_unchecked(ledger)
	var base_cycle := current_cycle - current_cycle % 2
	return {"available": true, "rows": rows, "cash_cents": current_cash,
		"unpaid_rent_cents": _unpaid_category(ledger, &"rent"), "total_overdue_cents": unpaid, "monthly_rent_cents": ledger.monthly_rent_cents, "monthly_payroll_cents": _monthly_payroll(ledger),
		"next_due_cycle": base_cycle + 2 if base_cycle <= MAX_INT - 2 else -1,
		"financially_blocked": unpaid > 0,
		"outstanding_expenses": _outstanding_unchecked(ledger, current_cycle),
		"credit": ledger.credit.duplicate(true), "bank_loans": ledger.bank_loans.duplicate(true),
		"credit_inputs": {"completed_months": current_cycle / 2,
			"paid_on_time_months": on_time, "late_months": late}}


static func outstanding(ledger: Dictionary, current_cycle: int) -> Dictionary:
	if not _is_valid(ledger) or ledger.last_cycle != current_cycle: return {"available": false}
	return {"available": true, "bills": _outstanding_unchecked(ledger, current_cycle)}


static func _outstanding_unchecked(ledger: Dictionary, current_cycle: int) -> Array:
	var result: Array = []
	for bill: Dictionary in ledger.obligations:
		if bill.unpaid_cents > 0: result.append(Bills.describe(bill, current_cycle))
	return result


static func _new_row(month: int, opening: int) -> Dictionary:
	var row := {"month": month, "partial": true, "cash_change_cents": 0, "net_profit_cents": 0}
	for key: String in NONNEGATIVE_ROW_FIELDS: row[key] = 0
	row.opening_cash_cents = opening
	row.closing_cash_cents = opening
	return row


static func _kind_valid(kind: StringName, delta: int) -> bool:
	if delta < 0: return EXPENSE_FIELDS.has(kind)
	if delta > 0: return kind in INCOME_KINDS
	return EXPENSE_FIELDS.has(kind) or kind in INCOME_KINDS or kind in FREE_KINDS


static func _add(row: Dictionary, key: String, amount: int) -> bool:
	if amount < 0 or amount > MAX_INT - int(row[key]): return false
	row[key] += amount
	return true


static func _update_totals(row: Dictionary) -> bool:
	var revenue: int = row.sales_net_earned_cents
	if row.other_income_cents > MAX_INT - revenue: return false
	revenue += int(row.other_income_cents)
	var expense := 0
	for key: String in ["feature_play_cents", "store_cents", "campaign_cents", "playtest_cents",
			"other_expense_cents", "rent_due_cents", "interest_cents", "payroll_due_cents"]:
		if row[key] > MAX_INT - expense: return false
		expense += int(row[key])
	row.operating_revenue_cents = revenue
	row.operating_expenses_cents = expense
	row.net_profit_cents = revenue - expense
	row.cash_change_cents = int(row.closing_cash_cents) - int(row.opening_cash_cents)
	# Accrual profit and cash movement are separate checked identities. Loan
	# principal/funding affect only cash; rent payment must not expense rent twice.
	var receipts := 0
	for key: String in ["sales_settled_cents", "other_income_cents", "financing_in_cents"]:
		if row[key] > MAX_INT - receipts: return false
		receipts += int(row[key])
	var outflows := 0
	for key: String in ["feature_play_cents", "store_cents", "campaign_cents", "playtest_cents",
			"other_expense_cents", "rent_paid_cents", "principal_paid_cents", "interest_paid_cents", "payroll_paid_cents"]:
		if row[key] > MAX_INT - outflows: return false
		outflows += int(row[key])
	# Subtract totals first so opening + lifetime turnover need not overflow.
	var movement := receipts - outflows
	if movement < -int(row.opening_cash_cents) or movement > MAX_INT - int(row.opening_cash_cents): return false
	if int(row.opening_cash_cents) + movement != row.closing_cash_cents: return false
	return true


static func _unpaid_unchecked(ledger: Dictionary) -> int:
	var unpaid := 0
	for obligation: Dictionary in ledger.obligations:
		if obligation.unpaid_cents > MAX_INT - unpaid: return -1
		unpaid += int(obligation.unpaid_cents)
	return unpaid


static func _append_transaction(ledger: Dictionary, cycle: int, month: int, kind: StringName,
		amount: int, cash_delta: int, cash_before: int, cash_after: int, source_id: StringName,
		due_month: int = 0) -> void:
	ledger.transactions.append({"sequence": ledger.transactions.size() + 1,
		"cycle": cycle, "month": month, "kind": kind, "amount_cents": amount,
		"cash_delta_cents": cash_delta, "cash_before_cents": cash_before,
		"cash_after_cents": cash_after, "source_id": source_id, "due_month": due_month})


static func _apply(ledger: Dictionary, cycle: int, cash_before: int, direct_delta: int,
		kind: StringName, sales_earned: int, settled: int, productive: bool,
		source_id: StringName, copy_source: bool = true, operation: Dictionary = {}) -> Dictionary:
	if cycle < 0 or cash_before < 0 or sales_earned < 0 or settled < 0 or not _kind_valid(kind, direct_delta): return {}
	if productive:
		if ledger.last_cycle == MAX_INT or cycle != int(ledger.last_cycle) + 1: return {}
	elif cycle != ledger.last_cycle or sales_earned != 0 or settled != 0:
		return {}
	# This comparison also rejects MIN_INT without ever negating it.
	if direct_delta < -cash_before or direct_delta > MAX_INT - cash_before: return {}
	var old_unpaid := _unpaid_unchecked(ledger)
	if old_unpaid < 0 or (not productive and old_unpaid > 0 and direct_delta < 0): return {}
	var cash := cash_before + direct_delta
	if settled > MAX_INT - cash: return {} # Settlement must fit BEFORE rent is paid.
	if sales_earned > MAX_INT - int(ledger.unsettled_sales_net_cents): return {}
	var unsettled: int = ledger.unsettled_sales_net_cents + sales_earned
	if settled > unsettled: return {}
	var rent_due: int = ledger.monthly_rent_cents if productive and cycle % 2 == 0 else 0
	if rent_due > MAX_INT - old_unpaid: return {}
	var available := cash + settled
	var bank_due := 0
	if productive:
		for loan: Dictionary in ledger.bank_loans:
			if loan.closed or loan.issued >= loan.schedule.term_months: continue
			var installment := Bank.installment(loan.schedule, loan.issued + 1)
			if installment.due_cycle == cycle: bank_due = installment.payment_cents
	if bank_due > MAX_INT - old_unpaid - rent_due: return {}
	var payroll_due := 0
	if productive:
		for employee: Dictionary in ledger.employees:
			if cycle == employee.first_due_cycle + employee.issued * 2: payroll_due += int(employee.wage_cents)
	if payroll_due > MAX_INT - old_unpaid - rent_due - bank_due: return {}
	var total_due := old_unpaid + rent_due + bank_due + payroll_due
	if productive and old_unpaid > 0 and available < total_due: return {}
	# Replay owns its private reconstruction and can append in place. Public
	# plans always deep-copy the caller's snapshot, including rejection paths.
	var next: Dictionary = ledger.duplicate(true) if copy_source else ledger
	if not operation.is_empty():
		if productive or not _bank_operation_valid(ledger, operation, direct_delta, kind, source_id): return {}
		if operation.type == &"hire":
			next.employees.append({"employee_id":operation.employee_id,"wage_cents":operation.wage_cents,"hire_cycle":cycle,"first_due_cycle":operation.first_due_cycle,"issued":0})
		if operation.type == &"accept":
			next.bank_loans.append({"loan_id": operation.quote.loan_id, "run_id": operation.quote.run_id, "quote_id": operation.quote.quote_id, "schedule": operation.quote.schedule.duplicate(true), "issued": 0, "principal_paid_cents": 0, "interest_paid_cents": 0, "closed": false, "closed_cycle": -1, "early_payoff": false})
	var month := (cycle - 1) / 2 + 1 if productive else cycle / 2 + 1
	var rows: Array = next.monthly_rows
	if rows[-1].month < month:
		rows.append(_new_row(month, cash_before))
	if rows[-1].month != month: return {}
	var row: Dictionary = rows[-1]
	if row.closing_cash_cents != cash_before: return {}
	if direct_delta < 0:
		if not _add(row, EXPENSE_FIELDS[kind], -direct_delta): return {}
		if kind == &"interest" and not _add(row, "interest_paid_cents", -direct_delta): return {}
	elif direct_delta > 0:
		if not _add(row, "financing_in_cents" if kind == &"financing_in" else "other_income_cents", direct_delta): return {}
		var income_field := "publisher_income_cents" if kind == &"publisher_receipt" else ("beta_income_cents" if kind == &"beta_income" else "miscellaneous_income_cents")
		if kind != &"financing_in" and not _add(row, income_field, direct_delta): return {}
	_append_transaction(next, cycle, month, kind, absi(direct_delta), direct_delta, cash_before, cash, source_id)
	if sales_earned > 0:
		if not _add(row, "sales_net_earned_cents", sales_earned): return {}
		_append_transaction(next, cycle, month, &"sales_earned", sales_earned, 0, cash, cash, &"")
	if settled > 0:
		if not _add(row, "sales_settled_cents", settled): return {}
		_append_transaction(next, cycle, month, &"sales_settlement", settled, settled, cash, available, &"")
	cash = available
	if rent_due > 0:
		if not _add(row, "rent_due_cents", rent_due): return {}
		next.obligations.append(Bills.create_bill(StringName("rent:%d" % month), &"studio_rent", &"rent", cycle, rent_due))
		_append_transaction(next, cycle, month, &"rent_due", rent_due, 0, cash, cash, &"", month)
	if payroll_due > 0:
		for employee: Dictionary in next.employees:
			if cycle != employee.first_due_cycle + employee.issued * 2: continue
			var bill := Bills.create_bill(StringName("%s:payroll:%d" % [employee.employee_id,month]),employee.employee_id,&"payroll",cycle,employee.wage_cents)
			next.obligations.append(bill)
			employee.issued += 1
			if not _add(row,"payroll_due_cents",employee.wage_cents): return {}
			_append_transaction(next,cycle,month,&"payroll_due",employee.wage_cents,0,cash,cash,employee.employee_id,month)
	if bank_due > 0:
		for loan: Dictionary in next.bank_loans:
			if loan.closed or loan.issued >= loan.schedule.term_months: continue
			var installment := Bank.installment(loan.schedule, loan.issued + 1)
			if installment.due_cycle != cycle: continue
			var bill := Bills.create_bill(StringName("%s:%d" % [loan.loan_id, installment.number]), loan.loan_id, &"bank_installment", cycle, installment.payment_cents)
			bill.principal_cents = installment.principal_cents
			bill.interest_cents = installment.interest_cents
			bill.principal_paid_cents = 0
			bill.interest_paid_cents = 0
			next.obligations.append(bill)
			loan.issued += 1
			if not _add(row, "interest_cents", installment.interest_cents): return {}
			_append_transaction(next, cycle, month, &"bank_interest_due", installment.interest_cents, 0, cash, cash, loan.loan_id, month)
	var rent_paid := 0
	var bills_paid := 0
	# Stable insertion order is chronological within each category.
	for category: StringName in [&"rent", &"payroll", &"bank_installment"]:
		for obligation: Dictionary in next.obligations:
			if obligation.expense_type != category or obligation.unpaid_cents == 0: continue
			var payment := mini(cash, int(obligation.unpaid_cents))
			if payment > 0:
				if category == &"rent":
					if not _add(row, "rent_paid_cents", payment): return {}
					rent_paid += payment
				elif category == &"payroll":
					if not _add(row,"payroll_paid_cents",payment): return {}
				elif category == &"bank_installment":
					var interest := mini(payment, int(obligation.interest_cents) - int(obligation.interest_paid_cents))
					var principal := payment - interest
					if not _add(row, "interest_paid_cents", interest) or not _add(row, "principal_paid_cents", principal): return {}
					obligation.interest_paid_cents += interest
					obligation.principal_paid_cents += principal
					for loan: Dictionary in next.bank_loans:
						if loan.loan_id == obligation.source_id:
							loan.interest_paid_cents += interest
							loan.principal_paid_cents += principal
				bills_paid += payment
				_append_transaction(next, cycle, month, &"rent_payment" if category == &"rent" else (&"payroll_payment" if category == &"payroll" else &"bank_payment"), payment, -payment, cash, cash - payment, obligation.source_id if category != &"rent" else &"", obligation.month)
				cash -= payment
			if not Bills.service(obligation, payment, cycle, month): return {}
			if category == &"rent": rows[int(obligation.month) - 1].rent_unpaid_cents = obligation.unpaid_cents
			if category == &"payroll": rows[int(obligation.month) - 1].payroll_unpaid_cents = obligation.unpaid_cents
	if operation.get("type") == &"payoff":
		for loan: Dictionary in next.bank_loans:
			if loan.loan_id != operation.loan_id: continue
			var principal: int = loan.schedule.principal_cents - loan.principal_paid_cents
			if principal > cash or not _add(row, "principal_paid_cents", principal): return {}
			_append_transaction(next, cycle, month, &"bank_payoff", principal, -principal, cash, cash - principal, loan.loan_id)
			cash -= principal
			bills_paid += principal
			loan.principal_paid_cents += principal
			loan.early_payoff = loan.issued < loan.schedule.term_months
	for loan: Dictionary in next.bank_loans:
		if not loan.closed and loan.principal_paid_cents == loan.schedule.principal_cents:
			loan.closed = true
			loan.closed_cycle = cycle
	row.closing_cash_cents = cash
	row.partial = not productive or cycle % 2 != 0
	if not _update_totals(row): return {}
	if productive and cycle % 2 == 0:
		next.credit = Bills.close_month(next.credit, next.obligations, month, row.net_profit_cents)
		if next.credit.is_empty(): return {}
	next.last_cycle = cycle
	next.cash_cents = cash
	next.unsettled_sales_net_cents = unsettled - settled
	next.actions.append({"cycle": cycle, "cash_before": cash_before, "direct_delta": direct_delta,
		"kind": kind, "sales_earned": sales_earned, "settled": settled,
		"productive": productive, "source_id": source_id})
	if not operation.is_empty(): next.actions[-1]["operation"] = operation.duplicate(true)
	return {"ledger": next, "cash_cents": cash, "rent_paid_cents": rent_paid, "bills_paid_cents": bills_paid}


## Compare every derived field against the complete atomic-action journal.
## Reconstructed menus cannot invent missing money, months, or obligations.
static func _is_valid(ledger: Dictionary) -> bool:
	for key: String in ["schema_version", "initial_cash_cents", "last_cycle", "cash_cents", "unsettled_sales_net_cents"]:
		if typeof(ledger.get(key)) != TYPE_INT or ledger[key] < 0: return false
	if ledger.schema_version != SCHEMA_VERSION: return false
	for key: String in ["monthly_rows", "obligations", "transactions", "actions"]:
		if typeof(ledger.get(key)) != TYPE_ARRAY: return false
	if typeof(ledger.get("monthly_rent_cents")) != TYPE_INT or ledger.monthly_rent_cents not in [50000,51500]: return false
	var rebuilt := create(ledger.initial_cash_cents, ledger.monthly_rent_cents)
	for action in ledger.actions:
		if typeof(action) != TYPE_DICTIONARY: return false
		for key: String in ["cycle", "cash_before", "direct_delta", "sales_earned", "settled"]:
			if typeof(action.get(key)) != TYPE_INT: return false
		if typeof(action.get("productive")) != TYPE_BOOL or typeof(action.get("kind")) != TYPE_STRING_NAME or typeof(action.get("source_id")) != TYPE_STRING_NAME: return false
		if action.cash_before != rebuilt.cash_cents or typeof(action.get("operation", {})) != TYPE_DICTIONARY: return false
		var step := _apply(rebuilt, action.cycle, action.cash_before, action.direct_delta,
			action.kind, action.sales_earned, action.settled, action.productive, action.source_id, false, action.get("operation", {}))
		if step.is_empty(): return false
		rebuilt = step.ledger
	return rebuilt == ledger


## Schema 1 had no explicit bill IDs. The original unique rent month is its
## identity. Migrate only if every old field equals the reconstructed journal.
static func upgrade_v1(legacy: Dictionary) -> Dictionary:
	if legacy.get("schema_version") != 1: return {}
	var candidate := legacy.duplicate(true)
	candidate.schema_version = SCHEMA_VERSION
	candidate.credit = Bills.create_credit()
	if typeof(candidate.get("actions")) != TYPE_ARRAY or typeof(candidate.get("initial_cash_cents")) != TYPE_INT or candidate.initial_cash_cents < 0: return {}
	var rebuilt := create(candidate.initial_cash_cents)
	for action in candidate.actions:
		if typeof(action) != TYPE_DICTIONARY: return {}
		for key in ["cycle", "cash_before", "direct_delta", "sales_earned", "settled"]:
			if typeof(action.get(key)) != TYPE_INT: return {}
		if typeof(action.get("productive")) != TYPE_BOOL or typeof(action.get("kind")) != TYPE_STRING_NAME or typeof(action.get("source_id")) != TYPE_STRING_NAME or action.cash_before != rebuilt.cash_cents: return {}
		var step := _apply(rebuilt, action.cycle, action.cash_before, action.direct_delta, action.kind, action.sales_earned, action.settled, action.productive, action.source_id, false)
		if step.is_empty(): return {}
		rebuilt = step.ledger
	var projected := rebuilt.duplicate(true)
	projected.schema_version = 1
	projected.erase("credit")
	if not legacy.has("monthly_rent_cents"): projected.erase("monthly_rent_cents")
	if not legacy.has("bank_loans"): projected.erase("bank_loans")
	if not legacy.has("employees"): projected.erase("employees")
	for i in range(projected.monthly_rows.size()):
		for key in ["interest_paid_cents","payroll_due_cents","payroll_paid_cents","payroll_unpaid_cents"]:
			if not legacy.monthly_rows[i].has(key): projected.monthly_rows[i].erase(key)
	for bill: Dictionary in projected.obligations:
		for key in ["bill_id", "source_id", "expense_type", "settled_cycle", "recovery_overdue_cycles"]: bill.erase(key)
	return rebuilt if projected == legacy else {}


static func _monthly_payroll(ledger: Dictionary) -> int:
	var monthly := 0
	for employee: Dictionary in ledger.employees: monthly += int(employee.wage_cents)
	return monthly


static func _hire_quote_unchecked(ledger: Dictionary, run_id: StringName) -> Dictionary:
	var cycle: int = ledger.last_cycle
	var gap := 2 + int(cycle % 2)
	if run_id.is_empty() or not ledger.employees.is_empty() or _unpaid_unchecked(ledger) != 0 or ledger.cash_cents < 10000 or cycle > MAX_INT-gap: return {}
	return {"type":&"hire","run_id":run_id,"employee_id":StringName("%s:production:1" % run_id),"revision":ledger.actions.size(),"fee_cents":10000,"wage_cents":1000,"hire_cycle":cycle,"first_due_cycle":cycle+gap}


static func hire_quote(ledger: Dictionary, run_id: StringName) -> Dictionary:
	return _hire_quote_unchecked(ledger,run_id) if _is_valid(ledger) else {}


static func hire_employee(ledger: Dictionary, quote: Dictionary, run_id: StringName) -> Dictionary:
	if not _is_valid(ledger) or quote.get("run_id") != run_id or typeof(quote.get("employee_id")) != TYPE_STRING_NAME: return {}
	return _apply(ledger,ledger.last_cycle,ledger.cash_cents,-10000,&"other_expense",0,0,false,quote.employee_id,true,quote)
