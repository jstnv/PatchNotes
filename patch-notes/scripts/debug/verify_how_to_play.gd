extends "res://scripts/debug/verify_pause_menu.gd"

func _initialize() -> void:
	await process_frame
	create_timer(120).timeout.connect(func(): push_error("How to Play timeout"); quit(2))
	node_added.connect(_replace_store)
	game = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	music = root.get_node("Soundtrack")
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var guide := hud.how_to_play
	game._active_phase.navigation.animate=false
	var title_button: Button = game._active_phase.get_node("CenterContainer/MenuLayout/HowToPlay")
	var before := game_state()
	title_button.grab_focus()
	await key(KEY_ENTER)
	expect(guide.is_open() and not paused,"Title keyboard entry opens full guide without pausing title")
	expect(not hud.tutorial_overlay.visible,"Full guide is separate from phase tips")
	expect(guide.sections.size() == 9,"Nine guide folders available")
	var ids := {}
	var topic_count := 0
	for i in range(guide.sections.size()):
		guide.folder_buttons[i].pressed.emit()
		await process_frame
		var section: Dictionary = guide.sections[i]
		expect(not ids.has(section.id) and not section.topics.is_empty(),"Unique nonempty folder "+section.id)
		ids[section.id] = true
		var pages := {}
		for j in range(section.topics.size()):
			guide.topic_buttons[j].pressed.emit()
			await process_frame
			var page: Dictionary = section.topics[j]
			expect(not pages.has(page.id),"Unique topic "+section.id+"/"+page.id)
			pages[page.id] = true
			expect(guide.page_title.text == page.title and not guide.summary.text.is_empty(),"Topic title/summary bound")
			expect(guide.reader.get_parsed_text().length() > 160,"Substantial readable guide content")
			expect(guide.topic_buttons[j].button_pressed and guide.folder_buttons[i].button_pressed,"Selected folder/topic indicated")
			expect(guide.previous_button.disabled == (j==0) and guide.next_button.disabled == (j==section.topics.size()-1),"Topic bounds respected")
			topic_count += 1
	guide.select_folder(0)
	guide.folder_buttons[0].grab_focus()
	await key(KEY_RIGHT)
	expect(guide.folder_index == 1 and root.gui_get_focus_owner() == guide.folder_buttons[1],"Right arrow changes and focuses folder")
	guide.topic_buttons[0].grab_focus()
	await key(KEY_DOWN)
	expect(guide.topic_index == 1 and root.gui_get_focus_owner() == guide.topic_buttons[1],"Down arrow changes and focuses topic")
	guide.select_topic(2) # The long dynamic Traits page.
	await process_frame
	await key(KEY_PAGEDOWN)
	expect(guide.reader.get_v_scroll_bar().value > 0,"Long article scrolls using Page Down")
	guide.close_button.grab_focus()
	await key(KEY_TAB)
	expect(root.gui_get_focus_owner() == guide.folder_buttons[0],"Tab wraps within guide")
	await key(KEY_TAB,true)
	expect(root.gui_get_focus_owner() == guide.close_button,"Reverse Tab wraps within guide")
	expect(game_state() == before,"Reading all topics never mutates run or RNG")
	await key(KEY_ESCAPE)
	expect(not guide.is_open() and root.gui_get_focus_owner() == title_button,"Esc returns focus to title entry")
	game._on_studio_created("Guide test Studio",&"action",[],game._active_phase)
	await process_frame
	await skip_save_invitation()
	var saved: Dictionary = game.checkpoints.store.inspect().payload.duplicate(true)
	before = game_state()
	await key(KEY_ESCAPE)
	expect(paused and game.pause_menu.is_open(),"Pause opens in Studio")
	game.pause_menu.how_to_play_button.grab_focus()
	await key(KEY_ENTER)
	expect(guide.is_open() and paused,"Pause How to Play opens above paused game")
	var clock: float = music.presentation_seconds()
	guide.select_folder(2)
	guide.select_topic(7)
	await key(KEY_PAGEDOWN)
	await create_timer(0.2).timeout
	expect(game_state() == before and music.presentation_seconds() > clock and not music.player.stream_paused,"Guide freezes state and RNG while music keeps playing")
	expect(game.checkpoints.store.inspect().payload == saved,"Guide never rewrites Studio save")
	await key(KEY_ESCAPE)
	expect(not guide.is_open() and paused and game.pause_menu.is_open(),"One Esc closes guide without resuming")
	expect(root.gui_get_focus_owner() == game.pause_menu.how_to_play_button,"Guide returns focus to Pause entry")
	await key(KEY_ESCAPE)
	expect(not paused,"Second Esc resumes normally")
	# Real committed hand: browsing the guide must not replay its effects.
	expect(game._begin_next_project(game._active_phase,"Guide project",&"action",&"fantasy"),"Development starts")
	await process_frame
	var phase: DesignPhase = game._active_phase
	var workspace := phase.get_workspace()
	expect(workspace.overlay.commit_draft(),"Design priorities commit")
	await process_frame
	hud.tutorial_overlay.close()
	for i in range(4): phase._on_card_pressed(phase.hand_container.get_child(i))
	workspace._present_action("play",phase._on_play_card_pressed)
	expect(workspace.hand_motion.busy,"Real card animation running")
	await key(KEY_ESCAPE)
	game.pause_menu.how_to_play_button.grab_focus()
	await key(KEY_ENTER)
	before = game_state()
	var trace: Array = workspace.hand_motion.trace.duplicate(true)
	await create_timer(0.3).timeout
	expect(paused and guide.is_open() and game_state() == before and workspace.hand_motion.trace == trace,"Guide freezes in-flight presentation and gameplay")
	guide.close_button.pressed.emit()
	expect(paused and not guide.is_open(),"Close button also returns to Pause")
	await key(KEY_ESCAPE)
	while workspace.hand_motion.busy: await process_frame
	for event in ["rise","score","grounded"]:
		expect(workspace.hand_motion.trace.filter(func(row): return row.event == event).size() == 4,"Exactly four "+event+" events after guide closes")
	check_prior_world()
	game.queue_free()
	await process_frame
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"folders":9,"topics":topic_count},"\t"))
	print("HOW_TO_PLAY checks=%d failures=%d topics=%d" % [checks,failures,topic_count])
	quit(0 if failures == 0 else 1)
