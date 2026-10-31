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
	var kick:=Time.get_ticks_usec()
	meter._request_save()
	var kickoff_ms: float=(Time.get_ticks_usec()-kick)/1000.0
	var frames:=0
	var maximum:=0
	var prior:=Time.get_ticks_usec()
	while meter.is_saving():
		await process_frame
		var now:=Time.get_ticks_usec()
		maximum=maxi(maximum,now-prior)
		prior=now
		frames+=1
	check(meter.failure.is_empty(),"Private background world checkpoint: "+meter.failure)
	var row := {"kickoff_ms":kickoff_ms,"max_frame_gap_ms":maximum/1000.0,"frames":frames,"releases":session.run.get_released_game_ids().size(),"cycle":world.cycle,
		"save_ms":(Time.get_ticks_usec()-start)/1000.0,"main_coordinator_validator_calls":meter.validation_calls,"main_coordinator_validation_ms":meter.validation_us/1000.0}
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
			if session.run.get_feature_research_quote(id).get("can_admit",false):
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
		check(await meter.wait_saved(),"Newest Research action is durable before departure")
		store.free()
	meter.in_studio=false
	checkpoints.append(row)
	print(JSON.stringify(row))

func _initialize() -> void:
	Engine.max_fps=60
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var session: RefCounted=Factory.create({"recipe":{"schema_version":1,"studio_id":"latency-world","studio_name":"Latency World","specialty":"action","traits":["family_funding"],"seed":"4417"}},catalog)
	check(session!=null,"Fixed-seed private Studio initializes")
	# Solvency fixture only; neither extra funds nor this test policy is player balance.
	check(session.run.add_cash(10000000),"Explicit synthetic accounting funds")
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://certified/rival-opening-5607-v1.json"))
	var world:=preload("res://scripts/market/rival_world_checkpoint.gd").new().restore(prior.fixture.world,StudioCheckpoint.new().capture(session.run),session.run,catalog,"0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99")
	check(world!=null,"Actual active-rival world initializes")
	var meter:=Meter.new()
	meter.store=PrivateStore.new("user://latency-checkpoint",meter._validate_payload)
	meter.background_saves=true
	root.add_child(meter)
	meter.attach(session.run)
	check(meter.attach_rivals(world,catalog),"Actual player/world binding")
	var rival_times: Array=[]
	var advance:=func():
		var tick_start:=Time.get_ticks_usec()
		var tick_report:=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
		rival_times.append({"cycle":world.cycle,"us":Time.get_ticks_usec()-tick_start,"ok":tick_report.ok})
		check(tick_report.ok,"Actual rival calendar commit")
	session.run.calendar_changed.connect(advance)
	await measure(session,world,meter)
	var policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Latency game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var commands:=0
	while session.run.get_released_game_ids().size()<2 and commands<180 and failures.is_empty():
		var before: int=session.run.get_released_game_ids().size()
		var choice: Dictionary=policy.call(session.observation())
		var outcome: Dictionary=session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		check(outcome.ok,"Legal deterministic campaign command "+str(commands))
		commands+=1
		if session.in_studio and session.run.get_released_game_ids().size()>before:
			await measure(session,world,meter)
	if true: # Explicit96-cycle performance fixture, not player/rival balance.
		while world.cycle<96 and failures.is_empty():
			check(session.run.complete_productive_action(),"Long shared-calendar action")
		await measure(session,world,meter)
	var adapter:=StudioCheckpoint.new()
	var player:=adapter.capture(session.run)
	var saved_world: Dictionary=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
	check(not player.is_empty() and not saved_world.is_empty(),"Final pre/post migration fixture captures")
	var report: Dictionary={"ok":failures.is_empty(),"failures":failures,"source_identity":Replay.source_identity(),"commands":commands,"timings":checkpoints,"rival_times":rival_times,
		"state":Replay.state(session),"player":player,"world":saved_world}
	if true:
		check(session.run.complete_productive_action(),"One expected continuation cycle commits")
		report.next_player=adapter.capture(session.run)
		report.next_world=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
		report.ok=failures.is_empty()
	var output:=""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):output=argument.trim_prefix("--output=")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report))
	print("Campaign action diagnostic: ",commands," commands; ",failures.size()," failures")
	session.run.calendar_changed.disconnect(advance)
	meter.free()
	quit(0 if failures.is_empty() else 1)
