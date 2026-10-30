extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Begin := preload("res://scripts/simulation/begin_project.gd")
var checks: Array = []
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func encoded(native: Dictionary) -> Dictionary:
	return CheckpointCodec.new().encode(native,CheckpointSchema.root(true))
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var adapter := StudioCheckpoint.new()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var run := adapter.hydrate(envelope.studio_payload)
	check(run != null,"fresh completed Studio hydrates")
	if run == null: finish(args[1]);return
	var original := adapter.capture(run)
	check(original == envelope.studio_payload,"typed capture roundtrip is exact")
	var native: Dictionary = CheckpointCodec.new().decode(original,CheckpointSchema.root(true))
	check(RunState.Commission.valid_save(native.run),"raw sales history matches Studio rights and finance")
	check(not run._commission_deals.is_empty(),"commission source retained")
	if run._commission_deals.is_empty(): finish(args[1]);return
	var id: StringName = run._commission_deals.keys()[0]
	var deal: Dictionary = run._commission_deals[id]
	var request := RunState.Commission.request_for(run,id)
	check(not request.is_empty(),"committed source produces trusted event request")
	check(run.commit_publisher_relationship_event(request),"identical completion event retry accepted")
	check(adapter.capture(run)==original,"event retry gives no money standing or RNG change")
	check(run.get_post_launch_campaign_offer(id).is_empty() and not run.purchase_post_launch_campaign(id,run.get_completed_run_cycles()),"publisher title rejects Studio-paid campaign")
	var report := run.get_released_game_monthly_report(id)
	check(report.owner==&"publisher" and report.studio_net_cents==0 and report.studio_settled_cents==0,"owner-aware report separates raw title sales from Studio income")
	for mutation in ["fee_terms","scope_terms","choice","owner","missing_event","duplicate_event","award","result","receipt","source","orphan_rights","relabel_ownership","renamed_receipt"]:
		var bad := native.duplicate(true)
		match mutation:
			"fee_terms": bad.run.commission_deals[id].terms.fee_cents+=1
			"scope_terms": bad.run.commission_deals[id].terms.required_scope+=1
			"choice": bad.run.commission_deals[id].terms.genre=&"puzzle"
			"owner": bad.run.release_metadata[id].owner=&"studio"
			"missing_event": bad.run.publisher_relationships.events.pop_back()
			"duplicate_event": bad.run.publisher_relationships.events.append(bad.run.publisher_relationships.events[-1].duplicate(true))
			"award": bad.run.publisher_relationships.events[-1].credited_investment_bp+=1
			"result": bad.run.commission_deals[id].result.fee_paid_cents+=1
			"receipt":
				for action: Dictionary in bad.run.studio_finance.actions:
					if action.source_id==deal.terms.quote_id: action.source_id=&"forged"
			"source": bad.run.commission_deals[id].terms.source_release_id=&"missing"
			"orphan_rights": bad.run.commission_deals.erase(id)
			"relabel_ownership", "renamed_receipt":
				bad.run.commission_deals.erase(id)
				bad.run.publisher_relationships.events.pop_back()
				for key in ["owner","publisher_id","commission_quote_id"]: bad.run.release_metadata[id].erase(key)
				if mutation=="renamed_receipt":
					for field in ["actions","transactions"]:
						for entry: Dictionary in bad.run.studio_finance[field]:
							if entry.source_id == deal.terms.quote_id: entry.source_id=&"forged"
		check(not adapter.validate(encoded(bad)).is_empty(),"saved source rejects "+mutation)
	var quote := run.get_commission_quote("Next commission",&"sports",&"fantasy")
	check(not quote.is_empty(),"completed commission permits a later offer without spending standing")
	check(adapter.capture(run)==original,"quote query has no state or RNG side effect")
	var project := PrimitivePredevelopment.prepare_project("Next commission",&"sports",&"fantasy",run)
	project._release_id=quote.project_id
	check(run.can_bind_commission_quote(quote,project),"exact prepared project accepts quoted terms")
	for mutation in ["base_name","genre","theme","project_id","studio_id","required_scope","fee_cents","accept_cycle","extra"]:
		var bad := quote.duplicate(true)
		if mutation in ["required_scope","fee_cents","accept_cycle"]: bad[mutation]+=1
		elif mutation=="base_name": bad[mutation]="different title"
		elif mutation=="extra": bad[mutation]=true
		else: bad[mutation]=&"different"
		check(not run.can_bind_commission_quote(bad,project),"bind rejects altered "+mutation)
	check(adapter.capture(run)==original,"all bad quote checks preserve Studio and RNG")
	var snapshots := PrimitiveSnapshotDatabase.new()
	check(snapshots.load_ledgers(),"snapshot fixture loads")
	var rejected := Begin.execute(run,snapshots,"Next commission",&"sports",&"fantasy",func(_p: ProjectState) -> bool: return false,[],quote)
	check(not rejected.ok and adapter.capture(run)==original,"readiness failure cannot bind fee rights or advance RNG")
	finish(args[1])
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("COMMISSION_AUDIT checks=%d failures=%d" % [checks.size(),failures])
	quit(0 if failures==0 else 1)
