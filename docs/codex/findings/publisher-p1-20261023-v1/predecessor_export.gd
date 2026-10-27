extends SceneTree
const World := preload("res://scripts/market/rival_world_checkpoint.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args[0]=="current-pair":
		var session: RefCounted=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"p1-pair","studio_name":"P1 pair","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
		var live: RivalWorld=preload("res://scripts/market/rival_trial.gd").create_world(session.run,session.catalog)
		var test_codec:=World.new()
		var altered:=test_codec.capture(live)
		altered.source_identity="6a54626db35988186fd6a1fd7f47af9191dfb4421dc798720a0725032a75f8c1"
		check(not test_codec.validate(altered,StudioCheckpoint.new().capture(session.run)).is_empty(),"old source cannot claim current schema")
		quit(0 if failures==0 else 1);return
	var decoder := CheckpointCodec.new()
	var old := decoder.open_envelope(FileAccess.get_file_as_string(args[0]))
	check(decoder.error.is_empty(),"unaltered prior EXE disk envelope checksum validates")
	var player := old.duplicate(true); player.erase("rival_world")
	var adapter := StudioCheckpoint.new()
	var run := adapter.hydrate(player)
	check(run!=null,"prior EXE player migrates")
	if run==null: quit(1);return
	var codec := World.new()
	var world := codec.restore(old.rival_world,player,run,root.get_node("CardDatabase").get_development_catalog())
	check(world!=null,"prior compiled EXE world migrates: "+codec.error)
	if world!=null:
		var current := codec.capture(world)
		var now := adapter.capture(run)
		var malformed := current.duplicate(true)
		malformed.source_identity = "6a54626db35988186fd6a1fd7f47af9191dfb4421dc798720a0725032a75f8c1"
		check(not codec.validate(malformed,now).is_empty(),"old source cannot claim current schema")
		malformed = current.duplicate(true)
		malformed.studios[0].run = old.rival_world.studios[0].run.duplicate(true)
		check(not codec.validate(malformed,now).is_empty(),"current source cannot carry a mixed predecessor Studio")
	print("P1 prior export failures=",failures)
	quit(0 if failures==0 else 1)
