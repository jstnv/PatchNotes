extends "res://scripts/debug/verify_publisher_trial_offers.gd"

func show_state(run: RunState, publisher: StringName, label: String, size: Vector2i) -> void:
	var before := [run.get_cash_cents(),run.get_completed_run_cycles(),run.random_streams.snapshot(),run.get_studio_finance_snapshot()]
	var browser := PublisherBrowser.new()
	browser.setup(run)
	root.add_child(browser)
	await process_frame
	var index := 2 if publisher == PublisherCatalog.CROWN_QUILL else 3
	browser._list.select(index)
	browser._on_selected(index)
	await process_frame
	expect(browser._details.text.contains(run.get_publisher_status(publisher).availability), "Browser displays authoritative availability")
	expect(not browser._details.text.contains("no offer is implemented"), "Playable publisher never claims no offer")
	expect(browser._details.get_global_rect().end.x <= size.x and browser._details.get_global_rect().end.y <= size.y, "Details fit supported viewport")
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../docs/codex/findings/queue-completion-v1/%s-%s-%d.png" % [publisher,label,size.x])
	expect(before == [run.get_cash_cents(),run.get_completed_run_cycles(),run.random_streams.snapshot(),run.get_studio_finance_snapshot()], "Browsing preserves cash/time/RNG/finance")
	browser.queue_free()
	await process_frame

func _run() -> void:
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = size
		root.content_scale_size = size
		for publisher: StringName in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
			var locked := RunState.new()
			locked.initialize_cash(0)
			locked.create_studio_with_traits("Locked",&"action",[])
			expect(not locked.get_publisher_status(publisher).unlocked and locked.get_pending_publisher_offer_ids().is_empty(), "Locked publisher has no offer")
			await show_state(locked,publisher,"locked",size)
			var run := trial_run()
			var quote := offer_for(run,publisher)
			expect(not quote.is_empty() and run.get_publisher_status(publisher).availability.contains("available from Contracts"), "Pending offer agrees with chooser")
			await show_state(run,publisher,"available",size)
			var state := run.accept_publisher_contract(quote)
			expect(state != null and run.get_publisher_status(publisher).availability.contains("in progress"), "Accepted offer shows in progress")
			await show_state(run,publisher,"active",size)
			var other := PublisherCatalog.NEON_CIRCUIT if publisher == PublisherCatalog.CROWN_QUILL else PublisherCatalog.CROWN_QUILL
			expect(run.get_publisher_status(other).availability.contains("Finish the active Contract") and run.get_pending_contract_choices().is_empty(), "Other pending offer truthfully waits")
			var phase: ContractPhase = load("res://scenes/phases/contract_phase.tscn").instantiate()
			expect(phase.setup(state,run),"Contract uses accepted state")
			root.add_child(phase)
			await process_frame
			for hand in range(2):
				for slot in range(4): (phase._candidate_row.get_children()[slot] as CardView).input_button.pressed.emit()
				expect(phase._play_selected_hand(),"Native Contract hand succeeds")
			phase.queue_free()
			await process_frame
			expect(run.get_publisher_status(publisher).availability.contains("completed") and not run.get_pending_publisher_offer_ids().has(quote.offer_id), "Completed offer absent from chooser")
			await show_state(run,publisher,"completed",size)
			expect(run.get_publisher_status(PublisherCatalog.STARWAVE).availability.contains("No Starwave offer"),"Starwave remains profile-only")
	print("Publisher browser states: %d failures" % failures)
	quit(0 if failures == 0 else 1)
