extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
var captures: Array=[]
var output:=""

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer!=null: return true
		var server:=TCPServer.new()
		if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK: return false
		_writer=server
		return true

func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("MARKET_UI "+label)

func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix): return value.substr(prefix.length())
	return ""

func _initialize() -> void:
	_run.call_deferred()

func replace_store(node: Node) -> void:
	if node is CheckpointCoordinator: node.store=TestStore.new("user://saves/studio",node._validate_payload)

func capture_view(label: String, control: Control, dimensions: Vector2i) -> void:
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var path:=output+"-"+label+"-%dx%d.png"%[dimensions.x,dimensions.y]
	var pixels:=root.get_texture().get_image()
	expect(pixels.save_png(path)==OK,"capture "+label)
	captures.append({"path":path,"rect":str(control.get_global_rect()),"viewport":str(dimensions),"pixels":str(pixels.get_size())})
	expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(control.get_global_rect()),"view inside viewport "+label)

func _run() -> void:
	output=arg("--output=")
	var pair: Variant=JSON.parse_string(FileAccess.get_file_as_string(arg("--checkpoint=")))
	expect(pair is Dictionary,"legal campaign checkpoint read")
	if not pair is Dictionary: quit(1);return
	var owner:=CheckpointCoordinator.new()
	owner.rival_catalog=root.get_node("CardDatabase").get_development_catalog()
	owner.store=TestStore.new("user://saves/studio",owner._validate_payload)
	var combined: Dictionary=pair.player.duplicate(true)
	combined.rival_world=pair.world
	expect(owner.store.save(combined).status==&"saved","normal Store publishes actual legal campaign")
	owner.store.release_writer();owner.free()
	node_added.connect(replace_store)
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		expect(game._active_phase is MainMenu,"normal Main Menu")
		game._continue_checkpoint()
		await process_frame
		expect(game._active_phase is StudioPhase,"normal Gameplay Continue")
		if not game._active_phase is StudioPhase: quit(1);return
		var studio: StudioPhase=game._active_phase
		var before:=StudioCheckpoint.new().capture(game.run_state)
		expect(game.rival_world.market_snapshot.id==pair.world.market.id,"month identity restored")
		studio._show_predevelopment()
		game.get_node("%GameplayHUD").contextual_tip.hide()
		expect(studio._predevelopment.genre_targets_label.text.contains("other same-Genre"),"visible prospective market explanation")
		await capture_view("predevelopment",studio._predevelopment,dimensions)
		expect(studio._predevelopment.begin_button.get_global_rect().end.y<=dimensions.y,"Begin button accessible")
		studio._predevelopment.cancelled.emit()
		studio.open_summary()
		studio._selected_release_id=game.run_state.get_released_game_ids()[1]
		studio.open_detailed_review()
		expect(studio._review_view.get_node("%CoreDescription").text.contains("Strong-release lifts"),"saved release explanation")
		studio._review_view.get_node("Margin/Layout/Categories").current_tab=1
		game.get_node("%GameplayHUD").contextual_tip.hide()
		await capture_view("review",studio._review_view,dimensions)
		studio._review_view.hide()
		studio.open_monthly_sales()
		expect(not studio._monthly_report._report.is_empty(),"exact monthly report available")
		var item: TreeItem=studio._monthly_report._table.get_root().get_first_child()
		if item!=null: item.select(0);studio._monthly_report._show_month()
		expect(studio._monthly_report._detail.text.contains("Genre-only"),"visible exclusive bucket explanation")
		await capture_view("sales",studio._monthly_report,dimensions)
		var after:=StudioCheckpoint.new().capture(game.run_state)
		var record:=FileAccess.open(output+"-state-%d.json"%dimensions.x,FileAccess.WRITE)
		record.store_string(JSON.stringify({"before":before,"after":after}));record.close()
		# Existing context tips mark their topics seen when screens open.
		before.run.erase("seen_tutorial_topics");after.run.erase("seen_tutorial_topics")
		expect(before==after,"all mechanics and RNG unchanged; existing tip-seen UI metadata excluded")
		game.checkpoints.store.release_writer()
		game.queue_free();await process_frame
	var f:=FileAccess.open(output+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity(),"captures":captures},"\t"));f.close()
	print("MARKET_UI checks=%d failures=%d"%[checks,failures])
	quit(0 if failures==0 else 1)
