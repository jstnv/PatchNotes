## Engine-scoped implementation workflow and migration checks.
extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:verify.call_deferred()
func verify() -> void:
	var run:=RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Implementation Studio",&"action",[]),"Studio fixture")
	var created:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Engine A"))
	var other:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Engine B"))
	check(created.get("ok",false) and other.get("ok",false),"Two independent proprietary engines")
	if not created.get("ok",false) or not other.get("ok",false):quit(1);return
	var a: StringName=created.engine_id
	var b: StringName=other.engine_id
	check(run.select_engine(a) and run.finalize_starter_selection(),"Select engine and finalize Studio setup")
	var quote:=run.get_feature_research_quote(&"text",a)
	check(quote.get("can_admit",false),"Feature implementation admission is available")
	check(run.admit_feature_research(quote),"Implementation down payment enters queue")
	var locked:=run.get_feature_research_quote(&"colored_text",b)
	check(not locked.get("unlocked",true) and not locked.get("can_admit",true),"Prerequisite belongs to the target engine")
	var second:=run.get_feature_research_quote(&"keyboard_and_mouse",b)
	check(second.get("can_admit",false) and run.admit_feature_research(second),"Another engine can join the existing Studio queue")
	check(run.get_feature_research_queue().size()==2 and not run.get_feature_research_quote(&"keyboard_and_mouse",b).can_research,"Only the queue head can complete")
	var completion:=run.get_feature_research_quote(&"text",a)
	check(completion.get("can_research",false),"Queued Feature can complete")
	var before_cycle:=run.get_completed_run_cycles()
	check(run.research_feature(completion),"Implementation completes through existing action")
	var features:=run.get_engine_feature_state()
	check(run.get_completed_run_cycles()==before_cycle+1,"Completion spends exactly one productive cycle")
	check(run.get_feature_research_quote(&"keyboard_and_mouse",b).can_research,"Next queued engine advances after the head completes")
	check(&"text" in features.engines[a].implemented and &"text" not in features.engines[b].implemented,"Permanent implementation remains engine-specific")
	check(&"text" in run.get_future_project_feature_ids() and &"text" in features.engines[a].committed,"Completion immediately supplies future projects without a commit")
	check(not run.stage_engine_features([&"text"] as Array[StringName],a) and run.get_engine_configuration_quote(a).is_empty(),"Stage and Commit are retired")
	var adapter:=StudioCheckpoint.new()
	var saved:=adapter.capture(run)
	check(not saved.is_empty() and adapter.validate(saved).is_empty(),"New workflow checkpoint validates: "+adapter.error)
	var restored: RunState=adapter.hydrate(saved) if not saved.is_empty() else null
	check(restored!=null and &"text" in restored.get_future_project_feature_ids(),"Completed implementation survives save hydration")
	if restored!=null:
		var old_run: RunState=restored
		var old_state:=old_run.get_engine_feature_state()
		old_state.version=1
		old_state.engines[a].committed.clear()
		old_state.engines[a].staged=[&"text"] as Array[StringName]
		old_run._engine_features=old_state
		var old:=adapter.capture(old_run)
		check(adapter.validate(old).is_empty(),"Historical staged checkpoint remains valid")
		var migrated: RunState=adapter.hydrate(old)
		check(migrated!=null and migrated.get_engine_feature_state().version==2 and &"text" in migrated.get_future_project_feature_ids(),"Historical paid and staged Feature becomes available without another payment")
		if migrated!=null:
			var queue_before:=migrated.get_feature_research_queue()
			var b_completion:=migrated.get_feature_research_quote(&"keyboard_and_mouse",b)
			var b_cycle:=migrated.get_completed_run_cycles()
			check(queue_before.size()==1 and b_completion.can_research and migrated.research_feature(b_completion),"Historical active queue survives migration and completes once")
			check(migrated.get_completed_run_cycles()==b_cycle+1 and &"keyboard_and_mouse" in migrated.get_engine_feature_state().engines[b].committed and &"keyboard_and_mouse" not in migrated.get_engine_feature_state().engines[a].committed,"Migrated queue completion remains engine-specific")
		old_state.engines[a].staged.clear()
		old_run._engine_features=old_state
		old=adapter.capture(old_run)
		check(adapter.validate(old).is_empty(),"Historical paid but uncommitted checkpoint remains valid")
		migrated=adapter.hydrate(old)
		check(migrated!=null and &"text" in migrated.get_future_project_feature_ids(),"Historical paid but uncommitted Feature becomes available")
		var historically_removed:=old_state.duplicate(true)
		historically_removed.configurations.append({"engine_id":a,"removed":[&"text"] as Array[StringName]})
		var preserved:=RunState.EngineFeatures.migrate(historically_removed,run._feature_offers)
		check(&"text" in preserved.engines[a].implemented and &"text" not in preserved.engines[a].committed,"Explicitly removed historical Feature remains owned but held")
	if restored!=null:
		var limited: RunState=adapter.hydrate(saved)
		check(limited.spend_cash_cents(limited.get_cash_cents()-100),"Low-cash fixture")
		check(not limited.get_feature_research_quote(&"text",b).can_admit,"Insufficient funds prevents a new implementation deposit")
	print("ENGINE_FEATURE_WORKFLOW failures=",failures)
	quit(1 if failures else 0)
