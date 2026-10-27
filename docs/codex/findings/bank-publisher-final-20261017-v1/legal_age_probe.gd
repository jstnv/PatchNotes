extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
func _initialize() -> void: probe.call_deferred()
func probe() -> void:
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(FileAccess.get_file_as_string(OS.get_environment("PN_SAVED_EVIDENCE")))
	var run := StudioCheckpoint.new().hydrate(payload)
	if run == null: push_error("Invalid legal prefix"); quit(1); return
	var session := Campaign.new()
	session.run=run
	session.catalog=root.get_node("CardDatabase").get_development_catalog()
	session.snapshots=PrimitiveSnapshotDatabase.new()
	if not session.snapshots.load_ledgers(): quit(1); return
	var actions: Array=[]
	var before: Dictionary=session.observation()
	print("OFFERS ",JSON.stringify(before.studio_actions.contract_offers))
	var chosen: Dictionary={}
	for offer: Dictionary in before.studio_actions.contract_offers:
		if offer.kind==&"publisher" and offer.quote.publisher_id==&"neon_circuit":chosen=offer;break
	if chosen.is_empty(): push_error("No legal Neon offer");quit(2);return
	for i in range(8):
		var view: Dictionary=session.observation()
		var request: Dictionary
		if view.phase==&"studio":
			if i>0:break
			request=session.command(&"accept_contract",chosen)
		elif view.contract.completed:request=session.command(&"dismiss_contract")
		elif view.contract.candidates.is_empty():request=session.command(&"contract",{"request":session.contract.command(&"begin")})
		else:
			var tokens: Array[int]=[]
			for c in range(4):tokens.append(int(view.contract.candidates[c].token))
			request=session.command(&"contract",{"request":session.contract.command(&"play",{"candidate_ids":tokens})})
		var result: Dictionary=session.execute(request)
		actions.append({"request":request,"result":result,"after":session.observation(),"finance":run.get_studio_finance_snapshot()})
		print(i," ",request.type," ok=",result.ok," cycle=",run.get_completed_run_cycles()," cash=",run.get_cash_cents())
		if not result.ok:break
	FileAccess.open(OS.get_environment("PN_PROBE_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"before":before,"actions":actions},"  "))
	quit(0)
