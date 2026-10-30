extends SceneTree
var checks: Array = []
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func encode(value: Dictionary) -> Dictionary:
	return CheckpointCodec.new().encode(value,CheckpointSchema.root(true))
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var adapter := StudioCheckpoint.new()
	var payload: Dictionary = envelope.studio_payload
	check(adapter.validate(payload).is_empty(),"saved nonzero P1 brief ledger validates")
	var run := adapter.hydrate(payload)
	check(run != null,"fresh process hydrates Studio")
	if run == null: finish(args[1]);return
	check(adapter.capture(run)==payload,"complete typed save/hydrate/capture roundtrip")
	var original := adapter.capture(run)
	var totals := run.get_publisher_relationships()
	check(totals.sidestreet.reputation_bp>=2000 and totals.sidestreet.investment_bp==0,"brief reaches R20 with no Investment")
	totals.sidestreet.reputation_bp=9999
	check(run.get_publisher_relationships().sidestreet.reputation_bp!=9999,"detached observation cannot mutate standing")
	check(run.get_completed_contract_count()==1,"briefs do not count toward legacy publisher unlocks")
	var event: Dictionary = run._publisher_relationships.events[0]
	var request := RunState.RelationshipRules.request_for(run,event.source_id)
	check(run.commit_publisher_relationship_event(request),"same committed source can idempotently retry")
	check(adapter.capture(run)==original,"retry does not change any saved state or RNG")
	for field in ["event_id","source_id","publisher_id","kind","cycle","reputation_bp"]:
		var bad := request.duplicate(true)
		if field=="cycle": bad[field]+=1
		elif field=="reputation_bp": bad[field]=10000
		else: bad[field]=&"forged"
		check(not run.commit_publisher_relationship_event(bad),"reject forged request "+field)
		check(adapter.capture(run)==original,"rejection atomicity "+field)
	run._relationship_commit_in_progress=true
	check(not run.commit_publisher_relationship_event(request),"nested commit guard rejects")
	run._relationship_commit_in_progress=false
	var decoded: Dictionary = CheckpointCodec.new().decode(payload,CheckpointSchema.root(true))
	for mutation in ["award","owner","missing","duplicate","result","cash","promise","cycle"]:
		var bad := decoded.duplicate(true)
		var id: StringName = event.source_id
		match mutation:
			"award": bad.run.publisher_relationships.events[0].credited_reputation_bp+=1
			"owner": bad.run.publisher_relationships.owner=&"other_studio"
			"missing": bad.run.publisher_relationships.events.remove_at(0)
			"duplicate": bad.run.publisher_relationships.events.append(bad.run.publisher_relationships.events[0].duplicate(true))
			"result": bad.run.sidestreet_briefs[id].state.result.numerator+=1
			"cash": bad.run.sidestreet_briefs[id].state.result.payout=1
			"promise": bad.run.sidestreet_briefs[id].state.challenge_terms.cash_cap_cents=10000
			"cycle": bad.run.publisher_relationships.events[0].cycle+=1
		check(not adapter.validate(encode(bad)).is_empty(),"typed save rejects "+mutation)
	var terms := ContractChallenges.terms_for_contract(ContractDefinitions.SIDESTREET_BRIEF)
	for row in [[10,0,10000],[11,0,5000],[12,0,0],[10,1,0]]:
		check(ContractChallenges.reward(terms,row[0],{0:6,1:6,2:6,3:6},row[1]).grade_bp==row[2],"exact promise threshold "+str(row))
	var next := run.get_sidestreet_brief_offer()
	check(not next.is_empty(),"one future pending brief survives stop-at-gate")
	if not next.is_empty():
		var state := run.accept_sidestreet_brief(next.offer_id)
		check(state!=null,"pending offer remains legally acceptable")
		check(run.accept_sidestreet_brief(next.offer_id)==null,"one active Contract prevents double acceptance")
		check(adapter.capture(run).is_empty(),"active brief cannot create Studio Continue")
		check(not run.commit_publisher_relationship_event(request),"active Contract blocks public award seam")
	finish(args[1])
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("P2_AUDIT checks=%d failures=%d" % [checks.size(),failures])
	quit(0 if failures==0 else 1)
