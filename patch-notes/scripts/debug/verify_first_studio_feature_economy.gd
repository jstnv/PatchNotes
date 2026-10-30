extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, description: String) -> void:
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)


# Historical v2 economy oracle; current root-first v3 starts have their own verifier.
func historical_roster(run: RunState, genre: StringName) -> void:
	run._owned_features.clear()
	for id: StringName in StudioSpecialties.preview(genre, 2).ids:
		run._owned_features[id] = true
	run._founding_roster_version = 2

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var database := root.get_node("CardDatabase")
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Economy Studio", &"adventure"), "Naming first Studio activates its economy")
	historical_roster(run, &"adventure")
	check(run.uses_first_studio_economy() and run.needs_starter_selection() and run.get_cash_cents() == 550000 and run.get_owned_feature_ids().size() == 19, "First Studio has $5,500 and the 19-Feature Adventure roster")
	var scope := 0
	for id: StringName in run.get_owned_feature_ids(): scope += database.get_card(id).scope
	check(scope == 26 and run.get_owned_feature_ids().has(&"controls") and not run.owns_feature(&"sprites"), "Adventure roster derives 26 printed Scope from the ledger")
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()]
	check(not ResearchTestActions.acquire(run,&"colored_text") and before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_owned_feature_ids()], "Feature Store cannot bypass pending starter selection")
	check(run.get_primitive_reserve_offer(&"sprites").price_cents == 45000 and run.get_primitive_reserve_offer(&"sprites").initial, "Two-Scope optional Feature costs exactly $450 in the Store")
	var optional_run := RunState.new()
	optional_run.initialize_cash_cents(0)
	optional_run.set_studio_name("Optional Studio", &"adventure")
	historical_roster(optional_run, &"adventure")
	check(optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000 and optional_run.get_completed_run_cycles() == 0 and optional_run.owns_feature(&"sprites"), "Initial optional purchase charges exactly $450 and no cycle")
	check(optional_run.get_feature_store_offer(&"animated_sprites").unlocked, "Initial Primitive purchase unlocks its Feature Store branch")
	check(not optional_run.purchase_starter_feature(&"sprites") and optional_run.get_cash_cents() == 505000, "Duplicate starter purchase rejects without spending")
	var uncapped := RunState.new()
	uncapped.initialize_cash_cents(0)
	uncapped.set_studio_name("Uncapped Studio", &"sports")
	historical_roster(uncapped, &"sports")
	var spent := 0
	# Acquire in legal prerequisite order; the authored catalog order is not a
	# shopping policy after the approved Lives -> Enemies -> Combat gates.
	for pass_index in range(4):
		for entry: Dictionary in FeatureStoreCatalog.starting_features():
			var id := StringName(entry.id)
			if uncapped.owns_feature(id): continue
			var quote := uncapped.get_primitive_reserve_offer(id)
			if not quote.unlocked: continue
			spent += int(quote.price_cents)
			check(uncapped.purchase_starter_feature(id), "Eligible remaining Primitive can be bought without starter caps")
	check(spent == 375000 and uncapped.get_owned_feature_ids().size() == 26 and uncapped.get_starter_pool_summary().scope == 38 and uncapped.get_cash_cents() == 175000 and uncapped.get_completed_run_cycles() == 0, "All currently eligible starters exceed both old caps, with exact cash and no cycles")
	check(not uncapped.owns_feature(&"local_leaderboards") and uncapped.get_primitive_reserve_offer(&"local_leaderboards").missing_parents == [&"high_scores"],"The remaining starter needs its approved Store parent, rather than bypassing it")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(null, run, snapshots), "First Studio opens before project creation")
	root.add_child(studio)
	await process_frame
	check(studio.get_node("%Dashboard").visible and studio.get_node_or_null("%StoreHint") == null and not studio.get_node("%StartNextGame").disabled, "First Studio has no Store-shopping panel")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	check(store != null and store.visible, "Feature Store opens during first-game starter purchasing")
	var owned_summary: Label = store.get("_owned_summary")
	check(owned_summary.text.contains("Scope 26") and not owned_summary.text.contains("Core Score") and owned_summary.text.contains("Graphics 12 · Sound 7 · Tech 15 · Design 29") and store._debug.tooltip_text.contains("$1150.00"), "Owned-pool totals and Debug play cost use current Store layout")
	store.call("_select_node", &"sprites")
	(store.get("_buy") as Button).pressed.emit()
	store.call("_select_node", &"scrolling")
	(store.get("_buy") as Button).pressed.emit()
	check(run.owns_feature(&"sprites") and run.owns_feature(&"scrolling") and run.get_cash_cents() == 460000 and run.get_completed_run_cycles() == 0 and run.get_starter_pool_summary().scope == 30, "Store buys multiple starter Features one click each for exact cash and zero cycles")
	await process_frame
	await process_frame
	check(owned_summary.text.contains("Scope 30") and owned_summary.text.contains("Graphics 19 · Sound 7 · Tech 22 · Design 29") and store._debug.tooltip_text.contains("$1370.00"), "Indicator and Debug refresh after sequential starter purchases")
	root.size = Vector2i(900, 600)
	root.content_scale_size = Vector2i(900, 600)
	await process_frame
	await process_frame
	check(owned_summary.get_global_rect().end.x <= store.get_global_rect().end.x and owned_summary.get_global_rect().end.y < (store.get("_scroll") as ScrollContainer).get_global_rect().position.y, "Owned-pool indicator fits within the scaled Store canvas above the browser")
	check(studio.get_node_or_null("%StoreHintText") == null, "Purchases do not restore unsolicited Store advice")
	store.hide()
	await process_frame
	await process_frame
	check(studio.get_node_or_null("%StoreHint") == null and studio.get_node("%StartNextGame").get_global_rect().end.y <= 600, "First-game action fits without a Store-shopping panel")
	studio.get_node("%StartNextGame").pressed.emit()
	check(not studio.get_node("%LowScopeWarning").visible and run.needs_starter_selection() and studio.get("_predevelopment") != null, "Specialty pool opens project setup without closing initial purchases")
	(studio.get("_predevelopment") as PredevelopmentOverlay).back_button.pressed.emit()
	check(run.needs_starter_selection() and run.get_completed_run_cycles() == 0, "Canceling setup leaves initial purchases open for free")
	check(run.finalize_starter_selection() and not run.finalize_starter_selection(), "Starter window can close only once")
	var reserve := run.get_primitive_reserve_offer(&"sprites")
	check(reserve.owned and not reserve.initial, "Purchased starter remains owned after the first game boundary")
	store.open_store() # Visible Store participates in its coalesced refresh.
	await process_frame
	await process_frame
	check(ResearchTestActions.acquire(run,&"enemies") and run.owns_feature(&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Later Studio reserve purchase spends exact cents and one productive cycle")
	await process_frame
	await process_frame
	check(owned_summary.text.contains("Scope 32") and owned_summary.text.contains("Graphics 21 · Sound 7 · Tech 25 · Design 29") and store._debug.tooltip_text.contains("$1460.00"), "Indicator refreshes after a reserve purchase")
	check(not ResearchTestActions.acquire(run,&"enemies") and run.get_cash_cents() == 415000 and run.get_completed_run_cycles() == 1, "Duplicate reserve purchase changes nothing")
	var acquired_colored := ResearchTestActions.acquire(run,&"colored_text")
	await process_frame
	await process_frame
	check(acquired_colored and run.get_cash_cents() == 300000 and run.get_completed_run_cycles() == 2 and owned_summary.text.contains("Scope 33") and owned_summary.text.contains("Graphics 23 · Sound 7 · Tech 25 · Design 29") and store._debug.tooltip_text.contains("$1460.00") and store._debug.tooltip_text.contains("1 Store Feature with play cost TBD"), "Owned later Feature costs one cycle and contributes Scope and Core; Debug retains undefined play costs")
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
