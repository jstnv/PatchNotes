extends SceneTree
var checks: Array = []
var summary: Dictionary = {}
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
	summary={"cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"reputation":run._publisher_reputation_bp,"investment":run._publisher_investment_capacity_bp,"deals":run._support_deals,"assessments":run._support_events,"rights":run._support_rights,"commissions":run._commission_deals,"next_quote":run.get_support_quote()}
	check(original==envelope.studio_payload,"exact Studio roundtrip preserves all state and RNG")
	check(run._support_deals.size()==int(args[2]),"expected preserved support deal count")
	var native: Dictionary = CheckpointCodec.new().decode(original,CheckpointSchema.root(true))
	var History = load("res://scripts/contracts/publisher_support_history.gd")
	check(History.valid_history(native.run.commission_deals,native.run.support_deals,native.run.support_events,native.run.release_metadata),"verified sources reconstruct chronological acceptance")
	for changed_id: StringName in native.run.support_deals:
		var forged: Dictionary = native.run.support_deals.duplicate(true)
		forged[changed_id].acceptance_investment_bp+=100
		var amounts := PublisherSupportTrial.quote_amounts(forged[changed_id].acceptance_investment_bp)
		for key: String in amounts: forged[changed_id][key]=amounts[key]
		check(PublisherSupportTrial.valid_terms(forged[changed_id]),"forged capacity retains internally valid terms")
		check(not History.valid_history(native.run.commission_deals,forged,native.run.support_events,native.run.release_metadata),"chronology rejects independently valid but unearned capacity")
	var quote := run.get_support_quote()
	if int(args[2])==1: check(not quote.is_empty(),"first passed support enables next quote")
	else: check(quote.is_empty(),"unassessed or missed latest support does not renew")
	if not quote.is_empty():
		var invalid := quote.duplicate(true)
		invalid.qualification_event_id=&"stale-or-forged"
		var snapshots := PrimitiveSnapshotDatabase.new()
		snapshots.load_ledgers()
		var begun: Dictionary = preload("res://scripts/simulation/begin_project.gd").execute(run,snapshots,"Rejected renewal",&"sports",&"fantasy",Callable(),[],{},invalid)
		check(not begun.ok,"invalid renewal confirmation rejects")
		check(adapter.capture(run)==original and run.get_support_quote()==quote,"failed confirmation preserves state RNG and qualification")
	for id: StringName in run._support_deals:
		var terms: Dictionary = run._support_deals[id]
		var rights: Dictionary = run._support_rights[id]
		check(PublisherSupportTrial.valid_terms(terms),"versioned frozen terms "+str(id))
		check(rights.raw_net_cents==rights.publisher_recoup_cents+rights.studio_earned_cents,"title rights conserve raw sales "+str(id))
		var receipts := 0
		for transaction: Dictionary in run._studio_finance.transactions:
			if transaction.kind==&"publisher_support_advance" and transaction.source_id==terms.quote_id:
				receipts+=1
				check(transaction.amount_cents==terms.funding_cents,"exact quoted funding "+str(id))
		check(receipts==1,"one funding receipt "+str(id))
		for mutation: String in ["capacity","qualification","previous","publisher","funding","rights","milestone"]:
			var bad := native.duplicate(true)
			match mutation:
				"capacity": bad.run.support_deals[id].acceptance_investment_bp+=100
				"qualification": bad.run.support_deals[id].qualification_event_id=&"forged-result"
				"previous": bad.run.support_deals[id].previous_support_id=terms.quote_id
				"publisher": bad.run.support_deals[id].publisher_id=&"crown_quill"
				"funding":
					for index in range(bad.run.studio_finance.transactions.size()-1,-1,-1):
						if bad.run.studio_finance.transactions[index].source_id==terms.quote_id:
							bad.run.studio_finance.transactions.remove_at(index)
							break
				"rights": bad.run.support_rights[id].publisher_recoup_cents+=1
				"milestone":
					if bad.run.support_events.has(terms.quote_id): bad.run.support_events[terms.quote_id].actual_units+=1
					else: bad.run.support_events[terms.quote_id]=PublisherSupportTrial.milestone(terms,100,10000)
			var encoded: Dictionary = CheckpointCodec.new().encode(bad,CheckpointSchema.root(true))
			check(not adapter.validate(encoded).is_empty(),"strict save rejects "+mutation+" "+str(id))
	check(adapter.capture(run)==original,"all corrupted save probes preserve original state")
	# Constructed temporal boundaries: do not label these legal campaigns.
	var publisher := PublisherCatalog.SIDESTREET
	var events: Array = [
		{"id":&"commission:one","publisher_id":publisher,"cycle":5,"phase":1,"source":&"one","award_bp":1500,"qualifies":true},
		{"id":&"support:old","publisher_id":publisher,"cycle":20,"phase":0,"source":&"old","award_bp":1000,"qualifies":true}]
	var deals := {&"old":{"quote_id":&"old","publisher_id":publisher,"accept_cycle":10,"project_id":&"old","observe_earning_cycle":6}}
	var metadata := {&"old":{"release_cycle":14}}
	var resolved := {&"old":{"passed":true}}
	var eligible: Dictionary = History.eligibility(publisher,20,20,deals,resolved,metadata,events)
	check(eligible.get("qualification_event_id")==&"support:old","new supported success qualifies")
	check(History.eligibility(publisher,19,19,deals,{},metadata,events).is_empty(),"unknown assessment blocks renewal")
	var capped := events.duplicate(true)
	capped[0].award_bp=10000
	check(History.capacity_at(publisher,20,capped)==10000,"capacity saturates independently of qualification")
	check(History.eligibility(publisher,20,20,deals,resolved,metadata,capped)==eligible,"successful cap result still qualifies")
	var missed := events.duplicate(true)
	missed[1].qualifies=false;missed[1].award_bp=0
	check(History.eligibility(publisher,20,20,deals,{&"old":{"passed":false}},metadata,missed).is_empty(),"miss alone never renews")
	missed.append({"id":&"commission:recovery","publisher_id":publisher,"cycle":21,"phase":1,"source":&"recovery","award_bp":1500,"qualifies":true})
	check(History.eligibility(publisher,20,20,deals,resolved,metadata,missed).is_empty(),"future start-cycle result cannot qualify pre-start quote")
	check(History.eligibility(publisher,21,21,deals,resolved,metadata,missed).get("qualification_event_id")==&"commission:recovery","later full commission recovers access")
	check(History.capacity_at(publisher,10,missed)==1500,"later commission cannot fund earlier accepted capacity")
	var wrong := missed.duplicate(true);wrong[2].publisher_id=&"neon_circuit"
	check(History.eligibility(publisher,21,21,deals,resolved,metadata,wrong).is_empty(),"other publisher outcome cannot renew")
	var partial := missed.duplicate(true);partial[2].qualifies=false;partial[2].award_bp=0
	check(History.eligibility(publisher,21,21,deals,resolved,metadata,partial).is_empty(),"partial commission cannot renew")
	deals[&"new"]={"quote_id":&"new","publisher_id":publisher,"accept_cycle":22,"project_id":&"new","observe_earning_cycle":6}
	metadata[&"new"]={"release_cycle":25}
	resolved[&"new"]={"passed":false}
	check(History.eligibility(publisher,31,31,deals,resolved,metadata,missed).is_empty(),"old successes cannot create an offer backlog")
	if int(args[2])==3:
		var pairs: Array = JSON.parse_string(FileAccess.get_file_as_string(args[3]))
		var diagnostics: Array = []
		var Replay = preload("res://scripts/simulation/development_replay.gd")
		var Factory = preload("res://scripts/simulation/run_factory.gd")
		for pair: Dictionary in pairs:
			var old_state: Dictionary = Replay.load_tape(pair.before)
			var exact_case: Dictionary = Replay.load_tape(pair.after)
			var restored: RefCounted = Factory.create(exact_case.initial,root.get_node("CardDatabase").get_development_catalog())
			check(restored!=null,"cold diagnostic restores "+pair.stage)
			if restored==null: continue
			var new_state: Dictionary = Replay.state(restored)
			var changes: Array = []
			collect_differences(old_state,new_state,"",changes)
			diagnostics.append({"stage":pair.stage,"differences":changes})
			check(changes==["/run/_market_committed_candidate"] or changes.is_empty(),"only historical market transaction scratch differs "+pair.stage)
			var prior_envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pair.checkpoint))
			check(restored.export_checkpoint()==prior_envelope,"all durable saved state and envelope exactly preserved "+pair.stage)
		summary.cold_session_diagnostics=diagnostics
	finish(args[1])
func collect_differences(a: Variant,b: Variant,path: String,changes: Array) -> void:
	if path=="/run/_market_committed_candidate":
		if a!=b: changes.append(path)
		return
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if not b.has(key): changes.append(path+"/"+str(key))
			else: collect_differences(a[key],b[key],path+"/"+str(key),changes)
		for key: Variant in b:
			if not a.has(key): changes.append(path+"/"+str(key))
	elif a!=b: changes.append(path)
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"summary":summary},"\t"))
	print("RENEWAL_AUDIT checks=%d failures=%d" % [checks.size(),failures])
	quit(0 if failures==0 else 1)
