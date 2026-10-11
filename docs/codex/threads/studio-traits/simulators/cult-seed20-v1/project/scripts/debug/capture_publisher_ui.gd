extends "res://scripts/debug/verify_publisher_trial_offers.gd"

func capture(label: String, width: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../docs/codex/findings/contracts-implementation-v1/%s-%d.png" % [label,width])

func _run() -> void:
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = size
		root.content_scale_size = size
		for publisher: StringName in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
			var game: Control = load("res://scenes/gameplay.tscn").instantiate()
			game.run_state = trial_run()
			root.add_child(game)
			await process_frame
			root.size = size
			root.content_scale_size = size
			game.get_node("%GameplayHUD").tutorial_overlay.close()
			var studio: StudioPhase = game._active_phase
			studio.get_node("%Contracts").pressed.emit()
			var chooser: OptionButton = studio._contract_chooser
			var quote := offer_for(game.run_state,publisher)
			for index in range(chooser.item_count):
				if chooser.get_item_metadata(index)==quote.offer_id:
					chooser.select(index)
					chooser.item_selected.emit(index)
			await capture(String(publisher)+"-offer",size.x)
			var before := StudioCheckpoint.new().capture(game.run_state)
			studio._contract_detail.find_child("CloseContractDetailButton",true,false).pressed.emit()
			expect(StudioCheckpoint.new().capture(game.run_state)==before,"Back path is free")
			studio.get_node("%Contracts").pressed.emit()
			for index in range(chooser.item_count):
				if chooser.get_item_metadata(index)==quote.offer_id:
					chooser.select(index)
					chooser.item_selected.emit(index)
			studio._contract_detail.find_child("AcceptContractButton",true,false).pressed.emit()
			var phase: ContractPhase = game._active_phase
			await process_frame
			for hand in range(2):
				var views := phase._candidate_row.get_children()
				for slot in range(4): (views[slot] as CardView).input_button.pressed.emit()
				expect(phase._play_selected_hand(),"Actual UI candidate hand commits")
			await capture(String(publisher)+"-result",size.x)
			phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
			await capture(String(publisher)+"-bank",size.x)
			game.queue_free()
			await process_frame
	print("Publisher UI: %d failures" % failures)
	quit(0 if failures==0 else 1)
