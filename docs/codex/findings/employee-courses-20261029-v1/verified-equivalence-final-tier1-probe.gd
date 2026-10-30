## Re-execute old pinned commands on this source; never rewrite replay identity.
extends SceneTree
const Session:=preload("res://scripts/simulation/campaign_session.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var failures:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1:push_error("One pinned campaign artifact base required");quit(1);return
	var original:=Replay.load_tape(args[0]+".tape.json")
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(JSON.parse_string(FileAccess.get_file_as_string(args[0]+".initial.json")))
	var session:=Session.new()
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	if original.is_empty() or run==null or not session.initialize(run,root.get_node("CardDatabase").get_development_catalog(),snapshots):push_error("Invalid pinned input "+adapter.error);quit(1);return
	var current:=Replay.begin(session)
	if current.initial_rng!=original.initial_rng or current.initial_state!=original.initial_state:push_error("Initial state/RNG changed");quit(1);return
	var executed:=0
	for expected: Dictionary in original.steps:
		Replay.record(session,current,expected.command)
		var actual: Dictionary=current.steps[-1]
		if actual.result!=expected.result or actual.state!=expected.state:
			failures+=1;push_error("Cross-source divergence at "+str(executed));break
		executed+=1
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if failures==0:
		FileAccess.open(output+".initial.json",FileAccess.WRITE).store_string(FileAccess.get_file_as_string(args[0]+".initial.json"))
		if not Replay.save_tape(output+".tape.json",current):failures+=1
	var report:={"failures":failures,"steps":executed,"old_source":original.source_identity,"current_source":current.source_identity,"input":args[0],"input_tape_sha256":FileAccess.get_sha256(args[0]+".tape.json"),"initial_sha256":FileAccess.get_sha256(args[0]+".initial.json")}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report))
	print("CAREER_SOURCE_EQUIVALENCE ",JSON.stringify(report));quit(failures)
