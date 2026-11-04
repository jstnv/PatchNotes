extends SceneTree
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer = server
		return true

var checks := 0
var failures := 0
var game: Control
var output := ""
var clock := [0.0]
var layout_clear := true
var action_row_stable := true
var captured_motion: Dictionary = {}
var action_y_before := 0.0

func cards_fit_stage(view: GuidedProductionTutorial) -> bool:
	for card: CardView in view.fan.card_views():
		var bounds := Rect2(card.get_global_transform()*Vector2.ZERO,Vector2.ZERO)
		for corner in [Vector2(240,0),Vector2(240,336),Vector2(0,336)]: bounds = bounds.expand(card.get_global_transform()*corner)
		if not view.stage.get_global_rect().encloses(bounds): return false
	return true

func check_presentation_layout(view: GuidedProductionTutorial) -> void:
	var header := view.stats.get_global_rect()
	var guide := view.instruction.get_global_rect()
	var bounds := view.stage.get_global_rect()
	for ghost: CardView in view.motion._ghosts:
		if not is_instance_valid(ghost) or not ghost.is_visible_in_tree(): continue
		var visible_card := ghost.get_global_rect().intersection(bounds)
		if visible_card.has_area() and (header.intersects(visible_card) or guide.intersects(visible_card)):
			layout_clear = false
	if view.synergy.banner.is_visible_in_tree():
		var banner := view.synergy.banner.get_global_rect()
		if header.intersects(banner) or guide.intersects(banner) or bounds.intersects(banner): layout_clear = false
func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func _initialize() -> void: _run.call_deferred()
func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store.release_writer()
		node.store = TestStore.new("user://saves/studio",node._validate_payload)
func settle(seconds := .08) -> void:
	await create_timer(seconds).timeout
	for i in 3: await process_frame
func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		Input.parse_input_event(event); await process_frame
	await settle()
func click(button: Button) -> void:
	# Let reflow after a show/hide settle before choosing a native pointer target.
	await settle(.16)
	await click_at(button.get_global_rect().get_center())
func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.pressed = pressed
		Input.parse_input_event(event); await process_frame
	await settle()
func select_card(view: CardView, fan: CardFan) -> void:
	for frame in 120:
		if not fan.card_views().any(func(card): return card.has_meta("fan_entering")): break
		await process_frame
	await settle(.18)
	for position in [Vector2(24,28),Vector2(55,45),Vector2(120,70),Vector2(120,180),Vector2(50,290)]:
		var point: Vector2 = view.get_global_transform()*position
		if root.get_visible_rect().has_point(point) and fan.get_global_rect().has_point(point) and fan.card_at(fan.get_global_transform().affine_inverse()*point)==view:
			await click_at(point)
			return
	expect(false,"Visible card has a pointer target")
func drain(view: GuidedProductionTutorial) -> void:
	var action_y := action_y_before
	for frame in 240:
		if not view.motion.busy: return
		check_presentation_layout(view)
		if absf(view.play_button.global_position.y-action_y)>1: action_row_stable = false
		if not captured_motion.has(view.model.lesson) and view.motion.trace.any(func(row): return row.event=="specialization_started"):
			captured_motion[view.model.lesson] = true
			await capture("animation-%d-%dx%d"%[view.model.lesson,root.size.x,root.size.y])
		if not view.motion._music_driven:
			# The shared return-fan entrance is a short real-time tween.
			await settle(.6)
			if not view.motion.busy: return
		clock[0] += .12
		view.motion.advance_music(clock[0])
		await process_frame
	expect(false,"Presentation finishes in bounded clock steps")
func state() -> Dictionary:
	return {"player":StudioCheckpoint.new().capture(game.run_state),"world":preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(game.rival_world)}
func disk() -> Dictionary:
	var result := {}
	for name in DirAccess.get_files_at("user://saves/studio"):
		result[name] = FileAccess.get_sha256("user://saves/studio/"+name)
	return result
