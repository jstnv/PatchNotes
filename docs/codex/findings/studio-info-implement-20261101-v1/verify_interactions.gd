extends "res://../docs/codex/findings/store-engine-layout-20261101-v1/verify_studio_layout.gd"

var checks := 0

func _run() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		# The production slot is application-wide, including other open games.
		# Use the maintained checkpoint verifier's private TCP lease seam.
		game.checkpoints.store._writer = TCPServer.new()
		if game.checkpoints.store._writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:
			expect(false,"Private fixture writer lease acquired");quit(1);return
		# A bounded Store stress viewport, overriding the startup Settings minimum.
		root.min_size=Vector2i.ZERO
		root.size=dimensions
		root.content_scale_size=dimensions
		expect(root.size==dimensions,"Actual requested navigation viewport "+str(dimensions))
		var menu: MainMenu = game.get("_active_phase")
		menu.navigation.animate=false
		menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		if is_instance_valid(menu._replace_dialog) and menu._replace_dialog.visible:
			menu._replace_dialog.hide()
			menu._replace_dialog.confirmed.emit()
		menu._name_input.text = "Navigation Test"
		menu._specialty.select(1)
		menu._play.pressed.emit()
		menu.call("_open_folder", &"traits")
		menu.call("_show_review")
		menu.call("_confirm_studio")
		# Full rival-world checkpoint preparation may exceed the shared helper's
		# 20s bound under concurrent verifiers. Await the actual transition.
		var ready_deadline:=Time.get_ticks_msec()+90000
		while game._transition_in_progress and Time.get_ticks_msec()<ready_deadline:await process_frame
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		run = game.run_state
		studio = game.get("_active_phase")
		var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Navigation Engine"))
		print("CREATION_DIAG ", created, " quote=",run.get_proprietary_engine_creation_quote("Navigation Engine"), " mutable=",run.can_mutate_checkpoint()," cash=",run.get_cash_cents(), " coordinator=", game.checkpoints.failure); expect(created.get("ok",false),"Navigation fixture creates a proprietary engine")
		if not created.get("ok",false):game.queue_free();continue
		engine_id=created.engine_id
		# This suite later verifies clicking an already-implemented Feature is a
		# no-op. New proprietary engines start empty; acquire Text legally first.
		var text_quote:=run.get_feature_research_quote(&"text",engine_id)
		expect(text_quote.get("can_admit",false) and run.admit_feature_research(text_quote),"Navigation fixture queues Text in its engine")
		expect(run.research_feature(run.get_feature_research_quote(&"text",engine_id)) and run.owns_feature(&"text",engine_id),"Navigation fixture completes Text implementation")
		studio._open_management()
		await _settle_studio(studio)
		studio._open_engines(created.engine_id)
		await _settle_studio(studio)
		studio._engine_browser._configure()
		await _settle_studio(studio)
		store = studio.get("_feature_store")
		expect(store!=null and store._engine_id==created.engine_id and store.is_visible_in_tree(),"Feature tree opens from the chosen engine detail")
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await process_frame
		await process_frame
		game.get_node("%GameplayHUD").contextual_tip.dismiss()
		await _verify_interactions(dimensions.x, game.get_node("%GameplayHUD"))
		game.queue_free()
		await process_frame
	print("Feature Store navigation verification: %d failures" % failures)
	quit(failures)




func expect(value: bool, description: String) -> void:
	checks += 1
	super.expect(value, description)

func click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at; motion.global_position = at
	root.push_input(motion, true)
	_mouse(at, true); _mouse(at, false)
	await process_frame

