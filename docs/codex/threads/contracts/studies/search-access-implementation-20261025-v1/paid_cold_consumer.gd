extends SceneTree
const Replay=preload("res://scripts/simulation/development_replay.gd")
var input:String
var output:String
var failures:=0
var checks:=0
func expect(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize()->void:_run.call_deferred()
func _run()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):input=arg.trim_prefix("--input=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var raw:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(raw)
	expect(run!=null,"Actual private paid Brief Studio checkpoint hydrates: "+adapter.error)
	if run==null:quit(1);return
	expect(adapter.capture(run)==raw,"Every saved Studio, ledger, ownership and RNG field round-trips exactly")
	expect(run._crown_briefs.size()==3,"Exactly three real paid Briefs persisted")
	for id:StringName in run._crown_briefs:
		var offer:Dictionary=run._crown_briefs[id]
		var receipt:Dictionary=RunState.ContractSearch.source(run,id,&"brief",&"crown_quill")
		expect(not receipt.is_empty() and offer.source_release_id.is_empty(),"Paid source is a real Search receipt, never a fabricated release")
		expect(offer.state.is_completed() and offer.state.get_result().get_payout_cents()==0 and offer.state.get_result().get_promotion()==0,"Two-hand completed Brief grants zero money or Promotion")
	var before:Dictionary=adapter.capture(run)
	var old_quote:Dictionary=run.get_contract_search_quote(&"crown_quill",&"brief")
	expect(not old_quote.is_empty() and run.search_contracts(old_quote),"Cold Studio can fund the next legal Crown Search")
	var after:Dictionary=adapter.capture(run)
	expect(not after.is_empty() and not run.search_contracts(old_quote) and adapter.capture(run)==after,"Duplicate/stale Search rejects without another cycle, state or RNG mutation")
	var corrupt:=adapter.hydrate(before)
	corrupt._contract_search.receipts[-1].publisher_id=&"sidestreet"
	expect(adapter.capture(corrupt).is_empty(),"Mixed publisher/paid-source forgery rejects")
	var totals:Dictionary=run.get_publisher_relationships()
	var record:Dictionary={"pass":failures==0,"checks":checks,"failures":failures,"source":Replay.source_identity(),"crown_reputation_bp":totals[&"crown_quill"].reputation_bp,"exact_original_rng":true,"scope":"Independent-process cold private paid Brief checkpoint and legal next Search; no canonical migration claim"}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("PAID_CROWN_COLD "+JSON.stringify(record));quit(failures)
