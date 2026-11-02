extends SceneTree
var failures: Array=[]
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:go.call_deferred()
func go() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	if OS.get_environment("PN_CONTINUE_MODE")=="seed":
		var validator=load("res://scripts/persistence/checkpoint_write_validator.gd").new()
		validator.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
		var store:=StudioCheckpointStore.new("user://saves/studio",validator._validate_payload)
		var combined: Dictionary=pair.player.duplicate(true);combined["rival_world"]=pair.world.duplicate(true)
		var result:=store.save(combined)
		check(result.status==&"saved","Genuine pair becomes durable exported-build checkpoint: "+str(result.get("reason","")))
		store.release_writer();finish({"seed_status":str(result.status)});return
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();root.add_child(game)
	for i in 8:await process_frame
	check(game._active_phase is MainMenu,"Fresh exported process enters Main Menu")
	if not game._active_phase is MainMenu:finish({});return
	check(not game._active_phase._actions.Continue.disabled,"Saved Studio enables actual Continue action")
	var before: Dictionary=game.checkpoints.store.inspect()
	check(before.status==&"valid","Exported process cold-validates durable checkpoint")
	var bytes:=FileAccess.get_file_as_bytes(before.get("path",""))
	var start:=Time.get_ticks_msec();game._active_phase.continue_requested.emit()
	check(game.get_node_or_null("ContinueLoading")!=null,"Continue displays loading surface immediately")
	var deadline:=Time.get_ticks_msec()+90000
	while game._loading_checkpoint and Time.get_ticks_msec()<deadline:await process_frame
	check(not game._loading_checkpoint,"Cold Continue finishes before deadline")
	check(game._active_phase is StudioPhase and game.project_state==null and game.active_contract_state==null,"Continue reveals only Studio boundary")
	check(StudioCheckpoint.new().capture(game.run_state)==pair.player,"Cold Continue preserves entire player/finance/history/RNG")
	var actual: Dictionary=load("res://scripts/market/rival_world_checkpoint.gd").new().capture(game.rival_world)
	var expected: Dictionary=pair.world.duplicate(true);expected.source_identity=actual.get("source_identity","")
	check(actual==expected,"Cold Continue preserves entire rival world except executing-source stamp")
	var after: Dictionary=game.checkpoints.store.inspect()
	check(after.get("payload")==before.get("payload") and FileAccess.get_file_as_bytes(before.get("path",""))==bytes,"Cold Continue does not rewrite save or repeat monthly settlement")
	var report:={"continue_ms":Time.get_ticks_msec()-start,"stage":"studio","runtime":actual.get("source_identity","")}
	game.queue_free();await process_frame;finish(report)
func finish(report: Dictionary) -> void:
	report.failures=failures
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("EXPORT_CONTINUE_DONE failures=",failures.size());quit(1 if failures.size() else 0)
