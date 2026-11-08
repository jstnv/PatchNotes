## Compare store-batch quotes to fresh action quotes without changing the run.
extends SceneTree
var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1

func _initialize() -> void:verify.call_deferred()

func admit(run: RunState,engine: StringName,id: StringName) -> bool:
	var quote:=run.get_feature_research_quote(id,engine)
	return quote.get("can_admit",false) and run.admit_feature_research(quote)

func compare(run: RunState,engine: StringName,label: String) -> void:
	var before:=StudioCheckpoint.new().capture(run)
	var rng:=run.random_streams.snapshot()
	var batch:=run.get_feature_store_view(engine)
	var mismatches:Array[String]=[]
	for id: StringName in run._feature_definitions:
		var direct:=run.get_feature_research_quote(id,engine)
		if batch.quotes.get(id,{})!=direct:mismatches.append(str(id))
	check(mismatches.is_empty(),label+" batch equals fresh quotes; mismatches="+str(mismatches))
	mismatches.clear()
	for id: StringName in run._feature_definitions:
		var direct:=run.get_engine_feature_activation_quote(id,engine)
		if batch.activation_quotes.get(id,{})!=direct:mismatches.append(str(id))
	check(mismatches.is_empty(),label+" batched activation equals fresh quotes; mismatches="+str(mismatches))
	check(StudioCheckpoint.new().capture(run)==before and run.random_streams.snapshot()==rng,label+" quote projection preserves checkpoint and RNG")

func verify() -> void:
	var run:=RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Projection parity",&"action",[]) and run.add_cash(500000),"Create funded Studio")
	var a:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Engine A"))
	var b:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Engine B"))
	check(a.get("ok",false) and b.get("ok",false),"Create two legal engines")
	if not a.get("ok",false) or not b.get("ok",false):quit(1);return
	var first: StringName=a.engine_id;var second: StringName=b.engine_id
	check(run.select_engine(first) and run.finalize_starter_selection(),"Select engine and finalize setup")
	check(admit(run,first,&"menu_system"),"Queue a Feature that will become historical paid-but-held supply")
	var payment:=run.get_feature_research_quote(&"menu_system",first)
	check(payment.get("can_research",false) and run.research_feature(payment),"Complete paid Feature")
	check(admit(run,first,&"16_bit_sound") and admit(run,second,&"controller") and admit(run,first,&"sprites"),"Queue replacement and cross-engine FIFO work")
	compare(run,first,"V3 engine A replacement and pending FIFO")
	compare(run,second,"V3 engine B interleaved FIFO")
	var prior:=run.get_engine_feature_state()
	prior.version=2
	for row: Dictionary in prior.engines.values():row.erase("enabled")
	run._engine_features=prior
	check(run.valid_engine_state(),"V2 library is valid before migration")
	compare(run,first,"V2 engine A replacement and pending FIFO")
	compare(run,second,"V2 engine B interleaved FIFO")
	prior.version=1
	prior.engines[first].committed.erase(&"menu_system")
	run._engine_features=prior
	check(run.valid_engine_state(),"V1 paid-but-uncommitted library is valid before migration")
	compare(run,first,"V1 engine A replacement and pending FIFO")
	compare(run,second,"V1 engine B interleaved FIFO")
	print("SCOPE_QUOTE_PARITY checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
