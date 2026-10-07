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
	check(run.initialize_cash_cents(0) and run.set_studio_name("Economy Studio", &"adventure"), "Naming first Studio activates its economy")
	check(run.uses_first_studio_economy() and run.needs_starter_selection() and run.get_cash_cents() == 550000 and run.get_owned_feature_ids().size() == 19, "First Studio has $5,500 and the 19-Feature Adventure roster")
	var scope := 0
	for id: StringName in run.get_owned_feature_ids(): scope += database.get_card(id).scope
	check(scope == 26 and run.get_owned_feature_ids().has(&"controls") and not run.owns_feature(&"sprites"), "Adventure roster derives 26 printed Scope from the ledger")
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()]
	check(not run.purchase_feature(&"colored_text") and before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()], "Feature Store cannot bypass pending starter selection")
	check(run.get_primitive_reserve_offer(&"sprites").price_cents == 45000 and run.get_primitive_reserve_offer(&"sprites").initial, "Two-Scope optional Feature costs exactly $450 in the Store")
	var optional_run := RunState.new()
	optional_run.initialize_cash_cents(0)
	optional_run.set_studio_name("Optional Studio", &"adventure")
	check(optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000 and optional_run.get_completed_run_cycles() == 0 and optional_run.owns_feature(&"sprites"), "Initial optional purchase charges exactly $450 and no cycle")
	check(optional_run.get_feature_store_offer(&"animated_sprites").unlocked, "Initial Primitive purchase unlocks its Feature Store branch")
	check(not optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000, "Duplicate starter purchase rejects without spending")
	var uncapped := RunState.new()
	uncapped.initialize_cash_cents(0)
	uncapped.set_studio_name("Uncapped Studio", &"sports")
	var spent := 0
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		if uncapped.owns_feature(id): continue
		spent += int(uncapped.get_primitive_reserve_offer(id).price_cents)
		check(uncapped.purchase_starter_feature(id), "Remaining Primitive can be bought without starter caps")
	check(spent == 405000 and uncapped.get_owned_feature_ids().size() == 27 and uncapped.get_starter_pool_summary().scope == 39 and uncapped.get_cash_cents() == 145000 and uncapped.get_completed_run_cycles() == 0, "Initial purchases exceed both old caps with exact cash and no cycles")
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
	check(owned_summary.text.contains("Scope 26") and owned_summary.text.contains("Core Score 63") and owned_summary.text.contains("Graphics 12 · Sound 7 · Tech 15 · Design 29") and owned_summary.text.contains("$1150.00") and not owned_summary.text.contains("TBD"), "Owned-pool indicator totals the specialty ledger roster and their exact priced play cost")
	store.call("_select_node", &"sprites")
	(store.get("_buy") as Button).pressed.emit()
	store.call("_select_node", &"scrolling")
	(store.get("_buy") as Button).pressed.emit()
	check(run.owns_feature(&"sprites") and run.owns_feature(&"scrolling") and run.get_cash_cents() == 460000 and run.get_completed_run_cycles() == 0 and run.get_starter_pool_summary().scope == 30, "Store buys multiple starter Features one click each for exact cash and zero cycles")
	check(owned_summary.text.contains("Scope 30") and owned_summary.text.contains("Core Score 77") and owned_summary.text.contains("Graphics 19 · Sound 7 · Tech 22 · Design 29") and owned_summary.text.contains("$1370.00"), "Indicator refreshes from owned cards after sequential starter purchases")
	root.size = Vector2i(900, 600)
	root.content_scale_size = Vector2i(900, 600)
	await process_frame
	await process_frame
	check(owned_summary.get_global_rect().end.x <= store.get_global_rect().end.x and owned_summary.get_global_rect().end.y < (store.get("_scroll") as ScrollContainer).get_global_rect().position.y, "Owned-pool indicator fits within the scaled Store canvas above the browser")
	check(studio.get_node("%StoreHintText").text.contains("30 owned Scope"), "Inline Store hint updates after purchases")
	store.hide()
	await process_frame
	await process_frame
	check(studio.get_node("%StoreHint").get_global_rect().end.x <= 900 and studio.get_node("%StartNextGame").get_global_rect().end.y <= 600, "Inline hint and first-game action fit the 900×600 Studio scene")
	studio.get_node("%StartNextGame").pressed.emit()
	check(not studio.get_node("%LowScopeWarning").visible and run.needs_starter_selection() and studio.get("_predevelopment") != null, "Specialty pool opens project setup without closing initial purchases")
	(studio.get("_predevelopment") as PredevelopmentOverlay).back_button.pressed.emit()
	check(run.needs_starter_selection() and run.get_completed_run_cycles() == 0, "Canceling setup leaves initial purchases open for free")
	check(run.finalize_starter_selection() and not run.finalize_starter_selection(), "Starter window can close only once")
	var reserve := run.get_primitive_reserve_offer(&"sprites")
	check(reserve.owned and not reserve.initial, "Purchased starter remains owned after the first game boundary")
	check(run.purchase_primitive_reserve_feature(&"enemies") and run.owns_feature(&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Later Studio reserve purchase spends exact cents and one productive cycle")
	check(owned_summary.text.contains("Scope 32") and owned_summary.text.contains("Core Score 82") and owned_summary.text.contains("Graphics 21 · Sound 7 · Tech 25 · Design 29") and owned_summary.text.contains("$1460.00"), "Indicator refreshes after a reserve purchase")
	check(not run.purchase_primitive_reserve_feature(&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Duplicate reserve purchase changes nothing")
	check(run.purchase_feature(&"colored_text") and run.get_cash_cents() == 300000 and run.get_completed_run_cycles() == 2 and owned_summary.text.contains("Scope 33") and owned_summary.text.contains("Core Score 84") and owned_summary.text.contains("Graphics 23 · Sound 7 · Tech 25 · Design 29") and owned_summary.text.contains("$1460.00") and owned_summary.text.contains("1 Store Feature with play cost TBD"), "Owned later Feature costs one cycle and contributes printed Scope and Core while its undefined play cost stays explicit")
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
	run.set_studio_name("Hand Studio", &"adventure")
	run.finalize_starter_selection()
	var project := PrimitivePredevelopment.prepare_project("Hand Test", &"action", &"fantasy", run)
	var phase := load("res://scenes/phases/design_phase.tscn").instantiate() as DesignPhase
	phase.setup(project, run)
	root.add_child(phase)
	await process_frame
	phase.get_workspace().overlay.cancel()
	check(phase.begin_design(), "Design can deal from the specialty Feature pool")
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
