## Run with PN_CHECKPOINT_TEST_PORT on an isolated user profile.
extends SceneTree
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null:return true
		var server:=TCPServer.new()
		if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:return false
		_writer=server
		return true
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;push_error(label)
func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:node.store=TestStore.new("user://engine-skill-world-"+str(Time.get_ticks_usec()),node._validate_payload)
func _initialize() -> void:verify.call_deferred()
func verify() -> void:
	node_added.connect(_replace_store)
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
	await process_frame
	var title_deadline:=Time.get_ticks_msec()+20000
	while (game._loading_checkpoint or game._title_checkpoint_job!=null) and Time.get_ticks_msec()<title_deadline:await process_frame
	check(not game._loading_checkpoint and game._title_checkpoint_job==null,"Title checkpoint inspection finishes before Studio creation")
	if game._loading_checkpoint or game._title_checkpoint_job!=null:quit(1);return
	var menu: MainMenu=game._active_phase
	game._on_studio_created("Tree World",&"action",[],menu)
	var deadline:=Time.get_ticks_msec()+20000
	while game._transition_in_progress and Time.get_ticks_msec()<deadline:await process_frame
	await process_frame
	var run: RunState=game.run_state
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Tree Engine"))
	check(created.get("ok",false),"World creates owned engine")
	if not created.get("ok",false):quit(1);return
	var id: StringName=created.engine_id
	var starters: Array[StringName]=[];starters.assign(run.ProprietaryEngines.FOUNDATIONS)
	check(run.get_engine_feature_state().engines[id].committed==starters,"Owned engine starts with all four Features in future supply")
	var state:=run.get_proprietary_engine_state();state.engines[id].challenge_progress[&"graphics"]=5;run._proprietary_engines=state
	check(run.purchase_engine_skill(run.get_engine_skill_quote(id,&"graphics")).get("ok",false),"World purchases completed branch")
	check(await game.checkpoints.wait_saved() and game.checkpoints.store.inspect().status==&"valid","Player and world save together")
	game._continue_checkpoint();await process_frame
	check(game.run_state.get_proprietary_engine_row(id).branch_progress.get(&"graphics")==1 and game.run_state.get_engine_feature_state().engines[id].capacity==25,"World Continue restores one branch and frozen milestone")
	check(game.run_state.get_engine_feature_state().engines[id].initial==starters and game.run_state.get_future_project_feature_ids(id)==starters,"World Continue preserves the four implemented starter Features")
	print("Engine Skill world Continue: %d failures"%failures)
	game.checkpoints.store.release_writer()
	quit(1 if failures else 0)
