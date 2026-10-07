extends SceneTree

const B := preload("res://scripts/finance/outstanding_expenses.gd")
var checks: Array = []
var failures: Array = []
var examples: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, description: String) -> void:
	checks.append(description)
	if not value: failures.append(description)

func _run() -> void:
	# Native typed bill hooks; no payroll producer is connected or modified.
	for count in [1,2,3]:
		var cash := 50500
		var rent := B.create_bill(&"rent:1",&"studio",&"rent",2,50000)
		var bills: Array = [rent]
		for i in range(count): bills.append(B.create_bill(StringName("pay:%d:1" % i),StringName("employee:%d" % i),&"payroll",2,1000))
		for bill: Dictionary in bills:
			var paid := mini(cash,int(bill.unpaid_cents))
			cash -= paid
			_check(B.service(bill,paid,2,1),"Native initial partial service %d/%s" % [count,bill.bill_id])
		_check(cash==0 and bills[0].unpaid_cents==0,"Rent-before-payroll tie order %d" % count)
		_check(bills[1].unpaid_cents==500 and bills[1].due_cycle==2,"Payroll keeps first due and exact partial balance %d" % count)
		var credit := B.close_month(B.create_credit(),bills,1,-count*1000)
		_check(credit.score==595,"One payroll category penalty, independent of employee count %d" % count)
		_check(B.close_month(credit,bills,1,100000).is_empty(),"Duplicate credit close rejected %d" % count)
		var receipt: int = count*1000-500+123
		cash=receipt
		for bill: Dictionary in bills:
			if bill.unpaid_cents==0: continue
			var paid := mini(cash,int(bill.unpaid_cents))
			cash-=paid
			_check(B.service(bill,paid,2,2),"Native zero-cycle receipt recovery %d/%s" % [count,bill.bill_id])
		_check(cash==123 and bills.all(func(v: Dictionary):return v.unpaid_cents==0),"Exact recovery remainder %d" % count)
		_check(bills[1].late and bills[1].due_cycle==2 and bills[1].payments.size()==2,"Recovery preserves late history and original age %d" % count)
		var recovered := B.close_month(credit,bills,2,0)
		_check(recovered.score==595,"Opening-boundary recovery does not repeat old penalty %d" % count)
		var restored: Array = bytes_to_var(var_to_bytes(bills))
		_check(restored==bills and restored.all(func(v: Dictionary):return B.valid_bill(v)),"Typed bill byte reconstruction %d" % count)
		examples.append({"count":count,"monthly_payroll_cents":count*1000,"initial_cash_cents":50500,"credit_after_first_close":credit,"receipt_cents":receipt,"cash_after_recovery_cents":cash,"bills":bills,"credit_next_close":recovered})
	# Age escalation, partial recovery and simultaneous rent/payroll categories.
	var aged := B.create_bill(&"pay:age",&"employee:age",&"payroll",2,1000)
	_check(B.service(aged,0,2,1),"New payroll shortfall marked late")
	var credit := B.close_month(B.create_credit(),[aged],1,0)
	credit = B.close_month(credit,[aged],2,0)
	_check(credit.score==585,"One-month payroll age uses native ten-point tier")
	_check(B.service(aged,250,5,3) and aged.unpaid_cents==750 and aged.due_cycle==2,"Later partial receipt does not reset due age")
	credit = B.close_month(credit,[aged],3,0)
	_check(credit.score==570,"Two-month payroll age uses native fifteen-point tier")
	var late_rent := B.create_bill(&"rent:late",&"studio",&"rent",2,50000)
	_check(B.service(late_rent,0,2,1),"Rent category constructed independently")
	var late_pay := B.create_bill(&"pay:simultaneous",&"employee:simultaneous",&"payroll",2,1000)
	_check(B.service(late_pay,0,2,1),"Payroll category constructed independently")
	var both := B.close_month(B.create_credit(),[late_rent,late_pay],1,0)
	_check(both.score==590,"Rent and payroll categories add once each")
	var out := {"checks":checks.size(),"failures":failures,"examples":examples,"limit":"Constructed native typed bill hooks; employee state and payroll production are absent. Byte reconstruction is not durable save/restart."}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): FileAccess.open(arg.trim_prefix("--out="),FileAccess.WRITE).store_string(JSON.stringify(out,"  "))
	print("EMPLOYEE PROTOCOL checks=",checks.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
