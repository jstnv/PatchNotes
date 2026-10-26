extends "res://scripts/debug/verify_new_save_loading.gd"
const Session=preload("res://scripts/simulation/campaign_session.gd")
func complete_fixture(session: RefCounted, kind: StringName, id: StringName=&"") -> bool:
	var payload: Dictionary={"kind":kind}
	if not id.is_empty():payload.offer_id=id
	if not session.execute(session.command(&"accept_contract",payload)).ok:return false
	if not session.execute(session.command(&"contract",{"request":session.contract.command(&"begin")})).ok:return false
	for n in range(2):
		if not session.execute(session.command(&"contract",{"request":session.contract.command(&"play",{"candidate_ids":session.contract.candidate_ids.slice(0,4)})})).ok:return false
	return session.execute(session.command(&"dismiss_contract")).ok
func click(button: Control) -> void:
	await create_timer(0.3).timeout
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event,true)
		await process_frame
	await process_frame
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	assert(OnboardingPreferences.new().answer(true))
	var db=root.get_node("CardDatabase")
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution
		var run: RunState=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(db.get_development_catalog(),false)
		var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
		var fixture:=Session.new();fixture.initialize(run,db.get_development_catalog(),snapshots)
		expect(complete_fixture(fixture,&"ironclad"),"Legal introductory Ironclad completes")
		expect(complete_fixture(fixture,&"sidestreet_brief",run.get_sidestreet_brief_offer().offer_id),"Last introductory Brief completes")
		expect(run.get_pending_contract_choices().is_empty(),"Legal Studio has no pending offers")
		var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game)
		for n in range(6):await process_frame
		root.size=resolution;root.content_scale_size=resolution
		for n in range(6):await process_frame
		expect(root.size==resolution,"Actual native window matches requested supported size")
		(game.get_node("%GameplayHUD") as GameplayHUD).contextual_tip.dismiss()
		var studio: StudioPhase=game._active_phase
		expect(not studio.get_node("%Contracts").disabled,"Contracts remains accessible with an empty offer list")
		var before:=run.get_completed_run_cycles()
		await click(studio.get_node("%Contracts"))
		await create_timer(0.3).timeout # Established 0.24s entrance must settle before geometry sampling.
		expect(studio._contract_detail.visible and studio._search_action.is_visible_in_tree(),"Actual pointer opens empty Search catalog")
		expect(run.get_completed_run_cycles()==before and studio._contract_detail.find_child("AcceptContractButton",true,false).disabled,"Browsing is free and cannot accept nonexistent work")
		for control: Control in [studio._search_work,studio._search_action,studio._search_status,studio._contract_detail.find_child("CloseContractDetailButton",true,false)]:
			expect(root.get_visible_rect().encloses(control.get_global_rect()),"Search control fits supported viewport: "+control.name)
		await capture("contract-search-empty-%d"%resolution.x)
		await click(studio._search_action)
		expect(run.get_completed_run_cycles()==before+1 and run.get_contract_search_state().receipts.size()==1,"Pointer Search commits one ordinary cycle and one offer")
		expect(studio._search_action.disabled and not studio._contract_detail.find_child("AcceptContractButton",true,false).disabled,"Pending discovered work blocks duplicate Search and enables acceptance")
		await capture("contract-search-found-%d"%resolution.x)
		await click(studio._contract_detail.find_child("AcceptContractButton",true,false))
		expect(game._active_phase is ContractPhase,"Accept enters ordinary playable Contract scene")
		if not game._active_phase is ContractPhase:game.queue_free();await process_frame;continue
		var phase: ContractPhase=game._active_phase
		for n in range(2):
			for view: CardView in phase._candidate_row.card_views().slice(0,4):view.input_button.pressed.emit()
			await click(phase._play_button)
			phase.hand_motion.cancel()
			await process_frame
		expect(phase._state.is_completed() and run.get_completed_run_cycles()==before+3,"Two played hands finish searched work with no duplicate cycle/effect")
		await click(phase.find_child("DismissCompletionButton",true,false))
		studio=game._active_phase
		expect(studio is StudioPhase and not studio.get_node("%Contracts").disabled,"Completing the last offer keeps Search reachable")
		await click(studio.get_node("%Contracts"))
		await create_timer(0.3).timeout # Established 0.24s entrance must settle before geometry sampling.
		expect(not studio._search_action.disabled and run.get_pending_contract_choices().is_empty(),"No new release is needed to search again")
		var close: Button=studio._contract_detail.find_child("CloseContractDetailButton",true,false)
		close.grab_focus()
		var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=true;root.push_input(key,true);await process_frame
		key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=false;root.push_input(key,true);await process_frame
		expect(studio.get_node("%Dashboard").visible,"Keyboard Back returns to Studio")
		var dto:=StudioCheckpoint.new().capture(run);var restored:=StudioCheckpoint.new().hydrate(dto)
		expect(restored!=null and restored.can_browse_contract_search() and not restored.get_contract_search_quote(&"sidestreet",&"cash").is_empty(),"Restored empty Studio retains Search availability")
		game.queue_free();await process_frame
	print("CONTRACT_SEARCH_UI checks=%d failures=%d"%[checks,failures]);quit(failures)
