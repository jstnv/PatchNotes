extends "res://scripts/debug/verify_starwave.gd"
func _run() -> void:
	var run:=starwave_fixture()
	var wave:=run.accept_publisher_contract(offer_for(run,PublisherCatalog.STARWAVE))
	for i in 3:
		var plan:=wave.plan_hand(passes())
		expect(commit_native_hand(run,wave,passes(),plan.remainder_cents),"prior Starwave hand")
	var side:=run.get_next_sidestreet_offer()
	var state:=run.accept_sidestreet_offer(side.offer_id)
	for i in 2:
		var plan:=state.plan_hand(passes())
		expect(commit_native_hand(run,state,passes(),plan.remainder_cents),"prior SideStreet hand")
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.capture(run)
	expect(not payload.is_empty(),"actual pre-challenge completed contracts: " + adapter.error)
	var folder:=OS.get_environment("PN_OLD_CONTRACT_STORAGE")
	var store:=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new(folder,adapter.validate)
	expect(store.acquire(),"private writer acquired")
	var result:=store.save(payload)
	expect(result.get("status")==&"saved","old executable publishes real disk generation: " + str(result))
	FileAccess.open(folder+".json",FileAccess.WRITE).store_string(JSON.stringify(payload,"\t"))
	store.release_writer()
	print("PRIOR_CONTRACTS failures=%d"%failures);quit(failures)
