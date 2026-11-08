extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Adapter := preload("res://scripts/debug/verify_feature_parents.gd")
var checks := 0
var failures := 0
var catalog: RefCounted
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("Primitive branches: " + label)
func fresh(genre: StringName = &"sports") -> RefCounted:
	return Factory.create_fresh_session({"schema_version":1,"studio_id":"branches-"+str(genre),"studio_name":"Branches","specialty":str(genre),"traits":[],"seed":"4417"},catalog)
func state(run: RunState) -> String:
	return Replay.digest(Replay.freeze(run))
func from_payload(payload: Dictionary) -> RefCounted:
	var envelope:Dictionary={"schema_version":"1","kind":"campaign_studio","source_identity":Replay.source_identity(),"engine_version":Engine.get_version_info().string,"rng_algorithm":RunRandom.ALGORITHM,"accepted_sequence":"0","studio_payload":payload}
	envelope.integrity=Replay.digest(envelope)
	return Factory.create({"checkpoint":envelope},catalog)
func _initialize() -> void:
	await process_frame
	create_timer(100).timeout.connect(func(): push_error("Primitive branches timed out");quit(2))
	catalog = root.get_node("CardDatabase").get_development_catalog()
	# Every new Studio uses the same fixed Public Action library, regardless of specialty.
	var public_script = preload("res://scripts/engines/public_action_engine.gd")
	for genre: StringName in StudioSpecialties.RULES:
		var public_run: RunState = fresh(genre).run
		var access := public_run.get_engine_entitlements()
		check(public_run.get_selected_engine_id()==&"public_action" and access.public_ids.has(&"public_action") and not access.owned_ids.has(&"public_action"),"Public access is selected but not owned: " + str(genre))
		check(public_run.get_future_project_feature_ids()==public_script.LIBRARY and public_run.get_selected_engine_capacity()==27,"fixed Public library and 27 capacity: " + str(genre))
		var printed_scope:=0
		for feature: StringName in public_run.get_future_project_feature_ids(): printed_scope+=int(public_run._feature_definitions[feature].scope)
		check(printed_scope==27,"Public library printed scope: " + str(genre))
		check(not public_run.select_engine(&"legacy_engine") and not public_run.get_feature_research_quote(&"dialogue",&"public_action").get("can_admit",false),"new Studio cannot select legacy or expand Public: " + str(genre))
	# Test each branch by legal FIFO actions on a fresh proprietary engine.
	for child: StringName in [&"dialogue", &"character_backstories", &"maps", &"exploration"]:
		var parent: StringName = FeatureStoreCatalog.PRIMITIVE_PARENTS[child]
		var branch_run: RunState = fresh().run
		var created := branch_run.create_proprietary_engine(branch_run.get_proprietary_engine_creation_quote("Branch Engine"))
		check(created.get("ok",false),"create proprietary engine for " + str(child))
		if not created.get("ok",false): continue
		var engine: StringName=created.engine_id
		check(branch_run.select_engine(engine) and branch_run.finalize_starter_selection(),"select proprietary engine for " + str(child))
		var foundation: Array[StringName]=[&"text",&"4_color_palette",&"8_bit_sound",&"keyboard_and_mouse"]
		var initial_supply:=branch_run.get_future_project_feature_ids(engine)
		check(initial_supply.size()==foundation.size() and foundation.all(func(id):return initial_supply.has(id)),"four proprietary foundations " + str(child))
		var public_before: Dictionary=branch_run.get_engine_feature_state().engines[&"public_action"].duplicate(true)
		var child_quote:=branch_run.get_feature_research_quote(child,engine)
		var before:=state(branch_run)
		check(not child_quote.get("unlocked",true) and not child_quote.get("can_admit",true),"child requires its own engine parent: " + str(child))
		check(not branch_run.admit_feature_research(child_quote) and state(branch_run)==before,"locked child admission is atomic: " + str(child))
		var parent_quote:=branch_run.get_feature_research_quote(parent,engine)
		var cash:=branch_run.get_cash_cents();var cycle:=branch_run.get_completed_run_cycles()
		check(parent_quote.get("can_admit",false) and branch_run.admit_feature_research(parent_quote),"queue parent " + str(child))
		check(branch_run.get_cash_cents()==cash-int(parent_quote.get("down_cents",-1)) and branch_run.get_completed_run_cycles()==cycle and not branch_run.owns_feature(parent,engine),"deposit only; queued parent is not owned: " + str(child))
		child_quote=branch_run.get_feature_research_quote(child,engine)
		check(not child_quote.get("can_admit",true),"queued parent does not unlock child: " + str(child))
		parent_quote=branch_run.get_feature_research_quote(parent,engine)
		cash=branch_run.get_cash_cents()
		check(parent_quote.get("can_research",false) and branch_run.research_feature(parent_quote),"complete parent " + str(child))
		check(branch_run.get_cash_cents()==cash-int(parent_quote.get("due_cents",-1)) and branch_run.get_completed_run_cycles()==cycle+1 and branch_run.owns_feature(parent,engine),"parent payment and one cycle " + str(child))
		child_quote=branch_run.get_feature_research_quote(child,engine)
		cash=branch_run.get_cash_cents();cycle=branch_run.get_completed_run_cycles()
		check(child_quote.get("unlocked",false) and child_quote.get("can_admit",false) and branch_run.admit_feature_research(child_quote),"owned parent unlocks queued child " + str(child))
		check(branch_run.get_cash_cents()==cash-int(child_quote.get("down_cents",-1)) and branch_run.get_completed_run_cycles()==cycle and not branch_run.owns_feature(child,engine),"child admission charges once without a cycle " + str(child))
		child_quote=branch_run.get_feature_research_quote(child,engine);cash=branch_run.get_cash_cents()
		check(child_quote.get("can_research",false) and branch_run.research_feature(child_quote),"complete child " + str(child))
		check(branch_run.get_cash_cents()==cash-int(child_quote.get("due_cents",-1)) and branch_run.get_completed_run_cycles()==cycle+1 and branch_run.owns_feature(child,engine) and branch_run.get_future_project_feature_ids(engine).has(child),"child payment, cycle and future supply " + str(child))
		before=state(branch_run)
		check(not branch_run.research_feature(child_quote) and state(branch_run)==before,"completed queue cannot pay twice " + str(child))
		check(branch_run.get_engine_feature_state().engines[&"public_action"]==public_before,"Public library remains unchanged " + str(child))
		var checkpoint:=StudioCheckpoint.new();var saved:=checkpoint.capture(branch_run)
		var restored: RunState=checkpoint.hydrate(saved) if not saved.is_empty() else null
		check(restored!=null and restored.get_engine_feature_state()==branch_run.get_engine_feature_state() and restored.random_streams.snapshot()==branch_run.random_streams.snapshot(),"engine state and RNG survive checkpoint " + str(child))
	# Historical rival control profile legally creates a legacy starter roster.
	var legacy_session:=Factory.create_fresh_session({"schema_version":1,"studio_id":"legacy-branch-control","studio_name":"Legacy","specialty":"action","traits":[],"seed":"4417","rival_founder_profile":"rival-current-trial-1977-control-v1"},catalog)
	check(legacy_session!=null,"legacy control founder is admitted")
	if legacy_session!=null:
		var legacy_run: RunState=legacy_session.run
		check(legacy_run.get_selected_engine_id()==&"legacy_engine" and legacy_run.needs_starter_selection(),"legacy founder begins with starter selection")
		var legacy_child:=legacy_run.get_primitive_reserve_offer(&"enemies")
		var unchanged:=state(legacy_run)
		check(not legacy_child.unlocked and not legacy_child.can_purchase and legacy_child.missing_parents==[&"lives_system"],"legacy absent parent locks child")
		check(not legacy_run.purchase_starter_feature(&"enemies") and state(legacy_run)==unchanged,"legacy missing-parent starter purchase rejected atomically")
		var legacy_parent:=legacy_run.get_primitive_reserve_offer(&"lives_system")
		var old_cash:=legacy_run.get_cash_cents();var old_cycle:=legacy_run.get_completed_run_cycles();var old_rng:=legacy_run.random_streams.snapshot()
		check(legacy_parent.can_purchase and legacy_run.purchase_starter_feature(&"lives_system"),"legacy starter parent purchase succeeds")
		check(legacy_run.get_cash_cents()==old_cash-int(legacy_parent.price_cents) and legacy_run.get_completed_run_cycles()==old_cycle and legacy_run.random_streams.snapshot()==old_rng,"legacy starter purchase is zero-cycle with exact cash and unchanged RNG")
		check(legacy_run.finalize_starter_selection(),"legacy starter setup finalizes")
		var quote:=legacy_run.get_feature_research_quote(&"enemies",&"legacy_engine")
		old_cash=legacy_run.get_cash_cents();old_cycle=legacy_run.get_completed_run_cycles()
		check(quote.get("unlocked",false) and quote.get("can_admit",false),"legacy owned parent makes child queueable")
		if quote.get("can_admit",false):
			check(legacy_run.admit_feature_research(quote),"legacy child enters queue")
			check(legacy_run.get_cash_cents()==old_cash-int(quote.down_cents) and legacy_run.get_completed_run_cycles()==old_cycle and not legacy_run.owns_feature(&"enemies"),"legacy queue charges deposit without ownership or cycle")
			quote=legacy_run.get_feature_research_quote(&"enemies",&"legacy_engine");old_cash=legacy_run.get_cash_cents()
			check(quote.get("can_research",false) and legacy_run.research_feature(quote),"legacy queued child completes")
			check(legacy_run.get_cash_cents()==old_cash-int(quote.due_cents) and legacy_run.get_completed_run_cycles()==old_cycle+1 and legacy_run.owns_feature(&"enemies") and legacy_run.random_streams.snapshot()==old_rng,"legacy completion charges once and consumes one cycle without RNG drift")
	var run: RunState=fresh().run
	for invalid in ["missing", "maps"]:
		run._feature_definitions[&"maps"]=run._feature_definitions[&"maps"].duplicate(true)
		run._feature_definitions[&"maps"].purchase_parent=invalid
		var before:=state(run)
		check(FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers).has("error") and run.get_primitive_reserve_offer(&"maps").is_empty() and not run.purchase_starter_feature(&"maps") and state(run)==before,"bad graph rejects atomically " + invalid)
	run=fresh().run
	run._feature_definitions[&"levels"]=run._feature_definitions[&"levels"].duplicate(true)
	run._feature_definitions[&"levels"].purchase_parent="maps"
	check(FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers).has("error"),"cycle rejected")
	run=fresh().run
	var chain:=run.get_feature_acquisition_quote(&"branching_dialogue")
	var ids:Array=[]
	for row:Dictionary in chain.steps: ids.append(row.id)
	check(ids.has(&"simple_story") and ids.has(&"dialogue") and ids.has(&"save_files") and ids.has(&"branching_nodes") and ids.count(&"simple_story")==1,"full downstream AND chain")
	run._feature_offers[&"branching_dialogue"]=run._feature_offers[&"branching_dialogue"].duplicate(true)
	run._feature_offers[&"branching_dialogue"].purchase_parents=["dialogue","character_backstories"]
	chain=run.get_feature_acquisition_quote(&"branching_dialogue")
	ids.clear()
	for row:Dictionary in chain.steps:ids.append(row.id)
	check(ids.count(&"simple_story")==1 and ids.has(&"dialogue") and ids.has(&"character_backstories"),"shared ancestor counted once across AND arms")
	var path:=OS.get_environment("PN_PRE_BRANCH_SAVES")
	var cold_records:Array=[]
	if not path.is_empty():
		var prior:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		var codec:=StudioCheckpoint.new()
		for key:String in prior:
			var restored:=codec.hydrate(prior[key])
			check(restored!=null,"real prior checkpoint restores " + key + ": " + codec.error)
			if restored==null: continue
			var expected:Dictionary=prior[key].duplicate(true);expected.content_revision=codec.revision()
			check(codec.capture(restored)==expected,"only rules marker changes " + key)
			if key=="queued":
				check(not restored.owns_feature(&"simple_story") and restored.research_feature(restored.get_feature_research_quote(&"dialogue")) and restored.owns_feature(&"dialogue"),"grandfather admitted queue without retroactive parent")
			var session:=from_payload(codec.capture(restored))
			check(session!=null,"fresh session from migrated Studio")
			if session!=null:
				var tape:=Replay.begin(session)
				var initial:=codec.capture(restored)
				var result:=Replay.record(session,tape,session.command(&"begin_development",{"name":"Migrated first game","genre":str(restored.get_studio_specialty()),"theme":"fantasy"}))
				check(result.ok,"migrated legal project start")
				check(Replay.replay(from_payload(initial),tape).ok,"exact migrated-state command replay")
				if key in ["strategy","queued"] and not OS.get_environment("PN_CARD_FRAME_OUTPUT").is_empty():
					var tape_path:=OS.get_environment("PN_CARD_FRAME_OUTPUT")+"."+key+".tape.json"
					check(Replay.save_tape(tape_path,tape),"save representative replay")
					cold_records.append({"initial":initial,"tape":tape_path})
	if not OS.get_environment("PN_CARD_FRAME_OUTPUT").is_empty():
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(cold_records,"\t"))
	print("PRIMITIVE_BRANCHES checks=%d failures=%d" % [checks,failures])
	quit(failures)
