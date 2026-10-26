extends SceneTree
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer=server
		return true
var checks := 0
var failures := 0
var output := ""
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or output.is_empty():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	node_added.connect(func(node):
		if node is CheckpointCoordinator:node.store=TestStore.new("user://saves/studio",node._validate_payload))
	# An explicit new save must reach the invitation even on a returning profile.
	assert(OnboardingPreferences.new().answer(true))
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	for i in range(4):await process_frame
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	var menu: MainMenu=game._active_phase
	var music=root.get_node("Soundtrack")
	var transport: AudioStreamPlayer=music.player
	var playback=transport.get_stream_playback()
	var start: float=music.presentation_seconds()
	menu.studio_created.emit("Fresh Horizon",&"adventure",[])
	var overlay=game.get_node_or_null("NewStudioLoading")
	expect(overlay!=null,"Create immediately shows a new-save loading screen")
	if overlay==null:
		game.queue_free();await process_frame;quit(failures);return
	expect(game._transition_in_progress and game.guided_tutorial==null,"Creation is guarded before the tutorial exists")
	expect(overlay.studio_label.text=="Fresh Horizon" and overlay.date_label.text=="1980 · Month 1, First Half","New-save loading shows Studio name and game date")
	menu.studio_created.emit("Duplicate must not win",&"action",[])
	var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true
	root.push_input(event,true)
	var stages := []
	var captured := false
	var deadline:=Time.get_ticks_msec()+15000
	while game._transition_in_progress and Time.get_ticks_msec()<deadline:
		if not stages.has(overlay.stage_label.text):stages.append(overlay.stage_label.text)
		if not captured and overlay._surface.modulate.a>=0.99:
			await capture("new-save-loading-1280")
			captured=true
		await process_frame
	expect(not game._transition_in_progress and game.get_node_or_null("NewStudioLoading")==null,"Loading completes and removes its input cover")
	expect(not paused and not game.pause_menu.is_open(),"Esc during creation cannot pause the loading flow")
	expect(stages.size()>=2 and captured,"Real creation stages render before the invitation")
	expect(game.run_state.get_studio_name()=="Fresh Horizon" and game.run_state.get_cash_cents()==570000 and game.run_state.get_completed_run_cycles()==0,"Identity, funding and free Studio entry commit once")
	var guide: GuidedProductionTutorial=game.guided_tutorial
	expect(guide!=null and guide.new_button.is_visible_in_tree() and guide.new_button.has_focus(),"Loading reveals the New to Patch Notes invitation, including returning profiles")
	expect(game._active_phase is StudioPhase and not game._active_phase.visible,"Studio stays behind the invitation")
	var saved: Dictionary=game.checkpoints.store.inspect()
	expect(saved.status==&"valid","New Studio is durably saved before invitation")
	expect(music.player==transport and transport.get_stream_playback()==playback and transport.playing and not transport.stream_paused and music.presentation_seconds()>start,"Same soundtrack transport and time map continue throughout creation")
	await capture("new-save-invitation-1280")
	var before:=StudioCheckpoint.new().capture(game.run_state)
	guide.choice.emit(true,false)
	await process_frame
	var studio: StudioPhase=game._active_phase
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	expect(studio.get_node_or_null("%StoreHint")==null and not hud.contextual_tip.panel.visible,"First Studio has no unsolicited Store-shopping tip")
	expect(not studio.get_node("%StartNextGame").disabled and not studio.get_node("%FeatureStoreButton").disabled,"Production and optional Store browsing remain available")
	expect(StudioCheckpoint.new().capture(game.run_state)==before,"Skipping the invitation changes no Studio values or RNG")
	await capture("new-save-studio-1280")
	game.queue_free();await process_frame
	print("NEW_SAVE_LOADING checks=%d failures=%d stages=%s"%[checks,failures,str(stages)])
	quit(failures)
