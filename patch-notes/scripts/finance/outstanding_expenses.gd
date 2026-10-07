class_name OutstandingExpenses
extends RefCounted

## Pure typed bill and credit policy. Only the rent producer is wired to RunState.
## Other types are extension hooks, not authorization to issue obligations.
const MAX_INT: int = 9223372036854775807
const POLICY_VERSION := "typed_expenses_v1"
const STARTING_SCORE := 600
const MIN_SCORE := 300 # Configurable prototype defaults under authority §69.
const MAX_SCORE := 850
const CLEAN_PROFIT_GAIN := 3
const PENALTIES := {&"rent": [5, 10, 20], &"bank_installment": [10, 20, 30],
	&"payroll": [5, 10, 15], &"student_loan": [5, 10, 20]}
const LABELS := {&"rent": "Rent", &"bank_installment": "Bank installment",
	&"payroll": "Payroll", &"student_loan": "Student Loan"}


static func create_bill(id: StringName, source: StringName, type: StringName,
		due_cycle: int, cents: int) -> Dictionary:
	if id.is_empty() or source.is_empty() or not PENALTIES.has(type) or due_cycle <= 0 or cents <= 0: return {}
	return {"bill_id": id, "source_id": source, "expense_type": type,
		"month": (due_cycle - 1) / 2 + 1, "due_cycle": due_cycle, "due_cents": cents,
		"paid_cents": 0, "unpaid_cents": cents, "paid_on_time": false, "late": false,
		"settled_cycle": -1, "recovery_overdue_cycles": -1, "payments": []}


## Called after automatic service at the due boundary, including a zero payment.
## Input is a private plan; caller must validate provenance before applying it.
static func service(bill: Dictionary, cents: int, cycle: int, payment_month: int) -> bool:
	if not valid_bill(bill) or cycle < bill.due_cycle or cents < 0 or cents > bill.unpaid_cents or payment_month < bill.month: return false
	if not bill.payments.is_empty() and cycle < bill.payments[-1].cycle: return false
	if bill.unpaid_cents == 0: return cents == 0
	if cents > 0:
		bill.paid_cents += cents
		bill.unpaid_cents -= cents
		bill.payments.append({"cycle": cycle, "month": payment_month, "cents": cents})
	if bill.unpaid_cents == 0:
		bill.settled_cycle = cycle
		bill.recovery_overdue_cycles = cycle - int(bill.due_cycle)
		bill.paid_on_time = not bill.late and cycle == bill.due_cycle
	if bill.unpaid_cents > 0 or cycle > bill.due_cycle: bill.late = true
	return true


static func valid_bill(bill: Dictionary) -> bool:
	for key in ["bill_id", "source_id", "expense_type"]:
		if typeof(bill.get(key)) != TYPE_STRING_NAME or bill[key].is_empty(): return false
	if not PENALTIES.has(bill.expense_type): return false
	for key in ["month", "due_cycle", "due_cents", "paid_cents", "unpaid_cents", "settled_cycle", "recovery_overdue_cycles"]:
		if typeof(bill.get(key)) != TYPE_INT: return false
	if typeof(bill.get("late")) != TYPE_BOOL or typeof(bill.get("paid_on_time")) != TYPE_BOOL or typeof(bill.get("payments")) != TYPE_ARRAY: return false
	if bill.due_cycle <= 0 or bill.month != (int(bill.due_cycle) - 1) / 2 + 1 or bill.due_cents <= 0 or bill.paid_cents < 0 or bill.paid_cents > bill.due_cents or bill.unpaid_cents != int(bill.due_cents) - int(bill.paid_cents): return false
	var paid := 0
	var last := int(bill.due_cycle)
	for payment in bill.payments:
		if typeof(payment) != TYPE_DICTIONARY: return false
		for key in ["cycle", "month", "cents"]:
			if typeof(payment.get(key)) != TYPE_INT: return false
		if payment.cycle < last or payment.cents <= 0 or payment.cents > int(bill.due_cents) - paid: return false
		# A boundary may belong to the closing action or the newly opened month.
		if payment.month < (int(payment.cycle) - 1) / 2 + 1 or payment.month > int(payment.cycle) / 2 + 1: return false
		paid += int(payment.cents)
		last = payment.cycle
	if paid != bill.paid_cents: return false
	if bill.unpaid_cents > 0:
		return bill.settled_cycle == -1 and bill.recovery_overdue_cycles == -1 and not bill.paid_on_time
	return bill.settled_cycle == last and bill.recovery_overdue_cycles == last - int(bill.due_cycle) and bill.paid_on_time == (not bill.late and last == bill.due_cycle) and (bill.late or bill.paid_on_time)


