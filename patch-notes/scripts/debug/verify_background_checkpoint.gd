extends SceneTree

const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
var max_gap_us:=0
var frames:=0
var last_frame:=0
var observing:=false
var kickoff_ms:=0.0

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		var server:=TCPServer.new()
		if server.listen(47413,"127.0.0.1")!=OK: return false
		_writer=server
		return true
	func _publish(payload: Dictionary, recovery: bool) -> Dictionary:
		OS.delay_msec(150)
		return super._publish(payload,recovery)

func expect(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL: "+label)

func _process(_delta: float) -> bool:
	if observing:
		var now:=Time.get_ticks_usec()
		if last_frame>0: max_gap_us=maxi(max_gap_us,now-last_frame)
		last_frame=now
		frames+=1
	return false

func finish() -> void:
	var report: Dictionary={"ok":failures==0,"checks":checks,"failures":failures,"frames":frames,"max_frame_gap_ms":max_gap_us/1000.0,"kickoff_ms":kickoff_ms}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report))
	quit(failures)

func _initialize() -> void:
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+".pid",FileAccess.WRITE).store_string(str(OS.get_process_id()))
	await process_frame
	var owner: Node=CheckpointCoordinator.new()
	root.add_child(owner)
	var properties: Array=owner.get_property_list().map(func(item: Dictionary): return item.name)
	expect(properties.has("background_saves"),"Coordinator supports an owned background save lifecycle")
	if not properties.has("background_saves"):
		owner.free()
		finish()
		return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_BG_FIXTURE")))
	var run:=StudioCheckpoint.new().hydrate(data.player)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var world:=WorldCodec.new().restore(data.world,data.player,run,catalog)
	expect(run!=null and world!=null,"Genuine compiled96-cycle fixture restores")
	owner.store.release_writer()
	owner.store=PrivateStore.new("user://background-checkpoint",owner._validate_payload)
	owner.attach(run)
	expect(owner.attach_rivals(world,catalog),"Real player/world are bound")
	owner.background_saves=true
	var start:=Time.get_ticks_usec()
	observing=true
	owner.entered_studio()
	var kickoff: float=(Time.get_ticks_usec()-start)/1000.0
	kickoff_ms=kickoff
	expect(kickoff<100.0,"96-cycle save kickoff does not block a gameplay frame")
	expect(owner.is_saving(),"Saving remains distinct from durable Saved")
	# Worker owns the first immutable snapshot; subsequent actions must be legal,
	# detached and coalesced without superseding an in-flight publication.
	expect(run.add_cash(1),"A legal newer Studio mutation can occur while saving")
	expect(run.add_cash(1),"Another mutation coalesces behind one writer")
	paused=true
	var ok: bool=await owner.wait_saved()
	paused=false
	observing=false
	expect(ok and not owner.is_saving(),"Paused tree still completes latest durable save: "+owner.failure)
	expect(frames>10 and max_gap_us<150000,"Frames keep advancing throughout validation/publication")
	var current: Dictionary=owner.store.inspect()
	expect(current.status==&"valid","Final generation validates independently")
	if current.status!=&"valid":
		owner.free()
		finish()
		return
	var saved: Dictionary=current.payload.duplicate(true)
	saved.erase("rival_world")
	saved.sequence="1"
	expect(saved==StudioCheckpoint.new().capture(run),"Newest detached player/RNG state is durable")
	expect(current.sequence==2,"Intervening signals coalesce to exactly one follow-up generation")
	expect(owner.completed_saves==2,"Only the two durable publications advance notification state")
	var prior_sequence: int=current.sequence
	run.cash_changed.emit()
	await process_frame
	expect(await owner.wait_saved(),"Identical notifications finish without a new publication")
	expect(owner.store.inspect().sequence==prior_sequence,"Background identical-state notifications do not create another generation")
	expect(owner.completed_saves==prior_sequence,"Identical notifications do not create a new Saved notification token")
	owner.store.fault=&"before_rename"
	expect(run.add_cash(1),"Fault fixture commits a new Studio action")
	await process_frame
	expect(not await owner.wait_saved(),"Failed background publication surfaces failure")
	expect(not run.checkpoint_mutations_allowed and not owner.before_departure(),"Save failure blocks mutations and departure")
	expect(owner.store.inspect().sequence==prior_sequence,"Failed write preserves last good generation")
	expect(owner.completed_saves==prior_sequence,"Failed publication cannot announce another successful save")
	owner.store.fault=&""
	owner.failure=""
	owner.pending=true
	expect(await owner.wait_saved(),"Retry safely publishes latest state")
	expect(run.checkpoint_mutations_allowed,"Retry restores mutation permission")
	# Teardown must join before releasing the writer lease and preserve work.
	expect(run.add_cash(1),"Teardown fixture commits an action")
	await process_frame
	var disk: StudioCheckpointStore=owner.store
	var location: String=disk.directory
	owner.free()
	disk.release_writer()
	var fresh: Node=CheckpointCoordinator.new()
	root.add_child(fresh)
	fresh.store=PrivateStore.new(location,fresh._validate_payload)
	fresh.rival_catalog=catalog
	fresh.background_saves=true
	var cold: RunState=fresh.load_current()
	expect(cold!=null and fresh.store.inspect().get("sequence")==prior_sequence+2,"Teardown drains and releases its writer before a fresh Continue")
	expect(fresh.completed_saves==0,"Loading a saved Studio does not announce a new publication")
	expect(cold.get_cash_cents()==run.get_cash_cents(),"Teardown persisted the latest committed action")
	fresh.entered_studio(true)
	expect(cold.add_cash(1),"Fresh Continue allows a new committed action")
	expect(await fresh.wait_saved(),"Fresh Continue initializes detached rival definitions for its next background save")
	fresh.free()
	finish()
