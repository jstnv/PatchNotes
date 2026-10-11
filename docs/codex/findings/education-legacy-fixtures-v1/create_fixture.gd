extends SceneTree

func _initialize()->void:call_deferred("_run")

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	var fixture_id:String=args[0]
	var trait_id:StringName=StringName(args[1])
	if trait_id==&"none":trait_id=&""
	var version:int=int(args[2])
	var destination:String=args[3]
	var ids:Array[StringName]=[]
	if not trait_id.is_empty():ids.append(trait_id)
	var selected:Dictionary=StudioTraits.evaluate_traits(ids,version)
	var run:=RunState.new()
	var success:bool=run.initialize_cash(0) and selected.valid and run._commit_studio_creation("Pre-education "+fixture_id,&"action",selected)
	if not success:push_error("Old runtime creation rejected");quit(1);return
	var finance:Dictionary=run.get_studio_finance_snapshot()
	var normal_receipts:Array=[]
	for entry:Dictionary in finance.transactions:
		if entry.kind==&"financing_in":normal_receipts.append(entry)
	var inactive:bool=not StudioTraits.is_active(selected,&"college_dropout") and not StudioTraits.is_active(selected,&"graduate")
	var zero_education:bool=selected.refunded_points==0 and selected.spent_points==0 and selected.point_cash_cents==20000 and selected.remaining_points==4 and finance.bank_loans.is_empty() and finance.obligations.is_empty() and not finance.has("education") and not finance.has("education_account")
	var original_receipt:bool=normal_receipts.size()==1 and normal_receipts[0].source_id==&"studio_trait_unspent_points_v1" and normal_receipts[0].amount_cents==20000 and run.get_cash_cents()==570000 and finance.transactions.size()==2
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.capture(run)
	if payload.is_empty():push_error("Old capture invalid: "+adapter.error);quit(1);return
	var store:=StudioCheckpointStore.new("user://education-legacy-fixture",adapter.validate)
	store._writer=TCPServer.new()
	if store._writer.listen(48971,"127.0.0.1")!=OK:push_error("Isolated fixture writer busy");quit(2);return
	var saved:=store.save(payload)
	var inspected:=store.inspect()
	if saved.status!=&"saved" or inspected.status!=&"valid":push_error("Old strict store rejected fixture");store.release_writer();quit(1);return
	var restored:=adapter.hydrate(inspected.payload)
	var exact:bool=restored!=null and adapter.capture(restored)==payload
	var envelope:String=FileAccess.get_file_as_string(inspected.path)
	var codec:=CheckpointCodec.new()
	var opened:=codec.open_envelope(envelope)
	var payload_text:=JSON.stringify(payload)
	var prefix:=destination.path_join(fixture_id)
	FileAccess.open(prefix+".checkpoint.json",FileAccess.WRITE).store_buffer(envelope.to_utf8_buffer())
	FileAccess.open(prefix+".payload.json",FileAccess.WRITE).store_buffer(payload_text.to_utf8_buffer())
	var exported_exact:bool=FileAccess.get_sha256(prefix+".checkpoint.json")==FileAccess.get_sha256(inspected.path) and opened==payload and codec.error.is_empty()
	var passed:bool=inactive and zero_education and original_receipt and exact and exported_exact
	var report:Dictionary={"passed":passed,"fixture_id":fixture_id,"trait_id":trait_id,"trait_version":version,"selected":selected,"finance":finance,"cash_cents":run.get_cash_cents(),"cycle":run.get_completed_run_cycles(),"inactive":inactive,"zero_education":zero_education,"normal_point_receipt":original_receipt,"old_runtime_hydrate_exact":exact,"exported_exact":exported_exact,"payload_sha256":payload_text.sha256_text(),"envelope_sha256":envelope.sha256_text(),"content_revision":payload.content_revision,"source_build":payload.source_build,"store_path":inspected.path,"exported_envelope":prefix+".checkpoint.json","exported_payload":prefix+".payload.json","rules":StudioCheckpoint.RULES}
	FileAccess.open(prefix+".result.json",FileAccess.WRITE).store_string(JSON.stringify(report))
	store.release_writer()
	print("PRE_EDUCATION_FIXTURE ",fixture_id," passed=",passed," version=",version," cash=",run.get_cash_cents())
	quit(0 if passed else 1)
