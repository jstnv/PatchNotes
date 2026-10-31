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

func persisted_session_digest(session: RefCounted) -> String:
	var state := Replay.state(session)
	# This transaction scratch is consumed at the player-to-world boundary and
	# overwritten by the next productive action. The saved world.market is its
	# durable authority; Continue intentionally does not restore the scratch.
	state.run.erase("_market_committed_candidate")
	if not state.development.is_empty():
		state.development.run.erase("_market_committed_candidate")
		state.development.hand._run_state.erase("_market_committed_candidate")
	return Replay.digest(state)

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
	var world: RivalWorld = Trial.create_legacy_world(player.run,catalog)
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
			var old_action_state := persisted_session_digest(world.studios[&"incumbent-arcade-foundry"])
			var old_adventure_state := persisted_session_digest(world.studios[&"incumbent-wayfinder-works"])
			var old_market := world.market_snapshot.duplicate(true)
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
				expect(persisted_session_digest(resumed.rival_world.studios[&"incumbent-arcade-foundry"])==old_action_state,"Continue preserves persisted Action session")
				expect(persisted_session_digest(resumed.rival_world.studios[&"incumbent-wayfinder-works"])==old_adventure_state,"Continue preserves persisted Adventure session")
				expect(not old_market.is_empty() and resumed.rival_world.market_snapshot==old_market,"Continue preserves committed market snapshot")
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
			var before_action := persisted_session_digest(world.studios[&"incumbent-arcade-foundry"])
			var before_adventure := persisted_session_digest(world.studios[&"incumbent-wayfinder-works"])
			var before_market := world.market_snapshot.duplicate(true)
			coordinator.store.release_writer()
			coordinator.free()
			var beta_coordinator := CheckpointCoordinator.new()
			beta_coordinator.store = TestStore.new("user://saves/studio",beta_coordinator._validate_payload)
			beta_coordinator.rival_catalog = catalog
			var beta_player: RunState = beta_coordinator.load_current()
			expect(beta_player!=null and beta_coordinator.rival_world!=null,"Beta Continue restores both rivals")
			if beta_player==null or beta_coordinator.rival_world==null: break
			beta_coordinator.entered_studio(true)
			expect(persisted_session_digest(beta_coordinator.rival_world.studios[&"incumbent-arcade-foundry"])==before_action,"Beta Continue preserves Action hand")
			expect(persisted_session_digest(beta_coordinator.rival_world.studios[&"incumbent-wayfinder-works"])==before_adventure,"Beta Continue preserves Adventure hand")
			expect(not before_market.is_empty() and beta_coordinator.rival_world.market_snapshot==before_market,"Beta Continue preserves committed market snapshot")
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
