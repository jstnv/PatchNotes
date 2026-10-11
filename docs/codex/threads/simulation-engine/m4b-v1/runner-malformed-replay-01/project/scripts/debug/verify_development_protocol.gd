extends "res://scripts/debug/verify_design_command.gd"

const Session := preload("res://scripts/simulation/development_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var reentry_count:=0

func make_session(seed_value: int = 4417) -> RefCounted:
	var project:=ProjectState.new(300)
	project.set("_release_id",&"protocol_project")
	project.initialize_snapshots(&"fast_follower",&"market_surge")
	var run:=RunState.new()
	run.initialize_cash(0)
	_expect(run.create_studio_with_traits("Protocol",&"action",[]),"Protocol studio")
	run.set("_bank_run_id",&"protocol_studio")
	run.set("_employees",EmployeeRoster.create(&"protocol_studio"))
	_expect(project.configure_predevelopment("Protocol",&"action",&"fantasy",run.get_owned_feature_ids()),"Protocol project")
	for id in RunRandom.STREAMS: run.random_streams.stream(id).seed=seed_value+RunRandom.STREAMS.find(id)
	var snapshots:=PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var session:=Session.new()
	_expect(session.initialize(project,run,root.get_node("CardDatabase").get_development_catalog(),snapshots),"Protocol session")
	return session

func _initialize() -> void:
	await process_frame
	var session:=make_session()
	var tape:=Replay.begin(session)
	var empty_before:=Replay.state(session)
	for bad in [{},{"schema_version":2},{"sequence":1},{"project_cycle":1.0},{"run_cycle":-1},{"project_id":"foreign"},{"project_id":{}},{"phase":"beta"},{"phase":[]},{"payload":[]},{"type":"unknown"}]:
		var request: Dictionary = session.command(&"begin")
		if bad.is_empty(): request={}
		else: request.merge(bad,true)
		var result: Dictionary = session.execute(request)
		_expect(not result.ok and result.events.is_empty() and Replay.state(session)==empty_before,"Malformed/stale request is side-effect free")
	var before_cycle: int = session.project.get_current_cycle()
	_expect(Replay.record(session,tape,session.command(&"priorities",{"distribution":{0:40,1:20,2:20,3:20}})).ok,"Planning priority accepted")
	_expect(session.project.get_current_cycle()==before_cycle,"Planning priorities are free")
	var request: Dictionary = session.command(&"begin")
	_expect(Replay.record(session,tape,request).ok,"Initial deal accepted")
	var before:=Replay.state(session)
	_expect(not Replay.record(session,tape,request).ok and Replay.state(session)==before,"Consumed command cannot repeat")
	for ids in [[-1],[session.hand.candidate_ids[0],session.hand.candidate_ids[0]],[0.0]]:
		_expect(not Replay.record(session,tape,session.command(&"redraw",{"candidate_ids":ids})).ok and Replay.state(session)==before,"Invalid instance selection preserves complete state")
	# Run direct field changes only in a separate constructed failure fixture.
	var broken:=make_session()
	broken.hand._pass_definitions.clear()
	var broken_before:=Replay.state(broken)
	_expect(not broken.execute(broken.command(&"begin")).ok and Replay.state(broken)==broken_before,"Failed initial deal restores RNG and planning state")
	# Reentrant commands from project signals cannot resolve twice.
	session.project.cycle_changed.connect(func() -> void:
		var inside:=Replay.state(session)
		var rejected: Dictionary = session.execute(session.command(&"host_playtest"))
		_expect(not rejected.ok and Replay.state(session)==inside,"Reentrant action rejected atomically")
		reentry_count+=1)
	for phase in range(3):
		if phase>0:
			_expect(Replay.record(session,tape,session.command(&"enter_next_phase")).ok,"Enter next phase")
			var entered:=Replay.state(session)
			_expect(not Replay.record(session,tape,session.command(&"enter_next_phase")).ok and Replay.state(session)==entered,"Repeated entry cannot mint redraws")
			_expect(Replay.record(session,tape,session.command(&"begin")).ok,"Begin next phase")
		var changed: Dictionary = {&"qa":40,&"marketing":30,&"insider":30} if phase==2 else {0:20,1:40,2:20,3:20}
		_expect(Replay.record(session,tape,session.command(&"priorities",{"distribution":changed})).ok,"Active priority change")
		for attempt in range(3):
			var selected: Array[int] = session.hand.candidate_ids.slice(0,4)
			_expect(Replay.record(session,tape,session.command(&"play",{"candidate_ids":selected})).ok,"Legal recorded hand")
			if phase>0 and attempt==0:
				_expect(Replay.record(session,tape,session.command(&"host_playtest")).ok,"Host Playtest recorded")
				var pending:=Replay.state(session)
				_expect(not Replay.record(session,tape,session.command(&"host_playtest")).ok and Replay.state(session)==pending,"Second pending playtest cannot charge twice")
		var cycle: int = session.project.get_current_cycle()
		var run_cycle: int = session.run.get_completed_run_cycles()
		_expect(Replay.record(session,tape,session.command(&"request_exit")).ok,"Exit request")
		if phase>0:
			_expect(session.awaiting_confirmation,"Under-scope exit needs explicit confirmation")
			var waiting:=Replay.state(session)
			_expect(not Replay.record(session,tape,session.command(&"play",{"candidate_ids":session.hand.candidate_ids.slice(0,4)})).ok and Replay.state(session)==waiting,"Pending confirmation blocks effects")
			_expect(Replay.record(session,tape,session.command(&"cancel_exit")).ok,"Cancel exit")
			var canceled:=Replay.state(session)
			_expect(not Replay.record(session,tape,session.command(&"confirm_exit")).ok and Replay.state(session)==canceled,"Cannot confirm canceled request")
			_expect(Replay.record(session,tape,session.command(&"request_exit")).ok,"Request exit again")
			_expect(Replay.record(session,tape,session.command(&"confirm_exit")).ok,"Confirm exit")
		_expect(session.finalized and session.project.get_current_cycle()==cycle and session.run.get_completed_run_cycles()==run_cycle,"Finalization costs zero cycles")
	_expect(reentry_count==14,"Exactly fourteen productive-cycle notifications")
	var ended:=Replay.state(session)
	_expect(not Replay.record(session,tape,session.command(&"enter_next_phase")).ok and Replay.state(session)==ended,"Beta boundary cannot enter Studio or refresh redraws")
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var path:=output+".tape.json" if not output.is_empty() else "user://development-tape.json"
	_expect(Replay.save_tape(path,tape),"Tape writes")
	var loaded:=Replay.load_tape(path)
	_expect(loaded==tape,"Object-disabled tape preserves 64-bit counters, keys and typed arrays")
	var replayed:=make_session()
	var report:=Replay.replay(replayed,loaded)
	_expect(report.ok and Replay.state(replayed)==ended,"Fresh session replays every accepted/rejected action and final state exactly")
	var other:=make_session(4418)
	var other_before:=Replay.state(other)
	_expect(not Replay.replay(other,loaded).ok and Replay.state(other)==other_before,"Different initial RNG rejected before mutation")
	var altered:=loaded.duplicate(true)
	altered.source_identity="wrong"
	var fresh:=make_session()
	var fresh_before:=Replay.state(fresh)
	_expect(not Replay.replay(fresh,altered).ok and Replay.state(fresh)==fresh_before,"Source mismatch rejected before mutation")
	for field in ["schema_version","engine_version","rng_algorithm","initial_rng"]:
		var incompatible:=loaded.duplicate(true)
		incompatible[field]="invalid"
		_expect(not Replay.replay(fresh,incompatible).ok and Replay.state(fresh)==fresh_before,"Replay version/RNG fence rejects before mutation")
	altered=loaded.duplicate(true)
	altered.steps[0].state="wrong"
	var mismatch:=Replay.replay(fresh,altered)
	_expect(not mismatch.ok and mismatch.step==0,"Replay identifies first divergent action")
	var policy_session:=make_session()
	var policy:=func(observation: Dictionary) -> Dictionary:
		observation.candidates.clear()
		return {"type":&"begin","payload":{}}
	var bounded:=Replay.drive(policy_session,policy,1)
	_expect(not bounded.ok and bounded.error=="Policy step bound reached" and policy_session.hand._candidate_cards.size()==7,"Policy observation is detached; explicit bound halts execution")
	_expect(not Replay.drive(make_session(),func(_view: Dictionary) -> Dictionary: return {"type":&"play","payload":{}},10).ok,"Illegal policy action stops with evidence")
	if not output.is_empty():
		FileAccess.open(output+".report.json",FileAccess.WRITE).store_string(JSON.stringify({"replay":report,"steps":tape.steps.size(),"reentry_checks":reentry_count,"final_state":Replay.digest(ended)},"\t"))
		FileAccess.open(output+".recipe.json",FileAccess.WRITE).store_string(JSON.stringify({"schema_version":1,"project_id":"protocol_project","studio_id":"protocol_studio","studio_name":"Protocol","game_name":"Protocol","genre":"action","theme":"fantasy","specialty":"action","competitor":"fast_follower","forecast":"market_surge","seed":"4417","traits":[],"tutorial":false,"required_scope":300},"\t"))
	print("Development protocol and tape verification complete: %d steps"%tape.steps.size())
	quit(1 if _failures else 0)
