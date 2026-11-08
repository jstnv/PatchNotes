## Public action and persistence coverage for engine-scoped Feature activation.
extends SceneTree
const BEFORE_CAPACITY=preload("res://scripts/debug/fixtures/engine_feature_actions_before_scope_limit.gd")

var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func _initialize() -> void: verify.call_deferred()

func scope(run: RunState, engine: StringName) -> int:
	var total := 0
	for id: StringName in run.get_future_project_feature_ids(engine):
		total += int(run._feature_definitions[id].scope)
	return total

func buy(run: RunState, engine: StringName, id: StringName) -> bool:
	var first := run.get_feature_research_quote(id,engine)
	if not first.get("can_admit",false) or not run.admit_feature_research(first):return false
	var second := run.get_feature_research_quote(id,engine)
	return second.get("can_research",false) and run.research_feature(second)

func quote(run: RunState, engine: StringName, id: StringName) -> Dictionary:
	return run.call("get_engine_feature_activation_quote",id,engine)

func toggle(run: RunState, q: Dictionary) -> bool:
	return bool(run.call("set_engine_feature_active",q))

func old_buy(run: RunState, engine: StringName, id: StringName) -> bool:
	var first:=BEFORE_CAPACITY.quote(run,id,engine)
	if not first.get("can_admit",false) or not BEFORE_CAPACITY.admit(run,first):return false
	var second:=BEFORE_CAPACITY.quote(run,id,engine)
	return second.get("can_research",false) and BEFORE_CAPACITY.complete(run,second)

func projected_scope(run: RunState, engine: StringName, id: StringName) -> int:
	var current: Array[StringName]=[];current.assign(run.get_engine_feature_state().engines[engine].committed)
	if id not in current:current.append(id)
	var total:=0
	for feature: StringName in RunState.EngineFeatures.normalize(current,run._feature_offers):total+=int(run._feature_definitions[feature].scope)
	return total

func verify_old_over_capacity(adapter: StudioCheckpoint) -> void:
	var old:=RunState.new()
	check(old.initialize_cash(0) and old.create_studio_with_traits("Historical capacity",&"action",[]) and old.add_cash(500000),"Create funded historical v2 fixture")
	var made:=old.create_proprietary_engine(old.get_proprietary_engine_creation_quote("Old engine"))
	if not made.get("ok",false):check(false,"Create historical engine");return
	var engine: StringName=made.engine_id
	check(old.select_engine(engine) and old.finalize_starter_selection(),"Select historical engine")
	var old_state:=old.get_engine_feature_state();old_state.version=2
	for row: Dictionary in old_state.engines.values():row.erase("enabled")
	old._engine_features=old_state
	var candidates: Array[StringName]=[&"controller",&"menu_system",&"sprites",&"recorded_sounds",&"main_theme",&"scrolling",&"colored_text",&"8_color_palette",&"inventory_system",&"timer_system",&"score_system",&"levels",&"simple_story",&"lives_system",&"save_files"]
	for id: StringName in candidates:
		var q:=BEFORE_CAPACITY.quote(old,id,engine)
		if q.get("can_admit",false) and projected_scope(old,engine,id)<=25:
			if not old_buy(old,engine,id):check(false,"Historical legal implementation "+str(id));return
	check(scope(old,engine)==25,"Historical library reaches old capacity through paid actions")
	var overflow: StringName=&""
	for id: StringName in candidates:
		if BEFORE_CAPACITY.quote(old,id,engine).get("can_admit",false) and projected_scope(old,engine,id)>25:
			overflow=id;break
	check(overflow!=&"" and old_buy(old,engine,overflow),"Pre-change action legitimately completes an over-cap Feature")
	if overflow==&"":return
	var original:=old.get_future_project_feature_ids(engine);var old_scope:=scope(old,engine)
	check(old_scope>25 and old.get_engine_feature_state().version==2,"Historical library is genuinely over capacity in v2")
	var checkpoint:=adapter.capture(old)
	check(not checkpoint.is_empty() and adapter.validate(checkpoint).is_empty(),"Historical over-cap checkpoint remains valid")
	var restored: RunState=adapter.hydrate(checkpoint) if not checkpoint.is_empty() else null
	check(restored!=null,"Continue accepts historical over-cap checkpoint")
	if restored==null:return
	check(restored.get_future_project_feature_ids(engine)==original and scope(restored,engine)==old_scope,"Continue preserves the full historical over-cap supply")
	check(quote(restored,engine,overflow).get("enabled",false) and restored.get_future_project_feature_ids(engine)==original,"Migration leaves historical over-cap Feature enabled without changing supply")

