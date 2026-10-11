extends "res://scripts/debug/verify_starwave.gd"

func click(point:Vector2)->void:
	var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		root.push_input(event,true)
		await process_frame

func _run()->void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var game:Control=load("res://scenes/gameplay.tscn").instantiate()
		var run:=starwave_fixture()
		game.run_state=run
		root.add_child(game)
		await process_frame
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await process_frame
		var studio:StudioPhase=game._active_phase
		var before:=snapshot(run)
		await click(studio.get_node("%Contracts").get_global_rect().get_center())
		expect(studio._contract_detail.visible,"Mouse opens Contract chooser")
		for i in range(studio._contract_chooser.item_count):
			var quote:=run.get_publisher_contract_offer(studio._contract_chooser.get_item_metadata(i))
			if quote.get("publisher_id")==PublisherCatalog.STARWAVE:
				studio._contract_chooser.select(i);studio._contract_chooser.item_selected.emit(i)
		await process_frame
		var detail:Label=studio._contract_detail.find_child("ContractDetailText",true,false)
		var accept:Button=studio._contract_detail.find_child("AcceptContractButton",true,false)
		expect(detail.text.contains("Three production hands") and detail.text.contains("$2,240.00") and detail.text.contains("No Promotion"),"Chooser has exact approved cash-only terms")
		expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(accept.get_global_rect()),"Chooser acceptance fits supported viewport")
		expect(before==snapshot(run),"Chooser changes no cash/time/RNG or offer")
		accept.grab_focus()
		for pressed in [true,false]:
			var key:=InputEventAction.new();key.action=&"ui_accept";key.pressed=pressed
			root.push_input(key,true)
			await process_frame
		expect(game._active_phase is ContractPhase,"Keyboard confirms selected Starwave offer")
		if not game._active_phase is ContractPhase:game.queue_free();await process_frame;continue
		var phase:ContractPhase=game._active_phase
		for hand in range(3):
			await process_frame
			expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._status_label.get_global_rect()),"Progress/cash preview fits viewport")
			expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._play_button.get_global_rect()),"Play button stays in viewport")
			for view:CardView in phase._candidate_row.get_children().slice(0,4):view.input_button.pressed.emit()
			await click(phase._play_button.get_global_rect().get_center())
			var timeout:=0
			while phase.hand_motion.busy and timeout<600:
				await create_timer(0.02).timeout;timeout+=1
			expect(not phase.hand_motion.busy and phase.get_contract_state().get_successful_hand_count()==hand+1,"Mouse hand commits exactly once through animation")
		await process_frame
		var dismiss:Button=phase._completion_panel.find_child("DismissCompletionButton",true,false)
		expect(phase._completion_modal.visible and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._completion_panel.get_global_rect()),"Completed result fits viewport")
		expect(phase._completion_stats.text.contains("No Promotion"),"Result distinguishes cash-only reward")
		await click(dismiss.get_global_rect().get_center())
		expect(game._active_phase is StudioPhase,"Mouse dismiss returns to Studio")
		expect(run.get_publisher_status(PublisherCatalog.STARWAVE).availability.contains("completed"),"Browser reports completed first offer")
		game.queue_free();await process_frame
	print("Starwave UI verification: %d failures"%failures)
	quit(0 if failures==0 else 1)
