extends "res://scripts/debug/verify_starwave_ui.gd"
func _initialize() -> void:
	create_timer(210).timeout.connect(func():push_error("Challenge capture timeout");quit(2))
	node_added.connect(func(node:Node):
		if node is CheckpointCoordinator:node.store=preload("res://scripts/debug/verify_rival_gameplay_activation.gd").TestStore.new("user://saves/studio",node._validate_payload))
func shot(label:String,dimensions:Vector2i) -> void:
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	expect(image.get_size()==dimensions,"native challenge capture size")
	image.save_png(OS.get_environment("PN_CHALLENGE_CAPTURE").path_join(label+"-%dx%d.png"%[dimensions.x,dimensions.y]))
func _run() -> void:
	for dimensions:Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		for publisher:StringName in [&"sidestreet",PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT,PublisherCatalog.STARWAVE]:
			var run:=starwave_fixture() if publisher in [&"sidestreet",PublisherCatalog.STARWAVE] else trial_run()
			var game:Control=load("res://scenes/gameplay.tscn").instantiate()
			game.run_state=run;root.add_child(game);await process_frame
			root.size=dimensions;root.content_scale_size=dimensions
			game.get_node("%GameplayHUD").tutorial_overlay.close();game.get_node("%GameplayHUD").contextual_tip.dismiss()
			await process_frame
			var studio:StudioPhase=game._active_phase
			var before:=snapshot(run)
			var initial:=StudioCheckpoint.new().capture(run)
			expect(not initial.is_empty(),"valid current initial publisher checkpoint")
			FileAccess.open(OS.get_environment("PN_CHALLENGE_CAPTURE").path_join(str(publisher)+"-initial-%d.json"%dimensions.x),FileAccess.WRITE).store_string(JSON.stringify(initial,"\t"))
			studio.get_node("%Contracts").pressed.emit()
			for i in studio._contract_chooser.item_count:
				var id:StringName=studio._contract_chooser.get_item_metadata(i)
				var quote:=run.get_publisher_contract_offer(id)
				if (publisher==&"sidestreet" and id==run.get_next_sidestreet_offer().get("offer_id")) or quote.get("publisher_id")==publisher:
					studio._contract_chooser.select(i);studio._contract_chooser.item_selected.emit(i);break
			await process_frame
			game.get_node("%GameplayHUD").contextual_tip.dismiss()
			var detail:Label=studio._contract_detail.find_child("ContractDetailText",true,false)
			var accept:Button=studio._contract_detail.find_child("AcceptContractButton",true,false)
			expect(detail.text.contains("challenge") and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(accept.get_global_rect()),"offer explanation and reachable acceptance " + str(publisher))
			expect(before==snapshot(run),"passive challenge offer")
			await shot(str(publisher)+"-offer",dimensions)
			accept.grab_focus()
			for pressed in [true,false]:
				var key:=InputEventAction.new();key.action=&"ui_accept";key.pressed=pressed;root.push_input(key,true);await process_frame
			expect(game._active_phase is ContractPhase,"keyboard challenge acceptance")
			if not game._active_phase is ContractPhase:quit(1);return
			var phase:ContractPhase=game._active_phase
			var state:=phase.get_contract_state()
			for hand in state.get_required_hands():
				await process_frame
				# Wait for the real fan entrance tween (last card starts after six
				# stagger steps), so evidence captures the settled playable hand.
				for frame in 90:
					var moving := false
					for view:CardView in phase._candidate_row.get_children():
						if view.has_meta("fan_entering"):moving=true
					if not moving:break
					await create_timer(0.02).timeout
				expect(game.get_node("%PhaseRoot").get_global_rect().encloses(phase._play_button.get_global_rect()),"Contract actions remain above reserved footer HUD " + str(publisher))
				expect(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._status_label.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._play_button.get_global_rect()),"challenge/progress/play fit " + str(publisher))
				if hand==0:await shot(str(publisher)+"-progress",dimensions)
				for view:CardView in phase._candidate_row.get_children().slice(0,4):view.input_button.pressed.emit()
				await click(phase._play_button.get_global_rect().get_center())
				for frame in 900:
					await create_timer(0.02).timeout
					if not phase.hand_motion.busy:break
				expect(state.get_successful_hand_count()==hand+1,"native animated hand exactly once")
				if publisher==PublisherCatalog.STARWAVE and not state.is_completed():
					var hint:Dictionary=game.get_node("%GameplayHUD")._guidance_for_current_state()
					expect(hint.title==("2 hands left" if hand==0 else "One hand left") and not hint.body.contains("after two"),"Starwave tip uses actual remaining hands")
					await shot("starwave-after-hand%d"%(hand+1),dimensions)
			await process_frame
			expect(phase._completion_stats.text.contains("Challenge grade") and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(phase._completion_panel.get_global_rect()),"separate challenge result fits")
			await shot(str(publisher)+"-result",dimensions)
			var dismiss:Button=phase._completion_panel.find_child("DismissCompletionButton",true,false)
			await click(dismiss.get_global_rect().get_center())
			expect(game._active_phase is StudioPhase,"result returns to Studio")
			game.queue_free();await process_frame
	print("CHALLENGE_CAPTURE failures=%d"%failures);quit(failures)
