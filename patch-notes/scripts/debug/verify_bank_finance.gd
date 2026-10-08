extends SceneTree
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
const B := preload("res://scripts/finance/bank_loan.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func step(l: Dictionary, earned: int = 0) -> Dictionary:
	var p := F.plan(l,l.last_cycle+1,l.cash_cents,0,&"calendar",earned,earned,true)
	check(not p.is_empty(),"Native productive action")
	return p.get("ledger",{})
func ready_ledger(start: int = 550000, latest: int = 200000) -> Dictionary:
	var l := F.create(start)
	l = step(l)
	l = step(l,200000)
	l = step(l)
	return step(l,latest)
func _initialize() -> void:
	for start in [550000,570000]:
		for odd in [false,true]:
			var l := ready_ledger(start)
			if odd: l = step(l)
			var before := l.duplicate(true)
			var q := F.bank_quote(l,50001,3,&"run")
			check(q.accepted and q.capacity_cents == 37500 and l == before,"Passive exact capacity")
			check(F.accept_loan(l,q,&"other").is_empty() and l == before,"Cross-run reject")
			var accepted := F.accept_loan(l,q,&"run")
			check(not accepted.is_empty(),"Accept")
			l = accepted.ledger
			check(l.cash_cents == before.cash_cents+50001 and l.last_cycle == before.last_cycle,"Zero-cycle proceeds")
			check(F.report(l,l.last_cycle,l.cash_cents).available,"Accepted journal reconstructs")
			check(F.accept_loan(l,q,&"run").is_empty(),"Duplicate/stale quote")
			check(not F.bank_quote(l,50000,12,&"run").accepted,"Second active loan")
			var due: int = q.schedule.first_due_cycle
			while l.last_cycle < q.schedule.last_due_cycle:
				l = step(l)
				check(F.report(l,l.last_cycle,l.cash_cents).available,"Every scheduled journal reconstructs")
			check(l.bank_loans[0].closed and l.bank_loans[0].principal_paid_cents == 50001,"Full term principal closes")
			check(l.bank_loans[0].interest_paid_cents == q.schedule.total_interest_cents,"Full term interest")
			check(l.obligations.filter(func(x): return x.expense_type == &"bank_installment")[0].due_cycle == due,"First full month provenance")
			var decoded: Dictionary = bytes_to_var(var_to_bytes(l))
			check(decoded == l and F.report(decoded,l.last_cycle,l.cash_cents).available,"Typed complete state roundtrip")
	for latest in [0,1000]:
		check(not F.bank_quote(ready_ledger(550000,latest),50000,12,&"run").accepted,"Zero/weak latest cannot borrow")
	for elapsed in [0,1,2,3,4]:
		var l := ready_ledger()
		var q := F.bank_quote(l,50000,12,&"run")
		l = F.accept_loan(l,q,&"run").ledger
		for i in range(elapsed): l = step(l)
		var payoff := F.payoff_quote(l,q.loan_id)
		var cash: int = l.cash_cents
		var result := F.pay_off(l,payoff)
		check(not result.is_empty(),"Before/at/after due payoff")
		l = result.ledger
		check(l.cash_cents == cash-payoff.total_cents and l.bank_loans[0].closed,"Exact payoff cash and closure")
		check(F.report(l,l.last_cycle,l.cash_cents).available and F.pay_off(l,payoff).is_empty(),"Payoff replay and duplicate protection")
		var interest: int = l.bank_loans[0].interest_paid_cents
		l = step(step(l))
		check(l.bank_loans[0].interest_paid_cents == interest,"Future interest waived")
	var l := ready_ledger()
	var q := F.bank_quote(l,50000,12,&"run")
	var stale: Dictionary = F.plan(l,4,l.cash_cents,1,&"other_income").ledger
	check(F.accept_loan(stale,q,&"run").is_empty(),"Receipt invalidates offer revision")
	l = F.accept_loan(l,q,&"run").ledger
	l = F.plan(l,4,l.cash_cents, -(l.cash_cents-50100), &"other_expense").ledger
	l = step(step(l))
	var bill: Dictionary = l.obligations[-1]
	check(bill.expense_type == &"bank_installment" and bill.interest_paid_cents == 100 and bill.principal_paid_cents == 0 and bill.late,"Rent priority and partial interest first")
	var report := F.report(l,6,0)
	check(report.available and report.unpaid_rent_cents == 0 and report.total_overdue_cents == 4567,"Total overdue distinct from rent")
	check(l.monthly_rows[2].interest_cents == 500 and l.monthly_rows[2].interest_paid_cents == 100,"Interest accrual distinct from cash")
	check(l.credit.history[-1].reasons.size() == 1,"One bank category penalty")
	var original := l.duplicate(true)
	check(F.plan(l,7,0,0,&"calendar",0,0,true).is_empty() and l == original,"Blocked action atomic")
	check(F.pay_off(l,F.payoff_quote(l,q.loan_id)).is_empty() and l == original,"Unaffordable payoff atomic")
	l = F.plan(l,6,0,200,&"other_income").ledger
	check(l.obligations[-1].interest_paid_cents == 300 and l.obligations[-1].due_cycle == 6,"Receipt partial recovery retains due")
	var payoff := F.payoff_quote(l,q.loan_id)
	l = F.plan(l,6,0,payoff.total_cents,&"other_income").ledger
	check(F.pay_off(l,payoff).is_empty(),"Recovery invalidates payoff quote")
	payoff = F.payoff_quote(l,q.loan_id)
	l = F.pay_off(l,payoff).ledger
	check(l.bank_loans[0].closed and l.obligations[-1].late and l.obligations[-1].paid_cents == 4667,"Late payoff preserves bill history")
	check(F.report(l,6,l.cash_cents).available,"Late payoff reconstruction")
	for field in ["principal_paid_cents","interest_paid_cents","issued","closed","schedule","loan_id"]:
		var broken := l.duplicate(true)
		broken.bank_loans[0][field] = null
		check(not F.report(broken,6,l.cash_cents).available,"Tampered loan rejects: "+field)
	print("Bank finance: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