static func age(bill: Dictionary, current_cycle: int) -> int:
	return maxi(0, current_cycle - int(bill.due_cycle))


static func tier(overdue_cycles: int) -> int:
	return mini(maxi(overdue_cycles, 0) / 2, 2)


static func describe(bill: Dictionary, current_cycle: int) -> Dictionary:
	if not valid_bill(bill) or current_cycle < bill.due_cycle: return {}
	var result := bill.duplicate(true)
	result.overdue_cycles = age(bill, current_cycle) if bill.unpaid_cents > 0 else bill.recovery_overdue_cycles
	result.penalty = PENALTIES[bill.expense_type][tier(result.overdue_cycles)] if bill.late else 0
	result.next_penalty = PENALTIES[bill.expense_type][mini(tier(result.overdue_cycles) + 1, 2)] if bill.unpaid_cents > 0 else 0
	return result


static func create_credit() -> Dictionary:
	return {"policy_version": POLICY_VERSION, "score": STARTING_SCORE,
		"last_processed_month": 0, "history": []}


## Strongest age per category, including recovery during this closing period.
## Recovery exactly at the opening boundary was already charged in the prior
## close; zero additional elapsed time does not manufacture another late period.
static func close_month(credit: Dictionary, bills: Array, month: int, profit: int) -> Dictionary:
	if month <= 0 or month > MAX_INT / 2 or credit.get("policy_version") != POLICY_VERSION: return {}
	if typeof(credit.get("score")) != TYPE_INT or credit.score < MIN_SCORE or credit.score > MAX_SCORE or typeof(credit.get("last_processed_month")) != TYPE_INT or typeof(credit.get("history")) != TYPE_ARRAY: return {}
	if credit.last_processed_month != month - 1 or credit.history.size() != month - 1: return {}
	var cycle := month * 2
	var oldest := {}
	var ids := {}
	for value in bills:
		if typeof(value) != TYPE_DICTIONARY or not valid_bill(value): return {}
		var bill: Dictionary = value
		if ids.has(bill.bill_id): return {}
		ids[bill.bill_id] = true
		if bill.due_cycle > cycle or not bill.late: continue
		if bill.unpaid_cents == 0 and bill.settled_cycle <= cycle - 2: continue
		var evaluated_cycle: int = cycle if bill.unpaid_cents > 0 else mini(cycle, bill.settled_cycle)
		var overdue := age(bill, evaluated_cycle)
		if not oldest.has(bill.expense_type) or overdue > oldest[bill.expense_type].overdue_cycles:
			oldest[bill.expense_type] = {"type": bill.expense_type, "bill_id": bill.bill_id,
				"due_cycle": bill.due_cycle, "evaluated_cycle": evaluated_cycle,
				"overdue_cycles": overdue, "points": -int(PENALTIES[bill.expense_type][tier(overdue)]),
				"recovered": bill.unpaid_cents == 0}
	var factors: Array = []
	var requested := 0
	for type: StringName in PENALTIES:
		if oldest.has(type):
			factors.append(oldest[type])
			requested += int(oldest[type].points)
	if factors.is_empty():
		requested = CLEAN_PROFIT_GAIN if profit > 0 else 0
		factors.append({"type": &"clean_profit" if profit > 0 else &"paid_no_profit", "points": requested})
	var result := credit.duplicate(true)
	result.score = clampi(int(credit.score) + requested, MIN_SCORE, MAX_SCORE)
	result.last_processed_month = month
	result.history.append({"month": month, "cycle": cycle, "policy_version": POLICY_VERSION,
		"operating_profit_cents": profit, "before": credit.score, "after": result.score,
		"requested_change": requested, "change": int(result.score) - int(credit.score), "reasons": factors})
	return result
