extends "res://scripts/debug/verify_primitive_branches.gd"

func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var path:=ProjectSettings.globalize_path("res://../docs/codex/findings/bank-publisher-final-20261017-v1/bank-before-cold/checkpoint.34.json")
	var payload:=CheckpointCodec.new().open_envelope(FileAccess.get_file_as_string(path))
	var session:=from_payload(payload)
	check(session!=null,"actual exported Studio51 prefix restores")
	if session==null:quit(1);return
	var initial: Dictionary=session.export_checkpoint()
	var tape:=Replay.begin(session)
	var rows: Array=[]
	var result:=Replay.record(session,tape,session.command(&"begin_development",{"name":"Bank-only guard","genre":"action","theme":"fantasy"}))
	check(result.ok and session.run.get_completed_run_cycles()==52,"legal begin Development reaches next due")
	var report: Dictionary=session.run.get_studio_finance_report()
	var blocking: Array=report.outstanding_expenses.filter(func(bill: Dictionary)->bool:return bill.expense_type!=&"student_loan")
	check(blocking.size()==1 and blocking[0].expense_type==&"bank_installment" and blocking[0].unpaid_cents==42,"Bank alone blocks:42 cents; no rent/payroll arrears")
	check(blocking[0].due_cycle==52 and blocking[0].overdue_cycles==0,"partially paid Bank keeps original due52 age0")
	check(report.outstanding_expenses.filter(func(bill: Dictionary)->bool:return bill.expense_type==&"student_loan").size()==1,"separate nonblocking education due exists")
	result=Replay.record(session,tape,session.command(&"development",{"request":session.development.command(&"begin")}))
	check(result.ok,"free Design entry remains available")
	for distribution: Dictionary in [{0:30,1:20,2:25,3:25},{0:20,1:30,2:25,3:25}]:
		var before:=Replay.digest(Replay.state(session))
		var request: Dictionary=session.command(&"development",{"request":session.development.command(&"priorities",{"distribution":distribution})})
		result=Replay.record(session,tape,request)
		check(not result.ok and Replay.digest(Replay.state(session))==before,"valid changed priorities cannot carry even42 cents of Bank debt forward")
		rows.append({"request":request,"result":result,"state_digest":before})
	var before_money:=Replay.digest(Replay.state(session))
	var quote: Dictionary=session.run.get_studio_action_finance_observation().bank_payoff_quotes[0]
	result=Replay.record(session,tape,session.command(&"bank_payoff",{"quote":quote}))
	check(not result.ok and Replay.digest(Replay.state(session))==before_money,"unaffordable real payoff rejects atomically")
	check(session.run.get_completed_run_cycles()==52 and session.run.get_studio_finance_report()==report,"rejections preserve dates/payments/credit/cash")
	check(session.export_checkpoint().is_empty(),"uncommitted Development is not a Continue checkpoint")
	check(Replay.replay(Factory.create({"checkpoint":initial},catalog),tape).ok,"Bank-only route and rejections replay exactly")
	var out:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	Replay.save_tape(out+".tape.json",tape)
	FileAccess.open(out+".initial.json",FileAccess.WRITE).store_string(JSON.stringify(initial,"\t"))
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"input":path,"input_sha256":FileAccess.get_sha256(path),"report":report,"block_reason":session.run.get_financial_block_reason(),"rows":rows,"checks":checks,"failures":failures},"\t"))
	print("BANK_ONLY_GUARD checks=%d failures=%d"%[checks,failures]);quit(failures)
