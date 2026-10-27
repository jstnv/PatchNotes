extends "res://scripts/debug/verify_primitive_branches.gd"
func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var path:=ProjectSettings.globalize_path("res://../docs/codex/findings/queue-completion-20261011-v1/checkpoints/education-distressed-committed/checkpoint.33.json")
	var prior:=CheckpointCodec.new().open_envelope(FileAccess.get_file_as_string(path))
	var session:=from_payload(prior)
	check(session!=null,"real Studio49 prefix restores")
	if session==null:quit(1);return
	var initial: Dictionary=session.export_checkpoint()
	var tape:=Replay.begin(session)
	var rows: Array=[]
	var commands: Array=[session.command(&"begin_development",{"name":"Age observation","genre":"action","theme":"fantasy"})]
	for index in range(8):
		var request: Dictionary
		if index==0:request=commands[0]
		elif index==1:request=session.command(&"development",{"request":session.development.command(&"begin")})
		else:
			var distribution:={0:30,1:20,2:25,3:25} if index%2==0 else {0:20,1:30,2:25,3:25}
			request=session.command(&"development",{"request":session.development.command(&"priorities",{"distribution":distribution})})
		if index==2:
			print("AGE_DIAGNOSTIC ",JSON.stringify({"run_can":session.run.can_advance_calendar_cycle(),"project_can":session.development.project.can_advance_cycle(),"cash":session.run.get_cash_cents(),"draws":session.run.get_available_redraws(),"valid":PriorityAllocation.is_valid_distribution(request.payload.request.payload.distribution),"priorities":session.development.hand.priorities,"plan_generic":not session.run._plan_productive_cycle(0).is_empty(),"plan_typed":not session.run._plan_productive_cycle(0,&"",&"priority_change",session.development.project.get_release_id()).is_empty()}))
		var result:=Replay.record(session,tape,request)
		check(result.ok,"legal bounded priority action "+str(index)+": "+str(result.get("error","")))
		rows.append({"command":request,"result":result,"cycle":session.run.get_completed_run_cycles(),"cash":session.run.get_cash_cents(),"finance":session.run.get_studio_finance_report()})
		if not result.ok:break
	check(session.export_checkpoint().is_empty(),"active development cannot publish a Continue checkpoint")
	var found:=false
	for row: Dictionary in rows:
		for bill: Dictionary in row.finance.outstanding_expenses:
			if bill.expense_type==&"bank_installment" and bill.unpaid_cents>0 and bill.overdue_cycles>=2:found=true
	check(found,"still-unpaid Bank age2 or greater reached legally")
	check(Replay.replay(Factory.create({"checkpoint":initial},catalog),tape).ok,"exact prefix/action replay")
	var out:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	Replay.save_tape(out+".tape.json",tape)
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"input":path,"input_sha256":FileAccess.get_sha256(path),"initial":initial,"rows":rows,"checks":checks,"failures":failures},"	"))
	print("BANK_AGE checks=%d failures=%d"%[checks,failures]);quit(failures)
