extends SceneTree
const Fence:=preload("res://scripts/simulation/transaction_projection.gd")
var checks:=0
var failures:=0
class Nested extends RefCounted:
	var data: Dictionary={"rows":[{"points":4,"id":&"typed"}]}
	var rng:=RandomNumberGenerator.new()
class Fixture extends RefCounted:
	var data: Dictionary={"rows":[{"value":7}],"child":Nested.new()}
func expect(ok: bool,label: String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize()->void:
	await process_frame
	var fence: Variant=load("res://scripts/simulation/transaction_projection.gd")
	expect(fence.has_method("fingerprint"),"Transaction fence has exact compact comparison")
	if not fence.has_method("fingerprint"):quit(1);return
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../tools/fixtures/background_checkpoint_v003_c96.json"))
	var run:=StudioCheckpoint.new().hydrate(fixture.player)
	var original:=Fence.authority(run)
	var start:=Time.get_ticks_usec()
	for repeat in 8:Fence.authority(run)
	var old_us:=Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	var snapshot: Dictionary=fence.call("fingerprint",run)
	for repeat in 8:fence.call("fingerprint",run)
	var new_us:=Time.get_ticks_usec()-start
	expect(new_us*2<old_us,"Late Run comparison avoids per-number projection allocations")
	expect(snapshot==fence.call("fingerprint",run),"Unchanged authority matches exactly")
	var source:=run._studio_finance.duplicate(true)
	run._studio_finance.actions[-1].direct_delta+=1
	expect(snapshot!=fence.call("fingerprint",run) and original!=Fence.authority(run),"Same-sized nested journal mutation invalidates both fences")
	run._studio_finance=source
	run._studio_finance.actions[-1].cycle=float(run._studio_finance.actions[-1].cycle)
	expect(snapshot!=fence.call("fingerprint",run),"Numerically equal float cannot reuse exact authority")
	run._studio_finance=source.duplicate(true)
	run._studio_finance.actions[-1].cycle=int(run._studio_finance.actions[-1].cycle)
	expect(snapshot==fence.call("fingerprint",run),"Independent restored data matches")
	var nested:=Fixture.new()
	expect(var_to_bytes({"child":nested.data.child})!=var_to_bytes({"child":null}),"Object encoding cannot alias a previously proven null/data container")
	var before: Dictionary=fence.call("fingerprint",nested)
	nested.data.child.data.rows[0].points+=1
	expect(before!=fence.call("fingerprint",nested),"Objects inside containers retain deep state checks")
	before=fence.call("fingerprint",nested)
	nested.data.child.rng.state+=1
	expect(before!=fence.call("fingerprint",nested),"Nested RNG state changes invalidate authority")
	before=fence.call("fingerprint",nested)
	nested.data.rows[0].value+=1
	expect(before!=fence.call("fingerprint",nested),"Mixed-container plain values retain deep checks")
	before=fence.call("fingerprint",run)
	run._preparing_project=true
	expect(before==fence.call("fingerprint",run),"Only existing transaction scratch exemptions remain")
	expect(Fence._data_proof_bytes<=Fence.DATA_PROOF_BYTES and Fence._data_proofs.size()<=Fence.DATA_PROOF_LIMIT,"Data-only proof storage stays bounded")
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"original_8_reads_us":old_us,"compact_9_reads_us":new_us}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report));quit(1 if failures else 0)
