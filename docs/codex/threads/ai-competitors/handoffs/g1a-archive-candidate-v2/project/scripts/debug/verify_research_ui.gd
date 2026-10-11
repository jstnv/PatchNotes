extends "res://scripts/debug/verify_research_integration.gd"

func _run() -> void:
	for resolution: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var run := fresh([&"resourceful"])
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(run)
		store.open_store()
		for i in 5: await process_frame
		var before := snapshot(run)
		store._select_node(&"colored_text")
		await create_timer(0.8).timeout
		expect(snapshot(run)==before,"Browsing is passive")
		expect(store._map.price.text.contains("Down payment") and store._map.price.text.contains("Resourceful"),"Detail explains split cost and saving")
		var details_rect := store._map.popup.get_global_rect()
		expect(details_rect.position.y>=0 and details_rect.end.y<=resolution.y and details_rect.end.x<=resolution.x,"Research detail fits viewport")
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../docs/codex/findings/feature-research-v1/detail-%dx%d.png" % [resolution.x,resolution.y])
		store._purchase()
		expect(store._admission_dialog.visible and store._admission_dialog.dialog_text.contains("irreversible") and snapshot(run)==before,"Admission requires explicit irreversible-payment confirmation")
		store._admission_dialog.hide()
		store._admission_dialog.confirmed.emit()
		await process_frame
		expect(run.get_feature_research_queue().size()==1 and not run.owns_feature(&"colored_text"),"Confirmed queue shown without ownership")
		store._refresh()
		expect(not store._research_button.disabled and store._research_button.text.contains("$225.00"),"Research button shows live final amount")
		store._map.dismiss()
		for i in 4: await process_frame
		for control: Control in [store._research_list,store._research_button]:
			var rect := control.get_global_rect()
			expect(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=resolution.x and rect.end.y<=resolution.y,"Queue controls fit "+str(resolution))
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://../docs/codex/findings/feature-research-v1/queue-%dx%d.png" % [resolution.x,resolution.y])
		store._research_button.pressed.emit()
		expect(run.owns_feature(&"colored_text") and run.get_feature_research_queue().is_empty(),"Visible Research completes queue")
		store.queue_free()
		await process_frame
	print("Research UI: %d failures" % failures)
	quit(failures)
