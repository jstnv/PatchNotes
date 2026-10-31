extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func fresh(id: String,traits: Array=[]) -> RefCounted:
	var s=Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":id,"specialty":"action","traits":traits,"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
	assert(s!=null);assert(s.run.finalize_starter_selection());return s
func image(run: RunState) -> PackedByteArray:
	return var_to_bytes([run.get_cash_cents(),run.get_completed_run_cycles(),run.get_engine_feature_state(),run.get_studio_finance_snapshot(),run.random_streams.snapshot()])
func cold(run: RunState) -> RunState:
	var adapter:=StudioCheckpoint.new();var saved=adapter.capture(run)
	var result=adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
	if result==null:print("COLD_ERROR ",adapter.error)
	return result
func implement(run: RunState,id: StringName) -> bool:
	var q=run.get_feature_research_quote(id)
	return q.get("can_admit",false) and run.admit_feature_research(q) and run.research_feature(run.get_feature_research_quote(id))
func _initialize() -> void:
	await process_frame
	var session=fresh("phase1_full");var run: RunState=session.run
	var rng=run.random_streams.snapshot()
	check(run._register_proprietary_engine(&"b","Engine B") and run.select_engine(&"b"),"Register and select an independent proprietary engine")
	check(not run.get_feature_research_quote(&"colored_text").unlocked,"Prerequisite on A does not satisfy implementation on B")
	check(implement(run,&"text"),"Buy and complete root on B through legal transactions")
	print("B_COLORED ",run.get_feature_research_quote(&"colored_text"));check(run.get_feature_research_quote(&"colored_text").unlocked,"Completed parent satisfies B prerequisite")
	check(run.get_future_project_feature_ids().is_empty(),"Implemented-only card stays out of draws")
	var before=image(run)
	check(not run.stage_engine_features([&"colored_text"] as Array[StringName]) and image(run)==before,"Unimplemented staging rejected atomically")
	check(run.stage_engine_features([&"text"] as Array[StringName]),"Stage implemented root for free")
	var q=run.get_engine_configuration_quote();var stale=q.duplicate(true);stale.cost_cents=1
	before=image(run)
	check(not run.commit_engine_configuration(stale) and image(run)==before,"Forged configuration rejects without mutation")
	var cycle=run.get_completed_run_cycles()
	check(run.commit_engine_configuration(q) and run.get_completed_run_cycles()==cycle+1,"One batch costs exactly one productive cycle")
	check(run.get_future_project_feature_ids()==[&"text"],"Committed-only prospective supply")
	before=image(run)
	check(not run.commit_engine_configuration(q) and image(run)==before,"Repeated/stale commit is atomic")
	var removal=run.get_engine_configuration_quote(&"",[] as Array[StringName])
	check(removal.requires_respec and removal.cost_cents==3000,"Removal charges 10% only of removed base value")
	before=image(run)
	check(not run.commit_engine_configuration(removal) and image(run)==before,"Removal cannot masquerade as free addition")
	check(run.commit_engine_configuration(removal,true) and run.owns_feature(&"text") and run.get_future_project_feature_ids().is_empty(),"Respec empties configuration but preserves permanent implementation")
	check(run.stage_engine_features([&"text"] as Array[StringName]) and run.commit_engine_configuration(run.get_engine_configuration_quote()),"Permanently implemented Feature can be added back without repurchase")
	check(run.random_streams.snapshot()==rng,"Implementation/configuration consume no RNG")
	check(cold(run)!=null,"Cold typed JSON round trip with respec history")
	# Frozen project observes its own pool/capacity even after a future selection changes.
	var started=session.execute(session.command(&"begin_development",{"name":"Frozen","genre":"action","theme":"aliens"}))
	print("STARTED ",started);check(started.get("ok",false),"Begin development from committed B")
	if started.get("ok",false):
		var project: ProjectState=session.development.project
		var supply=project.get_feature_supply_ids();var capacity=project.get_engine_max_scope()
		check(run.select_engine(&"legacy_engine") and project.get_feature_supply_ids()==supply and project.get_engine_max_scope()==capacity and capacity==20,"Active pool and capacity remain frozen across engine selection")
		var count=run.get_feature_familiarity(&"text")
		check(run.record_resolved_feature(project,&"text",&"design") and not run.record_resolved_feature(project,&"text",&"design") and run.get_feature_familiarity(&"text")==count+1,"Familiarity follows accepted frozen project, once per Feature/project")
		check(not session.execute(session.command(&"stage_engine_features",{"feature_ids":[]})).get("ok",false),"Headless staging respects Studio-only command boundary")
	# Quote arithmetic fixture: shared parent familiarity; no claim of a played campaign.
	var pricing=fresh("phase1_price").run
	pricing._familiarity[&"text"]=8
	var price=pricing.get_feature_research_quote(&"colored_text")
	print("PRICE ",price);check(price.discount_percent==80 and price.total_cents==17000 and price.down_cents==8500 and price.due_cents==8500,"80% parent familiarity discounts entire price, split half upfront")
	var discounted_cash=pricing.get_cash_cents()
	check(pricing.admit_feature_research(price) and pricing.research_feature(pricing.get_feature_research_quote(&"colored_text")) and pricing.get_cash_cents()==discounted_cash-17000,"Discounted whole-price charge is exact")
	var improved=fresh("phase1_improved").run
	var entry=improved.get_feature_research_quote(&"colored_text")
	check(improved.admit_feature_research(entry),"Admit at original familiarity")
	improved._familiarity[&"text"]=8
	var later=improved.get_feature_research_quote(&"colored_text")
	check(later.down_cents==entry.down_cents and later.due_cents==0 and improved.research_feature(later),"Improved familiarity never refunds a paid deposit")
	# Genuine pre-extraction paid queue, generated by the preserved prior runtime.
	var path=OS.get_cmdline_user_args()[1].trim_prefix("--legacy=")
	var adapter:=StudioCheckpoint.new();var legacy=adapter.hydrate(JSON.parse_string(FileAccess.get_file_as_string(path)))
	check(legacy!=null,"Genuine old paid queue loads without source relabeling")
	if legacy!=null:
		var oldq=legacy.get_feature_research_quote(&"colored_text")
		print("OLD ",oldq);check(oldq.implementation_version==0 and oldq.down_cents==42500 and oldq.due_cents==42500,"Paid old queue retains original deposit/installment terms")
		check(legacy.research_feature(oldq) and &"colored_text" in legacy.get_future_project_feature_ids() and cold(legacy)!=null,"Old queue completes and cold-restores with preserved auto-supply terms")
	# Native Store controls retain existing map/prerequisite surfaces.
	var ui_run=fresh("phase1_ui").run
	var store=FeatureStore.new();root.add_child(store);store.setup(ui_run)
	check(store._engine_selector.item_count>=1 and store._configuration_commit.disabled,"Store presents selected engine and honest empty staging")
	store.queue_free()
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	quit(0 if failures.is_empty() else 1)
