extends "res://scripts/debug/verify_rival_gameplay_activation.gd"

const Replay := preload("res://scripts/simulation/development_replay.gd")
var game: Control
var music: Node
var traces: Array = []

func _initialize() -> void:
	await process_frame
	create_timer(90).timeout.connect(func(): push_error("Pause verifier timeout"); quit(2))
	node_added.connect(_replace_store)
	root.size = Vector2i(1280,720)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	music = root.get_node("Soundtrack")
	await process_frame
	await key(KEY_ESCAPE)
	expect(not paused and not game.pause_menu.is_open(), "Title does not pause")
	game._on_studio_created("Pause test Studio", &"action", [], game._active_phase)
	await process_frame
	await skip_save_invitation()
	var saved: Dictionary = game.checkpoints.store.inspect().payload.duplicate(true)
	expect(game.checkpoints.store.inspect().status == &"valid", "Real initial Studio checkpoint exists")
	await check_pause_and_settings()
	# Studio -> title -> Continue uses the real scene replacement and disk slot.
	await key(KEY_ESCAPE)
	game.pause_menu.main_menu_button.pressed.emit()
	await scene_changed
	game = current_scene
	expect(not paused and game._active_phase is MainMenu, "Saved Studio returns to active title")
	expect(game.checkpoints.store.inspect().payload == saved, "Returning from Studio does not create an extra save")
	game._continue_checkpoint()
	await process_frame
	await skip_save_invitation()
	expect(game._active_phase is StudioPhase and game.run_state.get_studio_name() == "Pause test Studio", "Title Continue restores saved Studio")
	# Play a real hand, then pause while its committed result is being presented.
	expect(game._begin_next_project(game._active_phase, "Pause project", &"action", &"fantasy"), "Legal development begins")
	await process_frame
	var design: DesignPhase = game._active_phase
	var workspace: PhaseWorkspace = design.get_workspace()
	expect(workspace.overlay.commit_draft(), "Design setup commits a legal deal")
	await process_frame
	game.get_node("%GameplayHUD").tutorial_overlay.close()
	for i in range(4): design._on_card_pressed(design.hand_container.get_child(i))
	expect(design.get_selected_candidate_views().size() == 4, "Four real candidates selected")
	workspace._present_action("play", design._on_play_card_pressed)
	var motion: HandPresentation = workspace.hand_motion
	expect(motion.busy, "Actual card presentation is running")
	await create_timer(0.3).timeout
	await key(KEY_ESCAPE)
	expect(paused and motion.busy, "Esc pauses even when HandPresentation owns GUI focus")
	var clock_before: float = music.presentation_seconds()
	var trace_before: Array = motion.trace.duplicate(true)
	var state_before := game_state()
	var raw_before: Array = Replay.freeze([game.run_state, game.project_state])
	var ghost_positions := positions(motion)
	await create_timer(0.65).timeout
	expect(motion.trace == trace_before and positions(motion) == ghost_positions, "Card events and positions freeze")
	expect(music.presentation_seconds() > clock_before + 0.4 and game_state() == state_before, "Music advances while full run/project and RNG remain frozen")
	await key(KEY_ESCAPE)
	while motion.busy: await process_frame
	var raw_after: Array = Replay.freeze([game.run_state, game.project_state])
	# Finishing the first hand reveals its existing next tutorial tip. This single
	# presentation acknowledgment is the only permitted difference after resume.
	if raw_after[0]._seen_tutorial_topics.has("first_game_redraw_select"):
		raw_before[0]._seen_tutorial_topics["first_game_redraw_select"] = true
	expect(raw_after == raw_before, "Resume preserves gameplay/RNG; a still-open tip may defer the next-tip acknowledgment")
	state_before = game_state()
	for event in ["rise", "score", "grounded"]:
		var rows := motion.trace.filter(func(row): return row.event == event)
		expect(rows.size() == 4, "No missing or duplicated " + event)
		for i in range(rows.size()): expect(rows[i].index == i, "Ordered " + event)
	traces.append(motion.trace.duplicate(true))
	# Main Menu cancellation and acceptance retain the committed-Studio boundary.
	await key(KEY_ESCAPE)
	game.pause_menu.main_menu_button.pressed.emit()
	expect(game.pause_menu.confirming and game.pause_menu.message.text.contains("cycle 0"), "Unsaved departure explains exact Continue destination")
	expect(root.gui_get_focus_owner() == game.pause_menu.resume_button, "Discard confirmation defaults to Cancel")
	await key(KEY_ESCAPE)
	expect(paused and not game.pause_menu.confirming and game_state() == state_before, "Escape cancels discard without resuming or changing state")
	game.pause_menu.main_menu_button.pressed.emit()
	game.pause_menu.main_menu_button.pressed.emit()
	await scene_changed
	game = current_scene
	expect(not paused and game._active_phase is MainMenu, "Confirmed discard returns to unpaused title")
	expect(game.checkpoints.store.inspect().payload == saved, "Mid-development return preserves exact Studio checkpoint")
	game._continue_checkpoint()
	await process_frame
	await skip_save_invitation()
	expect(game.project_state == null and game.run_state.get_completed_run_cycles() == 0, "Continue rolls back unsaved hand and departure cycles")
	expect(game.checkpoints.store.inspect().payload == saved, "Continue does not rewrite or pay anything twice")
	await check_save_failure()
	check_prior_world()
	# Freeing a paused scene must never strand subsequent scenes in pause.
	await key(KEY_ESCAPE)
	expect(paused, "Final pause opens")
	game.queue_free()
	await process_frame
	expect(not paused, "Scene teardown releases owned pause")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"card_traces":traces},"\t"))
	print("PAUSE_MENU checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)

func skip_save_invitation() -> void:
	# New-save loading spans several rendered frames; a fixed single-frame wait
	# can arrive before the invitation on a slower host. Keep the test bounded.
	var deadline := Time.get_ticks_msec() + 3000
	while (game.guided_tutorial == null or not game.guided_tutorial.asking) and Time.get_ticks_msec() < deadline:
		await process_frame
	var view: GuidedProductionTutorial = game.guided_tutorial
	expect(view != null and view.asking, "Save restore offers the optional tutorial before pause testing")
	if view != null:
		view.experienced_button.pressed.emit()
		view.skip_button.pressed.emit()
	await process_frame

func key(code: Key, shift := false) -> void:
	if code==KEY_ESCAPE and game!=null and is_instance_valid(game.pause_menu) and not game.pause_menu.is_open():
		var owners:=[]
		for owner in get_nodes_in_group(PauseMenu.CANCEL_OWNER_GROUP):
			if (owner is CanvasLayer and owner.visible) or (owner is CanvasItem and owner.is_visible_in_tree()):owners.append(str(owner.get_path()))
		print("PAUSE_PRECONDITIONS ",{"can_pause":game.pause_menu.can_pause.call(),"guided":game.guided_tutorial!=null,"settings":game.pause_menu.settings_open.call(),"guide":game.pause_menu.guide_open.call(),"owners":owners})
	var event := InputEventKey.new()
	event.keycode = code
	event.shift_pressed = shift
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func game_state() -> String:
	return Replay.digest([game.run_state, game.project_state])

func positions(motion: HandPresentation) -> Array:
	var result := []
	for card in motion._ghosts: result.append([card.position,card.rotation,card.scale])
	return result

func check_pause_and_settings() -> void:
	var state_before := game_state()
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	hud.settings_button.grab_focus()
	var timer := Timer.new()
	timer.wait_time = 0.5
	game.add_child(timer)
	timer.start()
	await key(KEY_ESCAPE)
	expect(paused and game.pause_menu.is_open(), "Escape opens Pause")
	expect(root.gui_get_focus_owner() == game.pause_menu.resume_button, "Resume owns initial focus")
	var time_left := timer.time_left
	var music_before: float = music.presentation_seconds()
	await create_timer(music.PAUSE_FADE + 0.2).timeout
	expect(timer.time_left == time_left, "Gameplay Timer is frozen")
	expect(not music.player.stream_paused and music.presentation_seconds() > music_before + 0.4 and music.pause_weight == 1.0, "Music and grid keep running with full pause treatment")
	await key(KEY_TAB,true)
	expect(root.gui_get_focus_owner() == game.pause_menu.main_menu_button, "Reverse Tab wraps inside Pause")
	await key(KEY_TAB)
	await key(KEY_DOWN)
	expect(root.gui_get_focus_owner() == game.pause_menu.settings_button, "Arrow navigation reaches Settings")
	await key(KEY_ENTER)
	var settings: DemoSettingsMenu = hud.settings_menu
	expect(paused and settings.is_open(), "Settings opens while game remains paused")
	await key(KEY_TAB)
	expect(root.gui_get_focus_owner() == settings.resolution, "Settings owns Tab while paused")
	settings.draft.Music_muted = true
	settings.apply_draft()
	expect(settings.committed.Music_muted, "Audio settings can be saved while paused")
	settings.draft.width = 1152
	settings.draft.height = 648
	settings.apply_draft()
	expect(settings.previewing, "Display preview can start while paused")
	settings.deadline = Time.get_ticks_msec() / 1000.0 - 1.0
	await process_frame
	await process_frame
	expect(not settings.previewing and settings.draft.width == 1280, "Timed display revert still processes while paused")
	await key(KEY_ESCAPE)
	expect(not settings.is_open() and paused and game.pause_menu.is_open(), "Settings Escape returns to Pause")
	expect(root.gui_get_focus_owner() == game.pause_menu.settings_button, "Settings restores Pause focus")
	await key(KEY_ESCAPE)
	expect(not paused and not game.pause_menu.is_open(), "Second Escape resumes gameplay")
	expect(root.gui_get_focus_owner() == hud.settings_button, "Resume restores gameplay focus")
	expect(game_state() == state_before, "Pause/settings preserve run, finance and RNG state")
	await create_timer(0.1).timeout
	expect(timer.time_left < time_left and music.presentation_seconds() > music_before, "Timer and music grid continue after Resume")
	await key(KEY_ESCAPE)
	await key(KEY_ENTER)
	expect(not paused, "Enter activates the focused Resume button")
	timer.queue_free()

func check_save_failure() -> void:
	# Trigger pending Studio save from the menu path before deferred flush runs.
	await key(KEY_ESCAPE)
	game.checkpoints.store.fault = &"before_rename"
	expect(game.run_state.add_cash_cents(123), "Fixture action commits before disk fault")
	game.pause_menu.main_menu_button.pressed.emit()
	expect(not await game.checkpoints.wait_saved(), "Injected save failure completes before recovery inspection")
	await process_frame
	expect(not paused and game._active_phase is StudioPhase and game._save_failure_dialog.visible, "Failed flush keeps game and opens usable recovery")
	game.checkpoints.store.fault = &""
	expect(game.checkpoints.retry(), "Failed save can retry without replaying action")
	game._save_failure_dialog.hide()
	await process_frame
	# Existing OS-close confirmation must also remain operable after pausing.
	expect(game._begin_next_project(game._active_phase,"Quit test",&"action",&"fantasy"), "Second project begins")
	await key(KEY_ESCAPE)
	game._request_quit()
	expect(not paused and game._quit_dialog.visible, "OS-close path unpauses before its existing confirmation")
	game._quit_dialog.hide()
	game._continue_checkpoint()
	await process_frame
	await skip_save_invitation()

func check_prior_world() -> void:
	var path := OS.get_environment("PN_PAUSE_PRIOR_WORLD")
	if path.is_empty(): return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var adapter := StudioCheckpoint.new()
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld = codec.restore(data.world,data.player,adapter.hydrate(data.player),catalog)
	expect(world != null, "Pre-pause rival/Founder checkpoint restores: " + codec.error)
	if world == null: return
	var expected_player:Dictionary=data.player.duplicate(true)
	expected_player.content_revision=adapter.revision()
	expect(adapter.capture(world.player) == expected_player, "Prior player state exact except accepted content revision")
	var actual: Dictionary = codec.capture(world)
	var expected: Dictionary = data.world.duplicate(true)
	expected.source_identity = actual.source_identity
	for row:Dictionary in expected.studios:row.run.content_revision=adapter.revision()
	expect(actual == expected, "Prior rival/Founder state exact except accepted source/content markers")
	expected.source_identity = "unknown-pause-source"
	expect(codec.restore(expected,data.player,adapter.hydrate(data.player),catalog) == null, "Unknown checkpoint source still rejects")