func verify() -> void:
	var run:=RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Activation Studio",&"action",[]),"Create a fresh Studio")
	check(run.add_cash(500000),"Fund fixture through the normal finance ledger")
	var first:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Activation A"))
	var other:=run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Activation B"))
	check(first.get("ok",false) and other.get("ok",false),"Create two independent proprietary engines")
	if not first.get("ok",false) or not other.get("ok",false):quit(1);return
	var engine: StringName=first.engine_id
	var engine_b: StringName=other.engine_id
	check(run.select_engine(engine) and run.finalize_starter_selection(),"Select engine and finish Studio setup")
	var has_api:=run.has_method("get_engine_feature_activation_quote") and run.has_method("set_engine_feature_active")
	check(has_api,"Run exposes per-engine activation quote and action")
	if not has_api:quit(1);return
	check(scope(run,engine)==5 and quote(run,engine,&"text").get("enabled",false),"Starter Features begin enabled")
	var guard_calls: Array[int]=[0]
	run.checkpoint_before_mutation=func() -> bool:
		guard_calls[0]+=1
		return false
	var guarded:=quote(run,engine,&"text")
	check(guarded.get("can_toggle",false) and guard_calls[0]==0,"Reading an activation quote never invokes the checkpoint mutation guard")
	check(not toggle(run,guarded) and guard_calls[0]>0 and quote(run,engine,&"text").get("enabled",false),"The checkpoint mutation guard still blocks activation changes")
	run.checkpoint_before_mutation=Callable()
	check(buy(run,engine,&"colored_text") and buy(run,engine,&"sprites"),"Implement two legal children of the starter Features")
	var palette:=quote(run,engine,&"4_color_palette")
	check(palette.get("enabled",false) and not palette.get("can_toggle",true) and &"colored_text" in palette.get("active_children",[]) and &"sprites" in palette.get("active_children",[]),"A parent cannot be disabled while either of its direct children is enabled")
	var text_parent:=quote(run,engine,&"text")
	check(not text_parent.get("can_toggle",true) and &"colored_text" in text_parent.get("active_children",[]),"An enabled AND child blocks each of its parents")
	var cycle:=run.get_completed_run_cycles();var cash:=run.get_cash_cents();var random:=run.random_streams.snapshot();var empty_queue:=run.get_feature_research_queue()
	check(not toggle(run,palette) and not toggle(run,text_parent),"Blocked parent toggles cannot be applied")
	check(toggle(run,quote(run,engine,&"colored_text")),"Disable the AND child immediately")
	check(&"colored_text" in run.get_engine_feature_state().engines[engine].implemented and &"colored_text" not in run.get_future_project_feature_ids(engine),"Disabling preserves permanent implementation while removing future supply")
	check(quote(run,engine,&"text").get("can_toggle",false) and toggle(run,quote(run,engine,&"text")),"Inactive children do not block disabling their parent")
	var inactive_child:=quote(run,engine,&"colored_text")
	check(not inactive_child.get("enabled",true) and not inactive_child.get("can_toggle",true) and &"text" in inactive_child.get("inactive_parents",[]),"An inactive parent blocks reactivating its AND child")
	check(not toggle(run,inactive_child),"Cannot bypass an inactive parent")
	check(run.get_cash_cents()==cash and run.get_completed_run_cycles()==cycle and run.random_streams.snapshot()==random and run.get_feature_research_queue()==empty_queue,"Activation and rejection spend no cash, cycle, RNG or queue work")
	check(buy(run,engine,&"scrolling"),"An implemented parent permits paid implementation even while inactive")
	var scrolling:=quote(run,engine,&"scrolling")
	check(not scrolling.get("enabled",true) and not scrolling.get("can_toggle",true) and &"text" in scrolling.get("inactive_parents",[]),"Child implemented under an inactive parent stays disabled")
	check(toggle(run,quote(run,engine,&"text")) and toggle(run,quote(run,engine,&"colored_text")),"Restoring parents allows the child to be re-enabled")
	check(not quote(run,engine,&"scrolling").get("enabled",true) and quote(run,engine,&"scrolling").get("can_toggle",false),"Previously inactive child is independently available to enable")
	for id: StringName in [&"lives_system",&"enemies",&"general_combat",&"turn_based_combat",&"scripted_ai",&"difficulty_levels",&"menu_system",&"save_files",&"character_classes"]:
		if not buy(run,engine,id):check(false,"Implement legal graph Feature: "+str(id));quit(1);return
	check(scope(run,engine)==24,"The graph fixture remains within the 25-Scope engine limit")
	var combat:=quote(run,engine,&"general_combat")
	var save_files:=quote(run,engine,&"save_files")
	check(not combat.get("can_toggle",true) and &"turn_based_combat" in combat.get("active_children",[]) and &"character_classes" in combat.get("active_children",[]),"Multiple direct active children block their common parent")
	check(not save_files.get("can_toggle",true) and &"character_classes" in save_files.get("active_children",[]),"Cross-category AND child blocks its Technology parent")
	check(not quote(run,engine,&"turn_based_combat").get("can_toggle",true) and not quote(run,engine,&"scripted_ai").get("can_toggle",true),"Both parents of Difficulty Levels are protected")
	check(toggle(run,quote(run,engine,&"difficulty_levels")),"Disable Difficulty Levels")
	check(quote(run,engine,&"turn_based_combat").get("can_toggle",false) and quote(run,engine,&"scripted_ai").get("can_toggle",false),"Inactive AND child no longer blocks either direct parent")
	check(toggle(run,quote(run,engine,&"difficulty_levels")),"Re-enable Difficulty Levels")
	check(buy(run,engine,&"16_bit_sound") and scope(run,engine)==24,"Replacement has zero additional normalized Scope")
	var sound_parent:=quote(run,engine,&"8_bit_sound")
	check(sound_parent.get("enabled",false) and not sound_parent.get("can_toggle",true) and &"16_bit_sound" in sound_parent.get("active_children",[]),"Replaced 8-Bit Sound remains logically enabled as the 16-Bit parent")
	check(&"8_bit_sound" not in run.get_future_project_feature_ids(engine) and &"16_bit_sound" in run.get_future_project_feature_ids(engine),"Draw supply contains only the active replacement")
	check(buy(run,engine,&"controller") and scope(run,engine)==25,"Fill the engine exactly to its capacity")
	check(buy(run,engine,&"timer_system"),"Over-cap paid implementation completes through the ordinary FIFO")
	var timer:=quote(run,engine,&"timer_system")
	check(not timer.get("enabled",true) and timer.get("scope_blocked",false) and not timer.get("can_toggle",true) and int(timer.get("projected_scope",0))>25 and timer.get("scope_capacity",0)==25,"Over-cap Feature is implemented but disabled and explains the capacity block")
	var forged:=timer.duplicate(true);forged.can_toggle=true;forged.scope_blocked=false
	var before_forgery:=StudioCheckpoint.new().capture(run)
	check(not toggle(run,forged) and StudioCheckpoint.new().capture(run)==before_forgery,"Forged capacity quote is rejected without any state mutation")
	check(not toggle(run,timer) and &"timer_system" in run.get_engine_feature_state().engines[engine].implemented and &"timer_system" not in run.get_future_project_feature_ids(engine),"Blocked activation preserves paid ownership and draw supply")
	var snapshot:=run.get_future_project_feature_ids(engine)
	var project:=ProjectState.new(30)
	check(project.configure_predevelopment("Frozen activation project",&"action",&"fantasy",snapshot),"Freeze a project before changing activation")
	var pending:=run.get_feature_research_quote(&"controller",engine_b)
	check(pending.get("can_admit",false) and run.admit_feature_research(pending),"Queue unrelated work on the second engine")
	var stale:=quote(run,engine,&"controller")
	check(toggle(run,quote(run,engine,&"difficulty_levels")),"Change activation after obtaining an earlier quote")
	var stale_snapshot:=StudioCheckpoint.new().capture(run)
	check(not toggle(run,stale) and StudioCheckpoint.new().capture(run)==stale_snapshot,"Stale activation quote cannot change state")
	check(toggle(run,quote(run,engine,&"difficulty_levels")),"Restore Difficulty Levels after stale-quote test")
	var before:=StudioCheckpoint.new().capture(run);cash=run.get_cash_cents();cycle=run.get_completed_run_cycles();random=run.random_streams.snapshot();var queue:=run.get_feature_research_queue()
	var controller:=quote(run,engine,&"controller")
	check(controller.get("enabled",false) and controller.get("can_toggle",false) and toggle(run,controller),"Disable an independent Feature to free Scope")
	timer=quote(run,engine,&"timer_system")
	check(not timer.get("scope_blocked",true) and timer.get("projected_scope",0)==25 and timer.get("can_toggle",false) and toggle(run,timer),"Enable another Feature exactly at the Scope limit")
	check(run.get_cash_cents()==cash and run.get_completed_run_cycles()==cycle and run.random_streams.snapshot()==random and run.get_feature_research_queue()==queue,"Free activation leaves pending FIFO, cash, cycle and RNG unchanged")
	check(project.get_feature_supply_ids()==snapshot and &"controller" in snapshot and &"timer_system" not in snapshot,"Existing project retains its frozen Feature supply")
	check(not quote(run,engine_b,&"controller").get("enabled",false) and run.get_engine_feature_state().engines[engine_b].implemented.size()==4,"Activation changes remain local to the selected engine")
	var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run)
	check(not saved.is_empty() and adapter.validate(saved).is_empty() and saved!=before,"Activation state saves with valid provenance")
	var loaded: RunState=adapter.hydrate(saved) if not saved.is_empty() else null
	check(loaded!=null,"Continue restores activation state")
	if loaded!=null:
		check(not quote(loaded,engine,&"controller").get("enabled",true) and quote(loaded,engine,&"timer_system").get("enabled",false) and loaded.get_feature_research_queue()==queue,"Continue preserves disabled/enabled Features and pending queue")
		check(loaded.get_future_project_feature_ids(engine)==run.get_future_project_feature_ids(engine),"Continue preserves normalized future supply")
		var broken:=loaded.get_engine_feature_state();broken.engines[engine].erase("enabled");loaded._engine_features=broken
		check(not loaded.valid_engine_state(),"Malformed activation record is rejected")
	# Existing legitimate Studio checkpoints remain readable under the new scheme.
	var prior: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://../sims/new-engine-foundations-20261104/old-engine/prior.json"))
	var legacy: RunState=adapter.hydrate(prior.player) if prior is Dictionary else null
	check(legacy!=null,"Pre-activation engine checkpoint migrates")
	if legacy!=null:
		var old_id:=StringName(prior.engine_id)
		check(legacy.get_engine_feature_state().engines[old_id].implemented.is_empty() and legacy.get_future_project_feature_ids(old_id).is_empty(),"Old engine retains its pre-existing implementation and supply")
		var v1:=legacy.get_engine_feature_state();v1.version=1
		for row: Dictionary in v1.engines.values():row.erase("enabled")
		legacy._engine_features=v1
		var v1_saved:=adapter.capture(legacy)
		check(not v1_saved.is_empty() and adapter.validate(v1_saved).is_empty(),"A v1 pre-activation checkpoint remains valid")
		var v1_loaded: RunState=adapter.hydrate(v1_saved) if not v1_saved.is_empty() else null
		check(v1_loaded!=null and v1_loaded.get_future_project_feature_ids(old_id).is_empty(),"A v1 checkpoint restores without inventing Features")
	verify_old_over_capacity(adapter)
	var career: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/flex-hands-20261101-v1/preceding-world.json"))
	var contractor: RunState=adapter.hydrate(career.player) if career is Dictionary else null
	check(contractor!=null,"Released-game fixture restores for a legal Contract")
	if contractor!=null:
		var made:=contractor.create_proprietary_engine(contractor.get_proprietary_engine_creation_quote("Contract activation"))
		check(made.get("ok",false) and contractor.select_engine(made.get("engine_id",&"")) and contractor.is_primitive_contract_offer_available(),"Contract fixture selects the new engine through normal gates")
		if made.get("ok",false):
			var accepted:=contractor.accept_primitive_contract()
			check(accepted!=null,"Accept a legal Contract")
			if accepted!=null:
				var frozen:=accepted.get_eligible_feature_ids()
				check(toggle(contractor,quote(contractor,made.engine_id,&"text")),"Disable a starter Feature after Contract acceptance")
				check(&"text" in frozen and accepted.get_eligible_feature_ids()==frozen and &"text" not in contractor.get_future_project_feature_ids(made.engine_id),"Accepted Contract retains frozen supply after activation changes")
	print("ENGINE_FEATURE_ACTIVATION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
