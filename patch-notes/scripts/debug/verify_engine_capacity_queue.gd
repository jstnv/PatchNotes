## Queue completion at capacity keeps implementations while respecting active supply.
extends SceneTree

var checks:=0
var failures:=0

func check(ok: bool, label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1

func _initialize() -> void: verify.call_deferred()

func scope(run: RunState, engine: StringName, added: StringName=&"") -> int:
	var ids:=run.get_future_project_feature_ids(engine)
	if not added.is_empty() and added not in ids:ids.append(added)
	ids=RunState.EngineFeatures.normalize(ids,run._feature_offers)
	var total:=0
	for id: StringName in ids:total+=int(run._feature_definitions[id].scope)
	return total

func buy(run: RunState,engine: StringName,id: StringName) -> bool:
	var q:=run.get_feature_research_quote(id,engine)
	if not q.get("can_admit",false) or not run.admit_feature_research(q):return false
	q=run.get_feature_research_quote(id,engine)
	return q.get("can_research",false) and run.research_feature(q)

func verify() -> void:
	var run:=RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Capacity queue",&"action",[]) and run.add_cash(500000),"Create and fund a Studio")
	var made:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Capacity engine"))
	check(made.get("ok",false),"Create a proprietary engine")
	if not made.get("ok",false):quit(1);return
	var engine: StringName=made.engine_id
	check(run.select_engine(engine) and run.finalize_starter_selection(),"Select engine and finish setup")
	var candidates: Array[StringName]=[&"controller",&"menu_system",&"sprites",&"recorded_sounds",&"main_theme",&"scrolling",&"colored_text",&"8_color_palette",&"inventory_system",&"timer_system",&"score_system",&"levels",&"simple_story",&"lives_system",&"save_files"]
	for id: StringName in candidates:
		if scope(run,engine)==25:break
		var next:=scope(run,engine,id);var q:=run.get_feature_research_quote(id,engine)
		if q.get("can_admit",false) and next>scope(run,engine) and next<=25:
			if not buy(run,engine,id):check(false,"Implement "+str(id));quit(1);return
	check(scope(run,engine)==25,"Paid implementations can fill exactly 25 Scope")
	if scope(run,engine)!=25:quit(1);return
	check(buy(run,engine,&"16_bit_sound") and scope(run,engine)==25,"Replacement implementation fits without double-counting parent")
	var selected: Array[StringName]=[]
	for id: StringName in candidates:
		if run.get_feature_research_quote(id,engine).get("can_admit",false) and scope(run,engine,id)>25:
			selected.append(id)
			if selected.size()==2:break
	check(selected.size()==2,"Find two legal over-cap Features")
	if selected.size()!=2:quit(1);return
	for id: StringName in selected:
		check(run.admit_feature_research(run.get_feature_research_quote(id,engine)),"Queue over-cap Feature "+str(id))
	var checkpoint:=StudioCheckpoint.new();var saved:=checkpoint.capture(run)
	var loaded: RunState=checkpoint.hydrate(saved) if not saved.is_empty() else null
	check(loaded!=null and loaded.get_feature_research_queue()==run.get_feature_research_queue(),"Continue preserves the over-cap FIFO")
	if loaded==null:quit(1);return
	for id: StringName in selected:
		var q:=loaded.get_feature_research_quote(id,engine)
		check(q.get("can_research",false) and loaded.research_feature(q),"Finish paid FIFO item even at capacity: "+str(id))
		var activation:=loaded.get_engine_feature_activation_quote(id,engine)
		check(not activation.get("enabled",true) and activation.get("scope_blocked",false) and not activation.get("can_toggle",true),"Over-cap Feature stays implemented and inactive: "+str(id))
	check(loaded.get_feature_research_queue().is_empty() and scope(loaded,engine)==25,"FIFO clears once without exceeding active capacity")
	var saved_completed:=checkpoint.capture(loaded)
	var reloaded: RunState=checkpoint.hydrate(saved_completed) if not saved_completed.is_empty() else null
	check(reloaded!=null and reloaded.get_future_project_feature_ids(engine)==loaded.get_future_project_feature_ids(engine),"Continue preserves the active supply after FIFO completion")
	if reloaded!=null:
		for id: StringName in selected:
			check(id in reloaded.get_engine_feature_state().engines[engine].implemented and not reloaded.get_engine_feature_activation_quote(id,engine).get("enabled",true),"Continue retains paid inactive Feature "+str(id))
	print("ENGINE_CAPACITY_QUEUE checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
