extends "res://scripts/debug/education_native_route.gd"

var checks:=0
func verify(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)

func _run()->void:
	var mode:=_arg("--mode=","")
	var directory:=_arg("--directory=","")
	var trace:Dictionary={"mode":mode,"checks":0,"failures":0,"fixture":"Constructed RunState action and checkpoint acceptance; explicit funding is not balance evidence","cases":{}}
	var adapter:=StudioCheckpoint.new()
	var c:=CheckpointCoordinator.new();root.add_child(c)
	c.store._writer=TCPServer.new();verify(c.store._writer.listen(48973,"127.0.0.1")==OK,"Isolated fresh-process writer")
	var run:RunState
	if mode=="creation":
		run=RunState.new();run.initialize_cash(0)
		verify(run.create_studio_with_traits("Education restart acceptance",&"action",[&"college_dropout"]),"Normal active trait creation")
		c.attach(run)
	elif mode=="native_seed":
		var input:=directory.path_join("before-education-payoff.payload.json")
		var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
		run=adapter.hydrate(payload);verify(run!=null,"Genuine native earned seed validates")
		trace.fixture="Genuine legal native route checkpoint; no added funding"
		trace.input_sha256=FileAccess.get_sha256(input)
		c.attach(run)
	else:
		var inspected:=c.store.inspect();verify(inspected.status==&"valid","Fresh process finds valid saved generation")
		if inspected.status!=&"valid":quit(1);return
		var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://education-expected.json"))
		var original_hash:=FileAccess.get_sha256(inspected.path)
		run=c.load_current();verify(run!=null,"Cold Continue restores complete typed run")
		if run==null:quit(1);return
		verify(adapter.capture(run)==expected,"All fields, finance, account, credits, paid history and RNG match exact previous process")
		c.entered_studio(true)
		verify(FileAccess.get_sha256(inspected.path)==original_hash and not c.pending,"Continue does not rewrite original saved bytes")
		trace.before=adapter.capture(run);trace.original_path=inspected.path;trace.original_sha256=original_hash
		if mode=="native_rollback":
			trace.fixture="Genuine native route; unsaved mid-phase payoff rollback"
			var game:Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game);await process_frame
			var route:Dictionary={"actions":[],"errors":[],"blockers":[],"stop":""}
			verify(_begin_game(game,"Unsaved education payoff",&"action",route),"Legal project departure")
			c.in_studio=false
			verify(run.pay_off_education(run.get_education_payoff_quote()),"Elective payoff commits only active memory in unsaved phase")
			verify(c.store.inspect().payload==inspected.payload and FileAccess.get_sha256(inspected.path)==original_hash,"Unsaved mid-phase payoff leaves exact Studio generation")
			trace.cases.after_unsaved_payoff=run.get_studio_finance_snapshot();trace.unsaved=adapter.capture(run)
			trace.checks=checks;trace.failures=failures
			FileAccess.open(directory.path_join("restart-trace.json"),FileAccess.WRITE).store_string(JSON.stringify(trace))
			game.queue_free();c.queue_free();await process_frame;quit(failures);return
		c.in_studio=false
	trace.cases.before=run.get_studio_finance_snapshot()
	match mode:
		"month12":
			verify(run.add_cash_cents(20000000,&"financing_in",&"education_acceptance_fixture"),"Explicit long-horizon acceptance funding recorded once")
			while run.get_completed_run_cycles()<24:verify(run.complete_productive_action(),"Journaled grace productive action")
			verify(run.get_studio_finance_snapshot().education.issued==0,"Month12 still has zero education bills/interest")
		"first_partial":
			verify(run.complete_productive_action(),"Cycle25 grace half")
			verify(run.spend_cash_cents(run.get_cash_cents()-50100,&"other_expense",&"education_acceptance_shortage"),"Declared fixture creates exact shortage without state injection")
			verify(run.complete_productive_action(),"First due through actual cycle26 pipeline")
			var account:Dictionary=run.get_studio_finance_snapshot().education
			verify(account.issued==1 and account.interest_paid_cents==100 and account.principal_paid_cents==0,"First due100c pays original interest only")
		"partial_continue":
			verify(run.complete_productive_action(),"Education-only arrears allow production after cold restore")
			verify(not run.get_bank_quote(50000,12).accepted,"Education arrears still exclude Bank quote")
		"recovery":
			verify(run.add_cash_cents(20000000,&"financing_in",&"education_acceptance_recovery"),"Explicit recovery funding routes through ordinary journal service")
			verify(run.complete_productive_action(),"Next original close updates credit once")
			verify(StudioFinanceLedger.get_unpaid(run.get_studio_finance_snapshot())==0,"Original due arrears recovered")
		"final_due":
			while run.get_completed_run_cycles()<215:verify(run.complete_productive_action(),"Actual accepted long-horizon cycle")
			verify(run.spend_cash_cents(run.get_cash_cents()-50000,&"other_expense",&"education_final_due_shortage"),"Exact final-shortage fixture spend")
			verify(run.complete_productive_action(),"Final due96 through cycle216 pipeline")
			verify(run.get_studio_finance_snapshot().education.issued==96 and run.get_education_payoff_quote().total_cents==7111,"Final original residual remains as arrears")
		"final_continue":
			verify(run.complete_productive_action(),"Final arrears permit nonboundary production after cold restore")
			verify(run.get_studio_finance_snapshot().education.issued==96 and run.get_education_payoff_quote().total_cents==7111,"No further education accrual after96")
		"final_recovery":
			verify(run.add_cash_cents(100000,&"financing_in",&"education_final_recovery"),"Journaled final overdue cash recovery")
			verify(run.complete_productive_action(),"Cycle218 no97th bill")
			verify(run.get_studio_finance_snapshot().education.closed and run.get_studio_finance_snapshot().education.issued==96,"Recovered final account closed persistently")
		"native_payoff":
			trace.fixture="Genuine native route restored after unsaved payoff rollback"
			verify(not run.get_studio_finance_snapshot().education.closed,"Uncommitted payoff rolled back to Studio")
			var quote:=run.get_education_payoff_quote();trace.quote=quote
			verify(run.pay_off_education(quote),"Restored actual earned cash pays education once")
			verify(not run.pay_off_education(quote),"Repeated payoff rejects")
		"native_check":
			trace.fixture="Genuine native route after saved education payoff"
			verify(run.get_studio_finance_snapshot().education.closed and run.get_education_payoff_quote().is_empty(),"Closure survives a fresh Continue")
			verify(not run.get_studio_finance_snapshot().bank_loans[0].closed,"Ordinary Bank account preserved through education payoff")
			for key in ["issued","principal_paid_cents","interest_paid_cents"]:
				var broken:=adapter.capture(run);broken.run.studio_finance.education[key]=str(int(broken.run.studio_finance.education[key])+1)
				verify(c.store.save(broken).status!=&"saved" and c.store.inspect().status==&"valid","Corrupt account save cannot replace current valid generation")
		"final_check":verify(run.get_studio_finance_snapshot().education.closed and run.get_studio_finance_snapshot().education.issued==96,"Final closure survives independent cold restore")
	trace.cases.after=run.get_studio_finance_snapshot()
	c.entered_studio();verify(c.flush() and c.failure.is_empty(),"Commit accepted Studio boundary")
	var payload:=adapter.capture(run);verify(not payload.is_empty(),"Final checkpoint validates: "+adapter.error)
	FileAccess.open("user://education-expected.json",FileAccess.WRITE).store_string(JSON.stringify(payload))
	trace.payload=payload;trace.saved=c.store.inspect();trace.checks=checks;trace.failures=failures
	FileAccess.open(directory.path_join("restart-trace.json"),FileAccess.WRITE).store_string(JSON.stringify(trace))
	c.queue_free();await process_frame
	print("EDUCATION RESTART ",mode," checks=",checks," failures=",failures);quit(failures)
