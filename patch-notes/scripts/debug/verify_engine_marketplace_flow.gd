## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_marketplace_flow.gd
extends SceneTree

const Entitlements := preload("res://scripts/engines/engine_entitlements.gd")
const Royalty := preload("res://scripts/engines/engine_royalty.gd")
class StudioSession extends RefCounted:
	var run: RunState
	func _init(owner: RunState) -> void: run = owner

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _studio(name: String, specialty: StringName) -> RunState:
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits(name,specialty,[]),"Studio fixture creates")
	return run

func _release(run: RunState, snapshots: PrimitiveSnapshotDatabase) -> ProjectState:
	var project := ProjectState.new(30)
	project.set_engine_id(&"action_engine")
	project.initialize_snapshots(&"fast_follower",&"stable_market")
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(),{},0.0,0.0,0.0,7.0,1.0,0,0.0,1.0,50,0.0,7.0,7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project,run))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project,snapshots))
	project.set("_units_sold_result",UnitsSoldResult.new(&"primitive_units_sold_v1",&"month_1",500,70,70,100,200,300,10000,10000,751,1,751.0,751))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

func _initialize() -> void: _verify.call_deferred()

func _verify() -> void:
	check(Royalty.increment(0,4) == 0 and Royalty.increment(4,5) == 1 and Royalty.increment(5,9) == 0 and Royalty.increment(9,10) == 1,"Cumulative cents preserve fractional royalty progress")
	var buyer := _studio("Engine buyer",&"action")
	var creator := _studio("Action creator",&"action")
	creator._bank_run_id = &"incumbent-action"
	creator._engine_entitlements = Entitlements.create(creator._bank_run_id)
	creator._contract_search = RunState.ContractSearch.create(creator._bank_run_id)
	creator._employees = EmployeeRoster.create(creator._bank_run_id)
	creator._publisher_relationships = RunState.RelationshipLedger.create(creator._bank_run_id)
	var world := RivalWorld.new()
	world.player = buyer
	world.studios = {&"incumbent-action":StudioSession.new(creator)}
	check(creator.get_engine_entitlements().owned_ids.has(&"action_engine"),"Real creator owns its listed engine")
	var player_before := buyer.get_cash_cents()
	var creator_before := creator.get_cash_cents()
	check(not world.license_engine(&"action_engine").ok and buyer.get_cash_cents() == player_before,"Unaffordable purchase changes neither studio")
	check(buyer.add_cash_cents(200000),"Buyer can fund the license")
	player_before = buyer.get_cash_cents()
	var purchase: Dictionary = world.license_engine(&"action_engine")
	check(purchase.get("ok",false) and buyer.get_cash_cents() == player_before - 750000 and creator.get_cash_cents() == creator_before + 750000,"License transfers the exact $7,500 to its creator")
	check(buyer.get_engine_entitlements().licensed_ids.has(&"action_engine") and not world.license_engine(&"action_engine").ok,"License persists and cannot be bought twice")
	check(buyer.select_engine(&"action_engine") and buyer.get_selected_engine_id() == &"action_engine","Licensed engine is selectable")
	var adapter := StudioCheckpoint.new()
	var encoded: Dictionary = adapter.capture(buyer)
	check(not encoded.is_empty() and adapter.error.is_empty(),"Licensed Studio checkpoint encodes")
	var restored: RunState = adapter.hydrate(encoded)
	check(restored != null and restored.get_selected_engine_id() == &"action_engine" and restored.get_engine_entitlements().licensed_ids.has(&"action_engine"),"Engine selection and license survive save hydration")
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	check(buyer.add_cash_cents(100000),"Buyer can fund its next production cycle")
	var begun: Dictionary = preload("res://scripts/simulation/begin_project.gd").execute(buyer,snapshots,"Engine game",&"action",&"fantasy")
	check(begun.get("ok",false) and begun.project.get_engine_id() == &"action_engine" and begun.project.get_engine_max_scope() == 25,"New project freezes the selected engine and Scope cap")
	var released := _release(buyer,snapshots)
	check(buyer.register_release(released),"Licensed release enters real sales accounting")
	var release_id := released.get_release_id()
	var sales_plan: Dictionary = buyer._plan_sales_cycle(&"",preload("res://scripts/market/market_transaction_trial.gd").neutral())
	check(not sales_plan.is_empty() and sales_plan.payable == sales_plan.records[release_id].settled_cents - int(sales_plan.records[release_id].settled_cents / 5),"Real sales plan deducts cumulative platform-net royalty")
	var royalty_before := creator.get_cash_cents()
	check(buyer.complete_productive_action() and world.settle_engine_royalties().get("ok",false),"Real licensed sales and creator transfer settle")
	var first_due: int = int(buyer.get_released_game_sales(release_id).settled_cents / 5)
	check(creator.get_cash_cents() == royalty_before + first_due,"Creator receives exactly 20% of actual platform-net sales")
	check(world.settle_engine_royalties().get("ok",false) and creator.get_cash_cents() == royalty_before + first_due,"Repeated settlement does not duplicate royalties")
	check(buyer.complete_productive_action() and world.settle_engine_royalties().get("ok",false) and creator.get_cash_cents() == royalty_before + first_due,"Non-settlement half pays no royalty")
	check(buyer.complete_productive_action() and world.settle_engine_royalties().get("ok",false),"Later real settlement transfers only its new royalty")
	var cumulative_due: int = int(buyer.get_released_game_sales(release_id).settled_cents / 5)
	check(creator.get_cash_cents() == royalty_before + cumulative_due,"Cumulative creator receipts have no rounding drift")
	var creator_save: Dictionary = adapter.capture(creator)
	var creator_restore: RunState = adapter.hydrate(creator_save) if not creator_save.is_empty() else null
	if creator_restore == null: print("CREATOR_CHECKPOINT_ERROR " + adapter.error)
	check(creator_restore != null and creator_restore._engine_royalty_receipts.get(release_id) == cumulative_due,"Creator royalty receipt survives checkpoint hydration")
	var ui_run := _studio("Engine UI",&"action")
	var phase: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(phase)
	check(phase.setup(null,ui_run,snapshots),"Studio phase opens for engine navigation")
	phase._open_management()
	check(phase.get_node_or_null("%StudioEnginesButton") != null,"Studio Management exposes the Engines page")
	phase._open_engines()
	check(phase._menu_panels[&"engines"].visible and phase._engine_browser.buttons.size() == 3,"Engine page shows built-in selection and both listings")
	var setup := PredevelopmentOverlay.new()
	root.add_child(setup)
	setup.market_run = buyer
	setup.open()
	check(setup.engine_picker.summary.text.contains("Max 25 Scope") and setup.engine_label.text.contains("freeze when"),"Project setup explains selected engine capacity before Begin")
	setup.queue_free()
	phase.queue_free()
	print("Engine marketplace flow: %d failures" % failures)
	quit(1 if failures else 0)
