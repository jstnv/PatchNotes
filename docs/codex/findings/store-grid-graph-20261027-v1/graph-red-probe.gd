extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func fresh(id: String) -> RunState:
	var session: RefCounted = Factory.create_fresh_session({"schema_version":1,"studio_id":id,"studio_name":"Grid graph","specialty":"action","traits":[],"seed":"771"},root.get_node("CardDatabase").get_development_catalog())
	if session == null: return null
	var run: RunState = session.run
	run.finalize_starter_selection()
	return run

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()==2 and args[0]=="--capture":
		var run := fresh("grid-predecessor")
		expect(run!=null,"Normal unfunded factory route initializes")
		if run==null: quit(1); return
		for id: StringName in [&"save_files",&"split_screen",&"colored_text"]:
			expect(run.admit_feature_research(run.get_feature_research_quote(id)),"Pre-change legal queue "+str(id))
		var adapter := StudioCheckpoint.new()
		var pending := adapter.capture(run)
		expect(not pending.is_empty() and adapter.validate(pending).is_empty(),"Old pending queue is a valid Studio checkpoint")
		for id: StringName in [&"save_files",&"split_screen",&"colored_text"]:
			expect(run.research_feature(run.get_feature_research_quote(id)),"Pre-change legal completion "+str(id))
		var owned := adapter.capture(run)
		expect(not owned.is_empty() and adapter.validate(owned).is_empty(),"Old completed purchases form a valid Studio checkpoint")
		FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"source_identity":Replay.source_identity(),"pending":pending,"owned":owned},"\t"))
		quit(failures); return
	var run := fresh("grid-new")
	var graph := FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	expect(not graph.has("error"),"Entire catalog is acyclic and well formed")
	expect(graph.parents[&"save_files"]==[&"menu_system"],"Save Files follows Menu System")
	expect(graph.parents[&"split_screen"]==[&"branching_nodes",&"scrolling"],"Primitive Split Screen has ordered Branching Nodes AND Scrolling")
	expect(graph.parents[&"colored_text"]==[&"text",&"4_color_palette"],"Colored Text requires Text AND 4-Color Palette")
	expect(graph.parents[&"branching_nodes"]==[&"save_files"],"Existing Save Files to Branching Nodes edge retained")
	expect(not run._feature_offers.has(&"split_screen") and run._feature_offers.has(&"save_files"),"Primitive versus later Store catalog identity retained")
	var before := Replay.digest(StudioCheckpoint.new().capture(run))
	expect(not run.admit_feature_research(run.get_feature_research_quote(&"save_files")),"Missing Menu System blocks new Save Files admission")
	expect(not run.admit_feature_research(run.get_feature_research_quote(&"split_screen")),"Missing two parents blocks new Split Screen admission")
	expect(before==Replay.digest(StudioCheckpoint.new().capture(run)),"Rejected acquisitions preserve all saved fields/RNG")
	# Controlled ownership permutations prove every AND arm; not campaign evidence.
	for id: StringName in [&"save_files",&"split_screen",&"colored_text"]:
		var parents: Array = graph.parents[id]
		for parent: StringName in parents: run._owned_features.erase(parent)
		for index in range(parents.size()+1):
			var quote := run.get_feature_research_quote(id)
			expect(quote.unlocked==(index==parents.size()),"Exact AND eligibility "+str(id)+" / "+str(index))
			if index<parents.size(): run._owned_features[parents[index]]=true
	if args.size()==1:
		var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
		for kind: String in ["pending","owned"]:
			var codec := StudioCheckpoint.new()
			var restored := codec.hydrate(old[kind])
			expect(restored!=null,"Exact pre-grid "+kind+" checkpoint restores: "+codec.error)
			if restored==null: continue
			var saved := codec.capture(restored)
			var expected: Dictionary=old[kind].duplicate(true)
			expected.content_revision=codec.revision()
			expect(saved==expected,"Every historical "+kind+" field survives apart from revision")
			if kind=="pending":
				for id: StringName in [&"save_files",&"split_screen",&"colored_text"]:
					expect(restored.research_feature(restored.get_feature_research_quote(id)),"Grandfathered FIFO completes despite new absent parent: "+str(id))
					expect(restored.owns_feature(id),"Paid queue grants only its purchased card "+str(id))
				expect(not restored.owns_feature(&"menu_system") and not restored.owns_feature(&"branching_nodes") and not restored.owns_feature(&"scrolling"),"No free ancestor grants during migration/completion")
				expect(codec.validate(codec.capture(restored)).is_empty(),"Completed migrated queue revalidates under current rules")
		var corrupted: Dictionary=old.pending.duplicate(true)
		corrupted.run.cash_cents="1"
		expect(StudioCheckpoint.new().hydrate(corrupted)==null,"Corrupt prior cash/finance pair still rejects")
		corrupted=old.pending.duplicate(true)
		corrupted.content_revision="unknown-grid-catalog"
		expect(StudioCheckpoint.new().hydrate(corrupted)==null,"Unknown catalog revision still rejects")
	print("Store grid graph: %d checks, %d failures"%[checks,failures])
	quit(failures)
