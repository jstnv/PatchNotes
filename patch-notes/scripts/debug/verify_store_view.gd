extends SceneTree
## Compare batched quotes with individual calls to the current authority.
## The old half-price oracle remains archived in fixtures, not a Phase1 rule.
const Before := preload("res://scripts/run_state.gd")
const TransactionView := preload("res://scripts/simulation/transaction_projection.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:
	await process_frame
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var late:=StudioCheckpoint.new().hydrate(fixture.player)
	var fresh:=RunState.new()
	fresh.initialize_cash(0)
	expect(fresh.create_studio_with_traits("Batch quotes",&"action",[]),"Fresh Studio creates")
	expect(late.has_method("get_feature_store_view"),"Store can obtain one synchronous quote bundle")
	if not late.has_method("get_feature_store_view"):quit(1);return
	for run: RunState in [fresh,late]:
		var original:=Before.new()
		TransactionView.copy_fields(run,original)
		var before:=TransactionView.authority(run)
		var view: Dictionary=run.call("get_feature_store_view")
		expect(not view.has("error"),"Validated graph produces a view")
		for id: StringName in run._feature_definitions:
			expect(var_to_bytes(view.quotes.get(id,{}))==var_to_bytes(original.get_feature_research_quote(id)),"Every exact Research quote field: "+str(id))
			expect(var_to_bytes(view.offers.get(id,{}))==var_to_bytes(original.get_feature_store_offer(id)),"Every exact Store offer field: "+str(id))
			expect(var_to_bytes(view.reserves.get(id,{}))==var_to_bytes(original.get_primitive_reserve_offer(id)),"Every exact Primitive offer field: "+str(id))
		expect(var_to_bytes(before)==var_to_bytes(TransactionView.authority(run)),"Batch read leaves complete authority unchanged")
		view.quotes.clear();view.offers.clear();view.reserves.clear()
		expect(not run.call("get_feature_store_view").quotes.is_empty(),"Returned containers do not alias later views")
		var current: Dictionary=run.call("get_feature_store_view")
		if run==late:
			for id: StringName in current.quotes:
				var quote: Dictionary=current.quotes[id]
				if not quote.get("can_admit",false):continue
				expect(run.admit_feature_research(quote),"Batched live quote admits through ordinary transaction")
				expect(not run.admit_feature_research(quote),"Stale batched quote cannot admit twice")
				var next: Dictionary=run.call("get_feature_store_view").quotes[id]
				expect(next.queued and next.can_research and next!=quote,"A successful action immediately produces a fresh quote")
				break
		var corrupt: Dictionary=run._feature_definitions.duplicate(true)
		run._feature_definitions[&"music"].purchase_parent="music"
		expect(run.call("get_feature_store_view").has("error"),"Changed invalid graph cannot reuse previous view")
		run._feature_definitions=corrupt
	var result: Dictionary={"ok":failures==0,"checks":checks,"failures":failures}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result))
	print(JSON.stringify(result));quit(1 if failures else 0)
