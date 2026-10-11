extends SceneTree
const Planner := preload("res://scripts/simulation/g2_legal_mix.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures := 0
var report := {}
var out := ""

func expect(value: bool,label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: "+label)

func _initialize() -> void:
	await process_frame
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=",true,1)
		if pair.size() == 2: args[pair[0]] = pair[1]
	out = str(args.get("output",""))
	if out.is_empty(): quit(2); return
	if args.get("mode","unit") == "unit": unit()
	elif args.get("mode") == "catalog_parity": catalog_parity(args)
	else: study(args)
	report.checks = checks
	report.failures = failures
	report.ok = failures == 0
	report.source_identity = Replay.source_identity()
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("G2 private candidate: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func unit() -> void:
	var key := Planner.gap_key([20,13,40,0],[40,26,40,26])
	expect(key.sum == key.denominator*2,"Exact proportional gaps sum without rounding")
	expect(Planner.gap_key([100,100,100,100],[40,26,40,26]).sum == 0,"No surplus credit")
	expect(Planner.gap_key([0,0,0,0],[0,26,40,26]).is_empty(),"Zero target rejected")
	expect(Planner.gap_key([0,0,0,0],[999999937,999999929,999999893,999999883]).is_empty(),"Overflow-risk exact denominator rejected")
	var before := Planner.gap_key([0,5,5,5],[10,10,10,10])
	expect(Planner.target_order(before) == [0,1,2,3],"Positive targets descending then G/S/T/D")
	expect(Planner.relevant(before,Planner.gap_key([2,4,5,5],[10,10,10,10]),0),"Better total permits other-gap tradeoff")
	expect(not Planner.relevant(before,Planner.gap_key([1,4,5,5],[10,10,10,10]),0),"Equal-total tradeoff rejected")
	expect(not Planner.relevant(before,Planner.gap_key([0,6,5,5],[10,10,10,10]),0),"Unchanged target rejected")
	var a := Planner.gap_key([5,5,0,0],[10,10,10,10])
	var b := Planner.gap_key([10,0,0,0],[10,10,10,10])
	expect(Planner.better(b,a,0),"Targeted tie favors target")
	var balanced := Planner.gap_key([2,2,3,3],[10,10,10,10])
	expect(Planner.better(balanced,b),"Baseline overall tie minimizes largest gap")
	var feature := {"mask":1,"core":[10,0,0,0],"cost":10,"ids":["fixture"],"phase":"design"}
	var pass_hand := {"mask":0,"core":[0,1,0,0],"cost":0,"ids":["pass"],"phase":"design"}
	var groups := {"design":[feature,pass_hand],"alpha":[pass_hand]}
	var solved := Planner.search(groups,[10,10,10,10],[2,1],10,100,100)
	expect(solved.complete and solved.baseline.core == [10,2,0,0],"Finite feature can appear once; renewable hand repeats")
	expect(solved.baseline.cost == 10 and solved.legal_terminal_states == 1,"Cash exact and equal paths collapse")
	var denied := Planner.search(groups,[10,10,10,10],[2,1],9,100,100)
	expect(denied.status == "no_legal_mix" and denied.baseline.is_empty(),"Insufficient finite work budget is no legal exit")
	var bounded := Planner.search(groups,[10,10,10,10],[2,1],10,1,100)
	expect(not bounded.complete and bounded.baseline.is_empty() and bounded.targeted.is_empty(),"Budget miss suppresses partial vector and rank")
	for budget in [0,9,10,15,20]:
		for hand_count in [1,2,3]:
			var optimized := Planner.search(groups,[10,10,10,10],[hand_count,hand_count],budget,5000,5000)
			var reference := Planner.reference_search(groups,[10,10,10,10],[hand_count,hand_count],budget,5000,5000)
			expect(optimized.status == reference.status and optimized.baseline.get("gap",{}) == reference.baseline.get("gap",{}),"Optimized frontier agrees with unpruned small exhaustive fixture")
	var mixed := {"design":[{"mask":1,"core":[4,0,0,1],"cost":5},{"mask":2,"core":[0,1,3,2],"cost":4},{"mask":0,"core":[0,2,1,0],"cost":0}],"alpha":[{"mask":4,"core":[1,0,2,4],"cost":6},{"mask":8,"core":[3,3,0,0],"cost":8},{"mask":0,"core":[2,0,1,0],"cost":0}]}
	for budget in [0,5,10,15,20]:
		for count in [1,2,3]:
			var optimized := Planner.search(mixed,[10,13,11,9],[count,count],budget,50000,50000)
			var reference := Planner.reference_search(mixed,[10,13,11,9],[count,count],budget,50000,50000)
			expect(optimized.complete and reference.complete and optimized.status == reference.status and optimized.baseline.get("gap",{}) == reference.baseline.get("gap",{}),"Nontrivial finite-mask cost/work dominance baseline equals exhaustive reference")
			for target in range(4): expect(optimized.targeted[target].get("gap",{}) == reference.targeted[target].get("gap",{}),"Every targeted vector objective equals exhaustive reference")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var fresh: RefCounted = Factory.create({"recipe":{"schema_version":1,"studio_id":"g2-guard","studio_name":"G2 Guard","specialty":"action","traits":[],"seed":"4417"}},catalog)
	expect(fresh != null and not Planner.hand_catalog(fresh.run,catalog,fresh.run.get_owned_feature_ids()).ok,"Scripted first-game boundary rejects before favorable dealing")
	report = {"kind":"unit","scope":"Synthetic exact-math/DP negative controls; live weighted production covered by study witnesses"}

func catalog_parity(args: Dictionary) -> void:
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var checkpoint: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(args.get("checkpoint",""))))
	var session: RefCounted = Factory.create({"checkpoint":checkpoint},catalog) if checkpoint is Dictionary else null
	var previous: GDScript = load(str(args.get("reference","")))
	expect(session != null and previous != null,"Current legal Studio and retained v2 reference load")
	if session == null or previous == null: return
	var owned: Array = session.run.get_owned_feature_ids()
	var pools: Array = [owned]
	for entry in FeatureStoreCatalog.entries(): pools.append(owned+[StringName(entry.id)])
	var rows: Array = []
	for pool: Array in pools:
		var before: Dictionary = previous.hand_catalog(session.run,catalog,pool)
		var after := Planner.hand_catalog(session.run,catalog,pool)
		expect(before.ok and after.ok and Replay.digest(before) == Replay.digest(after),"v2/v3 complete hand catalogs identical within tested pool bounds")
		rows.append({"pool":pool,"v2":Replay.digest(before),"v3":Replay.digest(after)})
	var tiny := Planner.hand_catalog(session.run,catalog,owned,1)
	expect(not tiny.ok and tiny.get("tuples") == 1 and not tiny.has("groups"),"Preprocessing cap returns no partial hand catalog")
	report = {"kind":"catalog_parity","rows":rows,"reference_path":args.reference,"reference_sha256":FileAccess.get_sha256(args.reference),"scope":"Baseline plus11 hypothetical catalog inputs; catalog equality only, no acquisition or ownership claim"}

func study(args: Dictionary) -> void:
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var checkpoint: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(args.get("checkpoint",""))))
	var session: RefCounted = Factory.create({"checkpoint":checkpoint},catalog) if checkpoint is Dictionary else null
	expect(session != null,"Source-compatible real Studio checkpoint")
	if session == null: return
	var start_hash := Replay.digest(Replay.state(session))
	var start_rng := Replay.digest(session.run.random_streams.snapshot())
	var owned: Array = session.run.get_owned_feature_ids()
	var candidate := StringName(str(args.get("candidate","")))
	var acquisition := {}
	if not candidate.is_empty():
		var quote: Dictionary = session.run.get_feature_research_quote(candidate)
		var due := Planner.known_cash(session.run,1)
		if not quote.get("can_admit",false) or not due.get("ok",false) or int(quote.get("down_cents",0))+int(quote.get("remaining_cents",0))+int(due.get("known_dues_cents",0)) > session.run.get_cash_cents():
			report = {"kind":"store","candidate":str(candidate),"status":"not_admissible_in_declared_screen","quote":quote,"dues":due,"initial_state":start_hash,"initial_rng":start_rng}
			return
		var tape := Replay.begin(session)
		var admitted := Replay.record(session,tape,session.command(&"admit_research",{"quote":quote}))
		expect(admitted.ok,"Candidate admitted through real current quote")
		if not admitted.ok: return
		expect(not session.run.owns_feature(candidate),"Admission does not grant ownership")
		var paid := Replay.record(session,tape,session.command(&"research",{"quote":session.run.get_feature_research_quote(candidate)}))
		expect(paid.ok and session.run.owns_feature(candidate),"Candidate ownership only after actual research completes")
		if not paid.ok: return
		Replay.save_tape(out+".acquisition.tape.json",tape)
		Replay.save_tape(out+".acquisition.initial.json",{"checkpoint":checkpoint})
		acquisition = {"tape":out+".acquisition.tape.json","initial":out+".acquisition.initial.json","commands":tape.steps.size(),"quote":quote,"post_checkpoint":session.export_checkpoint()}
	var anchor_hash := Replay.digest(Replay.state(session))
	var anchor_rng := Replay.digest(session.run.random_streams.snapshot())
	var cash := Planner.known_cash(session.run,7)
	expect(cash.get("ok",false),"Declared known-dues allowance available")
	if not cash.get("ok",false): return
	var allowance := mini(100000,int(cash.spendable_after_dues))
	var targets: Array = PrimitiveReviewCalculator.GENRE_TARGETS[session.run.get_studio_specialty()]
	var h := int(args.get("hands",1))
	var baseline_catalog := Planner.hand_catalog(session.run,catalog,owned)
	expect(baseline_catalog.ok,"Shared production enumerates owned finite sources")
	if not baseline_catalog.ok: return
	var baseline := Planner.search(baseline_catalog.groups,targets,[h,h],allowance,500000,100000)
	var witness := {}
	if baseline.complete and not baseline.baseline.is_empty():
		witness = Planner.validate_witness(catalog,owned,baseline.baseline.witness)
		expect(witness.ok and witness.core == baseline.baseline.core,"Full selected baseline vector has controlled legal deal/production witness")
	var after := {}
	var candidate_witness := {}
	var target := -1
	var qualifies := false
	if not candidate.is_empty() and baseline.complete and not baseline.baseline.is_empty():
		var expanded: Array = session.run.get_owned_feature_ids()
		var after_catalog := Planner.hand_catalog(session.run,catalog,expanded)
		expect(after_catalog.ok,"Legally owned candidate enters exact catalog")
		if not after_catalog.ok: return
		after = Planner.search(after_catalog.groups,targets,[h,h],allowance,500000,100000)
		if after.complete:
			for index in Planner.target_order(baseline.baseline.gap):
				if not after.targeted[index].is_empty() and Planner.relevant(baseline.baseline.gap,after.targeted[index].gap,index):
					target = index
					qualifies = true
					candidate_witness = Planner.validate_witness(catalog,expanded,after.targeted[index].witness)
					expect(candidate_witness.ok and candidate_witness.core == after.targeted[index].core,"Candidate relevance uses witnessed joint vector")
					break
	expect(Replay.digest(Replay.state(session)) == anchor_hash and Replay.digest(session.run.random_streams.snapshot()) == anchor_rng,"Both ownership envelopes use one unchanged anchor state and RNG")
	var store: Array = []
	for entry: Dictionary in FeatureStoreCatalog.entries():
		var offer: Dictionary = session.run.get_feature_store_offer(StringName(entry.id))
		store.append({"id":entry.id,"parent":entry.purchase_parent,"owned":offer.get("owned",false),"unlocked":offer.get("unlocked",false),"quote":session.run.get_feature_research_quote(StringName(entry.id)),"era":"current_live_tier"})
	report = {"kind":"planner","hands":[h,h],"status":"defer" if not baseline.complete or (not after.is_empty() and not after.complete) else "complete","cash_allocation":cash,"allowance_cents":allowance,"targets":targets,"owned_before":owned,"candidate":str(candidate),"anchor_state":anchor_hash,"anchor_rng":anchor_rng,"initial_state":start_hash,"initial_rng":start_rng,"acquisition":acquisition,"baseline":baseline,"after":after,"baseline_witness":witness,"candidate_witness":candidate_witness,"candidate_qualifies":qualifies,"target":target,"store_screen":store,"comparison":"Same post-research anchor/cash/RNG, remove only newly acquired candidate from baseline planning pool; legal ownership proven by real commands. Not pre/post full-state equality."}
