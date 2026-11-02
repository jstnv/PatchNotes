extends "res://scripts/debug/verify_research_integration.gd"

const Confirmation := preload("res://scripts/ui/quit_confirmation.gd")
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	expect(ok, message)

func escape() -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame

func _run() -> void:
	for resolution: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		for id: StringName in [&"text", &"16_bit_sound"]:
			var run:=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(root.get_node("CardDatabase").get_development_catalog())
			var engine:=preload("res://scripts/debug/ui_test_actions.gd").create_feature_engine(run,"Confirmation Engine")
			check(run.select_engine(engine),"Editable owned engine selected")
			if id==&"16_bit_sound":
				check(run.admit_feature_research(run.get_feature_research_quote(&"8_bit_sound")) and run.research_feature(run.get_feature_research_quote(&"8_bit_sound")), "Upgrade parent acquired legally")
			var store := FeatureStore.new()
			root.add_child(store)
			store.setup(run)
			store.open_store()
			for frame in 5: await process_frame
			store._select_node(id)
			await create_timer(0.8).timeout
			var before := snapshot(run)
			var quote := run.get_feature_research_quote(id)
			check(quote.can_admit, "Legal selected Feature can enter queue: "+str(quote))
			if not quote.can_admit:
				store.queue_free();await process_frame;continue
			for action: String in ["cancel", "escape", "close"]:
				store._purchase()
				var dialog := store._admission_dialog
				await process_frame
				var animated: bool = dialog.get_script() == Confirmation and dialog.get("_entrance") != null
				await create_timer(0.32).timeout
				check(dialog.visible and snapshot(run) == before, "Opening confirmation is passive")
				check(dialog.get_script() == Confirmation and dialog.has_node("QuitCopy/Warning"), "Shared menu confirmation installed")
				check(dialog.borderless and dialog.transparent_bg and dialog.transparent, "Shared chamfered transparent surface")
				check(dialog.title == "Implement Feature in this engine?" and dialog.get_ok_button().text == "OK" and dialog.get_cancel_button().text == "Cancel", "Implementation title and existing actions displayed")
				check(dialog.dialog_text.contains(CashFormatter.format_exact_cents(quote.down_cents)) and dialog.dialog_text.contains(CashFormatter.format_exact_cents(quote.due_cents)) and dialog.dialog_text.contains("irreversible") and dialog.dialog_text.contains("No cancellation or reordering") and dialog.dialog_text.contains("not guaranteed to be drawn or played"), "Exact quote and research warnings visible")
				check(dialog.dialog_text.contains("Upgrade:") == (id == &"16_bit_sound"), "Upgrade supply warning appears only for upgrade")
				if dialog.has_node("QuitCopy/Warning"):
					var body: Label = dialog.get_node("QuitCopy/Warning")
					var heading: Label = dialog.get_node("QuitCopy/Header/Heading")
					check(body.text == dialog.dialog_text and heading.text == dialog.title, "Custom title/body display complete authoritative copy")
					check(body.size.y >= body.get_combined_minimum_size().y and body.get_global_rect().end.y < dialog.get_ok_button().get_global_rect().position.y, "Long warning fits above buttons without overlap")
					check(Rect2i(Vector2i.ZERO,resolution).encloses(Rect2i(dialog.position,dialog.size)), "Entire confirmation fits supported viewport")
					check(dialog.get_ok_button().theme_type_variation == &"PrimaryButton" and animated, "Shared primary button and timed entrance")
				if action == "cancel": dialog.get_cancel_button().pressed.emit()
				elif action == "escape": await escape()
				elif dialog.has_node("QuitCopy/Header/Close"): dialog.get_node("QuitCopy/Header/Close").pressed.emit()
				else: dialog.get_cancel_button().pressed.emit()
				await process_frame
				check(not dialog.visible and snapshot(run) == before, "Cancel/Escape/close preserve cash, history, ownership, queue and RNG")
			store._purchase()
			await create_timer(0.32).timeout
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("PN_CARD_FRAME_OUTPUT") + "-%s-%d.png" % [id,resolution.x])
			store._admission_dialog.get_ok_button().pressed.emit()
			await process_frame
			check(run.get_cash_cents() == int(before[2]) - int(quote.down_cents) and run.get_completed_run_cycles() == int(before[3]), "Confirmed admission charges exact deposit and zero cycles")
			check(run.get_feature_research_queue().size() == 1 and not run.owns_feature(id), "Confirmed admission queues without ownership")
			var admitted := snapshot(run)
			store._admission_dialog.confirmed.emit()
			check(snapshot(run) == admitted, "Stale confirm cannot duplicate deposit or queue")
			check(run.research_feature(run.get_feature_research_quote(id)) and run.owns_feature(id) and run.get_feature_research_queue().is_empty(), "Existing productive Research completes acquisition")
			store.queue_free()
			await process_frame
	var report := {"checks":assertions,"failures":failures,"runtime_source":preload("res://scripts/simulation/development_replay.gd").source_identity()}
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(report))
	print("RESEARCH_CONFIRMATION ",JSON.stringify(report))
	quit(failures)
