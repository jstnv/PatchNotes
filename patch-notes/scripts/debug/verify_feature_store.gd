extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_verify")

func expect(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _verify() -> void:
	var db := root.get_node("CardDatabase")
	var run := RunState.new()
	run.initialize_cash_cents(1000001)
	expect(run.get_owned_feature_ids().size() == 27, "Starting ownership derives all 27 Primitive Features")
	expect(not run.owns_feature(&"graphics_pass") and not run.owns_feature(&"save_files"), "Passes and store nodes do not start owned")
	expect(db.get_card_count() == 40 and db.get_cards_by_phase(CardData.PHASE_DESIGN).size() == 17, "Fixed Primitive definitions and supply unchanged")
	expect(not run.purchase_feature(&"branching_nodes"), "Locked child rejects")
	var signals := [0, 0]
	run.cash_changed.connect(func(): signals[0] += 1)
	run.features_changed.connect(func(): signals[1] += 1)
	expect(run.purchase_feature(&"save_files") and run.get_cash_cents() == 780001 and run.get_completed_run_cycles() == 1, "Purchase spends exact cents and one cycle, preserving remainder")
	expect(run.get_feature_store_offer(&"branching_nodes").unlocked, "Ownership unlocks child without playing parent")
	var before := run.get_cash_cents()
	expect(not run.purchase_feature(&"save_files") and not run.purchase_feature(&"unknown") and run.get_cash_cents() == before and signals == [1, 1], "Duplicate and unknown requests are signal-free no-ops")
	var poor := RunState.new()
	poor.initialize_cash_cents(64999)
	expect(not poor.purchase_feature(&"colored_text") and poor.get_cash_cents() == 64999 and not poor.owns_feature(&"colored_text"), "One-cent-short purchase rejects")
	var project := ProjectState.new(30)
	expect(run.record_resolved_feature(project, &"text", &"design"), "Resolved parent grants first project credit")
	expect(not run.record_resolved_feature(project, &"text", &"design") and run.get_feature_familiarity(&"text") == 1, "Retrigger cannot grant second project credit")
	expect(not run.record_resolved_feature(project, &"text", &"alpha") and not run.record_resolved_feature(project, &"text", &"contract"), "Wrong phase and contract do not grant credit")
	expect(run.get_feature_store_offer(&"colored_text").price_cents == 58500, "One project credit gives exact 10 percent discount")
	for i in range(6):
		run.record_resolved_feature(ProjectState.new(30), &"text", &"design")
	expect(run.get_feature_familiarity(&"text") == 7 and run.get_feature_store_offer(&"colored_text").price_cents == 32500, "Seven projects retain credits but discount caps at 50 percent")
	before = run.get_cash_cents()
	expect(run.purchase_feature(&"colored_text") and run.get_cash_cents() == before - 32500 and run.get_completed_run_cycles() == 2, "Purchase uses current discounted price and one cycle")
	expect(run.get_feature_store_offer(&"save_files").discount_percent == 0 and run.get_feature_store_offer(&"difficulty_levels").discount_percent == 0 and run.get_feature_store_offer(&"difficulty_levels").unlocked, "Roots and three-Gameplay ownership gate have no discount")
	var eligible: Array = db.get_owned_features_for_phase(run, &"design")
	expect(eligible.size() == 15 and db.get_card(&"colored_text").primary_value == 2 and db.get_card(&"save_files").scope == 2, "Narrow supply API includes purchased authentic ledger definitions")
	var store := FeatureStore.new()
	root.add_child(store)
	store.setup(run)
	store.open_store()
	store.set("_selected", &"branching_nodes")
	store.call("_show_details")
	var detail: Label = store.get("_details")
	expect(detail.text.contains("Own Save Files") and store._map.price.text.contains("$1500.00"), "Branch detail shows prerequisite and exact price")
	if "--capture-store" in OS.get_cmdline_user_args():
		store.call("_refresh")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/feature-store.png")
	store.call("_purchase")
	expect(run.owns_feature(&"branching_nodes") and store.get("_selected") == &"branching_nodes", "Store purchase retains selection")
	var view_before := detail.text
	store.call("_purchase")
	expect(detail.text == view_before, "Rejected UI purchase preserves visible state")
	store.hide()
	store.open_store()
	expect(run.get_completed_run_cycles() == 3 and run.get_available_redraws() == 4, "Three purchases cost one cycle each; browsing and rejection cost none")
	store.queue_free()
	await process_frame
	await _verify_tree_ui()
	await _verify_phase_credits()
	print("Feature Store verification: %d failures" % failures)
	quit(failures)

func _verify_phase_credits() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	var run := RunState.new()
	run.initialize_cash(10000)
	run.purchase_feature(&"save_files")
	game.run_state = run
	root.add_child(game)
	await process_frame
	var design: DesignPhase = game.get("_active_phase")
	design.get_workspace().overlay.cancel()
	expect(design.begin_design(), "Begin real Design for familiarity integration")
	await _resolve_fixture(design, [&"text", &"sprites", &"4_color_palette", &"8_bit_sound", &"graphics_pass", &"sound_pass", &"design_pass"], &"_on_play_card_pressed", run)
	expect(run.get_feature_familiarity(&"text") == 1, "Successful Design resolution grants credit")
	game.project_state.finalize_design_bugs(false, 0, [], [])
	expect(game.call("_replace_design_with_alpha", design, load("res://scenes/phases/alpha_phase.tscn")), "Actual Design-to-Alpha transition succeeds")
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get_workspace().overlay.cancel()
	expect(run.owns_feature(&"save_files") and run.get_feature_familiarity(&"text") == 1 and alpha.get("_run_state") == run, "Ownership and credits survive phase transition")
	expect(alpha.begin_alpha(), "Begin real Alpha")
	await _resolve_fixture(alpha, [&"enemies", &"controls", &"power_ups", &"general_combat", &"graphics_pass", &"sound_pass", &"design_pass"], &"_on_play_alpha_hand_pressed", run)
	expect(run.get_feature_familiarity(&"enemies") == 1 and run.get_feature_store_offer(&"scripted_ai").price_cents == 171000, "Alpha parent resolution discounts direct Core child")
	expect(not run.record_resolved_feature(game.project_state, &"text", &"design"), "Credit cannot repeat after phase transition")
	game.queue_free()
	await process_frame

func _resolve_fixture(phase: Control, ids: Array[StringName], action: StringName, run: RunState) -> void:
	var db := root.get_node("CardDatabase")
	phase.call("_clear_candidate_pool")
	var candidates: Array = phase.get("_candidate_cards")
	for id: StringName in ids:
		var card: CardData = db.get_card(id)
		candidates.append(card)
		var available: Array = phase.get("_available_features")
		if card.card_type == &"feature" and not available.has(card): available.append(card)
		if phase is DesignPhase: available.erase(card)
		var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		phase.get_node("%HandContainer").add_child(view)
	expect(run.get_feature_familiarity(ids[0]) == 0, "Dealing grants no familiarity")
	var views := phase.get_node("%HandContainer").get_children()
	for i in range(3): views[i].input_button.pressed.emit()
	phase.call(action)
	expect(run.get_feature_familiarity(ids[0]) == 0, "Selection and incomplete rejected hand grant no familiarity")
	views[3].input_button.pressed.emit()
	phase.call(action)
	await process_frame

func _verify_tree_ui() -> void:
	var run := RunState.new()
	run.initialize_cash_cents(64999)
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	studio.set("_run_state", run)
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	await process_frame
	expect(store.visible and not studio.get_node("%Dashboard").visible, "Studio button opens tree")
	var nodes: Dictionary = store.get("_nodes")
	var edges: Array = store.get("_edges")
	expect(nodes.size() == 38 and edges.size() == 10, "Full ledger has 38 nodes and nine parent edges plus Gameplay gate")
	var lane_by_id: Dictionary = store.get("_lane_by_id")
	var lane_buttons: Dictionary = store.get("_lane_buttons")
	expect(lane_by_id.size() == nodes.size() and lane_buttons.size() == 5, "Every ledger Feature appears once across five browsable lanes")
	for entry: Dictionary in FeatureStoreCatalog.entries():
		var parent := StringName(entry.purchase_parent)
		if not parent.is_empty():
			store.call("_select_lane", lane_by_id[StringName(entry.id)])
			expect(edges.has([parent, StringName(entry.id)]) and lane_by_id[parent] == lane_by_id[StringName(entry.id)] and _child_is_outward(store, nodes[parent], nodes[StringName(entry.id)], lane_by_id[parent]), "Correct outward category connector: " + entry.name)
	store.call("_select_lane", &"Technology & Tools")
	expect(_child_is_outward(store, nodes[&"save_files"], nodes[&"branching_nodes"], &"Technology & Tools") and edges.has([&"save_files", &"branching_nodes"]) and not edges.any(func(edge: Array): return edge[1] == &"save_files"), "Save Files is an independent root with an upward child")
	store.call("_select_lane", &"Gameplay")
	var tree: Control = store.get("_tree")
	expect(edges.has([&"gameplay_gate", &"difficulty_levels"]) and _child_is_outward(store, tree.get_node("GameplayGate"), nodes[&"difficulty_levels"], &"Gameplay"), "Difficulty retains distinct Gameplay ownership gate inward of its node")
	expect(lane_buttons[&"Gameplay"].focus_mode == Control.FOCUS_ALL and nodes[&"difficulty_levels"].focus_mode == Control.FOCUS_ALL, "Lane and node navigation are keyboard/controller focusable")
	expect(nodes[&"colored_text"].text.contains("Need cash") and nodes[&"branching_nodes"].text.contains("Locked"), "Unaffordable and locked node states are distinct")
	store.call("_select_lane", &"Visuals")
	store.call("_select_node", &"colored_text")
	expect(store.get("_buy").disabled, "One-cent-short UI disables purchase")
	run.record_resolved_feature(ProjectState.new(30), &"text", &"design")
	expect(store._map.price.text.contains("10%") and store._map.price.text.contains("[s]$650.00[/s]") and store._map.price.text.contains("$585.00") and not store.get("_buy").disabled, "Live familiarity discount refreshes details and affordability")
	run.add_cash(10000)
	store.call("_select_lane", &"Technology & Tools")
	store.call("_select_node", &"save_files")
	store.get("_buy").pressed.emit()
	expect(nodes[&"save_files"].text.contains("Owned") and nodes[&"branching_nodes"].text.contains("Available"), "Purchase updates root and reveals available child")
	expect(not nodes[&"save_files"].text.contains("$") and not nodes[&"save_files"].tooltip_text.contains("$") and not store.get("_details").text.contains("price"), "Owned node, tooltip and detail hide acquisition prices immediately")
	expect(store._map.price.text.is_empty(), "Owned popup has no acquisition price")
	expect(not nodes[&"branching_nodes"].text.contains("$") and nodes[&"branching_nodes"].tooltip_text.contains("Base:"), "Map stays price-free; unowned tooltip retains its quote")
	var scroll: ScrollContainer = store.get("_scroll")
	scroll.scroll_horizontal = 200
	await process_frame
	var saved_scroll := scroll.scroll_horizontal
	store.call("_select_lane", &"Audio")
	store.call("_select_lane", &"Technology & Tools")
	expect(nodes.values().all(func(node: Button): return node.visible and node.size.x == node.size.y), "All square nodes remain visible across navigation")
	store.call("_select_node", &"save_files")
	var before := run.get_cash_cents()
	store.hide()
	studio.get_node("%FeatureStoreButton").pressed.emit()
	expect(store.get("_selected") == &"" and not store._map.popup.visible and run.get_cash_cents() == before and run.get_completed_run_cycles() == 1, "Reopening dismisses old popup and preserves cash and cycles")
	expect(not store.get("_cash").text.contains("Cash:"), "Store header omits duplicate cash balance")
	store._map.fit_map()
	await process_frame
	await process_frame
	expect(store._map.bounds.x * store._map.zoom <= scroll.size.x and store._map.bounds.y * store._map.zoom <= scroll.size.y, "Show all fits the complete map")
	store.call("_select_node", &"colored_text")
	await process_frame
	await process_frame
	expect(store._map.popup.visible and store.get("_details").text.contains("2 Graphics · 1 Scope"), "Node popup spells out printed score categories and Scope")
	expect(store.get_global_rect().encloses(store._map.popup.get_global_rect()), "Popup stays within Store bounds: %s / %s" % [store.get_global_rect(), store._map.popup.get_global_rect()])
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = store.global_position + Vector2(2, 2)
	store._map._input(click)
	expect(not store._map.popup.visible and store.get("_selected") == &"", "Outside click dismisses popup")
	store.call("_select_node", &"text")
	store.call("_select_node", &"colored_text")
	expect(store.get("_selected") == &"colored_text" and store._map.popup.visible, "Another node replaces the single popup")
	expect(run.get_cash_cents() == before and run.get_completed_run_cycles() == 1, "Map zoom, browsing and dismissals are passive")
	if "--capture-store" in OS.get_cmdline_user_args():
		store.call("_select_lane", &"Visuals")
		scroll.scroll_horizontal = 0
		store.call("_select_node", &"colored_text")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/feature-store-tree.png")
	if "--capture-lanes" in OS.get_cmdline_user_args():
		for dimensions: Vector2i in [Vector2i(1152, 648), Vector2i(900, 600)]:
			root.size = dimensions
			store.call("_select_lane", &"Visuals")
			scroll.scroll_horizontal = 0
			store.call("_select_node", &"colored_text")
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://design-logs/feature-node-map-v1/detail-%d.png" % dimensions.x)
			store._map.fit_map()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://design-logs/feature-node-map-v1/whole-map-%d.png" % dimensions.x)
	studio.queue_free()
	await process_frame

func _child_is_outward(store: FeatureStore, parent: Control, child: Control, lane: StringName) -> bool:
	var parent_rect := parent.get_rect() if parent == store._gate else store._map.node_footprint(parent)
	var child_rect := store._map.node_footprint(child)
	var direction: Vector2 = store._map.CATEGORY_DIRECTIONS[lane]
	if direction == Vector2.LEFT: return child_rect.end.x < parent_rect.position.x
	if direction == Vector2.RIGHT: return child_rect.position.x > parent_rect.end.x
	return direction == Vector2.UP and child_rect.end.y < parent_rect.position.y
