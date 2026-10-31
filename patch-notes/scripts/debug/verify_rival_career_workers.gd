extends SceneTree
const Factory:=preload("res://scripts/simulation/run_factory.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Hydration:=preload("res://scripts/persistence/rival_hydration_job.gd")
const ReadJob:=preload("res://scripts/persistence/checkpoint_read_job.gd")
const Validator:=preload("res://scripts/persistence/checkpoint_write_validator.gd")
const Coordinator:=preload("res://scripts/persistence/checkpoint_coordinator.gd")
class LocalStore extends StudioCheckpointStore:
	func acquire() -> bool:return true
class InputProbe extends Node:
	var count:=0
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.physical_keycode==KEY_F8:count+=1
var failures: Array=[]
var checks:=0
var probe: InputProbe
var measurements: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func output() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):return arg.trim_prefix("--output=")
	return "user://rival-career-workers.json"
func tick_input() -> void:
	var press:=InputEventKey.new();press.physical_keycode=KEY_F8;press.pressed=true;Input.parse_input_event(press)
	var release:=InputEventKey.new();release.physical_keycode=KEY_F8;Input.parse_input_event(release)
func await_job(job: RefCounted,label: String) -> void:
	var started:=Time.get_ticks_usec();var previous:=started;var gap:=0;var frames:=0;var before:=probe.count
	while not job.poll():
		tick_input();await process_frame;frames+=1
		var now:=Time.get_ticks_usec();gap=maxi(gap,now-previous);previous=now
		if now-started>30000000:check(false,"bounded worker "+label);return
	measurements.append({"label":label,"elapsed_us":Time.get_ticks_usec()-started,"frames":frames,"max_frame_gap_us":gap,"input_events":probe.count-before})
	check(frames>0 and probe.count>before,"input/render loop progresses during "+label)
func _initialize() -> void:
	await process_frame
	probe=InputProbe.new();root.add_child(probe);var label:=Label.new();label.text="Patch Notes loading verification";root.add_child(label)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var session: RefCounted=Factory.create_fresh_session({"schema_version":1,"studio_id":"worker-player","studio_name":"Worker verifier","specialty":"action","traits":[],"seed":"717"},catalog);var adapter:=StudioCheckpoint.new();var p:=adapter.capture(session.run);var rng: Dictionary=session.run.random_streams.snapshot()
	var fresh:=Hydration.new();fresh.start(p,catalog);await await_job(fresh,"fresh opening")
	check(fresh.world!=null,"fresh worker world: "+fresh.error)
	check(fresh.player!=session.run and session.run.random_streams.snapshot()==rng and adapter.capture(session.run)==p,"fresh worker owns detached player")
	if fresh.world==null:finish();return
	fresh.world.player=session.run;fresh.world.bind_market_providers();var codec:=Codec.new();var w:=codec.capture(fresh.world)
	var validator:=Validator.new();validator.rival_catalog=catalog;var store:=LocalStore.new("user://quality-worker-slot-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec()),validator._validate_payload);var body: Dictionary=p.duplicate(true);body.rival_world=w
	check(store.save(body).status==&"saved","strict private save")
	var read:=ReadJob.new();read.start(store.directory,catalog);await await_job(read,"strict cold inspect and restore")
	check(read.player!=null and read.world!=null,"read worker hydrates once: "+read.error)
	if read.world!=null:check(codec.capture(read.world)==w,"worker cold world exact")
	var meter:=Coordinator.new();meter.store=store;meter.rival_catalog=catalog;root.add_child(meter);var operation: RefCounted=meter.begin_load();var start:=Time.get_ticks_usec();var frames:=0
	while not operation.done:
		operation.advance_async();tick_input();await process_frame;frames+=1
		if Time.get_ticks_usec()-start>30000000:check(false,"coordinator load bound");break
	check(operation.restored!=null and meter.rival_world!=null and frames>1,"interactive Continue adopts complete worker result")
	if meter.rival_world!=null:check(codec.capture(meter.rival_world)==w,"coordinator Continue world exact")
	check(not meter.pending and not meter.in_studio,"load does not publish a new checkpoint or active progress")
	check(store.save(body).status==&"saved","second valid private generation")
	var broken:=FileAccess.open(store.directory.path_join("checkpoint.2.json"),FileAccess.WRITE);broken.store_string("damaged-current-evidence");broken.close()
	var invalid:=ReadJob.new();invalid.start(store.directory,catalog);await await_job(invalid,"invalid latest with valid backup")
	check(invalid.inspected.get("status")!=&"valid" and invalid.inspected.has("backup") and invalid.player==null and invalid.world==null,"no silent backup attachment")
	meter.queue_free();finish()
func finish() -> void:
	var report:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"measurements":measurements,"native":not DisplayServer.get_name()=="headless"};FileAccess.open(output(),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_WORKERS "+JSON.stringify(report));quit(0 if failures.is_empty() else 1)
