extends SceneTree

var failures := 0
var checks := 0
var capture := OS.get_environment("PN_STORE_COPY_CAPTURE")

func _initialize() -> void: _verify.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func snap(run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids(), run.get_feature_research_queue(), run.get_studio_finance_snapshot(), run.random_streams.snapshot()]

func store_for(run: RunState) -> FeatureStore:
	var store := FeatureStore.new()
	root.add_child(store)
	store.setup(run)
	return store

func reject(run: RunState, id: StringName) -> void:
	var before := snap(run)
	check(not run.admit_feature_research(run.get_feature_research_quote(id)) and snap(run) == before, "Rejected admission preserves cash/cycles/ownership/queue/finance/RNG: " + str(id))

func shot(label: String) -> void:
	await process_frame
	await process_frame
	if capture.is_empty(): return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(capture.path_join(label + ".png")) == OK, "Rendered capture " + label)

func _verify() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var run := RunState.new()
		run.initialize_cash_cents(32499)
		var store := store_for(run)
		await process_frame
		await process_frame
		await process_frame
		var quote := run.get_feature_research_quote(&"colored_text")
		check(store.queue_block_reasons(quote) == ["Need $325.00 to queue"], "Exact one-cent-short deposit reason")
		store._select_node(&"branching_nodes")
		check(store._map.shopping_details.text.contains("Locked — Own Save Files") and store._map.shopping_details.text.contains("Need $750.00 to queue"), "Details retain simultaneous prerequisite and deposit blocks")
		reject(run, &"branching_nodes")
		reject(run, &"colored_text")
		await create_timer(0.65).timeout
		await shot("blocked-%d" % dimensions.x)
		check(store._map.popup.visible and store._map.popup.modulate.a > 0.99 and store.get_global_rect().encloses(store._map.popup.get_global_rect()), "All-block details visible and fit %d" % dimensions.x)
		run.add_cash_cents(1)
		quote = run.get_feature_research_quote(&"colored_text")
		check(not run.get_feature_store_offer(&"colored_text").affordable and quote.can_admit, "Deposit affordable while full price is not")
		store._nodes[&"colored_text"].grab_focus()
		await process_frame
		check(store._selected == &"colored_text" and root.gui_get_focus_owner() == store._nodes[&"colored_text"] and not store._buy.disabled, "Keyboard selection enables deposit-affordable queue")
		var before := snap(run)
		store._purchase()
		await shot("admission-%d" % dimensions.x)
		var dialog := store._admission_dialog
		check(dialog.dialog_text.contains("Ownership begins only after research finishes") and dialog.dialog_text.contains("games you start later") and dialog.dialog_text.contains("not guaranteed"), "Admission distinguishes queue, ownership and future supply")
		check(dialog.size.x <= dimensions.x and dialog.size.y <= dimensions.y and dialog.get_label().get_line_count() == dialog.get_label().get_visible_line_count(), "Admission text fits %d" % dimensions.x)
		check(dialog.get_cancel_button().has_focus(), "Admission defaults keyboard focus to Cancel")
		dialog.hide()
		check(snap(run) == before, "Opening and cancelling quote is passive")
		# Legacy funded fixture exercises authentic queue and project-supply APIs.
		run.add_cash(5000)
		var old_project := PrimitivePredevelopment.prepare_project("Before ownership", &"action", &"fantasy", run)
		check(run.admit_feature_research(run.get_feature_research_quote(&"colored_text")) and run.admit_feature_research(run.get_feature_research_quote(&"save_files")), "Two legal admissions")
		check(store.queue_status(run.get_feature_research_quote(&"colored_text")) == "Research head" and store.queue_status(run.get_feature_research_quote(&"save_files")) == "Queued", "FIFO head and waiting labels differ")
		var queued_project := PrimitivePredevelopment.prepare_project("Queued only", &"action", &"fantasy", run)
		check(not queued_project.get_feature_supply_ids().has(&"colored_text"), "Queue admission grants no next-project supply")
		check(run.research_feature(run.get_feature_research_quote(&"colored_text")), "Research completes")
		var next_project := PrimitivePredevelopment.prepare_project("After ownership", &"action", &"fantasy", run)
		check(not old_project.get_feature_supply_ids().has(&"colored_text") and not queued_project.get_feature_supply_ids().has(&"colored_text") and next_project.get_feature_supply_ids().has(&"colored_text"), "Ownership updates only projects begun afterwards")
		store._select_node(&"colored_text")
		check(store._details.text.contains("Owned") and store._buy.disabled, "Completed research displays Owned")
		await create_timer(0.65).timeout
		var tooltip: Control = store._owned_summary._make_custom_tooltip(store._owned_summary.tooltip_text)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", store.get_theme_stylebox("panel", "TooltipPanel"))
		root.add_child(panel)
		panel.position = Vector2(36, 220)
		panel.add_child(tooltip)
		await shot("owned-tooltip-%d" % dimensions.x)
		check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(panel.get_global_rect()) and tooltip.get_line_count() == tooltip.get_visible_line_count(), "Actual custom tooltip wraps within %d" % dimensions.x)
		check(tooltip.text.contains("Printed Scope") and tooltip.text.contains("Passes are free") and tooltip.text.contains("Each game keeps") and tooltip.text.contains("does not guarantee"), "Existing cost guidance and new supply guidance retained")
		panel.queue_free()
		store.queue_free()
		await process_frame
		# Constructed native-ledger arrears fixture; not a claimed played campaign.
		var gated := RunState.new()
		gated.initialize_cash_cents(0)
		gated.create_studio_with_traits("Copy gates", &"action", [])
		store = store_for(gated)
		await process_frame
		await process_frame
		await process_frame
		quote = gated.get_feature_research_quote(&"branching_nodes")
		check(store.queue_block_reasons(quote).has("Available after first game"), "Starter window explains first-game gate")
		reject(gated, &"branching_nodes")
		gated.finalize_starter_selection()
		var ledger := StudioFinanceLedger.create(0, 50000)
		for cycle in [1, 2]: ledger = StudioFinanceLedger.plan(ledger, cycle, 0, 0, &"calendar", 0, 0, true).ledger
		gated._studio_finance = ledger
		gated._completed_run_cycles = 2
		gated._cash_cents = 0
		store._select_node(&"branching_nodes")
		check(store._map.shopping_details.text.contains("Clear overdue bills to queue") and store.queue_block_reasons(gated.get_feature_research_quote(&"branching_nodes")).size() == 3, "All three prerequisite/deposit/overdue blockers are listed")
		reject(gated, &"branching_nodes")
		await create_timer(0.65).timeout
		await shot("overdue-%d" % dimensions.x)
		check(store._map.popup.visible and store._map.popup.modulate.a > 0.99 and store.get_global_rect().encloses(store._map.popup.get_global_rect()), "Overdue details visible and fit %d" % dimensions.x)
		gated._studio_finance = {}
		check(store.queue_block_reasons(gated.get_feature_research_quote(&"colored_text")).has("Feature queue unavailable; check Finances."), "Unavailable history is not mislabeled as arrears")
		reject(gated, &"colored_text")
		store.queue_free()
		await process_frame
	print("Store copy: %d checks, %d failures" % [checks, failures])
	quit(failures)
