extends SceneTree

const Begin := preload("res://scripts/simulation/begin_project.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks: Array = []

func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)

func fresh() -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	if not run.create_studio_with_traits("Transaction witness",&"sports",[]): return null
	for stream in RunRandom.STREAMS: run.random_streams.stream(stream).seed = 1112 + RunRandom.STREAMS.find(stream)
	return run

func _initialize() -> void: execute.call_deferred()

func launch_fixture() -> Dictionary:
	var run := fresh()
	var project := PrimitivePredevelopment.prepare_project("Atomic release",&"sports",&"fantasy",run)
	project._release_id = StringName("%s:project:1" % run._bank_run_id)
	project.initialize_snapshots(&"fast_follower",&"stable_market")
	project.add_core_scores_and_scope({0:40,1:30,2:40,3:35},30)
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.finalize_beta()
	return {"run":run,"project":project}

func launch_checks(snapshots: PrimitiveSnapshotDatabase) -> void:
	var f := launch_fixture()
	var launch := preload("res://scripts/simulation/launch_settlement.gd").new(f.project,f.run,snapshots)
	var before := Replay.digest([f.run,f.project])
	var plan := launch.plan()
	check(not plan.is_empty() and before == Replay.digest([f.run,f.project]),"release preparation freezes only detached results and RNG")
	if plan.is_empty(): return
	var briefing_fixture:=launch_fixture()
	var briefing: RunState=briefing_fixture.run
	briefing._unlocked_publishers[PublisherCatalog.SIDESTREET]=true
	var issued:=preload("res://scripts/simulation/launch_settlement.gd").new(briefing_fixture.project,briefing,snapshots).settle()
	check(issued.ok,"constructed completed release issues API-test Brief through production settlement")
	if not issued.ok:return
	var actions:=preload("res://scripts/simulation/studio_actions.gd")
	var offered: Dictionary=actions.observation(briefing).contract_offers[0]
	var forged:=offered.duplicate(true)
	forged.quote.cash_cents=1
	var untouched:=Replay.digest(briefing)
	check(not actions.execute(briefing,&"accept_contract",forged,true).ok and Replay.digest(briefing)==untouched,"altered observed Brief quote rejects without any state or RNG change")
	check(actions.execute(briefing,&"accept_contract",offered,true).ok,"exact observed Brief offer row is a legal acceptance payload")
	plan.draft._current_scope += 1
	check(not launch.commit(plan).ok and before == Replay.digest([f.run,f.project]),"mutated destination draft rejects with no live result or RNG change")
	plan = launch.plan()
	var observations: Array = []
	var project_ref: WeakRef = weakref(f.project)
	var run_ref: WeakRef = weakref(f.run)
	f.project.values_changed.connect(func():
		var observed_run: RunState = run_ref.get_ref()
		var observed_project: ProjectState = project_ref.get_ref()
		observations.append(observed_run.get_released_game_ids().has(observed_project.get_release_id()) and observed_project.has_month_one_sales_revenue_result() and not observed_run.complete_productive_action()))
	check(launch.commit(plan).ok and observations == [true],"Project observer sees registered result and blocks reentrant gameplay")
	var settled := Replay.digest([f.run,f.project])
	check(launch.settle().ok and observations == [true] and Replay.digest([f.run,f.project]) == settled,"duplicate release changes no state/RNG/notification")
	f = launch_fixture()
	launch = preload("res://scripts/simulation/launch_settlement.gd").new(f.project,f.run,snapshots)
	plan = launch.plan()
	f.run.checkpoint_mutations_allowed = false
	before = Replay.digest([f.run,f.project])
	check(not launch.commit(plan).ok and before == Replay.digest([f.run,f.project]),"late save guard rejects before all live launch changes")

