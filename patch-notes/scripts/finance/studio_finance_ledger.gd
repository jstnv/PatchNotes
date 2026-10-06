class_name StudioFinanceLedger
extends RefCounted

## Pure run-finance journal. Calendar/cash remain owned by RunState; this class
## only plans value snapshots and rebuilds reports from checked provenance.
const SCHEMA_VERSION := 1
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
	"financing_in_cents", "principal_paid_cents", "interest_cents"]


static func create(cash_cents: int) -> Dictionary:
	if cash_cents < 0: return {}
	var row := _new_row(1, 0)
	row.financing_in_cents = cash_cents
	row.closing_cash_cents = cash_cents
	row.cash_change_cents = cash_cents
	var ledger := {"schema_version": SCHEMA_VERSION, "initial_cash_cents": cash_cents,
		"last_cycle": 0, "cash_cents": cash_cents, "unsettled_sales_net_cents": 0,
		"monthly_rows": [row], "obligations": [], "transactions": [], "actions": []}
	_append_transaction(ledger, 0, 1, &"starting_funding", cash_cents, cash_cents, 0, cash_cents, &"")
	return ledger


static func plan(ledger: Dictionary, cycle: int, cash_before: int, direct_delta: int,
		kind: StringName, sales_earned: int = 0, settled: int = 0, productive: bool = false,
		source_id: StringName = &"") -> Dictionary:
	if not _is_valid(ledger) or ledger.cash_cents != cash_before: return {}
	return _apply(ledger, cycle, cash_before, direct_delta, kind, sales_earned, settled, productive, source_id)


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
		"unpaid_rent_cents": unpaid, "monthly_rent_cents": MONTHLY_RENT_CENTS,
		"next_due_cycle": base_cycle + 2 if base_cycle <= MAX_INT - 2 else -1,
		"financially_blocked": unpaid > 0,
		"credit_inputs": {"completed_months": current_cycle / 2,
			"paid_on_time_months": on_time, "late_months": late}}


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
			"other_expense_cents", "rent_due_cents", "interest_cents"]:
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
			"other_expense_cents", "rent_paid_cents", "principal_paid_cents", "interest_cents"]:
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
		source_id: StringName, copy_source: bool = true) -> Dictionary:
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
	var rent_due := MONTHLY_RENT_CENTS if productive and cycle % 2 == 0 else 0
	if rent_due > MAX_INT - old_unpaid: return {}
	var available := cash + settled
	var total_due := old_unpaid + rent_due
	if productive and old_unpaid > 0 and available < total_due: return {}
	# Replay owns its private reconstruction and can append in place. Public
	# plans always deep-copy the caller's snapshot, including rejection paths.
	var next: Dictionary = ledger.duplicate(true) if copy_source else ledger
	var month := (cycle - 1) / 2 + 1 if productive else cycle / 2 + 1
	var rows: Array = next.monthly_rows
	if rows[-1].month < month:
		rows.append(_new_row(month, cash_before))
	if rows[-1].month != month: return {}
	var row: Dictionary = rows[-1]
	if row.closing_cash_cents != cash_before: return {}
	if direct_delta < 0:
		if not _add(row, EXPENSE_FIELDS[kind], -direct_delta): return {}
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
		next.obligations.append({"month": month, "due_cycle": cycle, "due_cents": rent_due,
			"paid_cents": 0, "unpaid_cents": rent_due, "paid_on_time": false,
			"late": false, "payments": []})
		_append_transaction(next, cycle, month, &"rent_due", rent_due, 0, cash, cash, &"", month)
	var rent_paid := 0
	for obligation: Dictionary in next.obligations:
		if obligation.unpaid_cents == 0: continue
		var payment := mini(cash, int(obligation.unpaid_cents))
		if payment > 0:
			if not _add(row, "rent_paid_cents", payment): return {}
			if payment > MAX_INT - rent_paid: return {}
			rent_paid += payment
			obligation.paid_cents += payment
			obligation.unpaid_cents -= payment
			obligation.payments.append({"cycle": cycle, "month": month, "cents": payment})
			_append_transaction(next, cycle, month, &"rent_payment", payment, -payment, cash, cash - payment, &"", obligation.month)
			cash -= payment
			# A completed rent month remains marked late after eventual recovery.
			if obligation.unpaid_cents == 0 and not obligation.late and obligation.due_cycle == cycle:
				obligation.paid_on_time = true
		if obligation.unpaid_cents > 0: obligation.late = true
		rows[int(obligation.month) - 1].rent_unpaid_cents = obligation.unpaid_cents
	row.closing_cash_cents = cash
	row.partial = not productive or cycle % 2 != 0
	if not _update_totals(row): return {}
	next.last_cycle = cycle
	next.cash_cents = cash
	next.unsettled_sales_net_cents = unsettled - settled
	next.actions.append({"cycle": cycle, "cash_before": cash_before, "direct_delta": direct_delta,
		"kind": kind, "sales_earned": sales_earned, "settled": settled,
		"productive": productive, "source_id": source_id})
	return {"ledger": next, "cash_cents": cash, "rent_paid_cents": rent_paid}


## Compare every derived field against the complete atomic-action journal.
## Reconstructed menus cannot invent missing money, months, or obligations.
static func _is_valid(ledger: Dictionary) -> bool:
	for key: String in ["schema_version", "initial_cash_cents", "last_cycle", "cash_cents", "unsettled_sales_net_cents"]:
		if typeof(ledger.get(key)) != TYPE_INT or ledger[key] < 0: return false
	if ledger.schema_version != SCHEMA_VERSION: return false
	for key: String in ["monthly_rows", "obligations", "transactions", "actions"]:
		if typeof(ledger.get(key)) != TYPE_ARRAY: return false
	var rebuilt := create(ledger.initial_cash_cents)
	for action in ledger.actions:
		if typeof(action) != TYPE_DICTIONARY: return false
		for key: String in ["cycle", "cash_before", "direct_delta", "sales_earned", "settled"]:
			if typeof(action.get(key)) != TYPE_INT: return false
		if typeof(action.get("productive")) != TYPE_BOOL or typeof(action.get("kind")) != TYPE_STRING_NAME or typeof(action.get("source_id")) != TYPE_STRING_NAME: return false
		if action.cash_before != rebuilt.cash_cents: return false
		var step := _apply(rebuilt, action.cycle, action.cash_before, action.direct_delta,
			action.kind, action.sales_earned, action.settled, action.productive, action.source_id, false)
		if step.is_empty(): return false
		rebuilt = step.ledger
	return rebuilt == ledger
