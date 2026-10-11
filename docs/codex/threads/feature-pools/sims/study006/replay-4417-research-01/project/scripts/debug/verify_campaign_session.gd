extends SceneTree
const Bootstrap := preload("res://scripts/debug/campaign_replay_cli.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const BeginProject := preload("res://scripts/simulation/begin_project.gd")
var failures := 0
var reentry_checks := 0
var tape: Dictionary

func expect(ok: bool,message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: "+message)

func fresh(recipe: Dictionary) -> RefCounted:
	return Bootstrap.create_fresh_session(recipe,root.get_node("CardDatabase"))

func act(session: RefCounted,kind: StringName,payload: Dictionary = {},accepted: bool = true) -> Dictionary:
	var before := Replay.state(session)
	var result := Replay.record(session,tape,session.command(kind,payload))
	expect(result.ok == accepted,"Expected acceptance for "+str(kind))
	if not result.ok: expect(Replay.state(session) == before and result.events.is_empty(),"Rejection preserves state and all RNG: "+str(kind))
	return result

func dev(session: RefCounted,kind: StringName,payload: Dictionary = {}) -> void:
	act(session,&"development",{"request":session.development.command(kind,payload)})

func _initialize() -> void:
	await process_frame
	var recipe := {"schema_version":1,"studio_id":"campaign_fixture","studio_name":"Campaign","specialty":"action","traits":[],"seed":"4417"}
	var session := fresh(recipe)
	expect(session != null,"Fresh campaign initialized")
	if session == null: quit(1); return
	tape = Replay.begin(session)
	var initial := Replay.state(session)
	for change in [{"sequence":1},{"run_cycle":0.0},{"run_id":"foreign"},{"phase":"beta"},{"project_id":"foreign"},{"payload":[]},{"type":3},{"schema_version":2}]:
		var request: Dictionary = session.command(&"begin_development",{"name":"Game","genre":&"action","theme":&"fantasy"})
		request.merge(change,true)
		expect(not session.execute(request).ok and initial == Replay.state(session),"Malformed/stale campaign rejects")
	act(session,&"launch",{},false)
	act(session,&"wait",{},false)
	act(session,&"begin_development",{"name":" ","genre":&"action","theme":&"fantasy"},false)
	act(session,&"begin_development",{"name":"Game","genre":&"action","theme":&"fantasy","priorities":{0:99}},false)
	# The fixture policy is intentionally simple and finite, not competitor policy.
	for game_index in range(3):
		var start_cycle: int = session.run.get_completed_run_cycles()
		var start: Dictionary = session.command(&"begin_development",{"name":"Same Name","genre":&"action" if game_index != 1 else &"puzzle","theme":&"fantasy","priorities":{0:30,1:20,2:30,3:20}})
		var started := Replay.record(session,tape,start)
		expect(started.ok,"Next project starts")
		if not started.ok: break
		expect(session.run.get_completed_run_cycles() == start_cycle+1 and session.development.project.get_current_cycle() == 0,"Begin advances Run once, project zero")
		var once := Replay.state(session)
		expect(not Replay.record(session,tape,start).ok and once == Replay.state(session),"Start cannot charge twice")
		act(session,&"campaign",{"release_id":&"absent"},false)
		act(session,&"launch",{},false)
		# Every synchronous project notification attempts a reentrant campaign action.
		var reentrant := func() -> void:
			var before := Replay.state(session)
			expect(not session.execute(session.command(&"launch")).ok and before == Replay.state(session),"Reentrant command rejects")
			reentry_checks += 1
		session.development.project.values_changed.connect(reentrant)
		for phase_index in range(3):
			if phase_index > 0: dev(session,&"enter_next_phase")
			dev(session,&"begin")
			for hand_index in range(2):
				dev(session,&"play",{"candidate_ids":session.development.hand.candidate_ids.slice(0,4)})
			dev(session,&"request_exit")
			if session.development.awaiting_confirmation: dev(session,&"confirm_exit")
		var before_launch: Array = [session.run.get_cash_cents(),session.run.get_completed_run_cycles(),session.development.project.get_current_cycle()]
		var result := act(session,&"launch")
		session.development.project.values_changed.disconnect(reentrant)
		if not result.ok: break
		expect(session.in_studio and before_launch == [session.run.get_cash_cents(),session.run.get_completed_run_cycles(),session.development.project.get_current_cycle()],"Release and Studio entry are free")
		expect(session.run.get_released_game_ids().size() == game_index+1,"One registered release per project")
		act(session,&"launch",{},false)
		act(session,&"acknowledge_publishers")
		var checkpoint := StudioCheckpoint.new()
		expect(not checkpoint.capture(session.run).is_empty(),"Completed route remains representable by existing Studio checkpoint")
		if game_index == 0:
			# Exactly one admission and one completion. Quote is recorded, never
			# silently regenerated while executing a submitted research command.
			var quote: Dictionary = session.run.get_feature_research_quote(&"save_files")
			expect(quote.get("can_admit",false),"Store node legal after first project")
			if quote.get("can_admit",false):
				act(session,&"admit_research",{"quote":quote})
				act(session,&"admit_research",{"quote":quote},false)
				act(session,&"research",{"quote":quote},false)
				act(session,&"research",{"quote":session.run.get_feature_research_quote(&"save_files")})
				expect(session.run.owns_feature(&"save_files") and &"save_files" not in session.development.project.get_feature_supply_ids(),"Research ownership does not rewrite released supply")
		if game_index == 1:
			expect(&"save_files" in session.development.project.get_feature_supply_ids(),"Following project freezes completed research into supply")
		# Buy a campaign only if the current real release-age window allows it.
		for id in session.run.get_released_game_ids():
			if session.run.get_post_launch_campaign_offer(id).get("can_purchase",false):
				act(session,&"campaign",{"release_id":id})
				act(session,&"campaign",{"release_id":id},false)
				break
	expect(session.in_studio and session.run.get_released_game_ids().size() == 3,"Three complete projects reached Studio")
	var ended := Replay.state(session)
	var replayed := fresh(recipe)
	var report := Replay.replay(replayed,tape)
	expect(report.ok and Replay.state(replayed) == ended,"Fresh campaign replays complete command tape exactly")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty():
		Replay.save_tape(output+".tape.json",tape)
		FileAccess.open(output+".recipe.json",FileAccess.WRITE).store_string(JSON.stringify(recipe,"\t"))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"replay":report,"steps":tape.steps.size(),"reentry_checks":reentry_checks,"final_state":ended},"\t"))
	# Failed view preparation must consume no snapshots, finance or serial.
	var rejected := fresh(recipe)
	var rejected_before := Replay.state(rejected)
	var readiness := func(_project: ProjectState) -> bool: return false
	expect(not BeginProject.execute(rejected.run,rejected.snapshots,"Failed",&"action",&"fantasy",readiness).ok and rejected_before == Replay.state(rejected),"Failed destination preparation restores all RNG and Run state")
	var blocked := fresh(recipe)
	blocked.run.checkpoint_mutations_allowed = false
	var blocked_before := Replay.state(blocked)
	expect(not blocked.execute(blocked.command(&"begin_development",{"name":"Blocked","genre":&"action","theme":&"fantasy"})).ok and blocked_before == Replay.state(blocked),"Blocked checkpoint rejects begin atomically")
	for traits in [["graduate"],["college_dropout"],["cult_following"],["resourceful"]]:
		var trait_recipe := recipe.duplicate(true)
		trait_recipe.traits = traits
		var left := fresh(trait_recipe)
		var right := fresh(trait_recipe)
		expect(left != null and right != null and Replay.state(left) == Replay.state(right),"Deterministic trait bootstrap "+str(traits))
	var policy_session := fresh(recipe)
	var policy := func(view: Dictionary) -> Dictionary:
		view.owned_features.clear()
		view.research_quotes.clear()
		return {"type":&"acknowledge_publishers"}
	var bounded: Dictionary = policy_session.drive(policy,2,1)
	expect(not bounded.ok and bounded.error == "Policy step bound reached" and bounded.tape.steps.size() == 2 and not policy_session.run.get_owned_feature_ids().is_empty(),"Policy is bounded and observation detached")
	expect(not fresh(recipe).drive(func(_view: Dictionary) -> Dictionary: return {"type":&"wait"},2,1).ok,"Illegal policy decision stops the driver")
	var observation_only := func(view: Dictionary) -> Dictionary:
		if view.phase == &"studio": return {"type":&"begin_development","payload":{"name":"Policy","genre":&"action","theme":&"fantasy"}}
		var current: Dictionary = view.development
		return {"type":&"development","payload":{"request":{"schema_version":1,"type":&"begin","project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":{}}}}
	var driven := fresh(recipe)
	var observed: Dictionary = driven.drive(observation_only,2,1)
	expect(not observed.ok and observed.error == "Policy step bound reached" and driven.development.hand.active,"Policy can construct legal development commands from observation alone")
	print("Campaign session verification: %d failures; %d steps; %d reentrant checks" % [failures,tape.steps.size(),reentry_checks])
	quit(1 if failures else 0)
