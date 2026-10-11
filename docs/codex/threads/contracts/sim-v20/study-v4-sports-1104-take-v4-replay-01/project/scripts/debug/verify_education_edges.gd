extends "res://scripts/debug/verify_education_debt.gd"
var vectors := {}

func _run() -> void:
	var l:=fixture(&"college_dropout")
	for i in range(4): l=step(l,0,200000 if i%2 else 0)
	l=step(l)
	for pair in [[9,0],[10,7068],[105,7111]]:
		var q:=F.bank_quote(l,50000,pair[0],&"education-test")
		check(q.schedule.first_due_cycle==8 and q.obligations_cents==pair[1],"Odd acceptance reserves actual first-full-month overlap")
	var quote:=F.bank_quote(l,50000,12,&"education-test")
	l=F.accept_loan(l,quote,&"education-test").ledger
	l=move(l,25)
	var next_bank:=BankLoan.installment(quote.schedule,10)
	var available:int=50000+next_bank.payment_cents+100
	l=F.plan(l,25,l.cash_cents,-(l.cash_cents-available),&"other_expense").ledger
	l=step(l)
	check(l.obligations[-1].expense_type==&"student_loan" and l.obligations[-1].interest_paid_cents==100,"Same-date Bank precedes education after rent")
	cases["same-date-shortage"]=l.duplicate(true)
	l=step(l)
	next_bank=BankLoan.installment(quote.schedule,11)
	l=step(l,50000+int(next_bank.payment_cents))
	check(F.get_blocking_unpaid(l)>0,"Older education consumes available cash ahead of newer Bank due")
	cases["older-education-newer-bank"]=l.duplicate(true)
	var before:=l.duplicate(true)
	check(F.plan(l,29,l.cash_cents,F.get_blocking_unpaid(l),&"other_income",0,0,true).is_empty() and l==before,"Recovery cannot bypass Bank arrears after older education service")
	var recovered:=step(l,F.get_unpaid(l))
	check(F.get_unpaid(recovered)==0 and F._is_valid(recovered),"Sufficient genuine action income clears ordered debts once")
	cases["mixed-recovered"]=recovered
	# Cash-positive arrears cannot persist after normal automatic service. These
	# explicit private-plan vectors exercise approved elective ordering; public
	# ledger APIs must reject their deliberately unjournaled cash override.
	var vector:=before.duplicate(true)
	var edu:=F._education_payoff_unchecked(vector)
	var required:int=edu.required_cash_cents
	vector.cash_cents=required
	var result:=F._apply(vector,28,required,0,&"calendar",0,0,false,edu.account_id,true,edu)
	check(not result.is_empty() and result.cash_cents==0 and result.ledger.education.closed,"Elective education payoff services newer Bank before education")
	check(F.pay_off_education(vector,edu).is_empty(),"Unjournaled cash vector cannot enter public finance API")
	if not result.is_empty(): vectors["education-payoff-mixed"]={"before":vector.duplicate(true),"after":result.ledger,"quote":edu,"isolated_payment_plan":true}
	var bank_payoff:=F._payoff_unchecked(vector,quote.loan_id)
	vector.cash_cents=bank_payoff.total_cents
	var bank_result:=F._apply(vector,28,vector.cash_cents,0,&"calendar",0,0,false,quote.loan_id,true,bank_payoff)
	check(not bank_result.is_empty() and bank_result.ledger.bank_loans[0].closed and bank_result.ledger.education==vector.education,"Existing elective Bank payoff does not add an education reserve")
	if not bank_result.is_empty(): vectors["bank-payoff-with-education"]={"before":vector,"after":bank_result.ledger,"quote":bank_payoff,"isolated_payment_plan":true}
	var all_due:=fixture(&"college_dropout")
	for i in range(4):all_due=step(all_due,0,200000 if i%2 else 0)
	all_due=F.accept_loan(all_due,F.bank_quote(all_due,50000,12,&"education-test"),&"education-test").ledger
	all_due=F.hire_employee(all_due,F.hire_quote(all_due,&"education-test"),&"education-test").ledger
	all_due=move(all_due,25)
	all_due=F.plan(all_due,25,all_due.cash_cents,-all_due.cash_cents,&"other_expense").ledger
	all_due=step(all_due)
	cases["four-category-arrears"]=all_due.duplicate(true)
	var all_quote:=F._education_payoff_unchecked(all_due)
	var all_vector:=all_due.duplicate(true);all_vector.cash_cents=all_quote.required_cash_cents
	var all_paid:=F._apply(all_vector,26,all_vector.cash_cents,0,&"calendar",0,0,false,all_quote.account_id,true,all_quote)
	check(not all_paid.is_empty() and all_paid.cash_cents==0 and all_paid.ledger.education.closed and F._blocking_unpaid_unchecked(all_paid.ledger)==0,"Education payoff covers already-due rent, payroll and Bank before education exactly")
	if not all_paid.is_empty():vectors["education-payoff-all-categories"]={"before":all_vector,"after":all_paid.ledger,"quote":all_quote,"isolated_payment_plan":true}
	var short_vector:=all_vector.duplicate(true);short_vector.cash_cents-=1
	check(F._apply(short_vector,26,short_vector.cash_cents,0,&"calendar",0,0,false,all_quote.account_id,true,all_quote).is_empty(),"One cent short of full mixed reserve rejects entire elective plan")
	var final:=move(fixture(&"college_dropout"),215)
	final=F.plan(final,215,final.cash_cents,-(final.cash_cents-50000),&"other_expense").ledger
	final=step(final)
	check(final.education.issued==96 and not final.education.closed and F.education_payoff_quote(final).total_cents==7111,"Final due arrears remain payable with exact residual interest")
	cases["final-due-arrears"]=final.duplicate(true)
	final=step(final)
	check(final.education.issued==96 and final.education.interest_paid_cents==178524,"After final due no scheduled interest is added")
	var due_quote:=F._education_payoff_unchecked(final)
	var final_vector:=final.duplicate(true)
	final_vector.cash_cents=due_quote.required_cash_cents
	# Non-boundary current row exists; represent this isolated cash vector's opening.
	final_vector.monthly_rows[-1].closing_cash_cents=final_vector.cash_cents
	final_vector.monthly_rows[-1].financing_in_cents+=final_vector.cash_cents
	var final_paid:=F._apply(final_vector,217,final_vector.cash_cents,0,&"calendar",0,0,false,due_quote.account_id,true,due_quote)
	check(not final_paid.is_empty() and final_paid.ledger.education.closed and final_paid.ledger.education.issued==96,"Explicit payoff after due 96 closes existing arrears")
	if not final_paid.is_empty(): vectors["final-payoff"]={"before":final_vector,"after":final_paid.ledger,"quote":due_quote,"isolated_payment_plan":true}
	final=step(final,100000)
	check(final.education.closed and final.education.issued==96 and F._is_valid(final),"Native income recovery after final due closes without bill 97")
	cases["final-arrears-recovered"]=final
	var old:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/education-legacy-fixtures-v1/v5-graduate.payload.json"))
	old.run.studio_finance.monthly_rent_cents="50001"
	check(StudioCheckpoint.new().hydrate(old)==null,"Malformed old rent rejects without runtime error")
	var directory:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--directory="):directory=arg.trim_prefix("--directory=")
	if not directory.is_empty():FileAccess.open(directory.path_join("edge-cases.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"ordering_vectors":vectors}))
	print("Education edges: %d checks, %d failures" % [checks,failures])
	quit(failures)
