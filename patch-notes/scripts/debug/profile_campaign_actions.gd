extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
var failures: Array[String] = []
var checkpoints: Array = []

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		for port in range(47810,47820):
			var server := TCPServer.new()
			if server.listen(port,"127.0.0.1")==OK:
				_writer=server
				return true
		return false

class Meter extends CheckpointCoordinator:
	var validation_calls := 0
	var validation_us := 0
	func _validate_payload(payload: Dictionary) -> String:
		var start := Time.get_ticks_usec()
		var reason := super._validate_payload(payload)
		validation_us += Time.get_ticks_usec()-start
		validation_calls += 1
		return reason

func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); push_error(label)

func measure(session: RefCounted, world: RivalWorld, meter: Meter) -> void:
	var start := Time.get_ticks_usec()
	meter.in_studio=true
	meter.pending=true
	meter.validation_calls=0
	meter.validation_us=0
	check(meter.flush(),"Private world checkpoint: "+meter.failure)
	var row := {"releases":session.run.get_released_game_ids().size(),"cycle":world.cycle,
		"save_ms":(Time.get_ticks_usec()-start)/1000.0,"validator_calls":meter.validation_calls,"validation_ms":meter.validation_us/1000.0}
	var scene: StudioPhase=load("res://scenes/phases/studio_phase.tscn").instantiate()
	start=Time.get_ticks_usec()
	check(scene.setup(null,session.run,session.snapshots),"Studio setup")
	root.add_child(scene)
	row.studio_mount_ms=(Time.get_ticks_usec()-start)/1000.0
	scene.free()
	if session.run.get_released_game_ids().size()==2:
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(session.run)
		var selected: StringName=&""
		for id: StringName in session.run._feature_definitions:
			if session.run.get_feature_research_quote(id).can_admit:
				selected=id
				break
		check(not selected.is_empty(),"A legal Feature can be queued after Game 2")
		start=Time.get_ticks_usec()
		check(session.run.admit_feature_research(session.run.get_feature_research_quote(selected)),"Queue actual research")
		await process_frame
		await process_frame
		row.queue_ms=(Time.get_ticks_usec()-start)/1000.0
		start=Time.get_ticks_usec()
		check(session.run.research_feature(session.run.get_feature_research_quote(selected)),"Actual research cycle")
		await process_frame
		await process_frame
		row.research_ms=(Time.get_ticks_usec()-start)/1000.0
		store.free()
	meter.in_studio=false
	checkpoints.append(row)
	print(JSON.stringify(row))

func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=Factory.create({"recipe":{"schema_version":1,"studio_id":"latency-world","studio_name":"Latency World","specialty":"action","traits":["family_funding"],"seed":"4417"}},catalog)
	check(session!=null,"Fixed-seed private Studio initializes")
	# Solvency fixture only; neither extra funds nor this test policy is player balance.
	check(session.run.add_cash(100000),"Explicit synthetic accounting funds")
	var world:=Trial.create_world(session.run,catalog)
	check(world!=null,"Actual active-rival world initializes")
	var meter:=Meter.new()
	meter.store=PrivateStore.new("user://latency-checkpoint",meter._validate_payload)
	root.add_child(meter)
	meter.attach(session.run)
	check(meter.attach_rivals(world,catalog),"Actual player/world binding")
	var advance:=func(): check(world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS).ok,"Actual rival calendar commit")
	session.run.calendar_changed.connect(advance)
	await measure(session,world,meter)
	var policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Latency game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var commands:=0
	while session.run.get_released_game_ids().size()<4 and commands<180 and failures.is_empty():
		var before: int=session.run.get_released_game_ids().size()
		var choice: Dictionary=policy.call(session.observation())
		var outcome: Dictionary=session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		check(outcome.ok,"Legal deterministic campaign command "+str(commands))
		commands+=1
		if session.in_studio and session.run.get_released_game_ids().size()>before:
			await measure(session,world,meter)
	if OS.get_environment("PN_LATENCY_LONG")=="1":
		while world.cycle<96 and failures.is_empty():
			check(session.run.complete_productive_action(),"Long shared-calendar action")
		await measure(session,world,meter)
	var adapter:=StudioCheckpoint.new()
	var player:=adapter.capture(session.run)
	var saved_world: Dictionary=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
	check(not player.is_empty() and not saved_world.is_empty(),"Final pre/post migration fixture captures")
	var report: Dictionary={"ok":failures.is_empty(),"failures":failures,"source_identity":Replay.source_identity(),"commands":commands,"timings":checkpoints,
		"state":Replay.state(session),"player":player,"world":saved_world}
	if OS.get_environment("PN_LATENCY_NEXT")=="1":
		check(session.run.complete_productive_action(),"One expected continuation cycle commits")
		report.next_player=adapter.capture(session.run)
		report.next_world=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
		report.ok=failures.is_empty()
	var output:=OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report))
	print("Campaign action diagnostic: ",commands," commands; ",failures.size()," failures")
	session.run.calendar_changed.disconnect(advance)
	meter.free()
	quit(0 if failures.is_empty() else 1)
