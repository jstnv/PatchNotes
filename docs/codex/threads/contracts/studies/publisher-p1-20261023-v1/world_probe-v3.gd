extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var checks := 0
var failures := 0

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(0,"127.0.0.1") != OK: return false
		_writer = server
		return true

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: "+label)
	else: print("PASS: "+label)

func _initialize() -> void:
	call_deferred("_run")

func normalized(player: Dictionary, baseline: Dictionary) -> Dictionary:
	var result := player.duplicate(true)
	if not baseline.run.has("publisher_relationships"): result.run.erase("publisher_relationships")
	result.content_revision = baseline.content_revision
	result.sequence = baseline.sequence
	return result

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3: quit(2); return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	var codec := WorldCodec.new()
	var run: RunState
	var world: RivalWorld
	if args[0] == "make":
		var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"p1-world-4417","studio_name":"P1 world","specialty":"action","traits":[],"seed":"4417"},catalog)
		check(session != null,"legal world player")
		if session == null: quit(1); return
		run = session.run; world = Trial.create_world(run,catalog)
		check(world != null,"current trial world creates")
		if world == null: quit(1); return
	else:
		var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
		run = adapter.hydrate(input.player)
		check(run != null,"whole-world player hydrates: "+adapter.error)
		if run == null: quit(1); return
		world = codec.restore(input.world,input.player,run,catalog)
		check(world != null,"whole-world restore: "+codec.error)
		if world == null: quit(1); return
		var captured := codec.capture(world)
		check(not captured.is_empty(),"restored world captures")
		if captured.is_empty(): quit(1); return
		var projected := captured.duplicate(true); projected.source_identity = input.world.source_identity
		for i in range(projected.studios.size()): projected.studios[i].run = normalized(projected.studios[i].run,input.world.studios[i].run)
		check(projected == input.world,"all existing rival state RNG market and ownership fields preserved")
		check(normalized(adapter.capture(run),input.player) == input.player,"all existing player fields preserved")
		var bad: Dictionary = input.world.duplicate(true); bad.source_identity = "unknown-source"
		check(not codec.validate(bad,input.player).is_empty(),"unknown world source still rejects")
		bad = input.world.duplicate(true); bad.studios[0].run.run.bank_run_id = "wrong-owner"
		check(not codec.validate(bad,input.player).is_empty(),"forged rival ownership rejects")
		var combined: Dictionary = adapter.capture(run); combined.rival_world = captured
		var coordinator := CheckpointCoordinator.new(); coordinator.rival_catalog = catalog
		check(coordinator._validate_payload(combined).is_empty(),"coordinator validates full upgraded pair")
		var original_pair: Dictionary = input.player.duplicate(true); original_pair.rival_world = input.world
		check(coordinator._validate_payload(original_pair).is_empty(),"coordinator validates unmodified predecessor pair")
		coordinator.store = PrivateStore.new("user://p1-world-generations",coordinator._validate_payload)
		var saved: Dictionary = coordinator.store.save(combined)
		check(saved.get("status") == &"saved","isolated native generation saves")
		var before := coordinator.store.inspect()
		combined.run.publisher_relationships.owner = "forged-owner"
		check(coordinator.store.save(combined).get("status") == &"invalid","invalid relationship cannot publish generation")
		check(coordinator.store.inspect() == before,"rejected generation preserves last valid disk save")
		coordinator.store.release_writer(); coordinator.free()
	var prior: int = run.get_completed_run_cycles()
	check(run.complete_productive_action(Callable(),0,prior),"bounded next productive player cycle")
	var advanced := world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
	check(advanced.ok and world.cycle == prior+1,"rivals continue exactly one cycle")
	var player := adapter.capture(run); var saved_world := codec.capture(world)
	check(not player.is_empty() and not saved_world.is_empty(),"new Studio world checkpoint remains valid")
	var file := FileAccess.open(args[2],FileAccess.WRITE)
	check(file != null,"isolated whole-world fixture opens")
	if file != null: file.store_string(JSON.stringify({"player":player,"world":saved_world})); file.close()
	print("P1 world checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
