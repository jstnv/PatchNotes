extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
var checks: Array = []
var awards := 0
var begin_notifications := 0
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var exact := Replay.load_tape(args[0])
	var session: RefCounted = Factory.create(exact.initial,root.get_node("CardDatabase").get_development_catalog())
	check(session!=null,"restore exact matched initial Studio")
	if session==null: finish(args[2]);return
	session.run.calendar_changed.connect(func() -> void:
		var run: RunState = session.run
		if run.has_pending_commission() and run._completed_run_cycles==int(run._commission_deals.values()[0].terms.accept_cycle)+1:
			begin_notifications+=1
			check(run._studio_finance.last_cycle==run._completed_run_cycles,"Begin publication sees bound commission with committed finance")
			check(StudioCheckpoint.new().capture(run).is_empty(),"Begin observer cannot capture active project as Studio Continue")
	)
	session.run.publisher_relationships_changed.connect(func() -> void:
		var run: RunState = session.run
		if run._commission_deals.is_empty() or run.has_pending_commission(): return
		awards+=1
		var before := Replay.digest(Replay.state(session))
		var id: StringName = run._commission_deals.keys()[0]
		var request := RunState.Commission.request_for(run,id)
		check(not request.is_empty(),"award observer sees committed result rights receipt and standing source")
		check(not run.get_publisher_relationships().is_empty(),"award observer reconstructs full P1 ledger")
		check(run._studio_finance.cash_cents==run._cash_cents and run._studio_finance.last_cycle==run._completed_run_cycles,"award observer sees coherent cash finance and cycle")
		check(not run.register_release(session.development.project),"actual observer cannot reenter launch")
		check(not run.commit_publisher_relationship_event(request),"actual observer cannot reenter award")
		check(Replay.digest(Replay.state(session))==before,"observer rejections leave exact state and RNG unchanged")
	)
	var report := Replay.replay(session,Replay.load_tape(args[1]))
	check(report.ok,"entire delivery tape replays with transaction observers")
	check(begin_notifications==1 and awards==1,"one coherent binding and one settlement publication")
	var before := Replay.digest(Replay.state(session))
	check(session.run.register_release(session.development.project),"duplicate completed launch returns existing success")
	check(Replay.digest(Replay.state(session))==before,"duplicate launch does not repeat fee standing or Fans")
	finish(args[2])
func finish(path: String) -> void:
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"begin_notifications":begin_notifications,"awards":awards},"\t"))
	quit(0 if failures==0 else 1)
