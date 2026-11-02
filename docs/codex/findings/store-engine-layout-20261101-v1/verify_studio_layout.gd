extends "res://scripts/debug/verify_feature_store_navigation.gd"
func _run() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
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
		await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
		run = game.run_state
		studio = game.get("_active_phase")
		var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Navigation Engine"))
		expect(created.get("ok",false),"Navigation fixture creates a proprietary engine")
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


func _verify_interactions(width: int,hud: GameplayHUD) -> void:
	var before:=_snapshot()
	expect(store._engine_id==engine_id,"Actual engine context retained")
	expect((store._close.global_position-studio.global_position).distance_to(Vector2(28,24))<1.0,"Actual tree uses common Studio Back position")
	expect(store._map.scroll.size.y>=store.size.y-32,"Actual Studio tree fills its surface")
	expect(studio.get_global_rect().encloses(store._owned_summary.get_global_rect()) and studio.get_global_rect().encloses(store._research_button.get_global_rect()),"Actual engine chrome fits Studio")
	var header:=hud.get_node_or_null("TopHeader")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_CONTRACT_REPORT").get_base_dir().path_join("studio-tree-%d.png"%width))
	var at:=store._close.get_global_rect().get_center();_mouse(at,true);_mouse(at,false)
	await _settle_studio(studio)
	expect(not store.visible and studio._engine_browser.visible and studio._engine_browser.details.visible and studio._engine_browser.selected_id==engine_id,"Pointer Back returns to selected engine detail")
	studio._engine_browser.configure_button.pressed.emit();await _settle_studio(studio)
	expect(store.visible and store._engine_id==engine_id,"Reopen retains the same engine")
	expect(_snapshot()==before,"Actual tree/engine navigation preserves finance, history, clock and RNG")
