extends "res://scripts/debug/verify_new_save_loading.gd"
const Feedback=preload("res://scripts/contracts/crown_feedback.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
func click(control: Control) -> void:
	await create_timer(0.3).timeout
	var point:=root.get_final_transform()*control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;Input.parse_input_event(event)
		await process_frame
func wait_phase(game: Control, kind: String) -> bool:
	for i in range(90):
		if game._active_phase!=null and game._active_phase.get_script().resource_path.ends_with(kind):return true
		await process_frame
	return false
func _run() -> void:
	var folder:=OS.get_environment("PN_CROWN_OUTPUT")
	output=OS.get_environment("PN_CROWN_RESULTS").path_join("ui-captures");DirAccess.make_dir_recursive_absolute(output)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("flow-guard-final-artifacts/completed-current.json")))
	node_added.connect(func(node):
		if node is CheckpointCoordinator:node.store=TestStore.new("user://saves/studio",node._validate_payload))
	OnboardingPreferences.new().answer(true)
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game);current_scene=game
		await process_frame
		var run:=StudioCheckpoint.new().hydrate(data.studio_payload)
		expect(run!=null,"Legal earned Studio payload hydrates")
		game.checkpoints.attach(run)
		expect(game._finish_checkpoint_load(run),"Full Gameplay mounts earned Studio")
		await create_timer(0.5).timeout
		var studio: StudioPhase=game._active_phase
		await click(studio.get_node("%Contracts"))
		expect(studio._contract_detail.visible,"Real pointer opens Contracts")
		studio._search_publisher.select(1);studio._search_publisher.item_selected.emit(1)
		expect(studio._search_work.get_selected_metadata()==&"brief" and not studio._search_action.disabled,"Private Crown chooser exposes Brief only with real unlock")
		expect(studio._search_status.text.contains("Last 3 Crown Briefs"),"Existing validated zero streak appears quietly in Studio offer information")
		expect(studio._search_status.text.contains("Search: 1 cycle") and studio._search_status.text.contains("Brief: 2 hands"),"Search and work duration distinguished")
		await click(studio._search_action)
		await create_timer(0.6).timeout
		expect(studio._selected_contract_offer_id==run.get_crown_brief_offer().get("offer_id"),"Paid Search selects durable Crown offer")
		await capture("offer-%d"%dimensions.x)
		await click(studio._contract_detail.find_child("AcceptContractButton",true,false))
		expect(await wait_phase(game,"contract_phase.gd"),"Accept enters playable Brief")
		if not game._active_phase is ContractPhase:game.queue_free();await process_frame;continue
		var phase: ContractPhase=game._active_phase
		for hand in range(2):
			for view: CardView in phase._candidate_row.card_views().slice(0,4):view.input_button.pressed.emit()
			await create_timer(0.45).timeout
			expect(not phase._crown_details_button.disabled and phase._crown_row.visible,"Selected hand shows feedback and Details")
			expect(phase._crown_summary.text.contains("No award yet") if hand==0 else phase._crown_summary.text.contains("On completion"),"Correct provisional/final copy")
			var before:=StudioCheckpoint.new().capture(run)
			var world_before:=Replay.digest(game.rival_world.studios) if game.rival_world!=null else ""
			await click(phase._crown_details_button)
			expect(phase._crown_details_modal.visible,"Pointer opens grade Details")
			expect(phase._crown_details_text.text.contains("lower of Work completion") and phase._crown_details_text.text.contains("Spread:"),"Details explains minimum grade and raw scores")
			await capture("details-%d-hand%d"%[dimensions.x,hand])
			var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;Input.parse_input_event(key)
			await process_frame
			expect(not phase._crown_details_modal.visible and not paused,"Escape closes Details without pausing")
			expect(root.gui_get_focus_owner()==phase._crown_details_button,"Details restores button focus")
			expect(StudioCheckpoint.new().capture(run)==before,"Details leaves complete player state/RNG unchanged")
			if game.rival_world!=null:expect(Replay.digest(game.rival_world.studios)==world_before,"Details leaves active rival state unchanged")
			var viewport_rect:=Rect2(Vector2.ZERO,Vector2(dimensions))
			expect(viewport_rect.encloses(phase._play_button.get_global_rect()),"Action row stays inside viewport")
			expect(phase._crown_row.get_global_rect().end.y<=phase._candidate_row.get_global_rect().position.y,"Grade strip does not cover cards")
			await capture("selected-%d-hand%d"%[dimensions.x,hand])
			var count:=phase._state.get_successful_hand_count()
			await click(phase._play_button)
			await create_timer(0.2).timeout
			expect(phase._state.get_successful_hand_count()==count+1,"One click commits exactly one hand")
			if phase.hand_motion.busy:expect(phase._crown_summary.text.is_empty() or not phase._crown_row.visible,"Animation suppresses transient quote")
			for frame in range(240):
				if not phase.hand_motion.busy:break
				await create_timer(0.05).timeout
			expect(not phase.hand_motion.busy,"Visual hand finishes on bounded music clock")
		expect(phase._state.is_completed() and phase._completion_modal.visible,"Two hands show completed result")
		expect(phase._crown_completion_title.text=="Brief complete" and not phase._crown_result_details.disabled,"Brief complete wording and result Details")
		await create_timer(0.35).timeout # Capture the settled shared entrance, not its intermediate slide.
		expect(phase._completion_panel.get_global_rect().encloses(phase._crown_result_details.get_global_rect()),"Settled result Details fits its panel")
		expect(phase._completion_panel.get_global_rect().encloses((phase.find_child("DismissCompletionButton",true,false) as Button).get_global_rect()),"Settled Studio return fits its panel")
		await capture("result-%d"%dimensions.x)
		await click(phase._crown_result_details)
		expect(phase._crown_details_modal.visible,"Committed result opens trusted Details")
		await click(phase._crown_details_modal.get_child(0).find_child("CrownDetailsBack",true,false))
		expect(root.gui_get_focus_owner()==phase._crown_result_details,"Result Details restores focus")
		await click(phase.find_child("DismissCompletionButton",true,false))
		expect(await wait_phase(game,"studio_phase.gd"),"Dismiss returns to Studio")
		game.queue_free();await process_frame;await process_frame
	print("CROWN_FEEDBACK_UI checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
