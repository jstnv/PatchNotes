extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	var run: RunState=Factory.create_fresh_session({"schema_version":1,"studio_id":"engine-phase1","studio_name":"Engine One","specialty":"action","traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog()).run
	check(run.has_method("get_engine_feature_state"),"RunState owns explicit engine Feature state")
	if run.has_method("get_engine_feature_state"):
		check(run._register_proprietary_engine(&"prop_b","Second engine"),"Foundation registration has no creation economy")
		check(run.select_engine(&"prop_b") and not run.owns_feature(&"text"),"Second engine does not inherit first engine implementation")
		var before: int=run.get_completed_run_cycles();var cash: int=run.get_cash_cents()
		var quote: Dictionary=run.get_feature_research_quote(&"text")
		print("QUOTE ",quote," OWN ",run.owns_feature(&"text")," STARTER ",run.needs_starter_selection()," BLOCK ",run.get_financial_block_reason()," ENGINE ",run.get_engine_feature_state())
		check(quote.can_admit and quote.engine_id==&"prop_b","Implementation quote binds engine identity")
		check(run.admit_feature_research(quote),"Exact new implementation admission")
		check(not run.owns_feature(&"text") and run.get_completed_run_cycles()==before,"Admission grants no Feature and costs no cycle")
		check(run.research_feature(run.get_feature_research_quote(&"text")),"One productive completion")
		check(run.owns_feature(&"text") and run.get_completed_run_cycles()==before+1 and run.get_cash_cents()==cash-30000,"Permanent implementation exact base price/cycle")
		check(run.get_future_project_feature_ids().is_empty(),"Implementation does not automatically configure a card")
		check(run.stage_engine_features([&"text"] as Array[StringName]),"Stage implemented Feature free")
		check(run.get_completed_run_cycles()==before+1,"Staging advances no calendar")
		var configuration: Dictionary=run.get_engine_configuration_quote()
		check(configuration.can_commit and configuration.cost_cents==0 and run.commit_engine_configuration(configuration),"Addition batch commits for one cycle without respec fee")
		check(run.get_completed_run_cycles()==before+2 and run.get_future_project_feature_ids()==[&"text"],"Committed-only future draw pool")
		check(run.select_engine(&"legacy_engine") and run.owns_feature(&"text"),"First engine remains independent")
		check(run.get_feature_familiarity(&"text")==0,"Implementation/staging do not fabricate familiarity")
		var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run);var cold:=adapter.hydrate(JSON.parse_string(JSON.stringify(saved)))
		check(cold!=null and cold.get_engine_feature_state()==run.get_engine_feature_state(),"Engine state and transactions persist through typed JSON cold restore")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));quit(0 if failures.is_empty() else 1)
