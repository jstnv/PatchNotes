## Phase2A acceptance. Uses the actual new-Studio path; no player save access.
extends SceneTree
const PUBLIC := &"public_action"
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Market := preload("res://scripts/engines/engine_marketplace.gd")
const Production := preload("res://scripts/simulation/production_hand.gd")
var observations: Dictionary={}
var checks := 0
var failures: Array[String] = []
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	check(RunState.new().get_engine_feature_state().engines.has(&"legacy_engine"),"Unnamed primitive models preserve their legacy compatibility engine")
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var session = Factory.create_fresh_session({"schema_version":1,"studio_id":"public_acceptance","studio_name":"Public acceptance","specialty":"action","traits":[],"seed":"4417"},catalog)
	check(session != null,"New Studio bootstraps")
	if session != null:
		var run: RunState = session.run
		var access := run.get_engine_entitlements()
		check(run.get_selected_engine_id()==PUBLIC,"New Studio selects Public Action by default")
		check(access.get("public_ids",[]).has(PUBLIC),"Public access is explicit")
		check(not access.owned_ids.has(PUBLIC) and access.owned_ids.is_empty(),"Access grants no engine ownership/proprietary engine")
		check(not run.select_engine(&"legacy_engine"),"New Studio cannot select retired uncapped legacy engine")
		var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/threads/engine-system/2026-10-31-starting-libraries-recommended.json"))
		var expected: Array[StringName] = []
		for id: String in manifest.libraries.public_action.ids:expected.append(StringName(id))
		check(Array(run.get_future_project_feature_ids())==expected,"Exact approved Public Action manifest")
		var scope := 0
		for id: StringName in run.get_future_project_feature_ids():scope += int(run._feature_definitions[id].scope)
		check(scope==27,"Fixed library has27 printed Scope")
		var state := run.get_engine_feature_state()
		check(state.engines.has(PUBLIC) and not state.engines.has(&"legacy_engine"),"Only public starting engine registry")
		if state.engines.has(PUBLIC):
			check(state.engines[PUBLIC].kind==&"public" and run.get_selected_engine_capacity()==27,"Public type and27 maximum Scope")
			check(not run.stage_engine_features([&"text"] as Array[StringName]) and run.get_engine_configuration_quote().is_empty(),"Fixed library forbids staging/respec")
			check(not run.get_feature_research_quote(&"colored_text").get("can_admit",false),"Public Feature expansion is disabled")
		check(not Market.find(PUBLIC).is_empty(),"Public definition is discoverable")
		check(not Market.find(PUBLIC).get("technology_skill_tree",true) and not Market.find(PUBLIC).get("upgrades_available",true),"Public SkillTree and upgrades are unavailable")
		var cap := ProjectState.new(30)
		check(cap.set_engine_id(PUBLIC,27) and cap.add_scope(26) and not cap.add_scope(2) and cap.get_current_scope()==26 and cap.add_scope(1) and not cap.add_scope(1),"Public27 hard cap rejects overshoot atomically")
		check(run.finalize_starter_selection(),"Studio can immediately finalize starting access")
		if run.get_selected_engine_id()==PUBLIC: await verify_game(session)
	var bonuses:=Production.combine_bonuses([Market.production_bonus(PUBLIC),{0:1000},{0:1000}])
	var hand: Array=[]
	for i in range(4):hand.append({"primary_stat":&"graphics"})
	check(Production.calculate(hand,{0:10,1:10,2:10,3:10},true,bonuses).score_additions[0]==18,"Engine, supplied Studio and employee bonuses add1.5+0.1+0.1+0.1")
	var royalty = load("res://scripts/engines/engine_royalty.gd")
	var methods: Array = royalty.get_script_method_list().filter(func(m):return m.name=="cumulative")
	var rate_supported: bool=not methods.is_empty() and methods[0].args.size()==2
	check(rate_supported,"Royalty model accepts engine-specific basis points")
	if rate_supported:
		check(royalty.cumulative(10001,3000)==3000 and royalty.increment(3,4,3000)==1,"Public30 percent carries fractional cents cumulatively")
		check(royalty.cumulative(9223372036854775807,3000)==2767011611056432742,"Large royalty amounts avoid multiplication overflow")
		check(royalty.cumulative(101)==20 and royalty.increment(4,5)==1,"Legacy20 percent accounting is preserved")
	check(RunState.new().has_method("get_engine_royalty_payments"),"External provider payments have a saved-counter report")
	await verify_finance_and_ui(catalog)
	await verify_worlds(catalog)
	var output := {"checks":checks,"failures":failures,"observations":observations}
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):FileAccess.open(arg.trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("Public Action: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func verify_game(session: RefCounted) -> void:
	var run: RunState = session.run
	check(run.valid_engine_state(),"Current engine provenance is valid")
	var adapter := StudioCheckpoint.new()
	var saved := adapter.capture(run)
	check(not saved.is_empty(),"Public Studio typed capture: "+adapter.error)
	var restored := adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
	check(restored!=null and restored.get_selected_engine_id()==PUBLIC,"Public access survives cold JSON restore: "+adapter.error)
	var started: Dictionary = session.execute(session.command(&"begin_development",{"name":"Public game","genre":"action","theme":"fantasy"}))
	check(started.get("ok",false),"Public development begins without purchase")
	if started.get("ok",false):
		var project: ProjectState = session.development.project
		check(project.get_engine_id()==PUBLIC and project.get_engine_max_scope()==27 and project.get_feature_supply_ids()==run.get_future_project_feature_ids(),"Project freezes public identity/capacity/library")
		var familiarity := run.get_feature_familiarity(&"text")
		check(run.record_resolved_feature(project,&"text",&"design") and not run.record_resolved_feature(project,&"text",&"design") and run.get_feature_familiarity(&"text")==familiarity+1,"Public usage earns shared familiarity once per Feature/project")

# Synthetic751-unit title isolates settlement math; legal career is checked separately.
func _release(run: RunState, snapshots: PrimitiveSnapshotDatabase) -> ProjectState:
	var project := ProjectState.new(30)
	project.set_engine_id(PUBLIC,27)
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


func verify_finance_and_ui(catalog: RefCounted) -> void:
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Public finance",&"puzzle",[]) and run.finalize_starter_selection(),"Other Studio specialties receive the same public engine")
	var snapshots := PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var title := _release(run,snapshots)
	check(run.register_release(title),"Public release enters real sales accounting")
	var id := title.get_release_id()
	check(run._release_engine_ids.get(id)==PUBLIC,"Release records the frozen engine")
	var forged := run._release_engine_ids.duplicate(true);run._release_engine_ids.erase(id)
	check(not run.valid_engine_state() and run._plan_sales_cycle(&"",preload("res://scripts/market/market_transaction_trial.gd").neutral()).is_empty(),"Missing public release identity cannot evade royalty")
	run._release_engine_ids=forged
	var royalty=load("res://scripts/engines/engine_royalty.gd")
	for cycle in range(1,5):
		var raw_before := run.get_released_game_sales(id)
		var before_cash := run.get_cash_cents()
		var plan := run._plan_sales_cycle(&"",preload("res://scripts/market/market_transaction_trial.gd").neutral())
		check(not plan.is_empty(),"Sales planning accepted atcycle%d"%cycle)
		if plan.is_empty():break
		var raw_delta: int=plan.records[id].settled_cents-raw_before.settled_cents
		var royalty_delta: int=royalty.increment(raw_before.settled_cents,plan.records[id].settled_cents,3000)
		check(plan.payable==raw_delta-royalty_delta,"Public royalty uses post-platform delta atcycle%d"%cycle)
		check(run.complete_productive_action(),"Real productive settlement commits atcycle%d"%cycle)
		var report:=run.get_released_game_monthly_report(id)
		check(report.studio_net_cents==report.net_cents-report.net_cents*3000/10000 and report.studio_settled_cents==report.settled_cents-report.settled_cents*3000/10000,"Readonly report matches actual public-engine Studio proceeds atcycle%d"%cycle)
		check(run.get_cash_cents()==before_cash+raw_delta-royalty_delta-(30000 if preload("res://scripts/calendar/calendar_clock.gd").is_boundary(cycle,run.get_calendar_profile()) else 0),"Cash reconciles once with royalty/rent atcycle%d"%cycle)
		var payments=run.get_engine_royalty_payments()
		var world := RivalWorld.new();world.player=run
		check(world.settle_engine_royalties().get("transfers",{}).is_empty(),"Public provider is never credited to a rival")
		check(payments==run.get_engine_royalty_payments(),"Repeated provider receipt observation is idempotent")
	var payments=run.get_engine_royalty_payments()
	check(payments.size()==1 and payments[0].provider_kind==&"external_public_engine" and payments[0].paid_cents==royalty.cumulative(run.get_released_game_sales(id).settled_cents,3000),"External provider receipt binds actual saved post-platform settlements")
	check(not payments.is_empty(),"Synthetic positive-sales provider report is available")
	# Synthetic review/unit fixtures are arithmetic controls; only the legal career below is a save oracle.
	var rng:=run.random_streams.snapshot()
	var state:=run.get_engine_feature_state();state.engines[PUBLIC].initial.append(&"colored_text")
	check(not run.EngineFeatures.valid(state,run._feature_definitions,run._feature_offers),"Forged public manifest rejects")
	var browser=load("res://scripts/ui/engine_market_browser.gd").new();root.add_child(browser);browser.open(run,null);browser._inspect(PUBLIC)
	check(browser.buttons.has(PUBLIC) and browser.description.text.contains("30%") and browser.description.text.contains("not engine ownership") and browser.description.text.contains("No available upgrades") and browser.description.text.contains("27") and not browser.configure_button.visible,"Engine detail discloses public fixed terms without an implementation action")
	var picker=load("res://scripts/ui/engine_picker.gd").new();root.add_child(picker);picker.bind(run)
	check(picker.choices.item_count==1 and picker.choices.get_item_metadata(0)==PUBLIC and picker.summary.text.contains("27 printed Scope"),"Setup picker exposes Public27 before development")
	var store := FeatureStore.new();root.add_child(store);store.setup(run);store.open_store(PUBLIC)
	check(store.find_child("CommitEngineConfiguration",true,false)==null and not browser.configure_button.visible,"Fixed library has no Stage or Commit controls")
	var menu: MainMenu=MainMenu.new();root.add_child(menu);await process_frame
	menu._specialty.select(1);menu._refresh_preview()
	check(menu._emphasis.text.contains("27") and menu._preview.text.contains("30%"),"New-Studio preview describes Public27 and royalty")
	check(run.random_streams.snapshot()==rng,"Browsing/reporting consumes no mechanical RNG")
	browser.queue_free();picker.queue_free();menu.queue_free();store.queue_free();await process_frame

func verify_worlds(catalog: RefCounted) -> void:
	var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/public-engine-phase2a-20261031-v1/preceding-capture/report.json"))
	var adapter:=StudioCheckpoint.new();var old:=adapter.hydrate(before.player)
	check(old!=null and old.get_selected_engine_id()==&"legacy_engine" and old.get_engine_entitlements().version==1,"Genuine preceding Studio retains legacy access: "+adapter.error)
	if old!=null:
		var codec=load("res://scripts/market/rival_world_checkpoint.gd").new();var world=codec.restore(before.world,before.player,old,catalog)
		check(world!=null,"Genuine preceding eight-rival world restores: "+codec.error)
		if world!=null:
			check(world.historical_archive.size()==8 and old.get_selected_engine_capacity()==ProjectState.MAX_SIGNED_INT,"Old archive and uncapped saved engine remain preserved")
		var saved:=adapter.capture(old);check(adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))!=null,"Grandfathered Studio re-saves under current build")
	var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"public_career","studio_name":"Public career","specialty":"action","traits":[],"seed":"4417"},catalog)
	var policy=load("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Public game","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
	var outcome=session.drive(policy,120,2)
	check(session.run.get_released_game_ids().size()==2,"Unfunded legal public-engine route completes two releases: "+str(outcome.get("error","")))
	for id: StringName in session.run.get_released_game_ids():check(session.run._release_engine_ids.get(id)==PUBLIC,"Legal released title retains public identity")
	var original=Factory.create_fresh_session({"schema_version":1,"studio_id":"public_career","studio_name":"Public career","specialty":"action","traits":[],"seed":"4417"},catalog)
	var replayed=load("res://scripts/simulation/development_replay.gd").replay(original,outcome.tape)
	check(replayed.get("ok",false),"Independent replay agrees on every boundary and RNG: "+str(replayed))
	observations.career={"cycles":session.run.get_completed_run_cycles(),"releases":session.run.get_released_game_ids().size(),"cash_cents":session.run.get_cash_cents(),"payments":session.run.get_engine_royalty_payments(),"steps":outcome.tape.steps.size(),"replay_ok":replayed.get("ok",false)}
	var saved:=adapter.capture(session.run);var restored:=adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
	check(not saved.is_empty() and restored!=null,"Actual two-release career cold restore: "+adapter.error)
	if restored!=null:
		check(restored.get_engine_royalty_payments()==session.run.get_engine_royalty_payments(),"Actual career external payments survive cold restore")
		var missing:=saved.duplicate(true);missing.run.release_engine_ids=[]
		check(not adapter.validate(missing).is_empty(),"Typed checkpoint rejects missing Public release terms")
		var stripped:=saved.duplicate(true);stripped.run.erase("engine_features")
		check(not adapter.validate(stripped).is_empty(),"Typed checkpoint rejects stripped fixed registry")
		stripped.source_build=StudioCheckpoint.LEGACY_BUILD
		check(not adapter.validate(stripped).is_empty(),"Public access cannot downgrade to legacy build to omit registry")
	# Current public player and frozen eight-rival opening also round trip together.
	var current=Factory.create_fresh_session({"schema_version":1,"studio_id":"public_current_world","studio_name":"Public world","specialty":"puzzle","traits":[],"seed":"4417"},catalog)
	var world=load("res://scripts/market/rival_trial.gd").create_world(current.run,catalog)
	check(world!=null,"Current public Studio admits certified eight-rival world")
	if world!=null:
		var codec=load("res://scripts/market/rival_world_checkpoint.gd").new();var player:=adapter.capture(current.run);var frozen: Dictionary=codec.capture(world)
		var owner_cash: Dictionary={}
		for id: StringName in world.studios:owner_cash[id]=world.studios[id].run.get_cash_cents()
		check(world.settle_engine_royalties().get("transfers",{}).is_empty(),"Public access pays no rival royalty or license fee")
		for id: StringName in world.studios:check(world.studios[id].run.get_cash_cents()==owner_cash[id],"Public access preserves real rival bankroll: "+str(id))
		var restored_player:=adapter.hydrate(player);var back=codec.restore(JSON.parse_string(JSON.stringify(frozen)),JSON.parse_string(JSON.stringify(player)),restored_player,catalog)
		check(back!=null,"Public player and real current world cold restore: "+codec.error)
		if back!=null:check(back.historical_archive==world.historical_archive and back.market_snapshot==world.market_snapshot,"Current archive/market facts remain exact")
