extends SceneTree
const F:=preload("res://scripts/finance/studio_finance_ledger.gd")
const Old:=preload("res://scripts/persistence/pre_usability/finance.gd")
var failures:=0
var checks:=0
func _initialize() -> void:_run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",message)
	if not ok:failures+=1
func step(l:Dictionary,sales:int=0) -> Dictionary:
	var result:=F.plan(l,l.last_cycle+1,l.cash_cents,0,&"calendar",sales,sales,true)
	check(not result.is_empty(),"Legal finance cycle")
	return result.get("ledger",{})
func _run() -> void:
	var l:=F.create(0)
	l=step(l);l=step(l)
	var frozen:=l.duplicate(true)
	var q:=F.bank_quote(l,9223372036854775807,12,&"recovery")
	check(q.get("accepted",false),"Cash-poor overdue Studio can borrow without prior sales")
	if q.get("accepted",false):
		check(q.schedule.principal_cents==150000 and q.get("minimum_principal_cents")==150000,"Floor facility is three actual rents, not requested millions")
		check(q.get("recovery_cents")==50000 and q.get("net_proceeds_cents")==100000,"Overdue payment is deducted from proceeds")
		check(l==frozen,"Quote is passive")
		for field:String in ["rules_version","recovery_cents","net_proceeds_cents","maximum_principal_cents","capacity_cents","requested_principal_cents"]:
			var forged:=q.duplicate(true)
			forged[field]=2.0 if field=="rules_version" else int(forged[field])+1
			check(F.accept_loan(l,forged,&"recovery").is_empty(),"Altered displayed/recovery terms reject: "+field)
		var accepted:=F.accept_loan(l,q,&"recovery")
		check(not accepted.is_empty(),"Qualified recovery commits")
		if not accepted.is_empty():
			l=accepted.ledger
			check(l.cash_cents==100000 and l.obligations[0].unpaid_cents==0 and l.obligations[0].due_cycle==2 and l.obligations[0].late,"Recovery pays original-due arrears and preserves late history")
			check(F.report(l,l.last_cycle,l.cash_cents).available,"New quote journal reconstructs")
			check(F.accept_loan(l,q,&"recovery").is_empty(),"Repeated recovery quote rejects")
			check(not F.bank_quote(l,150000,12,&"recovery").accepted,"One-time floor facility cannot stack rescue loans")
	var rich:=F.create(100000000)
	check(not F.bank_quote(rich,150000,12,&"rich").accepted,"Millionaire without operating sales has no emergency subsidy")
	var lease:=F.create(0,51500)
	var lease_q:=F.bank_quote(lease,50000,12,&"lease")
	check(lease_q.get("accepted",false) and lease_q.schedule.principal_cents==154500,"Minimum uses actual expensive rent")
	var sales:=F.create(550000)
	for earned:int in [0,400000,0,400000]:sales=step(sales,earned)
	var huge:=F.bank_quote(sales,9223372036854775807,12,&"sales")
	check(huge.get("accepted",false) and huge.schedule.principal_cents==huge.maximum_principal_cents,"Oversized request adjusts to qualified exact-cent maximum")
	if huge.get("accepted",false):
		check(huge.schedule.maximum_installment_cents<=huge.capacity_cents,"Adjusted schedule fits capacity")
		var borrowed:=F.accept_loan(sales,huge,&"sales")
		if not borrowed.is_empty():
			check(not F.bank_quote(borrowed.ledger,150000,12,&"sales").accepted,"Existing payments consume full shared capacity")
	var before:=sales.duplicate(true)
	for round in 3:
		var loan:=F.bank_quote(sales,150000,12,&"sales")
		if not loan.get("accepted",false):check(false,"Ordinary qualifying loan");break
		var result:=F.accept_loan(sales,loan,&"sales")
		if result.is_empty():check(false,"Ordinary loan commits");break
		sales=result.ledger
		var payoff:=F.payoff_quote(sales,loan.loan_id)
		var paid:=F.pay_off(sales,payoff)
		if paid.is_empty():check(false,"Immediate payoff commits");break
		sales=paid.ledger
	var unchanged_income := true
	for i in sales.monthly_rows.size():
		for key:String in ["sales_settled_cents","sales_net_earned_cents","net_profit_cents"]:
			unchanged_income = unchanged_income and sales.monthly_rows[i][key]==(before.monthly_rows[i][key] if i<before.monthly_rows.size() else 0)
	check(sales.cash_cents==before.cash_cents and unchanged_income and sales.credit==before.credit,"Borrow/payoff loops create no cash, operating income or credit")
	var old:=Old.create(550000)
	for earned:int in [0,200000,0,200000]:old=Old.plan(old,old.last_cycle+1,old.cash_cents,0,&"calendar",earned,earned,true).ledger
	var old_quote:=Old.bank_quote(old,50001,3,&"legacy")
	var old_borrowed:Dictionary=Old.accept_loan(old,old_quote,&"legacy").ledger
	check(F.report(old_borrowed,old_borrowed.last_cycle,old_borrowed.cash_cents).available,"Accepted v1 quote remains exactly replayable")
	var strained:Dictionary=F.plan(old_borrowed,old_borrowed.last_cycle,old_borrowed.cash_cents,-old_borrowed.cash_cents,&"other_expense").ledger
	strained=step(strained);strained=step(strained)
	var rescue:=F.bank_quote(strained,150000,12,&"legacy")
	check(rescue.get("accepted",false) and rescue.get("recovery_cents",0)>50000,"One-time recovery also covers overdue active Bank payments")
	check(F.accept_loan(old,old_quote,&"legacy").is_empty(),"New acceptance cannot bypass v2 rules with a legacy quote")
	for invalid:Variant in [-1,0,1.5,true,"150000",null]:check(not F.bank_quote(before,invalid,12,&"bad").get("accepted",false),"Malformed amount rejects")
	print("Usability Bank: %d checks, %d failures"%[checks,failures]);quit(failures)
