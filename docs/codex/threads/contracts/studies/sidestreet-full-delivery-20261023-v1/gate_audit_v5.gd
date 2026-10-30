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
		var grade: int = mini(10000,mini(10000*int(result.delivered_scope)/int(deal.terms.required_scope),clampi(500*(int(result.review_tenths)-40),0,10000)))
		var award: int = 1500 if grade==10000 else 0
		var fee: int = 600000*grade/10000
		check(result.delivery_bp==grade,"actual delivered grade "+str(id))
		check(result.fee_paid_cents==fee and result.relationship_award_bp==award,"actual fee and requested award "+str(id))
		check(events.has(id) and events[id].requested_reputation_bp==award and events[id].requested_investment_bp==award,"actual production R/I request "+str(id))
		var receipts := 0
		for action: Dictionary in run._studio_finance.actions:
			if action.source_id==deal.terms.quote_id and action.kind==&"publisher_receipt" and action.direct_delta==fee: receipts+=1
		check(receipts==1,"one exact fee receipt "+str(id))
		check(run.get_post_launch_campaign_offer(id).is_empty(),"publisher title has no Studio campaign "+str(id))
		var report := run.get_released_game_monthly_report(id)
		check(report.owner==&"publisher" and report.studio_net_cents==0 and report.studio_settled_cents==0,"publisher-owned sales excluded "+str(id))
		var request := RunState.Commission.request_for(run,id)
		check(not request.is_empty() and run.commit_publisher_relationship_event(request),"trusted completion retry "+str(id))
		check(adapter.capture(run)==original,"retry changes no fee standing state or RNG "+str(id))
	check(run.get_publisher_relationships()[&"sidestreet"]==totals,"live standing equals ordered event credits")
	if int(args[2])==9:
		check(totals.reputation_bp==10000 and totals.investment_bp==10000,"both caps reached through final production witness")
		var final_id: StringName = &"commission-p1-sports-1112:project:13"
		var final_event: Dictionary = events[final_id]
		check(final_event.requested_reputation_bp==1500 and final_event.requested_investment_bp==1500 and final_event.credited_reputation_bp==0 and final_event.credited_investment_bp==1000,"actual full event clips R to zero and I to ten")
	elif int(args[2])==8:
		check(totals.reputation_bp==10000 and totals.investment_bp==9000 and clipped>=2,"follow-up miss preserves actual capped Reputation and Investment90")
	elif int(args[2])==7:
		check(totals.reputation_bp==10000 and totals.investment_bp==9000,"bounded seven-commission result preserves underdelivery")
	else:
		check(totals.investment_bp==1500*int(args[2]),"uncapped positive Investment equals completed count")
	if int(args[2])>=7:
		var missed: StringName = &"commission-p1-sports-1112:project:10"
		check(run._commission_deals[missed].result.delivery_bp==9666 and events[missed].requested_reputation_bp==0 and events[missed].requested_investment_bp==0,"29/30 miss retains partial fee and no retroactive award")
	for mutation: String in ["credit","request","missing","duplicate"]:
		var bad := native.duplicate(true)
		match mutation:
			"credit": bad.run.publisher_relationships.events[-1].credited_investment_bp+=1
			"request": bad.run.publisher_relationships.events[-1].requested_investment_bp-=1
			"missing": bad.run.publisher_relationships.events.pop_back()
			"duplicate": bad.run.publisher_relationships.events.append(bad.run.publisher_relationships.events[-1].duplicate(true))
		var encoded: Dictionary = CheckpointCodec.new().encode(bad,CheckpointSchema.root(true))
		check(not adapter.validate(encoded).is_empty(),"completed history rejects "+mutation)
	check(adapter.capture(run)==original,"all rejection probes preserve original Studio")
	finish(args[1])
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("GATE_AUDIT checks=%d failures=%d" % [checks.size(),failures])
	quit(0 if failures==0 else 1)
