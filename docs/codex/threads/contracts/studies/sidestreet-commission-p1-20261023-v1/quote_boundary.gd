extends SceneTree
const Begin := preload("res://scripts/simulation/begin_project.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks: Array = []
func check(ok: bool,label: String) -> void:
	checks.append({"pass":ok,"check":label})
	print("PASS: " if ok else "FAIL: ",label)
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var adapter := StudioCheckpoint.new()
	var snapshots := PrimitiveSnapshotDatabase.new()
	check(snapshots.load_ledgers(),"load snapshots")
	for field in ["_required_scope","_base_name","_genre_id"]:
		var run := adapter.hydrate(envelope.studio_payload)
		var before := adapter.capture(run)
		var quote := run.get_commission_quote("Callback test",&"sports",&"fantasy")
		var ready := func(project: ProjectState) -> bool:
			if field == "_required_scope": project._required_scope+=1
			elif field == "_base_name": project._base_name="Changed"
			else: project._genre_id=&"puzzle"
			return true
		var result := Begin.execute(run,snapshots,"Callback test",&"sports",&"fantasy",ready,[],quote)
		check(not result.ok and adapter.capture(run)==before,"post-readiness alteration rejects atomically "+field)
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted = Factory.create({"checkpoint":envelope},catalog)
	var before := StudioCheckpoint.new().capture(session.run)
	var queried: Dictionary = session.execute(session.command(&"quote_commission",{"name":"Quote check","genre":"sports","theme":"fantasy"}))
	check(queried.ok,"explicit free quote command succeeds")
	check(StudioCheckpoint.new().capture(session.run)==before,"quote command changes no gameplay or RNG")
	var saved: Dictionary = session.export_checkpoint()
	var restored: RefCounted = Factory.create({"checkpoint":saved},catalog)
	check(restored!=null and Replay.digest(restored.replay_state())==Replay.digest(session.replay_state()),"pending presentation quote restores exact session state")
	if restored!=null:
		var quote: Dictionary = restored.observation().commission_quote
		var command: Dictionary = restored.command(&"begin_development",{"name":"Quote check","genre":"sports","theme":"fantasy","commission_quote":quote})
		check(restored.execute(command).ok,"restored detached quote binds exact requested project")
		check(restored.export_checkpoint().is_empty(),"active commission rejects campaign Studio checkpoint")
		check(StudioCheckpoint.new().capture(restored.run).is_empty(),"active commission rejects direct Studio checkpoint")
	var failures := checks.filter(func(x: Dictionary) -> bool: return not x["pass"]).size()
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures==0 else 1)
