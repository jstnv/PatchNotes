class_name EducationDebt
extends RefCounted

## Approved education liability; scheduled balances never depend on late cash.
const VERSION := 1
const TERMS := {&"college_dropout": [500000, 7068], &"graduate": [2000000, 28273]}
const Clock := preload("res://scripts/calendar/calendar_clock.gd")

static func schedule(trait_id: StringName, calendar: Dictionary = {}) -> Dictionary:
	if not TERMS.has(trait_id) or not Clock.valid(calendar): return {}
	var principal: int = TERMS[trait_id][0]
	var regular: int = TERMS[trait_id][1]
	var result := {"schema_version":VERSION,"principal_cents":principal,"regular_due_cents":regular,"term_months":96,"first_due_cycle":Clock.month_end(13,calendar),"last_due_cycle":Clock.month_end(108,calendar),"total_interest_cents":0,"total_payment_cents":0}
	if result.first_due_cycle<0 or result.last_due_cycle<0:return {}
	if not calendar.is_empty():result.calendar=calendar.duplicate(true)
	var opening := principal
	for number in range(1,97):
		var interest := opening / 150 + int(opening % 150 >= 75)
		var due := regular if number < 96 else opening + interest
		result.total_interest_cents += interest
		result.total_payment_cents += due
		opening -= due - interest
	return result

static func installment(terms: Dictionary, number: int) -> Dictionary:
	if number < 1 or number > 96 or not Clock.valid(terms.get("calendar",{})): return {}
	var opening: int = terms.principal_cents
	for index in range(1,number+1):
		var interest := opening / 150 + int(opening % 150 >= 75)
		var due: int = terms.regular_due_cents if index < 96 else opening + interest
		if index == number:
			return {"number":number,"due_cycle":Clock.month_end(12+number,terms.get("calendar",{})),"opening_principal_cents":opening,"principal_cents":due-interest,"interest_cents":interest,"payment_cents":due}
		opening -= due - interest
	return {}

static func effective_installment(terms: Dictionary, number: int, calendar: Dictionary = {}) -> Dictionary:
	var result:=installment(terms,number)
	if result.is_empty() or not Clock.valid(calendar):return {}
	result.due_cycle=Clock.retarget_cycle(result.due_cycle,terms.get("calendar",{}),calendar)
	return result if result.due_cycle>=0 else {}

static func create(run_id: StringName, trait_id: StringName, calendar: Dictionary = {}) -> Dictionary:
	var terms := schedule(trait_id,calendar)
	if run_id.is_empty() or terms.is_empty(): return {}
	return {"schema_version":VERSION,"account_id":StringName("%s:education" % run_id),"run_id":run_id,"trait_id":trait_id,"schedule":terms,"issued":0,"principal_paid_cents":0,"interest_paid_cents":0,"closed":false,"closed_cycle":-1,"early_payoff":false}

static func overlap_reserve(account: Dictionary, bank_terms: Dictionary, calendar: Dictionary = {}) -> int:
	if account.is_empty() or account.closed or bank_terms.is_empty(): return 0
	var first: int=Clock.retarget_cycle(bank_terms.first_due_cycle,bank_terms.get("calendar",{}),calendar)
	var last: int=Clock.retarget_cycle(bank_terms.last_due_cycle,bank_terms.get("calendar",{}),calendar)
	if first<0 or last<first:return -1
	var maximum := 0
	for number in range(int(account.issued)+1,97):
		var due := effective_installment(account.schedule,number,calendar)
		if due.is_empty():return -1
		if due.due_cycle > last: break
		if due.due_cycle >= first: maximum = maxi(maximum,due.payment_cents)
	return maximum