func _verify_interactions(width: int, hud: GameplayHUD) -> void:
	var before := StudioCheckpoint.new().capture(run)
	var tip := hud.contextual_tip
	tip.show_tip("Follow the branches", "Queue a Feature, then Implement it for one cycle.")
	store._scroll.grab_focus()
	await process_frame
	print("TIP_INPUT focus=", root.gui_get_focus_owner(), " rect=", tip.dismiss_button.get_global_rect())
	await click(tip.dismiss_button)
	expect(not tip.panel.visible, "Pointer dismisses tip while Store map owns focus")
	expect(not store._map.dragging and store._map._drag_button == MOUSE_BUTTON_NONE, "Tip dismissal does not start a map gesture")
	expect(StudioCheckpoint.new().capture(run) == before, "Tip dismissal leaves all gameplay state unchanged")
	expect(store._cash.text == "Navigation Engine", "Store title is the selected engine name")
	expect(store._cash.size.x>=100,"Engine name has readable width after actual destination entrance")
	expect(store._research_button.is_visible_in_tree() and not store._research_list.is_visible_in_tree(), "Top Implement visible with queue dropdown hidden")
	for label: Node in store.find_children("*", "Label", true, false):
		if label.is_visible_in_tree():
			expect(not str(label.text).contains("implemented ·") and label.text != "Implementation Queue" and label.text != "Feature Implementation", "No redundant engine counts or implementation headings")
	# Text is legally implemented by the base fixture. A second root still has
	# normal admission/payment/completion terms, independent of the old starter gate.
	store._map._focus_node(&"8_bit_sound")
	await create_timer(0.75).timeout
	expect(not store._buy.disabled and store._buy.text.begins_with("Implement"), "Eligible root exposes the implementation action")
	var quote := run.get_feature_research_quote(&"8_bit_sound", engine_id)
	var cash := run.get_cash_cents()
	var cycle := run.get_completed_run_cycles()
	print("IMPLEMENT_INPUT quote=", quote, " rect=", store._buy.get_global_rect())
	await click(store._buy)
	expect(is_instance_valid(store._admission_dialog) and store._admission_dialog.visible, "Pointer opens implementation confirmation")
	if is_instance_valid(store._admission_dialog) and store._admission_dialog.visible:
		await create_timer(0.5).timeout
		var dialog := store._admission_dialog
		var point := Vector2(dialog.position)+dialog.get_ok_button().get_global_rect().get_center()
		print("CONFIRM_DIAG pos=",dialog.position," size=",dialog.size," ok=",dialog.get_ok_button().get_global_rect()," copy=",dialog.get_node("QuitCopy").get_global_rect()," selected=",store._selected," embedded=",dialog.is_embedded())
		dialog.get_ok_button().pressed.connect(func():print("CONFIRM_PRESSED"))
		dialog.confirmed.connect(func():print("CONFIRMED"))
		var hover:=InputEventMouseMotion.new();hover.position=point;hover.global_position=point;root.push_input(hover,true)
		for down in [true, false]:
			var event := InputEventMouseButton.new()
			event.position=point;event.global_position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
			event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
			root.push_input(event,true)
		await process_frame
		await process_frame
		print("CONFIRM_AFTER visible=",dialog.visible," hover=",dialog.gui_get_hovered_control()," selected=",store._selected," can_mutate=",run.can_mutate_checkpoint())
	expect(run.get_feature_research_quote(&"8_bit_sound",engine_id).get("queued",false), "Pointer confirmation admits selected Feature to engine queue")
	expect(run.get_cash_cents()==cash-int(quote.down_cents) and run.get_completed_run_cycles()==cycle, "Admission charges only exact deposit and zero cycles")
	expect(not store._research_button.disabled, "Queued implementation becomes actionable without reselecting")
	expect(not store._buy.disabled and store._buy.text.begins_with("Implement "), "Queued head remains actionable in selected Feature details")
	var due: int=run.get_feature_research_quote(&"8_bit_sound",engine_id).due_cents
	await click(store._buy)
	await process_frame
	expect(run.owns_feature(&"8_bit_sound",engine_id) and &"8_bit_sound" in run.get_future_project_feature_ids(engine_id), "Pointer completes implementation and supplies chosen engine")
	expect(run.get_cash_cents()==cash-int(quote.down_cents)-due and run.get_completed_run_cycles()==cycle+1, "Completion charges exact due once and one cycle")
	var completed := StudioCheckpoint.new().capture(run)
	await click(store._buy)
	expect(StudioCheckpoint.new().capture(run)==completed, "Repeat click on completed Feature cannot charge or consume another cycle")
	# A second implementation completes through the restored top action.
	var next_quote := run.get_feature_research_quote(&"4_color_palette",engine_id)
	expect(run.admit_feature_research(next_quote), "Second root legally queues for top-action regression")
	for frame in 3:await process_frame
	cash=run.get_cash_cents();cycle=run.get_completed_run_cycles()
	due=run.get_feature_research_quote(&"4_color_palette",engine_id).due_cents
	store._map._focus_node(&"4_color_palette")
	await create_timer(0.75).timeout
	await click(store._research_button)
	expect(run.owns_feature(&"4_color_palette",engine_id) and run.get_cash_cents()==cash-due and run.get_completed_run_cycles()==cycle+1,"Top Implement completes next Feature exactly once")
	expect(store._research_list.disabled and store._research_button.disabled,"Empty queue remains visibly unavailable")
	completed=StudioCheckpoint.new().capture(run)
	await click(store._research_button)
	expect(StudioCheckpoint.new().capture(run)==completed,"Empty queue cannot charge or advance time")
	store._scroll.grab_focus()
	await click(hud.tip_button)
	expect(tip.panel.visible,"Tip button can bring guidance back inside Store")
	await click(tip.dismiss_button)
	expect(not tip.panel.visible,"Reopened guidance is dismissible")
	expect(store._cash.size.x>=100,"Engine name remains readable after implementation refresh")
	# Capture the actual game with current tip and final compact header.
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("store-%d.png"%width))
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
