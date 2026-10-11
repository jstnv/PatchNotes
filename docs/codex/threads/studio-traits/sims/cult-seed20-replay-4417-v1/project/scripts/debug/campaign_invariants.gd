## Stable invariant IDs for bounded stress tests and exact failure reduction.
## Read-only assertions; these are not new gameplay validation or policy rules.
extends RefCounted

const Replay := preload("res://scripts/simulation/development_replay.gd")
const Finance := preload("res://scripts/finance/studio_finance_ledger.gd")

static func capture(session: RefCounted) -> Dictionary:
	var releases: Dictionary = {}
	for id: StringName in session.run.get_released_game_ids(): releases[id] = session.run.get_release_metadata(id)
	return {"state":Replay.digest(Replay.state(session)),"rng":session.run.random_streams.snapshot(),"sequence":session.sequence,"cycle":session.run.get_completed_run_cycles(),"ledger":session.run.get_studio_finance_snapshot(),"releases":releases}

static func _require(ok: bool,label: String,failures: Array[String]) -> void:
	if not ok and label not in failures: failures.append(label)

static func check(session: RefCounted,before: Dictionary,request: Dictionary,result: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var run: RunState = session.run
	var cycle: int = run.get_completed_run_cycles()
	var ledger: Dictionary = run.get_studio_finance_snapshot()
	var cash: Variant = run.get_cash_cents()
	_require(cash is int and cash >= 0,"money.cash_nonnegative_exact_integer",failures)
	_require(run.get_fans() is int and run.get_fans() >= 0,"fans.nonnegative_exact_integer",failures)
	_require(Finance.report(ledger,cycle,cash).get("available",false),"finance.journal_reconciles",failures)
	_require(cycle >= int(before.cycle) and cycle <= int(before.cycle)+1,"calendar.single_cycle_command",failures)
	# RunState's month is the absolute month ordinal, including after Year 1980.
	_require(run.get_current_year() == 1980+cycle/24 and run.get_current_month() == cycle/2+1,"calendar.matches_cycle",failures)
	_require(session.sequence == int(before.sequence)+int(result.get("ok",false)),"command.accepted_sequence_once",failures)
	if not result.get("ok",false):
		_require(before.state == Replay.digest(Replay.state(session)),"rejection.state_atomic",failures)
		_require(before.rng == run.random_streams.snapshot(),"rejection.rng_atomic",failures)
		_require(result.get("events",[]).is_empty(),"rejection.no_events",failures)
	else:
		_require(result.get("rng_before") == before.rng and result.get("rng_after") == run.random_streams.snapshot(),"rng.result_matches_authority",failures)
		for ordinal in range(result.get("events",[]).size()):
			_require(result.events[ordinal].get("event_id") == "%s:%d:%d" % [request.run_id,session.sequence,ordinal],"event.unique_ordered_identity",failures)
	for field in ["transactions","actions"]:
		var prior: Array = before.ledger.get(field,[])
		var current: Array = ledger.get(field,[])
		_require(current.size() >= prior.size() and current.slice(0,prior.size()) == prior,"finance."+field+"_append_only",failures)
	var preceding_cash := 0
	var sequence := 1
	for transaction: Dictionary in ledger.get("transactions",[]):
		for field in ["cash_before_cents","cash_after_cents","cash_delta_cents","amount_cents"]:
			_require(transaction.get(field) is int,"finance.transaction_integer_money",failures)
		_require(transaction.cash_before_cents == preceding_cash and transaction.cash_after_cents == transaction.cash_before_cents+transaction.cash_delta_cents,"finance.transaction_cash_chain",failures)
		_require(transaction.sequence == sequence,"finance.transaction_sequence_once",failures)
		preceding_cash = transaction.cash_after_cents
		sequence += 1
	_require(preceding_cash == cash,"finance.transaction_final_cash",failures)
	var months: Dictionary = {}
	for month: Dictionary in ledger.get("monthly_rows",[]):
		_require(not months.has(month.month) and month.month >= 1 and month.month <= cycle/2+1,"finance.month_row_once",failures)
		months[month.month] = true
	var bills: Dictionary = {}
	for bill: Dictionary in ledger.get("obligations",[]):
		_require(not bills.has(bill.bill_id),"finance.obligation_once",failures)
		bills[bill.bill_id] = true
		_require(bill.unpaid_cents is int and bill.unpaid_cents >= 0,"finance.obligation_exact_balance",failures)
	for id: StringName in before.releases:
		_require(run.get_release_metadata(id) == before.releases[id],"release.history_immutable",failures)
	var released: Array[StringName] = run.get_released_game_ids()
	_require(released.size() == before.releases.size()+int(result.get("ok",false) and request.type == &"launch"),"release.registration_once",failures)
	var seen: Dictionary = {}
	for id: StringName in released:
		_require(not seen.has(id),"release.unique_identity",failures)
		seen[id] = true
	return failures
