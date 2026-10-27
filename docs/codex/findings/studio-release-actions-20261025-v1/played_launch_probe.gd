extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
var checks := 0
var failures := 0
var output := ""
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures+=1
func settle() -> void: await create_timer(.4).timeout
func click(button: Button) -> void:
	await settle()
	expect(not button.disabled,"Action is enabled: "+button.text)
	var point := button.get_global_rect().get_center()
	var event := InputEventMouseMotion.new()
	event.position=point
	Input.parse_input_event(event)
	await process_frame
	expect(root.gui_get_hovered_control()==button,"Pointer reaches: "+button.text)
	for pressed in [true,false]:
		var press := InputEventMouseButton.new()
		press.position=point;press.pressed=pressed;press.button_index=MOUSE_BUTTON_LEFT
		Input.parse_input_event(press)
		await process_frame
	await settle()
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"Captured "+name)
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	assert(OnboardingPreferences.new().answer(true))
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"studio-actions","studio_name":"Release Check Studio","specialty":"role_playing","traits":[],"seed":"1001"},catalog)
	var policy=Policy.factory({"genre":"role_playing","theme":"fantasy","name_prefix":"First Release","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	var commands := 0
	for i in 80:
		var view: Dictionary=session.observation()
		if view.phase==&"beta":break
		var chosen: Dictionary=policy.call(view)
		var result: Dictionary=session.execute(session.command(chosen.type,chosen.get("payload",{})))
		assert(result.ok,JSON.stringify(result));commands+=1
	expect(session.phase()==&"beta" and session.run.get_released_game_ids().is_empty(),"Fresh legal Design/Alpha commands reach Beta before the first release")
	var game: Control=load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=session.run
	root.add_child(game)
	await settle()
	root.size=Vector2i(1280,720);root.content_scale_size=root.size
	await settle()
	var hud: GameplayHUD=game.get_node("%GameplayHUD")
	hud.contextual_tip.dismiss();hud.tutorial_overlay.close()
	var old: Control=game._active_phase
	game.get_node("%PhaseRoot").remove_child(old);old.queue_free()
	game.project_state=session.development.project
	var beta: BetaPhase=load("res://scenes/phases/beta_phase.tscn").instantiate()
	assert(beta.setup(game.project_state,game.run_state,game.get_snapshot_database()))
	beta.authorize_launch()
	beta.launch_requested.connect(game._on_beta_launch_requested.bind(beta))
	game.get_node("%PhaseRoot").add_child(beta)
	game._active_phase=beta;hud.set_phase(beta)
	beta.get_workspace().overlay.cancel()
	assert(beta.begin_beta())
	for hand in 2:
		for frame in 180:
			if not beta._candidate_views.any(func(card):return card.has_meta("fan_entering")):break
			await process_frame
		for view: CardView in beta._candidate_views.slice(0,4):beta._on_card_pressed(view)
		assert(beta.play_selected_hand(),"Legal Beta hand must resolve")
		for frame in 600:
			if not beta.get_workspace().hand_motion.busy:break
			await create_timer(.02).timeout
		assert(not beta.get_workspace().hand_motion.busy)
	var launched := beta.request_launch()
	if not launched:assert(beta.confirm_launch_for_verification())
	await settle()
	var studio: StudioPhase=game._active_phase
	expect(game.run_state.get_released_game_ids().size()==1,"Actual live Beta-to-Studio boundary registers exactly one release")
	await click(studio._review_view.get_node("%ContinueButton"))
	hud.contextual_tip.dismiss()
	expect(not studio.get_node("%PostGameSummaries").disabled and not studio.get_node("%Contracts").disabled and studio.get_node("%StartNextGame").text=="Produce Next Game","First-release dashboard exposes history, eligible Contracts and Next Game")
	await capture("first-release-dashboard")
	var saved := StudioCheckpoint.new().capture(game.run_state)
	var rng: Dictionary=game.run_state.random_streams.snapshot()
	await click(studio.get_node("%PostGameSummaries"))
	expect(studio.get_node("%SummaryPanel").visible and studio.get_node("%GameList").item_count==1,"Pointer opens the first game's committed summary")
	await capture("first-release-summary")
	await click(studio.get_node("%CloseSummaryButton"))
	await click(studio.get_node("%Contracts"))
	expect(is_instance_valid(studio._contract_detail) and studio._contract_detail.visible,"Pointer opens the newly legal Contract offer")
	await capture("first-release-contracts")
	var after := StudioCheckpoint.new().capture(game.run_state)
	var expected_topics: Array=saved.run.seen_tutorial_topics.duplicate(true)
	if not expected_topics.any(func(row):return row.key=="contract_offer"):
		expected_topics.append({"key":"contract_offer","value":true})
	expect(after.run.seen_tutorial_topics==expected_topics,"Opening Contracts records only its ordinary first-visit tip acknowledgement")
	saved.run.erase("seen_tutorial_topics");after.run.erase("seen_tutorial_topics")
	expect(after==saved and game.run_state.random_streams.snapshot()==rng,"Browsing preserves every other saved field and exact RNG")
	print("PLAYED_LAUNCH checks=%d failures=%d headless_design_alpha_commands=%d beta_hands=2"%[checks,failures,commands])
	game.queue_free();await process_frame
	quit(failures)
