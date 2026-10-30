extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
var checks: Array = []
var observed := 0
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var exact := Replay.load_tape(args[0])
	var session: RefCounted = Factory.create(exact.initial,root.get_node("CardDatabase").get_development_catalog())
	check(session!=null,"create exact legal fresh campaign")
	if session==null: quit(1);return
	session.run.publisher_relationships_changed.connect(func() -> void:
		observed+=1
		var run: RunState = session.run
		var before := Replay.digest(Replay.state(session))
		var event: Dictionary = run._publisher_relationships.events[-1]
		var request := RunState.RelationshipRules.request_for(run,event.source_id)
		check(run.get_publisher_relationships().sidestreet.reputation_bp>0,"observer sees reconstructed standing")
		check(run._studio_finance.last_cycle==event.cycle and run._completed_run_cycles==event.cycle,"award publication sees coherent cycle and finance")
		check(not run.commit_publisher_relationship_event(request),"actual award observer cannot reenter public producer")
		check(run.accept_sidestreet_brief(event.source_id)==null,"actual award observer cannot accept another Contract")
		check(Replay.digest(Replay.state(session))==before,"observer rejections preserve state and RNG")
	)
	var report := Replay.replay(session,Replay.load_tape(args[1]))
	check(report.ok,"full legal tape exactly reproduces with observer attached")
	check(observed==3,"three coherent award notifications exactly once")
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observed":observed,"replay":report},"\t"))
	quit(0 if failures==0 else 1)