func migration_checks() -> void:
	var path: String = get_script().resource_path.get_base_dir().path_join("current-p1.json")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var adapter := StudioCheckpoint.new()
	var upgraded := adapter.upgrade_commission_predecessor(fixture.player)
	check(not upgraded.is_empty(),"named current P1 player migration validates original generation: "+adapter.error)
	if upgraded.is_empty(): return
	var old := upgraded.duplicate(true)
	old.run.erase("sidestreet_briefs");old.run.erase("commission_deals");old.content_revision = fixture.player.content_revision
	check(old == fixture.player,"P1 migration changes no existing field, finance, RNG or ownership")
	var run := adapter.hydrate(fixture.player)
	check(run != null and adapter.capture(run)==upgraded and run._sidestreet_briefs.is_empty() and run._commission_deals.is_empty(),"direct P1 hydrate is prospective with exact upgraded capture")
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	check(codec.validate(fixture.world,fixture.player).is_empty(),"exact P1 world/source pair migrates: "+codec.error)
	var wrong: Dictionary = fixture.world.duplicate(true);wrong.source_identity = "unknown"
	check(not codec.validate(wrong,fixture.player).is_empty(),"unknown predecessor world source rejects")
	wrong = fixture.player.duplicate(true);wrong.run.cash_cents = "999999"
	check(adapter.upgrade_commission_predecessor(wrong).is_empty(),"old P1 accounting corruption rejects its frozen validator")
	for kind: String in ["sidestreet_brief_completion_v1","sidestreet_commission_completion_v1","unknown"]:
		wrong = fixture.player.duplicate(true)
		wrong.run.publisher_relationships.events = [{"ordinal":"1","event_id":"forged:event","source_id":"forged:source","publisher_id":"sidestreet","kind":kind,"cycle":"0","requested_reputation_bp":"0","requested_investment_bp":"0","credited_reputation_bp":"0","credited_investment_bp":"0"}]
		check(adapter.upgrade_commission_predecessor(wrong).is_empty(),"dormant P1 rejects fabricated typed source cleanly: "+kind)

func execute() -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	check(snapshots.load_ledgers(),"load normal project snapshots")
	for field in ["scope","core","phase","snapshots"]:
		var run := fresh()
		var before := Replay.digest(run)
		var ready := func(project: ProjectState) -> bool:
			if field == "scope": project.add_scope(1)
			elif field == "core": project.add_core_score(ProjectState.CoreScore.GRAPHICS,1)
			elif field == "phase": project._current_cycle += 1
			else: project._competitor_snapshot_id = &"forged"
			return true
		var result := Begin.execute(run,snapshots,"Prepared project",&"sports",&"fantasy",ready)
		check(not result.ok and Replay.digest(run)==before,"readiness cannot alter prepared "+field+" or consume Run/RNG")
	var run := fresh()
	var calls := [0]
	run.checkpoint_before_mutation = func() -> bool:
		calls[0] += 1
		return calls[0] == 1
	var before_cash := run.get_cash_cents()
	var cycle := run.get_completed_run_cycles()
	var ok := run.complete_productive_action(Callable(),137,cycle,&"",&"other_income",&"guard-witness")
	check(ok and calls[0]==1 and run.get_cash_cents()==before_cash+137,"single checkpoint guard commits planned cash exactly once")
	check(run.has_method("get_commission_quote") and run.has_method("get_sidestreet_brief_offer"),"approved commission and separate Brief APIs exist")
	if run.has_method("get_commission_quote"):
		var valid_run := fresh()
		var legal := Begin.execute(valid_run,snapshots,"Normal readiness",&"sports",&"fantasy",func(_project: ProjectState) -> bool: return true)
		check(legal.ok and valid_run.get_completed_run_cycles()==1 and valid_run.next_project_serial==2,"unchanged readiness commits ordinary Begin once")
		launch_checks(snapshots)
		migration_checks()
	var failures := checks.filter(func(row: Dictionary) -> bool: return not row["pass"]).size()
	var args := OS.get_cmdline_user_args()
	if args.size()>0: FileAccess.open(args[-1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures==0 else 1)
