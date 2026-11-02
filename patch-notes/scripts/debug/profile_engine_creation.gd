## One-off headless profile. Never uses the player save slot.
extends SceneTree
class TestStore extends StudioCheckpointStore:
	var save_ms:=0.0
	var validation_ms:=0.0
	var validation_calls:=0
	var validation_samples: Array[float]=[]
	var save_bytes:=0
	var _delegate: Callable
	func _validation_context() -> PackedByteArray:
		var target: Object=_delegate.get_object()
		return target.store_proof_context() if target!=null and target.has_method("store_proof_context") else []
	func _timed_validate(payload: Dictionary) -> String:
		var started:=Time.get_ticks_usec()
		var result: String=_delegate.call(payload)
		var elapsed:=float(Time.get_ticks_usec()-started)/1000.0
		validation_ms+=elapsed;validation_samples.append(elapsed)
		validation_calls+=1
		return result
	func save(payload: Dictionary) -> Dictionary:
		validation_ms=0.0;validation_calls=0;validation_samples.clear();save_bytes=0
		_delegate=validator;validator=_timed_validate
		var started:=Time.get_ticks_usec()
		var result:=super.save(payload)
		save_ms=float(Time.get_ticks_usec()-started)/1000.0
		validator=_delegate
		if result.get("status")==&"saved":save_bytes=FileAccess.get_file_as_bytes(result.path).size()
		return result
	func replace_run(payload: Dictionary) -> Dictionary:
		validation_ms=0.0;validation_calls=0;validation_samples.clear();save_bytes=0
		_delegate=validator;validator=_timed_validate
		var started:=Time.get_ticks_usec()
		var result:=super.replace_run(payload)
		save_ms=float(Time.get_ticks_usec()-started)/1000.0
		validator=_delegate
		if result.get("status")==&"saved":save_bytes=FileAccess.get_file_as_bytes(result.path).size()
		return result
	func acquire() -> bool:
		if _writer!=null:return true
		var server:=TCPServer.new()
		if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:return false
		_writer=server
		return true
func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:node.store=TestStore.new("user://engine-create-profile-"+str(Time.get_ticks_usec()),node._validate_payload)
func _initialize() -> void:profile.call_deferred()
func profile() -> void:
	node_added.connect(_replace_store)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
	await process_frame
	while game._loading_checkpoint:await process_frame
	var menu: MainMenu=game._active_phase
	game._on_studio_created("Profile Engines",&"action",[],menu)
	var deadline:=Time.get_ticks_msec()+20000
	while game._transition_in_progress and Time.get_ticks_msec()<deadline:await process_frame
	await process_frame
	if not await game.checkpoints.wait_saved():print("PROFILE ERROR initial save: ",game.checkpoints.failure);quit(1);return
	var run: RunState=game.run_state
	var baseline_saves: int=game.checkpoints.completed_saves
	var direct_cash_before:=run.get_cash_cents()
	var direct_cycle_before:=run.get_completed_run_cycles()
	var t0:=Time.get_ticks_usec()
	var quote:=run.get_proprietary_engine_creation_quote("Profile Direct")
	var t1:=Time.get_ticks_usec()
	var result:=run.create_proprietary_engine(quote)
	var t2:=Time.get_ticks_usec()
	var saved: bool=await game.checkpoints.wait_saved()
	var t3:=Time.get_ticks_usec()
	var direct_exact: bool=run.get_cash_cents()==direct_cash_before-10000 and run.get_completed_run_cycles()==direct_cycle_before and game.checkpoints.completed_saves-baseline_saves==1
	print("PROFILE_DIRECT ",JSON.stringify({"ok":result.get("ok",false),"exact_fee_and_save":direct_exact,"quote_ms":float(t1-t0)/1000.0,"transaction_ms":float(t2-t1)/1000.0,"save_wait_ms":float(t3-t2)/1000.0,"store_ms":game.checkpoints.store.save_ms,"validation_ms":game.checkpoints.store.validation_ms,"validation_calls":game.checkpoints.store.validation_calls,"validation_samples":game.checkpoints.store.validation_samples,"bytes":game.checkpoints.store.save_bytes,"saves":game.checkpoints.completed_saves-baseline_saves,"error":game.checkpoints.failure}))
	var studio: StudioPhase=game._active_phase
	var u0:=Time.get_ticks_usec()
	studio._open_engines()
	var browser=studio._engine_browser
	var u1:=Time.get_ticks_usec()
	browser._show_page(&"create")
	browser.create_input.text="Profile UI"
	var before_ui_saves: int=game.checkpoints.completed_saves
	var ui_cash_before:=run.get_cash_cents()
	var ui_cycle_before:=run.get_completed_run_cycles()
	var u2:=Time.get_ticks_usec()
	browser._create()
	var u3:=Time.get_ticks_usec()
	var saved_ui: bool=await game.checkpoints.wait_saved()
	var u4:=Time.get_ticks_usec()
	var ui_exact: bool=run.get_cash_cents()==ui_cash_before-10000 and run.get_completed_run_cycles()==ui_cycle_before and game.checkpoints.completed_saves-before_ui_saves==1
	print("PROFILE_UI ",JSON.stringify({"ok":saved_ui,"exact_fee_and_save":ui_exact,"open_ms":float(u1-u0)/1000.0,"create_handler_ms":float(u3-u2)/1000.0,"save_wait_ms":float(u4-u3)/1000.0,"store_ms":game.checkpoints.store.save_ms,"validation_ms":game.checkpoints.store.validation_ms,"validation_calls":game.checkpoints.store.validation_calls,"validation_samples":game.checkpoints.store.validation_samples,"bytes":game.checkpoints.store.save_bytes,"saves":game.checkpoints.completed_saves-before_ui_saves,"error":game.checkpoints.failure}))
	browser._show_page(&"create")
	browser.create_input.text="Profile UI Second"
	var before_second_saves: int=game.checkpoints.completed_saves
	var second_cash_before:=run.get_cash_cents()
	var second_cycle_before:=run.get_completed_run_cycles()
	var v0:=Time.get_ticks_usec()
	browser._create()
	var v1:=Time.get_ticks_usec()
	var saved_second: bool=await game.checkpoints.wait_saved()
	var v2:=Time.get_ticks_usec()
	var second_exact: bool=run.get_cash_cents()==second_cash_before-10000 and run.get_completed_run_cycles()==second_cycle_before and game.checkpoints.completed_saves-before_second_saves==1
	print("PROFILE_UI_SECOND ",JSON.stringify({"ok":saved_second,"exact_fee_and_save":second_exact,"create_handler_ms":float(v1-v0)/1000.0,"save_wait_ms":float(v2-v1)/1000.0,"store_ms":game.checkpoints.store.save_ms,"validation_ms":game.checkpoints.store.validation_ms,"validation_calls":game.checkpoints.store.validation_calls,"validation_samples":game.checkpoints.store.validation_samples,"bytes":game.checkpoints.store.save_bytes,"saves":game.checkpoints.completed_saves-before_second_saves,"error":game.checkpoints.failure}))
	var loaded: RunState=game.checkpoints.load_current()
	var reload_ok: bool=loaded!=null and loaded.get_proprietary_engine_state().engines.size()==3 and loaded.get_cash_cents()==run.get_cash_cents()
	print("PROFILE_RELOAD ",JSON.stringify({"ok":reload_ok,"engine_count":0 if loaded==null else loaded.get_proprietary_engine_state().engines.size()}))
	game.checkpoints.store.release_writer()
	quit(0 if result.get("ok",false) and saved and saved_ui and saved_second and direct_exact and ui_exact and second_exact and reload_ok else 1)
