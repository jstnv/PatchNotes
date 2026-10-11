extends SceneTree
const F := preload("res://scripts/finance/studio_finance_ledger.gd")
var failures := 0
var checks := 0
var cases := {}
var native_schedules := {}

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL: "+label)

func _initialize() -> void: call_deferred("_run")

func fixture(trait_id: StringName, cash: int = 20000000) -> Dictionary:
	# Explicitly funded accounting fixture, not player balance evidence.
	return F.open_education(F.create(cash),&"education-test",trait_id).ledger

func step(ledger: Dictionary, income: int = 0, sales: int = 0) -> Dictionary:
	var result := F.plan(ledger,ledger.last_cycle+1,ledger.cash_cents,income,&"other_income" if income else &"calendar",sales,sales,true)
	check(not result.is_empty(),"Constructed native finance action at %d" % (ledger.last_cycle+1))
	return result.get("ledger",ledger)

func move(ledger: Dictionary, cycle: int) -> Dictionary:
	while ledger.last_cycle < cycle: ledger = step(ledger)
	return ledger

func _run() -> void:
	for id: StringName in [&"college_dropout",&"graduate"]:
		var terms := EducationDebt.schedule(id)
		native_schedules[String(id)] = {"terms":terms,"installments":[]}
		var principal := 0
		var interest := 0
		var opening: int = terms.principal_cents
		for number in range(1,97):
			var due := EducationDebt.installment(terms,number)
			native_schedules[String(id)].installments.append(due)
			check(due.opening_principal_cents==opening and due.due_cycle==24+number*2,"Scheduled original principal and due date")
			opening -= int(due.principal_cents)
			principal += int(due.principal_cents); interest += int(due.interest_cents)
		check(opening==0 and principal==terms.principal_cents,"All scheduled principal reconciles")
		check(interest==(178571 if id==&"college_dropout" else 714263),"Approved total interest")
		check(EducationDebt.installment(terms,96).payment_cents==(7111 if id==&"college_dropout" else 28328),"Approved final residual cents")
		var l := fixture(id)
		var initial := F.education_payoff_quote(l)
		check(initial.total_cents==terms.principal_cents and initial.interest_cents==0,"Creation payoff excludes all future interest")
		l = move(l,25)
		check(l.education.issued==0 and l.monthly_rows.all(func(row): return row.interest_cents==0),"Months 1–12 and first half of 13 have no interest/bill")
		l = step(l)
		check(l.education.issued==1 and F.education_payoff_quote(l).total_cents==(496265 if id==&"college_dropout" else 1985060),"First paid due leaves approved principal payoff")
		cases[String(id)+"-first"] = l.duplicate(true)
		l = move(l,218)
		check(l.education.closed and l.education.issued==96 and l.education.principal_paid_cents==principal and l.education.interest_paid_cents==interest,"Final due closes exact account without bill 97")
		check(l.obligations.filter(func(b): return b.expense_type==&"student_loan").size()==96 and F._is_valid(l),"Full 96-bill journal replays")
		cases[String(id)+"-final"] = l.duplicate(true)
		for cash in [50000,50100]:
			var partial := move(fixture(id),25)
			partial = F.plan(partial,25,partial.cash_cents,-(partial.cash_cents-cash),&"other_expense").ledger
			partial = step(partial)
			var bill: Dictionary = partial.obligations[-1]
			check(bill.expense_type==&"student_loan" and bill.interest_paid_cents==cash-50000 and bill.principal_paid_cents==0,"Education partial covers interest first")
			var q := F.education_payoff_quote(partial)
			check(q.total_cents==terms.principal_cents+EducationDebt.installment(terms,1).interest_cents-(cash-50000),"Missed/partial payoff includes due interest once")
			var before := partial.duplicate(true)
			check(F.pay_off_education(partial,q).is_empty() and partial==before,"Unaffordable arrears payoff is atomic")
			partial = step(partial)
			check(F.get_blocking_unpaid(partial)==0 and F.get_unpaid(partial)>0,"Education-only arrears permit productive continuation")
			check(not F.bank_quote(partial,50000,12,&"education-test").accepted,"Education arrears disqualify new Bank borrowing")
			cases[String(id)+"-partial-"+str(cash)] = partial
	_verify_payoff()
	_verify_bank()
	_verify_creation_and_checkpoints()
	var directory := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--directory="): directory=arg.trim_prefix("--directory=")
	if not directory.is_empty(): FileAccess.open(directory.path_join("focused-cases.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases,"schedules":native_schedules}))
	print("Education verification: %d checks, %d failures" % [checks,failures])
	quit(failures)

func _verify_payoff() -> void:
	for cycle in [0,24,26,27,216]:
		var l := move(fixture(&"college_dropout"),cycle)
		if l.education.closed: continue
		var q := F.education_payoff_quote(l)
		var before := l.duplicate(true)
		var invalid := q.duplicate(true); invalid.total_cents += 1
		check(F.pay_off_education(l,invalid).is_empty() and l==before,"Malformed quote rejects without journal change")
		var updated: Dictionary = F.plan(l,cycle,l.cash_cents,1,&"other_income").ledger
		check(F.pay_off_education(updated,q).is_empty(),"Any finance revision invalidates payoff quote")
		var paid := F.pay_off_education(l,q)
		check(not paid.is_empty() and paid.cash_cents==l.cash_cents-q.required_cash_cents,"Exact zero-cycle education payoff")
		l=paid.ledger
		check(l.education.closed and l.last_cycle==cycle and l.credit==before.credit and F._is_valid(l),"Closure preserves calendar and credit with replayable provenance")
		check(F.pay_off_education(l,q).is_empty(),"Duplicate payoff is inert")
		var issued: int=l.education.issued
		l=move(l,cycle+4)
		check(l.education.issued==issued,"Payoff prevents future education bills")
		cases["payoff-"+str(cycle)]=l

func _verify_bank() -> void:
	var l:=fixture(&"graduate")
	for i in range(4): l=step(l,0,200000 if i%2 else 0)
	for pair in [[10,0],[11,28273],[106,28328]]:
		var quote:=F.bank_quote(l,50000,pair[0],&"education-test")
		check(quote.obligations_cents==pair[1] and quote.capacity_cents==(200000-50000-pair[1])/4,"Bank quote reserves exact maximum overlapping education due")
		if quote.accepted: check(not F.accept_loan(l,quote,&"education-test").is_empty(),"Acceptance revalidates same education reserve")
	var q:=F.bank_quote(l,50000,12,&"education-test")
	l=F.accept_loan(l,q,&"education-test").ledger
	l=move(l,26)
	var payoff:=F.payoff_quote(l,q.loan_id)
	check(not F.pay_off(l,payoff).is_empty(),"Existing Bank payoff remains available with active education")
	cases["bank-overlap"]=l

func _verify_creation_and_checkpoints() -> void:
	for pair in [[[],570000],[[&"college_dropout"],580000],[[&"graduate"],600000],[[&"family_funding",&"studio_buzz",&"graduate"],615000]]:
		var run:=RunState.new(); run.initialize_cash(0)
		check(run.create_studio_with_traits("Education",&"action",pair[0]) and run.get_cash_cents()==pair[1],"Approved startup cash with no debt principal deposit")
		var before:=run.get_studio_finance_snapshot()
		check(not run.create_studio_with_traits("Again",&"action",pair[0]) and run.get_studio_finance_snapshot()==before,"Duplicate confirmation cannot add debt or cash")
		var adapter:=StudioCheckpoint.new()
		var payload:=adapter.capture(run)
		check(not payload.is_empty(),"New education checkpoint captures: "+adapter.error)
		if payload.is_empty(): continue
		var restored:=adapter.hydrate(payload)
		check(restored!=null and adapter.capture(restored)==payload,"New typed checkpoint restores exactly")
		if not before.education.is_empty():
			for property in ["issued","principal_paid_cents","interest_paid_cents"]:
				var corrupt:Dictionary=CheckpointCodec.new().decode(payload,CheckpointSchema.root())
				corrupt.run.studio_finance.education[property]+=1
				check(not adapter.validate(CheckpointCodec.new().encode(corrupt,CheckpointSchema.root())).is_empty(),"Corrupt education counter rejected: "+property)
		cases["creation-"+str(pair[1])]=before
	var old_directory:="res://../docs/codex/findings/education-legacy-fixtures-v1"
	for version in [3,4,5]:
		for id in ["college_dropout","graduate"]:
			var path:=old_directory.path_join("v%d-%s.payload.json" % [version,id])
			var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
			var adapter:=StudioCheckpoint.new()
			var restored:=adapter.hydrate(payload)
			check(restored!=null,"Exact prior education preview restores: "+adapter.error)
			if restored!=null: check(restored.get_studio_traits().version==version and restored.get_cash_cents()==570000 and restored.get_studio_finance_snapshot().education.is_empty(),"Prior previews retain zero debt/refund and original funding")
