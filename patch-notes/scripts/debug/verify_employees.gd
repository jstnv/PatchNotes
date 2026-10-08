extends "res://scripts/debug/verify_bank_finance.gd"
const E := preload("res://scripts/employees/employee_roster.gd")
func card(id: StringName, type: StringName, primary: StringName, secondary: StringName = &"") -> CardData:
	var c := CardData.new()
	c.id=id
	c.card_type=type
	c.primary_stat=primary
	c.secondary_stat=secondary
	return c
func _initialize() -> void:
	var normal := {0:25,1:25,2:25,3:25}
	var changed := {0:40,1:20,2:20,3:20}
	var pass_card := card(&"pass",&"pass",&"graphics")
	var feature := card(&"feature",&"feature",&"sound",&"graphics")
	var matching := [pass_card,feature,pass_card,pass_card]
	var nonmatch := [card(&"p",&"pass",&"technology"),feature,feature,feature]
	var state := E.hire(E.create(&"studio"),&"employee_a",12)
	check(not state.is_empty() and not state.employees.employee_a.trained,"Stable employee hired without training")
	check(E.matches(E.card_facts(matching)) and not E.matches(E.card_facts(nonmatch)),"Printed secondary match and nonmatch")
	check(E.matches(E.card_facts([pass_card,card(&"f",&"feature",&"graphics"),pass_card,pass_card])),"Printed primary match")
	check(E.plan_hand(state,&"project",&"design",0,11,matching,normal).is_empty(),"No pre-hire progress")
	check(E.plan_hand(state,&"project",&"design",0,13,matching,normal,changed).is_empty(),"Training hand cannot spend new benefit")
	var alpha := E.plan_hand(state,&"project",&"alpha",0,13,matching,normal)
	check(not alpha.employees.employee_a.trained,"Alpha does not train")
	state=E.plan_hand(state,&"project",&"design",0,13,matching,normal)
	check(state.employees.employee_a.trained and E.available(state,&"project"),"Committed Design trains permanently")
	var before := state.duplicate(true)
	check(E.plan_hand(state,&"project",&"design",0,13,matching,normal).is_empty() and state==before,"Duplicate action rejects")
	check(E.plan_hand(state,&"project",&"alpha",1,14,matching,normal,normal).is_empty(),"Unchanged choice consumes nothing")
	check(E.plan_hand(state,&"project",&"alpha",1,14,matching,normal,{0:100}).is_empty(),"Invalid choice consumes nothing")
	state=E.plan_hand(state,&"project",&"alpha",1,14,matching,normal)
	check(E.available(state,&"project"),"Declining retains use")
	state=E.plan_hand(state,&"project",&"alpha",2,15,matching,normal,changed)
	check(not E.available(state,&"project") and E.available(state,&"next"),"Use once per project, next project resets use")
	check(E.plan_hand(state,&"project",&"alpha",3,16,matching,normal,changed).is_empty(),"Second use rejects")
	state=E.plan_hand(state,&"next",&"design",0,16,matching,normal,changed)
	check(state.employees.employee_a.trained and not E.available(state,&"next"),"Previously trained employee can use first matching hand")
	var reconstructed: Dictionary = bytes_to_var(var_to_bytes(state))
	check(E.valid(reconstructed) and reconstructed==state,"Lossless roster mapping")
	var broken := state.duplicate(true)
	broken.employees.employee_a.projects.clear()
	check(not E.valid(broken),"Reconstruction cannot reset uses")
	var multi := E.hire(state,&"employee_b",16)
	check(not multi.employees.employee_b.trained and multi.employees.employee_a.trained,"Constructed employee isolation")
	check(not E.available(multi,&"next"),"Untrained second employee does not inherit used benefit")
	for cycle in [4,5,6]:
		var l := ready_ledger()
		while l.last_cycle<cycle:l=step(l)
		var quote := F.hire_quote(l,&"owner")
		check(quote.first_due_cycle==cycle+2+cycle%2,"First full payroll month")
		var oldcash: int = l.cash_cents
		l=F.hire_employee(l,quote,&"owner").ledger
		check(l.cash_cents==oldcash-10000 and l.last_cycle==cycle,"Hire fee zero cycles")
		check(F.hire_employee(l,quote,&"owner").is_empty(),"Duplicate hire rejects")
		while l.last_cycle<quote.first_due_cycle:l=step(l)
		check(l.obligations[-1].expense_type==&"payroll" and l.obligations[-1].paid_cents==1000,"Native scheduled payroll")
		check(F.report(l,l.last_cycle,l.cash_cents).available,"Payroll journal reconstructs")
	var l := ready_ledger()
	var q := F.bank_quote(l,50000,12,&"owner")
	var hire := F.hire_quote(l,&"owner")
	var hired: Dictionary = F.hire_employee(l,hire,&"owner").ledger
	check(F.bank_quote(hired,50000,12,&"owner").capacity_cents==q.capacity_cents-250,"Payroll deducted once from Bank capacity")
	l=F.accept_loan(l,q,&"owner").ledger
	l=F.hire_employee(l,F.hire_quote(l,&"owner"),&"owner").ledger
	l=F.plan(l,4,l.cash_cents,-(l.cash_cents-50500),&"other_expense").ledger
	l=step(step(l))
	check(l.cash_cents==0 and l.obligations[-2].expense_type==&"payroll" and l.obligations[-2].paid_cents==500,"Rent then partial payroll")
	check(l.obligations[-1].expense_type==&"bank_installment" and l.obligations[-1].paid_cents==0,"Bank follows payroll")
	check(l.monthly_rows[2].payroll_due_cents==1000 and l.monthly_rows[2].payroll_paid_cents==500 and l.monthly_rows[2].payroll_unpaid_cents==500,"Payroll accrual and cash split")
	check(l.credit.history[-1].reasons.size()==2,"Payroll and bank categories charged once")
	var old := l.duplicate(true)
	check(F.plan(l,7,0,500,&"beta_income",0,0,true).is_empty() and old==l,"Insufficient recovery rejects atomically")
	l=F.plan(l,6,0,900,&"publisher_receipt").ledger
	check(l.obligations[-2].unpaid_cents==0 and l.obligations[-2].late and l.obligations[-1].interest_paid_cents==400,"Original-age payroll recovery then bank interest")
	check(l.employees[0].issued==1 and l.last_cycle==6,"Zero-cycle recovery issues no second payroll")
	check(F.report(l,6,0).available,"Mixed bills reconstruct")
	print("Employees: %d checks, %d failures" % [checks,failures])
	quit(failures)
