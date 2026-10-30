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
	for child: StringName in [&"dialogue", &"character_backstories", &"maps", &"exploration"]:
		var parent: StringName = FeatureStoreCatalog.PRIMITIVE_PARENTS[child]
		for initial in [true,false]:
			var session := fresh()
			var run: RunState = session.run
			# Controlled absence fixture, separate from unmodified specialty checks below.
			run._owned_features.erase(child);run._owned_features.erase(parent)
			if not initial: run.finalize_starter_selection()
			var before := state(run)
			var q := run.get_primitive_reserve_offer(child)
			check(not q.unlocked and not q.can_purchase and q.missing_parents == [parent], "missing parent quote " + str(child))
			check(not run.purchase_starter_feature(child) and not run.purchase_primitive_reserve_feature(child) and state(run)==before,"both absent-parent mutations atomic")
			var path := run.get_feature_acquisition_quote(child)
			check(path.steps.size()==2 and path.steps[0].id==parent and path.steps[1].id==child and path.cycles==(0 if initial else 2),"ordered chain and exact action count")
			check(path.price_cents==run.get_primitive_reserve_offer(parent).price_cents+q.price_cents,"full parent plus child acquisition price")
			if initial:
				check(run.purchase_starter_feature(parent),"initial parent buy")
			else:
				check(run.admit_feature_research(run.get_feature_research_quote(parent)),"queue parent")
				before=state(run)
				check(not run.get_feature_research_quote(child).can_admit and not run.purchase_primitive_reserve_feature(child) and state(run)==before,"queued parent is not ownership; atomic child rejection")
				check(run.research_feature(run.get_feature_research_quote(parent)),"finish parent")
			q=run.get_primitive_reserve_offer(child)
			check(q.unlocked and q.can_purchase,"owned parent unlock")
			var cash := run.get_cash_cents();var cycle := run.get_completed_run_cycles()
			if initial: check(run.purchase_starter_feature(child),"zero-cycle child purchase")
			else:
				check(run.admit_feature_research(run.get_feature_research_quote(child)),"admit child")
				check(not run.owns_feature(child),"admission not ownership")
				check(run.research_feature(run.get_feature_research_quote(child)),"complete child")
			var rent := 0 if initial else StudioFinanceLedger.MONTHLY_RENT_CENTS
			check(run.owns_feature(child) and run.get_cash_cents()==cash-q.price_cents-rent and run.get_completed_run_cycles()==cycle+(0 if initial else 1),"exact cents, second-cycle rent and timing unchanged")
	for genre: StringName in StudioSpecialties.RULES:
		var run: RunState = fresh(genre).run
		var preview := StudioSpecialties.preview(genre)
		check(run.get_owned_feature_ids()==preview.ids,"fixed specialty roster " + str(genre))
		for child: StringName in FeatureStoreCatalog.PRIMITIVE_PARENTS:
			if not run.owns_feature(child): continue
			check(run.get_feature_acquisition_quote(child).price_cents==0,"owned/granted child has no retroactive cost")
			check(run._primitive_contract_eligible_ids().has(child),"grant still in Primitive Contract supply")
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
