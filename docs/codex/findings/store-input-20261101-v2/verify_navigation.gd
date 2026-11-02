extends "res://scripts/debug/verify_feature_store_navigation.gd"
func _run() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = dimensions
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.checkpoints.store._writer=TCPServer.new()
		if game.checkpoints.store._writer.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1")!=OK:quit(2);return
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

