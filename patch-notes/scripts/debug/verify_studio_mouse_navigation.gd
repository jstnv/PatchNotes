extends "res://scripts/debug/verify_studio_checkpoint.gd"

func click(point: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	motion.global_position=point
	root.push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)
		await process_frame
func _run() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions
		root.content_scale_size=dimensions
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		for frame in range(4):await process_frame
		root.size=dimensions;root.content_scale_size=dimensions
		expect(root.size==dimensions,"Actual mouse-test viewport matches requested size")
		game.checkpoints.store._writer=TCPServer.new()
		expect(game.checkpoints.store._writer.listen(47831,"127.0.0.1")==OK,"Isolated mouse test writer")
		game.checkpoints.store.directory=ProjectSettings.globalize_path("user://mouse-%d"%dimensions.x)
		game._on_studio_created("Mouse test",&"action",[],game._active_phase)
		await process_frame
		var run: RunState=game.run_state
		run.finalize_starter_selection()
		var project:=PrimitivePredevelopment.prepare_project("Accounting fixture",&"action",&"fantasy",run)
		_finish_project(project)
		expect(run.register_release(project),"Released accounting fixture")
		game.checkpoints.pending=true
		expect(game.checkpoints.flush(),"Save fixture")
		game._continue_checkpoint()
		await process_frame
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		var state: ContractState=game.run_state.accept_primitive_contract()
		game._on_contract_requested(game._active_phase,state)
		await process_frame
		var contract: ContractPhase=game._active_phase
		for number in range(2):
			for view: CardView in contract._candidate_row.get_children().slice(0,4):view.input_button.pressed.emit()
			expect(contract._play_selected_hand(),"Native Contract hand")
		contract._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
		await process_frame
		expect(game._active_phase.get_node("Dashboard").get_global_rect().end.y<=game.get_node("%PhaseRoot").get_global_rect().end.y+1,"Post-Contract dashboard stays above footer")
		var hud: GameplayHUD=game.get_node("%GameplayHUD")
		hud.tutorial_overlay.close()
		hud.contextual_tip.dismiss()
		await process_frame
		await click(hud.cash_button.get_global_rect().get_center())
		expect(hud.studio_finances.visible,"Physical Cash click opens finance at %d"%dimensions.x)
		hud.studio_finances.open_bank()
		hud.studio_finances._payoff={"total_cents":45833} # Presentation-only quote fixture.
		hud.studio_finances._confirm_payoff()
		await process_frame
		expect(hud.studio_finances._confirm.visible and hud.studio_finances._confirm.size.x<=dimensions.x and hud.studio_finances._confirm.size.y<=dimensions.y,"Payoff confirmation fits viewport")
		hud.studio_finances._confirm.hide()
		hud.studio_finances.close()
		await click(hud.settings_button.get_global_rect().get_center())
		expect(hud.settings_menu.visible,"Physical Settings click opens menu at %d"%dimensions.x)
		hud.settings_menu.close()
		var studio: StudioPhase=game._active_phase
		await click(studio.get_node("%FeatureStoreButton").get_global_rect().get_center())
		await process_frame
		var store: FeatureStore=studio._feature_store
		hud.contextual_tip.dismiss()
		for lane in store.LANE_ORDER:
			store._map.fit_map()
			await process_frame
			await process_frame
			var view: Rect2=store._map._map_rect()
			var center: Vector2=store._map.tree.global_position+store._map.origins[lane]*store._map.zoom
			print("NAV ",lane," view=",view," center=",center," scroll=",store._scroll.scroll_vertical)
			expect(view.has_point(center),"Category center visible after overview: %s %d"%[lane,dimensions.x])
			# The user removed category shortcuts. Inspect a real card after
			# camera navigation instead of calling a deleted category button.
			var id: StringName=store.LANE_MEMBERS[lane][0]
			store._map.set_zoom(1.0)
			# Wait for the new canvas scroll ranges before revealing a card.
			await process_frame
			await process_frame
			await process_frame
			store._map._reveal_node(id)
			await create_timer(0.4).timeout
			print("MAP_CLICK ",id," rect=",store._nodes[id].get_global_rect()," toolbar=",store._toolbar.get_global_rect()," covered=",store._map._over_toolbar_control(store._nodes[id].get_global_rect().get_center()))
			await click(store._nodes[id].get_global_rect().get_center())
			await create_timer(0.4).timeout
			expect(store._selected==id and store._map.popup.visible,"Physical map card click inspects %s at %d"%[id,dimensions.x])
			store._map.dismiss()
		# Departure detaches Studio before queued deletion; late signals must be inert.
		var parent:=studio.get_parent()
		var cash_text:=store._cash.text
		parent.remove_child(studio)
		game.run_state.cash_changed.emit()
		store._refresh()
		expect(store._cash.text==cash_text,"Detached Store ignores late refresh signals")
		studio.queue_free()
		game.queue_free()
		await process_frame
	print("Studio mouse navigation: %d failures"%failures)
	quit(0 if failures==0 else 1)
