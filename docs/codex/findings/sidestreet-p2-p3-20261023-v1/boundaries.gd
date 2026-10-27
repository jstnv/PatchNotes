extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Begin := preload("res://scripts/simulation/begin_project.gd")
var checks: Array = []
func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"check":label});print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func encoded(native: Dictionary,active: bool = false) -> Dictionary:
	return CheckpointCodec.new().encode(native,CheckpointSchema.root(true,active))
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var case := Replay.load_tape(args[0]+"/prefix/cases/sports-1112/case.variant.json")
	var session := Factory.create(case.initial,catalog)
	var tape := Replay.load_tape(args[0]+"/prefix/cases/sports-1112/replay.tape.json")
	var witnessed := false
	for step: Dictionary in tape.steps:
		var command: Dictionary = step.command
		if session.contract != null and session.contract._state.get_contract_id()==ContractDefinitions.SIDESTREET_BRIEF and session.contract._state.get_successful_hand_count()==1 and command.type==&"contract" and command.payload.request.type==&"play":
			var run: RunState = session.run
			var ledger := run._publisher_relationships.duplicate(true)
			run._publisher_relationships.events.append({"ordinal":1,"event_id":&"forged","source_id":&"forged","publisher_id":&"sidestreet","kind":&"unknown","cycle":0,"requested_reputation_bp":0,"requested_investment_bp":0,"credited_reputation_bp":0,"credited_investment_bp":0})
			var before := Replay.digest(session.replay_state())
			var notifications: Array = []
			var observe := func(): notifications.append(true)
			for name in [&"cash_changed",&"contracts_changed",&"calendar_changed",&"publisher_relationships_changed"]:run.connect(name,observe)
			var rejected: Dictionary = session.execute(command)
			check(not rejected.ok and Replay.digest(session.replay_state())==before and notifications.is_empty(),"invalid prior source rejects finishing Brief before hand/cash/cycle/RNG or observer mutation")
			check(not run._productive_cycle_in_progress and not run._publishing_cycle and run._cycle_plan.is_empty() and run._pending_relationship_plan.is_empty(),"rejected Brief clears all transaction scratch guards")
			run._publisher_relationships = ledger
			var retry: Dictionary = session.execute(command)
			check(retry.ok and Replay.freeze(retry)==step.result and Replay.digest(session.replay_state())==step.state,"same legal Brief command retries to its exact recorded state and RNG")
			for name in [&"cash_changed",&"contracts_changed",&"calendar_changed",&"publisher_relationships_changed"]:run.disconnect(name,observe)
			witnessed=true;break
		var result: Dictionary = session.execute(command)
		if not result.ok:check(false,"prefix command rejected before Brief witness");break
	check(witnessed,"real legal second-hand Brief rejection seam reached")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]+"/prefix/cases/sports-1112/studio_checkpoint.json"))
	var adapter := StudioCheckpoint.new()
	var snapshots := PrimitiveSnapshotDatabase.new();check(snapshots.load_ledgers(),"snapshot definitions load")
	for field in ["scope","core","phase","supply","snapshots","final_guard"]:
		var run := adapter.hydrate(envelope.studio_payload)
		var original := adapter.capture(run)
		var quote := run.get_commission_quote("Prepared fence",&"sports",&"fantasy")
		var holder: Array = []
		var readiness := func(project: ProjectState) -> bool:
			holder.append(project)
			match field:
				"scope":project.add_scope(1)
				"core":project.add_core_score(ProjectState.CoreScore.GRAPHICS,1)
				"phase":project._current_cycle+=1
				"supply":project._feature_supply_ids.clear()
				"snapshots":project._competitor_snapshot_id=&"forged"
			return true
		if field=="final_guard":
			run.checkpoint_before_mutation=func() -> bool:
				holder[0].add_scope(1)
				return true
		var result := Begin.execute(run,snapshots,"Prepared fence",&"sports",&"fantasy",readiness,[],quote)
		check(not result.ok and adapter.capture(run)==original and not run.has_pending_commission(),"commission rejects full prepared authority alteration: "+field)
	var run := adapter.hydrate(envelope.studio_payload)
	var quote := run.get_commission_quote("Active DTO",&"sports",&"fantasy")
	var begun := Begin.execute(run,snapshots,"Active DTO",&"sports",&"fantasy",Callable(),[],quote)
	check(begun.ok,"legal actual commission begins for explicit active DTO")
	if begun.ok:
		check(adapter.capture(run).is_empty(),"active commissioned player still cannot Continue")
		var active := adapter.capture(run,begun.project.get_release_id())
		check(not active.is_empty(),"explicit project-linked active rival DTO captures: "+adapter.error)
		if not active.is_empty():
			var restored := adapter.hydrate(active,true)
			check(restored!=null and adapter.capture(restored,begun.project.get_release_id())==active,"active commissioned rival native DTO cold roundtrip exact")
			var native: Dictionary = CheckpointCodec.new().decode(active,CheckpointSchema.root(true,true))
			native.run.commission_deals[begun.project.get_release_id()].terms.required_scope=1
			check(not adapter.validate_active_rival(encoded(native,true)).is_empty(),"active terms must match the actual preparation Scope")
			check(adapter.capture(run,begun.project.get_release_id())==active,"active corruption probes preserve valid generation")
	var failed := checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failed},"\t"))
	quit(0 if failed==0 else 1)
