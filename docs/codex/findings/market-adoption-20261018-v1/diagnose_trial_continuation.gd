extends SceneTree
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer = server
		return true

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

var checks := 0
var failures := 0

func expect(value: bool, label: String) -> void:
	checks += 1
	if value: return
	failures += 1
	push_error("Rival trial: " + label)

func _initialize() -> void:
	await process_frame
	create_timer(90.0).timeout.connect(func() -> void: push_error("Rival trial timed out"); quit(2))
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var player: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":"trial-player","studio_name":"Player Studio","specialty":"action","traits":[],"seed":"4417"},catalog)
	expect(player != null,"legal player bootstrap")
	if player == null: quit(1); return
	var world: RivalWorld = Trial.create_world(player.run,catalog)
	expect(world != null and world.studios.size()==2,"two trial rivals activate")
	if world == null: quit(1); return
	expect(world.historical_archive.size()==2 and world.live_releases.is_empty(),"frozen archive is separate from live releases")
	var coordinator := CheckpointCoordinator.new()
	coordinator.store = TestStore.new("user://saves/studio",coordinator._validate_payload)
	coordinator.attach(player.run)
	expect(coordinator.attach_rivals(world,catalog),"world attaches to player save")
	coordinator.entered_studio()
	if not coordinator.failure.is_empty(): print("RIVAL_TRIAL_SAVE_FAILURE "+coordinator.failure)
	expect(coordinator.failure.is_empty(),"initial atomic world save")
	var restore_at := -1
	var beta_restored := false
	for index in range(20):
		var prior: int = player.run.get_completed_run_cycles()
		expect(player.run.complete_productive_action(Callable(),0,prior),"player productive boundary")
		var report: Dictionary = world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
		if report.ok:
			var view: Dictionary = world.studios[&"incumbent-arcade-foundry"].observation()
			print("RIVAL_TRIAL_CYCLE cycle=%d phase=%s active=%s hand=%d revision=%d blocked=%s releases=%d" % [world.cycle,view.phase,view.development.get("active",false),view.development.get("candidates",[]).size(),view.development.get("hand_revision",-1),report.studios[0].blocked_reason,world.live_releases.size()])
		expect(report.ok,"two rival cycles advance legally")
		if not report.ok: break
		expect(world.cycle==player.run.get_completed_run_cycles(),"synchronized world cycle")
		var probe := WorldCodec.new()
		var saved: Dictionary = probe.capture(world)
		if saved.is_empty(): print("RIVAL_TRIAL_CAPTURE_FAILURE cycle=%d reason=%s" % [world.cycle,probe.error])
		expect(not saved.is_empty(),"active rival world captures at Studio")
		coordinator.pending = true
		expect(coordinator.flush(),"atomic Studio generation accepts active world")
		if restore_at<0 and world.studios[&"incumbent-arcade-foundry"].phase()!=&"studio":
			restore_at=index
			var old_digest := Replay.digest(world.observation())
			var old_action_snapshot := Replay.state(world.studios[&"incumbent-arcade-foundry"])
			var old_action_state := Replay.digest(old_action_snapshot)
			var old_adventure_snapshot := Replay.state(world.studios[&"incumbent-wayfinder-works"])
			var old_adventure_state := Replay.digest(old_adventure_snapshot)
			coordinator.store.release_writer()
			coordinator.free()
			var resumed := CheckpointCoordinator.new()
			resumed.store = TestStore.new("user://saves/studio",resumed._validate_payload)
			resumed.rival_catalog = catalog
			var restored: RunState = resumed.load_current()
			expect(restored != null and resumed.rival_world != null,"Continue restores player and active rivals")
			if restored != null and resumed.rival_world != null:
				resumed.entered_studio(true)
				expect(Replay.digest(resumed.rival_world.observation())==old_digest,"Continue preserves exact world observation")
				var diagnostic := {"source":Replay.source_identity(),"before_action":old_action_snapshot,"after_action":Replay.state(resumed.rival_world.studios[&"incumbent-arcade-foundry"]),"before_adventure":old_adventure_snapshot,"after_adventure":Replay.state(resumed.rival_world.studios[&"incumbent-wayfinder-works"])}
				var continuation: Array=[]
				expect(world.market_snapshot==resumed.rival_world.market_snapshot,"durable committed market snapshot survives Continue exactly")
				for id: StringName in world.studios:
					expect(world.studios[id].run._market_committed_candidate==world.market_snapshot,"original scratch equals committed world snapshot")
					expect(resumed.rival_world.studios[id].run._market_committed_candidate.is_empty(),"restored scratch starts empty")
					expect(_persisted_session(world.studios[id])==_persisted_session(resumed.rival_world.studios[id]),"every other session field matches across Continue")
				for step in range(2):
					var a: bool=player.run.complete_productive_action(Callable(),0,world.cycle)
					var b: bool=restored.complete_productive_action(Callable(),0,resumed.rival_world.cycle)
					expect(a and b,"both original/restored player boundaries commit")
					var ar: Dictionary=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
					var br: Dictionary=resumed.rival_world.advance_committed_player_cycle(Trial.policies(resumed.rival_world),Trial.ZERO_STEPS)
					expect(ar.get("ok",false) and br.get("ok",false),"both rival worlds advance legally")
					expect(Replay.freeze(ar)==Replay.freeze(br),"exact rival action receipts/events agree")
					var ap:=StudioCheckpoint.new().capture(player.run)
					var bp:=StudioCheckpoint.new().capture(restored)
					expect(not ap.is_empty() and ap==bp,"player durable authority and RNG agree")
					var aw:=WorldCodec.new().capture(world)
					var bw:=WorldCodec.new().capture(resumed.rival_world)
					expect(not aw.is_empty() and aw==bw,"world durable authority and RNG agree")
					for id: StringName in world.studios:
						expect(_persisted_session(world.studios[id])==_persisted_session(resumed.rival_world.studios[id]),"full session except scratch agrees after continuation")
						expect(Replay.state(world.studios[id])==Replay.state(resumed.rival_world.studios[id]),"scratch overwritten: full raw session now agrees")
					continuation.append({"cycle":world.cycle,"report":Replay.freeze(ar),"player_digest":Replay.digest(ap),"world_digest":Replay.digest(aw)})
				diagnostic.continuation=continuation
				diagnostic.checks=checks
				diagnostic.failures=failures
				var destination := FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE)
				destination.store_string(JSON.stringify(diagnostic,"\t"))
				destination.close()
				resumed.store.release_writer()
				resumed.free()
				quit(1 if failures else 0)
				return
				expect(resumed.rival_world.cycle==restored.get_completed_run_cycles(),"Continue does not grant a cycle")
				var old_run: Dictionary = world.studios[&"incumbent-arcade-foundry"].run.random_streams.snapshot()
				expect(resumed.rival_world.studios[&"incumbent-arcade-foundry"].run.random_streams.snapshot()==old_run,"Continue preserves rival RNG")
				var forged: Dictionary = resumed.last_payload.duplicate(true)
				forged.rival_world.studios[0].archive[0].year = "1981"
				expect(not resumed._validate_payload(forged).is_empty(),"future historical title is rejected")
				world = resumed.rival_world
				player.run = restored
				coordinator = resumed
			else: break
		if index==4 and not beta_restored:
			var before_action := Replay.digest(Replay.state(world.studios[&"incumbent-arcade-foundry"]))
			var before_adventure := Replay.digest(Replay.state(world.studios[&"incumbent-wayfinder-works"]))
			coordinator.store.release_writer()
			coordinator.free()
			var beta_coordinator := CheckpointCoordinator.new()
			beta_coordinator.store = TestStore.new("user://saves/studio",beta_coordinator._validate_payload)
			beta_coordinator.rival_catalog = catalog
			var beta_player: RunState = beta_coordinator.load_current()
			expect(beta_player!=null and beta_coordinator.rival_world!=null,"Beta Continue restores both rivals")
			if beta_player==null or beta_coordinator.rival_world==null: break
			beta_coordinator.entered_studio(true)
			expect(Replay.digest(Replay.state(beta_coordinator.rival_world.studios[&"incumbent-arcade-foundry"]))==before_action,"Beta Continue preserves Action hand")
			expect(Replay.digest(Replay.state(beta_coordinator.rival_world.studios[&"incumbent-wayfinder-works"]))==before_adventure,"Beta Continue preserves Adventure hand")
			world = beta_coordinator.rival_world
			player.run = beta_player
			coordinator = beta_coordinator
			beta_restored = true
	if restore_at>=0:
		expect(world.studios[&"incumbent-arcade-foundry"].run.get_released_game_ids().size()>0,"restored rival reaches legal release")
	expect(beta_restored,"Beta save/Continue boundary was exercised")
	var old_player := StudioCheckpoint.new().capture(player.run)
	expect(not old_player.is_empty() and not old_player.has("rival_world") and coordinator._validate_payload(old_player).is_empty(),"old player-only Studio payload stays valid")
	print("RIVAL_TRIAL_ACTIVATION checks=%d failures=%d cycles=%d restore_at=%d releases=%d" % [checks,failures,world.cycle,restore_at,world.live_releases.size()])
	coordinator.store.release_writer()
	coordinator.free()
	quit(0 if failures==0 else 1)

func _persisted_session(session: RefCounted) -> Dictionary:
	var state: Dictionary=Replay.state(session)
	state.run.erase("_market_committed_candidate")
	if not state.development.is_empty():
		state.development.run.erase("_market_committed_candidate")
		state.development.hand._run_state.erase("_market_committed_candidate")
	return state