func capture(label: String) -> void:
	await settle(.3)
	if output.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game); current_scene = game
	await settle()
	game._on_studio_created("Tutorial safety",&"action",[],game._active_phase)
	await settle()
	var studio: StudioPhase = game._active_phase
	var original := state()
	var saved := disk()
	var view: GuidedProductionTutorial = game.guided_tutorial
	expect(view!=null and view.asking and view.new_button.visible,"First Studio offers the experience question")
	if view == null: quit(1); return
	await capture("invitation-1280")
	await click(view.new_button)
	expect(view.start_button.visible and root.gui_get_focus_owner()==view.start_button,"New players are offered, not forced into, the tutorial")
	await click(view.back_button)
	await click(view.experienced_button)
	expect(root.gui_get_focus_owner()==view.skip_button,"Experienced players can still choose either option")
	await capture("invitation-choice-1280")
	await click(view.start_button)
	expect(not view.asking and view.model.pool.size()==4,"Start opens a separate four-card practice pool")
	await settle()
	expect(view.stats.get_global_rect().position.y <= 16 and view.stats.get_global_rect().end.y <= 88,"Tutorial scoreboard occupies the same persistent top HUD as regular gameplay")
	if failures > 0:
		game.queue_free(); await process_frame
		quit(failures); return
	view.motion.clock_source = func(): return clock[0]
	var lessons := 0
	while game.guided_tutorial != null and lessons < 12:
		view = game.guided_tutorial
		# Complete actual lessons at both supported sizes and the reported large size.
		var size := Vector2i(1152,648) if view.model.lesson in [1,6,7] else Vector2i(1906,932) if view.model.lesson==8 else Vector2i(1280,720)
		root.size = size; root.content_scale_size = size
		await settle(.3)
		if view.model.lesson == GuidedProductionModel.Lesson.REDRAW:
			await capture("redraw-1280")
			await select_card(view.fan.card_views()[3],view.fan)
			expect(not view.redraw_button.disabled and view.play_button.disabled,"Only the scripted redraw advances this lesson")
			action_y_before = view.play_button.global_position.y
			await click(view.redraw_button)
			await drain(view)
			expect(view.model.lesson==GuidedProductionModel.Lesson.REDRAW_HAND,"Redraw produces the missing synergy card")
		else:
			for index in 4: await select_card(view.fan.card_views()[index],view.fan)
			await settle(.2)
			expect(cards_fit_stage(view),"All selected and remaining card bounds fit the playfield")
			expect(not view.play_button.disabled and view.selected.size()==4,"Four actual pointer selections enable the lesson action")
			if view.model.lesson in [0,1,2,5,6,7,8]: await capture("lesson-%d-1280"%view.model.lesson)
			if view.model.lesson==7:
				root.size = Vector2i(1152,648); root.content_scale_size = root.size
				await capture("qa-1152")
				expect(root.get_visible_rect().encloses(view.play_button.get_global_rect()) and root.get_visible_rect().encloses(view.stats.get_global_rect()),"QA scores and actions fit the smaller supported window")
				root.size = Vector2i(1280,720); root.content_scale_size = root.size
				await settle()
			var cycle := view.model.project.get_current_cycle()
			action_y_before = view.play_button.global_position.y
			await click(view.play_button)
			view.play_selected()
			expect(view.model.project.get_current_cycle()==cycle+1,"Busy/double activation resolves exactly once")
			await drain(view)
			for event in ["rise","score","grounded"]:
				expect(view.motion.trace.filter(func(row): return row.event==event).size()==4,"Exactly four "+event+" events")
			expect(view.model.resolved and view.next_button.visible and not view.next_button.disabled,"Next waits until presentation completes")
			expect(layout_clear,"Scores and instructions stay unobscured through score and synergy motion")
			expect(action_row_stable,"Action buttons keep their position while the fan is hidden")
			expect(view.stats.headings[5].text=="Scope" and view.stats.stats[5].text=="%d / 30"%view.model.project.get_current_scope(),"Tutorial shares the live Scope scoreboard and target")
			if view.model.lesson==8:
				expect(view.stats.headings[0].text=="Marketing" and view.stats.stats[0].text=="7" and view.stats.headings[6].text=="Known / Fixed" and view.stats.stats[6].text=="0 / 8" and view.stats.hidden_bugs_heading.text=="Hidden Bugs" and view.stats.hidden_bugs.text=="0","Beta scoreboard shows retained Marketing and exact final Bug states")
			await click(view.next_button)
			lessons += 1
		expect(state()==original and disk()==saved,"Practice preserves complete real Studio/world/RNG and checkpoint bytes")
	expect(game.guided_tutorial==null and game._active_phase==studio and studio.visible,"Completion returns to the same Studio instance")
	expect(OnboardingPreferences.new().read().completed,"Completion preference remembered separately")
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	await capture("returned-studio-1280")
	# Replay is an explicit button in the existing Studio phase tips.
	await click(game.get_node("%GameplayHUD").tutorial_button)
	var tips: TutorialOverlay = game.get_node("%GameplayHUD").tutorial_overlay
	expect(tips.visible and tips.practice_button.visible,"Studio tips offer tutorial replay")
	await click(tips.practice_button)
	await settle()
	view = game.guided_tutorial
	expect(view!=null and not view.asking,"Replay starts practice without repeating the invitation")
	root.size = Vector2i(1152,648); root.content_scale_size = root.size
	await capture("core-1152")
	view.fan.card_views()[0].input_button.grab_focus()
	await key(KEY_ENTER)
	expect(view.selected.has(view.fan.card_views()[0]),"Keyboard Accept selects the focused practice card")
	for index in range(1,4): await select_card(view.fan.card_views()[index],view.fan)
	await click(view.play_button)
	check_presentation_layout(view)
	await key(KEY_ESCAPE)
	expect(game.guided_tutorial==null and studio.visible and state()==original and disk()==saved,"Escape during animation returns safely with no late real effects")
	await settle(.4)
	expect(state()==original and disk()==saved,"Canceled presentation cannot mutate Studio later")
	game._offer_guided_tutorial()
	expect(game.guided_tutorial==null,"Answered invitation does not repeat")
	# A separate generated preference tests the actual Skip route.
	game._onboarding.path = "user://skip-invitation.cfg"
	game._offer_guided_tutorial()
	await settle()
	view = game.guided_tutorial
	await click(view.experienced_button)
	await click(view.skip_button)
	expect(game.guided_tutorial==null and game._onboarding.read().answered and not game._onboarding.read().completed,"Skip remembers the choice without creating a practice project")
	expect(state()==original and disk()==saved,"Skip preserves the Studio and saves")
	game._onboarding.path = "user://missing-folder/onboarding.cfg"
	game._offer_guided_tutorial()
	await settle()
	view = game.guided_tutorial
	await click(view.experienced_button); await click(view.skip_button)
	expect(game.guided_tutorial==null and game._active_phase.visible and not game._onboarding.error.is_empty(),"Unwritable preferences cannot trap the player in the invitation")
	expect(state()==original and disk()==saved,"Preference failure never changes real Studio saves")
	game.queue_free(); await process_frame
	# Exercise the actual staged Main Menu Continue route with fresh preferences.
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game); current_scene = game
	game._onboarding.path = "user://continue-invitation.cfg"
	await settle()
	# A new HUD reapplies saved window settings; match its logical test viewport.
	root.content_scale_size = root.size
	await settle()
	expect(game._active_phase is MainMenu,"Cold scene enters the actual Main Menu")
	# Title inspection is asynchronous. The live Continue action is disabled
	# until it completes, so the fixture must respect the same readiness gate.
	var title_started := Time.get_ticks_msec()
	var title_deadline := title_started + 90000
	while game._active_phase is MainMenu and (game._title_checkpoint_job != null or game._active_phase.checkpoint_info.get("status") == &"checking") and Time.get_ticks_msec() < title_deadline:
		await process_frame
	var title_ready: bool = game._active_phase is MainMenu and game._active_phase.checkpoint_info.get("status") == &"valid"
	print("Tutorial title inspection: %d ms, ready=%s" % [Time.get_ticks_msec()-title_started,title_ready])
	expect(title_ready,"Cold Continue waits for a valid inspected checkpoint")
	if title_ready: game._active_phase.continue_requested.emit()
	# Paired world hydration runs in a worker; elapsed frames are not a time bound.
	var continue_started := Time.get_ticks_msec()
	var continue_deadline := continue_started + 90000
	while game._loading_checkpoint and Time.get_ticks_msec() < continue_deadline:
		await process_frame
	print("Tutorial Continue wait: %d ms, loading=%s" % [Time.get_ticks_msec()-continue_started,game._loading_checkpoint])
	await settle()
	view = game.guided_tutorial
	expect(not game._loading_checkpoint and view==null and game._active_phase is StudioPhase,"First-time Continue opens Studio without the invitation")
	expect(game._start_guided_practice(),"Optional tutorial remains available after Continue")
	view = game.guided_tutorial
	if view != null:
		var continued := state()
		var continued_disk := disk()
		for index in 4: await select_card(view.fan.card_views()[index],view.fan)
		await click(view.play_button)
		expect(view.motion.busy,"Pointer Exit fixture has an active presentation")
		await click(view.exit_button)
		expect(game.guided_tutorial==null and game._active_phase.visible,"Pointer Exit stays accessible during animation")
		await settle(.4)
		expect(state()==continued and disk()==continued_disk,"Pointer cancellation preserves all restored state, RNG and generation bytes")
	game.queue_free(); await process_frame
	print("Guided tutorial UI: %d checks, %d failures"%[checks,failures])
	quit(failures)
