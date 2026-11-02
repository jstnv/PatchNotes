extends SceneTree
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
class ObservedStore extends StudioCheckpointStore:
	var lock:=Mutex.new()
	var publications:=0
	func acquire() -> bool:
		if _writer!=null:return true
		_writer=TCPServer.new();return _writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")==OK
	func count() -> int:
		lock.lock();var value:=publications;lock.unlock();return value
	func _publish(payload: Dictionary,recovery: bool) -> Dictionary:
		lock.lock();publications+=1;lock.unlock()
		OS.delay_msec(150)
		return super._publish(payload,recovery)
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var run:=StudioCheckpoint.new().hydrate(pair.player)
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var codec:=WorldCodec.new();var world:=codec.restore(pair.world,pair.player,run,catalog)
	check(world!=null,"Genuine paired fixture restores: "+codec.error)
	if world==null:quit(1);return
	var owner:=CheckpointCoordinator.new();root.add_child(owner)
	owner.store.release_writer();owner.store=ObservedStore.new("user://coalescing",owner._validate_payload)
	owner.background_saves=true;owner.attach(run);check(owner.attach_rivals(world,catalog),"Paired world bound")
	check(not owner.before_studio_action(),"Actual coordinator rejects Studio actions outside Studio")
	owner.entered_studio();check(await owner.wait_saved(),"Baseline is durable")
	var before:=owner.completed_saves
	check(run.add_cash(1),"First recorded mutation")
	owner._request_save()
	check(owner._write_job!=null,"Immutable preparation is outstanding")
	check(run.add_cash(1),"Newer recorded mutation supersedes preparation")
	paused=true
	check(await owner.wait_saved(),"Paused tree drains newest generation")
	paused=false
	check(owner.completed_saves==before+1,"Discarded preparation never reports Saved")
	check(owner.store.inspect().sequence==before+1,"Only newest generation publishes")
	var baseline: Dictionary=owner.last_payload.duplicate(true)
	var publication_count: int=owner.store.count()
	check(run.add_cash(1),"Begin publication case")
	owner._request_save()
	var deadline:=Time.get_ticks_msec()+30000
	while owner.store.count()==publication_count and Time.get_ticks_msec()<deadline:await process_frame
	check(owner.store.count()==publication_count+1,"Actual Store publication has begun")
	check(run.add_cash(1),"Newer mutation while publishing")
	check(await owner.wait_saved(),"In-progress publication and follow-up finish")
	check(owner.completed_saves==before+3,"Started publication cannot be cancelled; latest follows once")
	baseline=owner.last_payload.duplicate(true)
	before=owner.completed_saves
	owner.store.fault=&"before_rename"
	check(run.add_cash(1),"Fault case initial mutation");owner._request_save()
	check(run.add_cash(1),"Fault case latest mutation")
	check(not await owner.wait_saved(),"Replacement writer failure surfaces")
	check(owner.completed_saves==before and owner.last_payload==baseline,"Failure/cancellation preserve durable receipts")
	check(not owner.before_studio_action() and not owner.before_departure(),"Failure blocks Studio mutation and departure")
	owner.store.fault=&""
	check(await owner.retry_background(),"Retry publishes latest state")
	var current:=owner.store.inspect()
	check(current.status==&"valid","Retry independently inspects as valid")
	var player: Dictionary=current.payload.duplicate(true);player.erase("rival_world");player.sequence="1"
	check(player==StudioCheckpoint.new().capture(run),"Latest complete finance/history/RNG survives Retry")
	check(run.add_cash(1),"Teardown case first mutation");owner._request_save()
	check(run.add_cash(1),"Teardown latest mutation")
	check(owner.flush() and not owner.pending and owner._write_job==null,"Synchronous teardown barrier drains superseded preparation")
	current=owner.store.inspect();player=current.payload.duplicate(true);player.erase("rival_world");player.sequence="1"
	check(player==StudioCheckpoint.new().capture(run),"Teardown leaves exact latest Studio durable")
	owner.in_studio=false
	var retained: Dictionary=owner.last_payload.duplicate(true)
	check(run.add_cash(1) and not owner.pending,"Outside-Studio mutation never schedules a checkpoint")
	check(owner.last_payload==retained and not owner.before_studio_action(),"Continue boundary stays Studio-only")
	var directory:=owner.store.directory
	var previous_id: String=owner.last_payload.run_id
	owner.free()
	# An explicitly authorized new-Studio replacement must retain its intent and
	# the old checkpoint through both discarded preparation and publication fault.
	var fresh:=RunState.new();fresh.initialize_cash(0)
	check(fresh.create_studio_with_traits("Replacement coalescing",&"action",[]) and fresh.finalize_starter_selection(),"Create ordinary replacement Studio")
	var replacement:=CheckpointCoordinator.new();root.add_child(replacement)
	replacement.store.release_writer();replacement.store=ObservedStore.new(directory,replacement._validate_payload)
	replacement.rival_catalog=catalog;replacement.background_saves=true;replacement.attach(fresh)
	replacement.replace_on_save=true;replacement.entered_studio();replacement._request_save()
	replacement._write_job.supersede()
	check(fresh.add_cash(1),"Latest replacement mutation is recorded")
	replacement._finish_write()
	check(replacement.replace_on_save and replacement.pending and replacement.completed_saves==0 and replacement.last_payload.is_empty(),"Discarded replacement preserves intent without inventing durable receipts")
	check(replacement.store.inspect().payload.run_id==previous_id,"Discarded replacement leaves original slot intact")
	replacement.store.fault=&"before_rename"
	check(not await replacement.wait_saved() and replacement.replace_on_save,"Failed replacement preserves replacement intent")
	check(replacement.store.inspect().payload.run_id==previous_id,"Failed replacement preserves original valid slot")
	replacement.store.fault=&""
	check(await replacement.retry_background() and not replacement.replace_on_save and replacement.completed_saves==1,"Retry publishes replacement exactly once")
	var replaced:=replacement.store.inspect()
	check(replaced.status==&"valid" and replaced.payload.run_id==str(fresh._bank_run_id),"Latest replacement owns the valid slot")
	var restored:=replacement.load_current()
	check(restored!=null and StudioCheckpoint.new().capture(restored)==StudioCheckpoint.new().capture(fresh),"Replacement Continue preserves complete current state")
	replacement.free()
	print("CONTRACT_COALESCING checks=%d failures=%d"%[checks,failures]);quit(failures)
