extends SceneTree
var game: Control
var rows: Array=[]
var failures: Array=[]
var max_gap:=0
var last_frame:=0
var sampling:=false
class MeterStore extends StudioCheckpointStore:
	var writes: Array=[]
	func acquire() -> bool:
		if _writer!=null:return true
		_writer=TCPServer.new()
		return _writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")==OK
	func _publish(payload: Dictionary,recovery: bool) -> Dictionary:
		var start:=Time.get_ticks_msec()
		var main:=Thread.is_main_thread()
		var result:=super._publish(payload,recovery)
		writes.append({"milliseconds":Time.get_ticks_msec()-start,"main_thread":main,"status":str(result.status)})
		return result
func check(ok: bool,label: String) -> bool:
	if not ok:failures.append(label);push_error(label)
	return ok
func frame() -> void:
	var now:=Time.get_ticks_msec()
	if sampling and last_frame>0:max_gap=maxi(max_gap,now-last_frame)
	last_frame=now
func begin() -> int:
	max_gap=0;last_frame=Time.get_ticks_msec();sampling=true
	return last_frame
func record(label: String,start: int,call_ms: int) -> void:
	rows.append({"action":label,"total_ms":Time.get_ticks_msec()-start,"call_ms":call_ms,"frame_gap_ms":max_gap,"completed_saves":game.checkpoints.completed_saves,"saving":game.checkpoints.is_saving(),"pending":game.checkpoints.pending,"in_studio":game.checkpoints.in_studio,"cycle":game.run_state.get_completed_run_cycles()})
	sampling=false;print("CONTRACT_PROFILE ",JSON.stringify(rows[-1]))
func wait_until(predicate: Callable,label: String) -> bool:
	var deadline:=Time.get_ticks_msec()+60000
	while not predicate.call() and Time.get_ticks_msec()<deadline:await process_frame
	return check(predicate.call(),label)
func _initialize() -> void:go.call_deferred()
func play_contract(label: String) -> bool:
	if not check(game._active_phase is ContractPhase,"Actual Contract phase mounted"):return false
	var phase: ContractPhase=game._active_phase
	for index in phase._state.get_required_hands():
		var start:=begin()
		for view in phase._candidate_row.card_views().slice(0,4):phase._on_card_pressed(view)
		record(label+" select"+str(index+1),start,Time.get_ticks_msec()-start)
		start=begin()
		var saved: int=game.checkpoints.completed_saves
		var ok:=phase._play_selected_hand()
		var call_ms:=Time.get_ticks_msec()-start
		await process_frame;await process_frame
		record(label+" hand"+str(index+1),start,call_ms)
		if not check(ok and game.checkpoints.completed_saves==saved and not game.checkpoints.is_saving(),"Legal hand with no active-Contract checkpoint"):return false
	var start:=begin()
	phase.completion_dismissed.emit(phase)
	var call_ms:=Time.get_ticks_msec()-start
	if not await wait_until(func():return game._active_phase is StudioPhase,"Return to actual Studio"):return false
	pass # rapid next Studio action while its background save is outstanding
	record(label+" return/save",start,call_ms)
	return true
func go() -> void:
	process_frame.connect(frame)
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var run:=adapter.hydrate(pair.player)
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var world=codec.restore(pair.world,pair.player,run,catalog)
	if not check(run!=null and world!=null,"Genuine saved player/world hydrate: "+codec.error):finish();return
	# Presentation progress only, through the legal API; rewards already settled.
	while world.pending_awards_index()>=0:
		var index: int=world.pending_awards_index()
		var ok: bool=world.complete_awards_presentation() if world.annual_awards.entries[index].stage==9 else world.advance_awards_stage()
		if not check(ok,"Complete existing ceremony setup"):finish();return
	game=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
	for i in 8:await process_frame
	game._onboarding.answer(true)
	game.checkpoints.store.release_writer()
	game.checkpoints.store=MeterStore.new("user://contract-latency",game.checkpoints._validate_payload)
	game.run_state=run;game.rival_world=world
	game.checkpoints.attach(run)
	check(game.checkpoints.attach_rivals(world,catalog),"Paired world attached")
	game._connect_rival_calendar();game.get_node("%GameplayHUD").setup(null,run)
	check(game._enter_initial_studio(true),"Actual restored Studio entered")
	game.checkpoints.pending=true
	check(await game.checkpoints.wait_saved(),"Private baseline is durable")
	var studio: StudioPhase=game._active_phase
	studio._open_contracts(ContractState.CONTRACT_ID)
	var start:=begin();studio._accept_contract();var call_ms:=Time.get_ticks_msec()-start
	if not await wait_until(func():return game._active_phase is ContractPhase,"Ironclad acceptance"):finish();return
	record("accept intro",start,call_ms)
	if not await play_contract("intro"):finish();return
	studio=game._active_phase;studio._open_contracts()
	studio._search_work.select(0);studio._refresh_contract_search()
	if not check(not studio._search_quote.is_empty(),"Legal repeat cash Search quote"):finish();return
	var before: int=run.get_contract_search_state().receipts.size()
	start=begin();studio._search_for_contracts();call_ms=Time.get_ticks_msec()-start
	if not await wait_until(func():return run.get_contract_search_state().receipts.size()==before+1,"Actual Search commits"):finish();return
	pass # accept immediately; departure must await the latest Search checkpoint
	record("search/save",start,call_ms)
	var offer: StringName=run.get_contract_search_state().receipts[-1].offer_id
	studio._open_contracts(offer)
	start=begin();studio._accept_contract();call_ms=Time.get_ticks_msec()-start
	if not await wait_until(func():return game._active_phase is ContractPhase,"Found cash acceptance"):finish();return
	record("accept found",start,call_ms)
	await play_contract("cash")
	finish()
func finish() -> void:
	if is_instance_valid(game) and game.checkpoints.in_studio:check(await game.checkpoints.wait_saved(),"Final latest Studio state durable")
	var report: Dictionary={"rows":rows,"failures":failures}
	if is_instance_valid(game):
		report.writes=game.checkpoints.store.writes
		report.player=StudioCheckpoint.new().capture(game.run_state)
		report.world=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(game.rival_world)
		report.runtime=load("res://scripts/simulation/development_replay.gd").source_identity()
		game.queue_free();await process_frame
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CONTRACT_PROFILE_DONE failures=",failures.size())
	quit(1 if failures.size() else 0)
