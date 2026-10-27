extends SceneTree
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(label)
func arg(prefix: String) -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with(prefix): return item.substr(prefix.length())
	return ""
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--expected=")))
	var output:=arg("--output=")
	var results: Array=[]
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game);await process_frame
		expect(game._active_phase is MainMenu,"ordinary Main Menu")
		game._continue_checkpoint();await process_frame
		expect(game._active_phase is StudioPhase,"ordinary Continue reaches Studio")
		if not game._active_phase is StudioPhase: quit(1);return
		var player:=StudioCheckpoint.new().capture(game.run_state)
		var world:=preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(game.rival_world)
		# Context tips alone may mark existing topics seen when entering Studio.
		var reference: Dictionary=expected.player.duplicate(true)
		player.run.erase("seen_tutorial_topics");reference.run.erase("seen_tutorial_topics")
		expect(player==reference,"restored player authority and RNG exact")
		expect(world==expected.world,"restored world authority and RNG exact")
		var state: Dictionary=game.checkpoints.store.inspect()
		expect(state.sequence==expected.generation,"Continue does not publish generation")
		expect(FileAccess.get_sha256(state.path)==expected.generation_sha256_after,"original generation bytes unchanged")
		game.get_node("%GameplayHUD").contextual_tip.hide()
		await create_timer(0.2).timeout;await RenderingServer.frame_post_draw
		var path:=output+"-%dx%d.png"%[dimensions.x,dimensions.y]
		expect(root.get_texture().get_image().save_png(path)==OK,"Studio capture")
		results.append({"dimensions":str(dimensions),"capture":path,"generation":state.sequence,"cycle":game.run_state.get_completed_run_cycles()})
		game.checkpoints.store.release_writer();game.queue_free();await process_frame
	var file:=FileAccess.open(output+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":Replay.source_identity(),"checks":checks,"failures":failures,"results":results},"\t"));file.close()
	print("EXPORTED_CONTINUE checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
