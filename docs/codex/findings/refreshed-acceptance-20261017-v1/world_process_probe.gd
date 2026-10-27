extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0

class ProbeStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(47834,"127.0.0.1") != OK: return false
		_writer = server
		return true

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func signature(coordinator: CheckpointCoordinator) -> Dictionary:
	var states := {}
	for id in coordinator.rival_world.studios:
		states[str(id)] = Replay.digest(Replay.state(coordinator.rival_world.studios[id]))
	return {"player":Replay.digest(coordinator.adapter.capture(coordinator.run)),"world":Replay.digest(coordinator.rival_world.observation()),"sessions":states}

func advance(coordinator: CheckpointCoordinator, count: int) -> void:
	for index in range(count):
		var before := coordinator.run.get_completed_run_cycles()
		expect(coordinator.run.complete_productive_action(Callable(),0,before),"native player clock commits")
		var report := coordinator.rival_world.advance_committed_player_cycle(Trial.policies(coordinator.rival_world),Trial.ZERO_STEPS)
		expect(report.ok,"rivals execute legal bounded decisions")
		expect(coordinator.rival_world.cycle==before+1,"rivals advance exactly once")
		if not report.ok: return

func _initialize() -> void:
	await process_frame
	var mode := OS.get_environment("PN_ACCEPT_MODE")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var coordinator := CheckpointCoordinator.new()
	coordinator.store = ProbeStore.new("user://saves/studio",coordinator._validate_payload)
	coordinator.rival_catalog = catalog
	if mode=="seed":
		var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"acceptance-world","studio_name":"Acceptance World","specialty":"action","traits":[],"seed":"4417"},catalog)
		expect(session!=null,"fresh legal player factory")
		if session==null: quit(1); return
		coordinator.attach(session.run)
		var world: RivalWorld = Trial.create_world(session.run,catalog)
		expect(world!=null and coordinator.attach_rivals(world,catalog),"attach fresh rival world")
		coordinator.entered_studio()
		expect(coordinator.failure.is_empty(),"initial atomic world generation")
		advance(coordinator,5)
		coordinator.pending = true
		expect(coordinator.flush(),"commit active Beta rivals with Studio player")
		var baseline := signature(coordinator)
		FileAccess.open("user://acceptance-baseline.json",FileAccess.WRITE).store_string(JSON.stringify(baseline))
	else:
		var restored := coordinator.load_current()
		expect(restored!=null and coordinator.rival_world!=null,"fresh process restores player and rivals")
		if restored==null or coordinator.rival_world==null:
			print("RESTORE_FAILURE ",coordinator.failure)
			quit(1); return
		coordinator.entered_studio(true)
		var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://acceptance-baseline.json"))
		expect(signature(coordinator)==baseline,"full player/world/active-session/RNG digests restored exactly")
		expect(coordinator.run.get_completed_run_cycles()==5,"Continue grants no cycles")
		var committed: Dictionary = coordinator.store.inspect().payload
		if mode=="rollback":
			coordinator.in_studio = false
			advance(coordinator,2)
			expect(coordinator.run.get_completed_run_cycles()==7,"unsaved branch really advances")
			expect(coordinator.store.inspect().payload==committed,"out-of-Studio player and rival progress do not publish a checkpoint")
		elif mode=="continue":
			advance(coordinator,4)
			coordinator.pending = true
			expect(coordinator.flush(),"resumed rivals and player commit together")
			expect(coordinator.rival_world.live_releases.size()>0,"restored rivals reach actual releases")
			FileAccess.open("user://acceptance-final.json",FileAccess.WRITE).store_string(JSON.stringify(signature(coordinator)))
		else:
			var malformed := committed.duplicate(true)
			malformed.rival_world.cycle = "6"
			expect(not coordinator._validate_payload(malformed).is_empty(),"clock mismatch rejected")
			malformed = committed.duplicate(true)
			malformed.rival_world.studios.append(malformed.rival_world.studios[0])
			expect(not coordinator._validate_payload(malformed).is_empty(),"duplicate rival rejected")
			expect(coordinator.store.inspect().payload==committed,"rejected validation preserves durable generation")
	print("REFRESHED_WORLD_PROCESS mode=%s checks=%d failures=%d cycle=%d releases=%d" % [mode,checks,failures,coordinator.run.get_completed_run_cycles(),coordinator.rival_world.live_releases.size()])
	coordinator.store.release_writer()
	coordinator.free()
	await process_frame
	quit(0 if failures==0 else 1)
