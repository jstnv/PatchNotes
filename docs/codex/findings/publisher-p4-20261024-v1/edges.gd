extends SceneTree
const Begin := preload("res://scripts/simulation/begin_project.gd")
const Fence := preload("res://scripts/simulation/transaction_projection.gd")
const Support := preload("res://scripts/contracts/publisher_support.gd")
var checks: Array = []
var args: PackedStringArray
class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		_writer = TCPServer.new()
		return _writer.listen(47735,"127.0.0.1") == OK

func _initialize() -> void: execute.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"label":label})
	if not ok: printerr("FAIL: ",label)

func payload(label: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(args[1]+"/"+label+".json"))

func encode(native: Dictionary, active: bool = false) -> Dictionary:
	var codec := CheckpointCodec.new()
	var encoded: Variant = codec.encode(native,CheckpointSchema.root(true,active))
	check(codec.error.is_empty(),"constructed record encodes")
	return encoded

func execute() -> void:
	args = OS.get_cmdline_user_args()
	var adapter := StudioCheckpoint.new()
	var snapshots := PrimitiveSnapshotDatabase.new()
	check(snapshots.load_ledgers(),"snapshot definitions")
	var before := payload("pre-support")
	var final := payload("third-launched")
	var decoded := CheckpointCodec.new().decode(final,CheckpointSchema.root()) as Dictionary
	var ids: Array = decoded.run.support_deals.keys()
	var stable := adapter.hydrate(final)
	check(stable != null,"legal repeated save hydrates")
	var store := PrivateStore.new(args[0]+"/disk",adapter.validate)
	var saved := store.save(final)
	check(saved.status == &"saved","valid repeated history writes generation")
	var saved_bytes := FileAccess.get_file_as_bytes(saved.path)
	for mutation: String in ["capacity","required_scope","stale_source_map","boundary","previous","qualification","reused","changed_assessment","missing_assessment","rights","missing_funding","duplicate_funding","wrong_funding","foreign_owner","reordered_events","reordered_deals"]:
		var n := decoded.duplicate(true)
		match mutation:
			"capacity": n.run.support_deals[ids[1]].acceptance_investment_bp += 1
			"required_scope": n.run.support_deals[ids[0]].required_scope = 1
			"stale_source_map":
				var latest: StringName = n.run.support_deals[ids[2]].source_release_id
				var older: StringName = n.run.commission_deals[latest].terms.source_release_id
				n.run.support_deals[ids[2]].source_release_id = older
				var move: Dictionary = n.run.release_metadata[older]
				n.run.release_metadata.erase(older)
				n.run.release_metadata[older] = move
			"boundary": n.run.support_deals[ids[1]].relationship_boundary += 1
			"previous": n.run.support_deals[ids[2]].previous_support_id = n.run.support_deals[ids[0]].quote_id
			"qualification": n.run.support_deals[ids[2]].qualification_event_id = n.run.publisher_relationships.events[0].event_id
			"reused": n.run.support_deals[ids[2]].qualification_event_id = n.run.support_deals[ids[1]].qualification_event_id
			"changed_assessment": n.run.support_assessments[ids[1]].passed = true
			"missing_assessment": n.run.support_assessments.erase(ids[0])
			"rights": n.run.support_rights[ids[0]].publisher_recoup_cents -= 1
			"missing_funding": n.run.studio_finance.actions.remove_at(n.run.support_deals[ids[0]].finance_revision)
			"duplicate_funding": n.run.studio_finance.actions.append(n.run.studio_finance.actions[n.run.support_deals[ids[0]].finance_revision].duplicate(true))
			"wrong_funding": n.run.studio_finance.actions[n.run.support_deals[ids[0]].finance_revision].direct_delta += 1
			"foreign_owner": n.run.support_deals[ids[0]].studio_id = &"another-studio"
			"reordered_events": n.run.publisher_relationships.events.reverse()
			"reordered_deals":
				var reversed := {}
				for index in range(ids.size()-1,-1,-1): reversed[ids[index]] = n.run.support_deals[ids[index]]
				n.run.support_deals = reversed
		var malformed := encode(n)
		check(not adapter.validate(malformed).is_empty(),"reject "+mutation)
		var failed := store.save(malformed)
		check(failed.status != &"saved" and FileAccess.get_file_as_bytes(saved.path) == saved_bytes,"reject write preserves last valid disk: "+mutation)
		check(adapter.capture(stable) == final,"reject preserves original state/RNG: "+mutation)
	check(store.inspect().status == &"valid","last valid disk remains readable")
	store.release_writer()
	# Pure constructed cap evidence is separate from the legal route.
	var d: Dictionary = decoded.run.duplicate(true)
	var first: Dictionary = d.support_deals[ids[0]].duplicate(true)
	first.relationship_boundary = 1
	var cap_credit := {"ordinal":1,"event_id":&"constructed-cap-credit","source_id":&"constructed-full-commission","publisher_id":&"sidestreet","kind":&"constructed-fixture","cycle":1,"credited_investment_bp":10000}
	var zero_success := {"ordinal":2,"event_id":&"constructed-cap-success","source_id":ids[0],"publisher_id":&"sidestreet","kind":Support.KIND,"cycle":d.release_metadata[ids[0]].release_cycle+6,"credited_investment_bp":0}
	d.publisher_relationships.events = [cap_credit,zero_success]
	d.support_assessments[ids[0]].passed = true
	var cap := Support.eligibility(d,{ids[0]:first},2,d.completed_run_cycles,ids[0])
	check(not cap.is_empty() and cap.acceptance_investment_bp == 10000 and cap.qualification_event_id == zero_success.event_id,"CONSTRUCTED cap100 zero-credited success renews by ordinal")
	d.support_assessments[ids[0]].passed = false
	check(Support.eligibility(d,{ids[0]:first},2,d.completed_run_cycles,ids[0]).is_empty(),"CONSTRUCTED cap100 miss does not renew")
	d.support_assessments.erase(ids[0])
	check(Support.eligibility(d,{ids[0]:first},2,d.completed_run_cycles,ids[0]).is_empty(),"unresolved previous assessment blocks offer")
	# Prepared-project and final-guard rejection retain complete authority/RNG.
	for mutation: String in ["scope","core","phase","supply","snapshots","final_guard"]:
		var run := adapter.hydrate(before)
		var q := run.get_support_quote("Prepared support",&"sports",&"fantasy")
		var original := adapter.capture(run)
		var holder: Array = []
		var readiness := func(p: ProjectState) -> bool:
			holder.append(p)
			match mutation:
				"scope": p.add_scope(1)
				"core": p.add_core_score(0,1)
				"phase": p._current_cycle += 1
				"supply": p._feature_supply_ids.clear()
				"snapshots": p._competitor_snapshot_id = &"forged"
			return true
		if mutation == "final_guard":
			run.checkpoint_before_mutation = func() -> bool:
				holder[0].add_scope(1)
				return true
		var rejected := Begin.execute(run,snapshots,"Prepared support",&"sports",&"fantasy",readiness,[],{},q)
		check(not rejected.ok and adapter.capture(run) == original and run._support_deals.is_empty(),"support rejects full prepared authority change: "+mutation)
	var active_run := adapter.hydrate(before)
	var active_quote := active_run.get_support_quote("Active support",&"sports",&"fantasy")
	var begun := Begin.execute(active_run,snapshots,"Active support",&"sports",&"fantasy",Callable(),[],{},active_quote)
	check(begun.ok,"actual support transaction begins")
	check(adapter.capture(active_run).is_empty(),"player Continue remains Studio-only")
	var active := adapter.capture(active_run,begun.project.get_release_id())
	check(not active.is_empty(),"explicit active rival support DTO validates: "+adapter.error)
	var active_restored := adapter.hydrate(active,true)
	check(active_restored != null and adapter.capture(active_restored,begun.project.get_release_id()) == active,"active support saves full state/RNG exactly")
	var notifications: Array = []
	var rescued := adapter.hydrate(before)
	# CONSTRUCTED journal-valid expense/calendar edge, not a player playthrough.
	check(rescued.spend_cash_cents(rescued.get_cash_cents()),"constructed expense drains cash through authoritative ledger")
	check(rescued.complete_productive_action(),"constructed productive boundary creates due bill after owned-title settlement")
	check(not rescued.can_complete_productive_cycle() and rescued.can_complete_productive_cycle(70000),"funding rescues existing overdue start")
	var rescue_quote := rescued.get_support_quote("Funded recovery",&"sports",&"fantasy")
	var observe := func(): notifications.append({"support":rescued._support_deals.size(),"cash":rescued.get_cash_cents(),"cycle":rescued.get_completed_run_cycles(),"finance_cash":rescued._studio_finance.cash_cents})
	for signal_name: StringName in [&"cash_changed",&"calendar_changed",&"finance_changed"]: rescued.connect(signal_name,observe)
	var rescue := Begin.execute(rescued,snapshots,"Funded recovery",&"sports",&"fantasy",Callable(),[],{},rescue_quote)
	check(rescue.ok and not notifications.is_empty(),"funded due-bill recovery commits")
	for row: Dictionary in notifications: check(row.support == 1 and row.cash == row.finance_cash,"funded start observers see coherent committed state")
	var stale_before := Fence.authority(rescued)
	var stale := Begin.execute(rescued,snapshots,"Funded recovery",&"sports",&"fantasy",Callable(),[],{},rescue_quote)
	check(not stale.ok and Fence.authority(rescued) == stale_before,"duplicate funded start changes nothing")
	for signal_name: StringName in [&"cash_changed",&"calendar_changed",&"finance_changed"]: rescued.disconnect(signal_name,observe)
	# CONSTRUCTED journal fixture: large legitimate scheduled Bank obligation.
	# This tests the same funded productive-plan guard, not a played loan route.
	var journal := StudioFinanceLedger.create(1000000)
	for cycle in range(1,5):
		journal = StudioFinanceLedger.plan(journal,cycle,journal.cash_cents,0,&"calendar",1000000,2000000 if cycle%2==0 else 0,true).ledger
	var loan_quote := StudioFinanceLedger.bank_quote(journal,1000000,12,&"constructed-funded-start")
	check(loan_quote.get("accepted",false),"constructed journal obtains a rule-valid large loan")
	journal = StudioFinanceLedger.accept_loan(journal,loan_quote,&"constructed-funded-start").ledger
	journal = StudioFinanceLedger.plan(journal,4,journal.cash_cents,-journal.cash_cents,&"other_expense").ledger
	for cycle in [5,6]: journal = StudioFinanceLedger.plan(journal,cycle,journal.cash_cents,0,&"calendar",0,0,true).ledger
	var journal_before := journal.duplicate(true)
	check(StudioFinanceLedger.get_blocking_unpaid(journal) > 70000,"constructed due exceeds I15 funding")
	check(StudioFinanceLedger.plan(journal,7,journal.cash_cents,70000,&"publisher_support",0,0,true,&"insufficient-support").is_empty() and journal == journal_before,"still-unaffordable funded productive plan rejects atomically without changing Bank rules")
	var failures := checks.filter(func(row: Dictionary) -> bool: return not row["pass"]).size()
	FileAccess.open(args[0]+"/edges-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"constructed_boundaries":["pure cap100 eligibility","expense/calendar overdue recovery"],"source":preload("res://scripts/simulation/development_replay.gd").source_identity()},"\t"))
	print("P4 boundaries: ",checks.size()," failures: ",failures)
	quit(0 if failures == 0 else 1)
