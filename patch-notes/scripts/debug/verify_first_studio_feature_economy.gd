extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, description: String) -> void:
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var database := root.get_node("CardDatabase")
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Economy Studio"), "Naming first Studio activates its economy")
	check(run.uses_first_studio_economy() and run.needs_starter_selection() and run.get_cash_cents() == 550000 and run.get_owned_feature_ids().size() == 6, "First Studio has $5,500 and exactly six guaranteed Features")
	var scope := 0
	for id: StringName in run.get_owned_feature_ids(): scope += database.get_card(id).scope
	check(scope == 7 and run.get_owned_feature_ids().has(&"controls") and not run.owns_feature(&"sprites"), "Guaranteed pool derives seven printed Scope from the ledger")
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()]
	check(not run.purchase_feature(&"colored_text") and before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()], "Feature Store cannot bypass pending starter selection")
	check(run.get_primitive_reserve_offer(&"sprites").price_cents == 45000 and run.get_primitive_reserve_offer(&"sprites").initial, "Two-Scope optional Feature costs exactly $450 in the Store")
	var optional_run := RunState.new()
	optional_run.initialize_cash_cents(0)
	optional_run.set_studio_name("Optional Studio")
	check(optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000 and optional_run.get_completed_run_cycles() == 0 and optional_run.owns_feature(&"sprites"), "Initial optional purchase charges exactly $450 and no cycle")
	check(optional_run.get_feature_store_offer(&"animated_sprites").unlocked, "Initial Primitive purchase unlocks its Feature Store branch")
	check(not optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000, "Duplicate starter purchase rejects without spending")
	var capped_run := RunState.new()
	capped_run.initialize_cash_cents(0)
	capped_run.set_studio_name("Capped Studio")
	var capped_id: StringName
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		if RunState.GUARANTEED_PRIMITIVE_IDS.has(id): continue
		if not capped_run.purchase_starter_feature(id):
			capped_id = id
			break
	check(not capped_id.is_empty() and not capped_run.get_primitive_reserve_offer(capped_id).within_limits and capped_run.get_starter_pool_summary().spent_cents <= 400000 and capped_run.get_starter_pool_summary().scope <= 23, "Sequential starter purchases enforce the purchase and Scope caps")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(null, run, snapshots), "First Studio opens before project creation")
	root.add_child(studio)
	await process_frame
	check(studio.get_node("%Dashboard").visible and studio.get_node("%StoreHint").visible and not studio.get_node("%StartNextGame").disabled, "First Studio uses a nonblocking Store hint, not a pool menu")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	check(store != null and store.visible, "Feature Store opens during first-game starter purchasing")
	var owned_summary: Label = store.get("_owned_summary")
	check(owned_summary.text.contains("Scope 7") and owned_summary.text.contains("Core Score 18") and owned_summary.text.contains("G 5 · S 5 · T 7 · D 1") and owned_summary.text.contains("$320.00") and not owned_summary.text.contains("TBD"), "Owned-pool indicator totals the six ledger starters and their exact priced play cost")
	store.call("_select_node", &"sprites")
	(store.get("_buy") as Button).pressed.emit()
	store.call("_select_node", &"scrolling")
	(store.get("_buy") as Button).pressed.emit()
	check(run.owns_feature(&"sprites") and run.owns_feature(&"scrolling") and run.get_cash_cents() == 460000 and run.get_completed_run_cycles() == 0 and run.get_starter_pool_summary().scope == 11, "Store buys multiple starter Features one click each for exact cash and zero cycles")
	check(owned_summary.text.contains("Scope 11") and owned_summary.text.contains("Core Score 32") and owned_summary.text.contains("G 12 · S 5 · T 14 · D 1") and owned_summary.text.contains("$540.00"), "Indicator refreshes from owned cards after sequential starter purchases")
	root.size = Vector2i(900, 600)
	await process_frame
	await process_frame
	check(owned_summary.get_global_rect().end.x <= store.get_global_rect().end.x and owned_summary.get_global_rect().end.y < (store.get("_scroll") as ScrollContainer).get_global_rect().position.y, "Owned-pool indicator fits within the scaled Store canvas above the browser")
	check(studio.get_node("%StoreHintText").text.contains("11 / 23 Scope"), "Inline Store hint updates after purchases")
	store.hide()
	await process_frame
	await process_frame
	check(studio.get_node("%StoreHint").get_global_rect().end.x <= 900 and studio.get_node("%StartNextGame").get_global_rect().end.y <= 600, "Inline hint and first-game action fit the 900×600 Studio scene")
	studio.get_node("%StartNextGame").pressed.emit()
	check(studio.get_node("%LowScopeWarning").visible and run.needs_starter_selection(), "Below-20 Scope warning appears only when starting the first game")
	studio.get_node("%LowScopeWarning").hide()
	check(run.needs_starter_selection() and run.get_completed_run_cycles() == 0, "Dismissing the warning leaves starter purchases open and costs nothing")
	studio.get_node("%LowScopeWarning").confirmed.emit()
	check(studio.get("_predevelopment") != null and run.needs_starter_selection(), "Confirming the warning opens game setup without closing purchases")
	check(run.finalize_starter_selection() and not run.finalize_starter_selection(), "Starter window can close only once")
	var reserve := run.get_primitive_reserve_offer(&"sprites")
	check(reserve.owned and not reserve.initial, "Purchased starter remains owned after the first game boundary")
	check(run.purchase_primitive_reserve_feature(&"enemies") and run.owns_feature(&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Later Studio reserve purchase spends exact cents and one productive cycle")
	check(owned_summary.text.contains("Scope 13") and owned_summary.text.contains("Core Score 37") and owned_summary.text.contains("G 14 · S 5 · T 17 · D 1") and owned_summary.text.contains("$630.00"), "Indicator refreshes after a reserve purchase")
	check(not run.purchase_primitive_reserve_feature(&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Duplicate reserve purchase changes nothing")
	check(run.purchase_feature(&"colored_text") and run.get_completed_run_cycles() == 2 and owned_summary.text.contains("Scope 14") and owned_summary.text.contains("Core Score 39") and owned_summary.text.contains("G 16 · S 5 · T 17 · D 1") and owned_summary.text.contains("$630.00") and owned_summary.text.contains("1 Store Feature with play cost TBD"), "Owned later Feature costs one cycle and contributes printed Scope and Core while its undefined play cost stays explicit")
	var project := PrimitivePredevelopment.prepare_project("Economy Game", &"action", &"fantasy", run)
	check(project.get_feature_supply_ids().has(&"enemies") and project.get_feature_supply_ids().has(&"scrolling"), "Next project snapshots store-purchased starter and reserve Features")
	var cards: Array[CardData] = [database.get_card(&"text"), database.get_card(&"controls"), database.get_card(&"graphics_pass")]
	check(run.primitive_feature_hand_cost_cents(cards) == 9000 and run.primitive_feature_hand_cost_cents([database.get_card(&"graphics_pass")] as Array[CardData]) == 0, "Printed Text and Controls cost $50 and $40; Passes cost zero")
	check(run.primitive_feature_hand_cost_cents([database.get_card(&"colored_text")] as Array[CardData]) == 0, "Later Feature class play cost stays outside Primitive economics")
	studio.queue_free()
	await process_frame
	await _verify_design_hand_cost(database)
	print("First-Studio Feature economy verification: %d failures" % failures)
	quit(failures)


func _verify_design_hand_cost(database: Node) -> void:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	run.set_studio_name("Hand Studio")
	run.finalize_starter_selection()
	var project := PrimitivePredevelopment.prepare_project("Hand Test", &"action", &"fantasy", run)
	var phase := load("res://scenes/phases/design_phase.tscn").instantiate() as DesignPhase
	phase.setup(project, run)
	root.add_child(phase)
	await process_frame
	phase.get_workspace().overlay.cancel()
	check(phase.begin_design(), "Design can deal from the selected six-Feature pool")
	var selected: Array[CardData] = []
	for child in phase.get_node("%HandContainer").get_children():
		if child is CardView and child.card_data.card_type == &"feature":
			child.input_button.pressed.emit()
			selected.append(child.card_data)
			break
	for child in phase.get_node("%HandContainer").get_children():
		if selected.size() >= 4: break
		if child is CardView and not child.is_selected():
			child.input_button.pressed.emit()
			selected.append(child.card_data)
	var cost := run.primitive_feature_hand_cost_cents(selected)
	check(selected.size() == 4 and cost > 0, "Selected real Design hand contains a payable Feature")
	run.spend_cash_cents(run.get_cash_cents())
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), project.get_current_cycle(), project.get_current_scope()]
	phase.get_node("%PlayCardButton").pressed.emit()
	check(before == [run.get_cash_cents(), run.get_completed_run_cycles(), project.get_current_cycle(), project.get_current_scope()], "Unaffordable hand rejects before production or calendar mutation")
	run.add_cash_cents(cost)
	phase.get_node("%PlayCardButton").pressed.emit()
	check(run.get_cash_cents() == 0 and run.get_completed_run_cycles() == before[1] + 1 and project.get_current_cycle() == before[2] + 1, "Successful real Design hand charges exact printed cost once at productive boundary")
	phase.queue_free()
	await process_frame
