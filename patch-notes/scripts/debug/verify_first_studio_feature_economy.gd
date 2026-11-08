extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	if ok: print("PASS: " + description)
	else:
		failures += 1
		push_error("FAIL: " + description)

# First-Studio verification for the engine-scoped Implementation workflow.
func _run() -> void:
	root.size = Vector2i(1152, 648)
	var database := root.get_node("CardDatabase")
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Economy Studio", &"adventure"), "Naming first Studio activates its economy")
	check(run.get_cash_cents() == 550000 and run.get_completed_run_cycles() == 0, "First Studio starts with $5,500 and no productive cycles")
	check(run.get_selected_engine_capacity() == 27 and run.get_future_project_feature_ids().size() == 17, "Default Public Engine has its fixed 27-Scope, 17-Feature library")
	var creation := run.get_proprietary_engine_creation_quote("Economy Engine")
	check(not creation.is_empty(), "First Studio can quote a proprietary engine")
	var created := run.create_proprietary_engine(creation)
	check(created.get("ok", false) and run.get_cash_cents() == 540000 and run.get_completed_run_cycles() == 0, "Engine creation charges exactly $100 and no cycle")
	if not created.get("ok",false): quit(1); return
	var engine_id: StringName = created.engine_id
	var starters: Array[StringName]=[];starters.assign(run.ProprietaryEngines.FOUNDATIONS)
	check(run.get_engine_feature_state().engines[engine_id].committed == starters, "New engine starts with the four implemented Features")
	check(run.finalize_starter_selection(), "First-game selection can close before Implementation")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(null, run, snapshots), "First Studio opens before project creation")
	root.add_child(studio)
	await process_frame
	check(not studio.get_node("%FeatureStoreButton").visible, "Standalone dashboard Feature Store is retired")
	var store: FeatureStore=await preload("res://scripts/debug/ui_test_actions.gd").open_feature_implementation(studio,engine_id)
	check(store.visible and store._owned_summary.text.contains("Scope 5"), "Owned engine opens its four-Feature, five-Scope Implementation tree")
	var quote := run.get_feature_research_quote(&"controller",engine_id)
	check(quote.get("can_admit",false), "Independent Controller implementation can enter the engine queue")
	var initial_cash := run.get_cash_cents()
	check(run.admit_feature_research(quote) and run.get_cash_cents() == initial_cash - int(quote.down_cents) and run.get_completed_run_cycles() == 0, "Implementation down payment uses the quoted price and no cycle")
	quote=run.get_feature_research_quote(&"controller",engine_id)
	initial_cash=run.get_cash_cents()
	check(quote.get("can_research",false) and run.research_feature(quote), "Queued Controller implementation completes")
	check(run.get_cash_cents() == initial_cash - int(quote.due_cents) and run.get_completed_run_cycles() == 1, "Completion charges the unpaid balance in one productive cycle")
	await process_frame
	check(&"controller" in run.get_future_project_feature_ids(engine_id) and store._owned_summary.text.contains("Scope 6"), "Paid Controller is immediately available on this engine")
	check(run.get_selected_engine_id() != engine_id and run.get_future_project_feature_ids().size() == 17, "Implementation does not silently change the selected project engine")
	check(run.primitive_feature_hand_cost_cents([database.get_card(&"text"),database.get_card(&"controls")] as Array[CardData]) == 9000, "Printed Text and Controls retain $50 and $40 hand costs")
	store.hide()
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
