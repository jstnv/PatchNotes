extends SceneTree
var checks: Array = []
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var adapter := StudioCheckpoint.new()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var run := adapter.hydrate(envelope.studio_payload)
	check(run != null,"fresh-process typed Studio hydrate")
	if run == null: finish(args[1]);return
	var original := adapter.capture(run)
	check(original==envelope.studio_payload,"exact Studio roundtrip preserves state and RNG")
	check(run._commission_deals.size()==int(args[2]),"expected complete commission count")
	var native: Dictionary = CheckpointCodec.new().decode(original,CheckpointSchema.root(true))
	check(RunState.Commission.valid_save(native.run),"all completed sources and sales rights reconstruct")
	var totals := {"reputation_bp":0,"investment_bp":0}
	var events := {}
	var clipped := 0
	for event: Dictionary in run._publisher_relationships.events:
		if event.publisher_id != &"sidestreet": continue
		for measure: String in ["reputation_bp","investment_bp"]:
			var requested: int = event["requested_"+measure]
			var credited: int = event["credited_"+measure]
			check(credited==mini(requested,10000-int(totals[measure])),"ordered capped credit "+str(event.ordinal)+" "+measure)
			if credited<requested: clipped+=1
			totals[measure]+=credited
		if event.kind==RunState.Commission.KIND:
			check(not events.has(event.source_id),"unique commissioned standing source")
			events[event.source_id]=event
	check(events.size()==run._commission_deals.size(),"one production event per commission")
	for id: StringName in run._commission_deals:
		var deal: Dictionary = run._commission_deals[id]
		var result: Dictionary = deal.result
		check(result.delivery_bp==10000 and result.delivered_scope>=deal.terms.required_scope and result.review_tenths>=60,"legal full delivery "+str(id))
		check(result.fee_paid_cents==600000 and result.relationship_award_bp==1500,"full fee and requested award "+str(id))
		check(events.has(id) and events[id].requested_reputation_bp==1500 and events[id].requested_investment_bp==1500,"positive production R/I request "+str(id))
		var receipts := 0
		for action: Dictionary in run._studio_finance.actions:
			if action.source_id==deal.terms.quote_id and action.kind==&"publisher_receipt" and action.direct_delta==600000: receipts+=1
		check(receipts==1,"one exact full-fee receipt "+str(id))
		check(run.get_post_launch_campaign_offer(id).is_empty(),"publisher title has no Studio campaign "+str(id))
		var report := run.get_released_game_monthly_report(id)
		check(report.owner==&"publisher" and report.studio_net_cents==0 and report.studio_settled_cents==0,"publisher-owned sales excluded "+str(id))
		var request := RunState.Commission.request_for(run,id)
		check(not request.is_empty() and run.commit_publisher_relationship_event(request),"trusted completion retry "+str(id))
		check(adapter.capture(run)==original,"retry changes no fee standing state or RNG "+str(id))
	check(run.get_publisher_relationships()[&"sidestreet"]==totals,"live standing equals ordered event credits")
	if int(args[2])==7:
		check(totals.reputation_bp==10000 and totals.investment_bp==10000 and clipped>=2,"both caps reached through actual commissioned completions")
	else:
		check(totals.investment_bp==1500*int(args[2]),"uncapped positive Investment equals completed count")
	for mutation: String in ["credit","request","missing","duplicate"]:
		var bad := native.duplicate(true)
		match mutation:
			"credit": bad.run.publisher_relationships.events[-1].credited_investment_bp+=1
			"request": bad.run.publisher_relationships.events[-1].requested_investment_bp-=1
			"missing": bad.run.publisher_relationships.events.pop_back()
			"duplicate": bad.run.publisher_relationships.events.append(bad.run.publisher_relationships.events[-1].duplicate(true))
		var encoded := CheckpointCodec.new().encode(bad,CheckpointSchema.root(true))
		check(not adapter.validate(encoded).is_empty(),"completed history rejects "+mutation)
	check(adapter.capture(run)==original,"all rejection probes preserve original Studio")
	finish(args[1])
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("GATE_AUDIT checks=%d failures=%d" % [checks.size(),failures])
	quit(0 if failures==0 else 1)
