extends "res://scripts/debug/verify_starwave.gd"
func _run() -> void:
	var adapter:=StudioCheckpoint.new()
	var folder:=OS.get_environment("PN_CHALLENGE_CAPTURE").path_join("challenge-store")
	var storage:=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new(folder,adapter.validate)
	if OS.get_environment("PN_CHALLENGE_COLD")=="1":
		var saved:=storage.inspect()
		expect(saved.status==&"valid","cold disk generation is valid")
		var restored:=adapter.hydrate(saved.get("payload",{}))
		expect(restored!=null,"cold current Contract restore: " + adapter.error)
		if restored!=null:
			var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+".expected.json"))
			expect(adapter.capture(restored)==expected,"cold exact fields, bonus and RNG")
		print("CHALLENGE_COLD failures=%d"%failures);quit(failures);return
	var old:=OS.get_environment("PN_OLD_CONTRACT_STORAGE")
	var prior:=StudioCheckpointStore.new(old,adapter.validate)
	var inspected:=prior.inspect()
	expect(inspected.status==&"valid","actual pre-challenge source generation inspects valid")
	if inspected.status!=&"valid":quit(1);return
	var old_hash:=FileAccess.get_sha256(inspected.path)
	var restored:=adapter.hydrate(inspected.payload)
	expect(restored!=null,"actual old completed Contracts Continue: " + adapter.error)
	if restored==null:quit(1);return
	var expected:Dictionary=inspected.payload.duplicate(true);expected.content_revision=adapter.revision();expected.sequence="1"
	expect(adapter.capture(restored)==expected,"old contracts/cash/Promotion/RNG remain exact; only revision/sequence normalized")
	for row:Dictionary in restored._publisher_offers.values():
		if row.state!=null:
			expect(row.state.get_challenge_terms().is_empty() and row.state.get_result().get_bonus_cash_cents()==0 and row.state.get_result().get_bonus_promotion()==0,"no retroactive publisher bonus")
	for row:Dictionary in restored._sidestreet_entitlements.values():
		if row.state!=null:expect(row.state.get_challenge_terms().is_empty() and row.state.get_result().get_bonus_cash_cents()==0,"no retroactive SideStreet bonus")
	expect(FileAccess.get_sha256(inspected.path)==old_hash,"inspection/Continue preserves original generation bytes")
	DirAccess.make_dir_recursive_absolute(folder)
	expect(DirAccess.copy_absolute(inspected.path,folder.path_join("checkpoint.1.json"))==OK,"copy old generation into isolated writable test Store")
	var side:=restored.get_next_sidestreet_offer()
	var state:=restored.accept_sidestreet_offer(side.offer_id)
	expect(state!=null and not state.get_challenge_terms().is_empty(),"next acceptance uses frozen challenge terms")
	if state==null:quit(1);return
	for i in 2:
		var plan:=state.plan_hand(passes())
		expect(commit_native_hand(restored,state,passes(),plan.remainder_cents),"new acceptance legal final-hand bonus")
	expect(state.get_result().get_bonus_cash_cents()==10000 and state.get_result().get_bonus_promotion()==4,"new SideStreet bonus only")
	var payload:=adapter.capture(restored)
	expect(not payload.is_empty(),"new mixed old/current Contract save validates: " + adapter.error)
	storage.fault=&"before_rename"
	expect(storage.save(payload).status==&"io_error" and storage.inspect().sequence==1,"failed atomic publication keeps old generation")
	storage.fault=&""
	expect(storage.save(payload).status==&"saved" and storage.inspect().sequence==2,"retry publishes exactly one next generation")
	expect(FileAccess.get_sha256(inspected.path)==old_hash and FileAccess.get_sha256(folder.path_join("checkpoint.1.json"))==old_hash,"both original and copied old generation bytes retained")
	FileAccess.open(folder+".expected.json",FileAccess.WRITE).store_string(JSON.stringify(payload,"\t"))
	storage.release_writer()
	print("CHALLENGE_RESTORE failures=%d"%failures);quit(failures)
