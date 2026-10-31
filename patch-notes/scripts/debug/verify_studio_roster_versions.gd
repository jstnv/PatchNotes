extends "res://scripts/debug/verify_primitive_branches.gd"
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")

func historical_v2(genre: StringName) -> RunState:
	# Explicit constructed historical fixture, not today's once-only grant.
	# Actual preceding-source worlds are checked separately with cold files.
	var run: RunState=fresh(genre).run
	run._owned_features.clear()
	for id in StudioSpecialties.preview(genre,2).ids:run._owned_features[id]=true
	run._founding_roster_version=2
	return run

func core(ids: Array) -> Dictionary:
	var result := {"graphics":0,"sound":0,"technology":0,"design":0}
	for card: Dictionary in FeatureStoreCatalog.starting_features():
		if not str(card.id) in ids: continue
		for prefix in ["primary", "secondary"]:
			var stat: String = card.get(prefix+"_stat", "")
			if result.has(stat): result[stat] += int(card.get(prefix+"_value",0))
	return result

func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var codec := StudioCheckpoint.new()
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/studio_specialties_v1.json"))
	var current: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/studio_specialties_v2.json"))
	var roots: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/studio_specialties_v3.json"))
	var exceptions := {}
	for genre: String in old:
		var v1 := StudioSpecialties.preview(StringName(genre),1)
		var v2 := StudioSpecialties.preview(StringName(genre),2)
		var ids1: Array = v1.ids.map(func(id): return str(id)); ids1.sort()
		var ids2: Array = v2.ids.map(func(id): return str(id)); ids2.sort()
		check(ids1 == old[genre].ids and ids2 == current[genre].ids,"independent exact roster fixtures " + genre)
		var v3 := StudioSpecialties.preview(StringName(genre),3)
		var ids3: Array=v3.ids.map(func(id):return str(id));ids3.sort()
		check(ids3==roots[genre].ids and v3.scope==roots[genre].scope and v3.count==roots[genre].count,"historical root-first v3 preview stays exact "+genre)
		check(v1.count == v2.count and v1.scope == v2.scope and v2.count == current[genre].count and v2.scope == current[genre].scope,"unchanged count and Scope " + genre)
		var expected: Array = v1.ids.duplicate()
		var c1 := core(ids1); var c2 := core(ids2)
		if StringName(genre) in StudioSpecialties.LEVELS_SWAP:
			expected[expected.find(&"maps")] = &"levels"
			c1.technology -= 2; c1.design += 2
		check(v2.ids == expected and c1 == c2,"exact ordered swap and Core delta only " + genre)
		var run := historical_v2(StringName(genre))
		check(run.get_owned_feature_ids() == v2.ids and run.get_founding_roster_version() == 2,"explicit historical v2 fixture " + genre)
		for child: StringName in [&"dialogue", &"character_backstories", &"maps", &"exploration"]:
			check(not run.owns_feature(child) or run.owns_feature(FeatureStoreCatalog.PRIMITIVE_PARENTS[child]),"original four parent gates closed " + genre + "/" + str(child))
		exceptions[genre] = []
		for child: StringName in FeatureStoreCatalog.PRIMITIVE_PARENTS:
			if run.owns_feature(child) and not run.owns_feature(FeatureStoreCatalog.PRIMITIVE_PARENTS[child]):
				exceptions[genre].append(str(child))
		var payload := codec.capture(run)
		check(not payload.is_empty() and payload.run.founding_roster_version == "2","explicit persisted v2 " + genre)
		var restored := codec.hydrate(payload)
		check(restored != null and restored.get_founding_roster_version() == 2 and codec.capture(restored) == payload,"v2 exact checkpoint round trip " + genre)
		for invalid in ["0","6","2.5",2,null]:
			var malformed := payload.duplicate(true); malformed.run.founding_roster_version = invalid
			check(codec.hydrate(malformed) == null,"invalid version rejects " + str(invalid))
		var before := state(run)
		check(not run.set_studio_name("Repeat",&"action") and state(run) == before,"no repeat grant")
	for genre: StringName in StudioSpecialties.LEVELS_SWAP:
		for resourceful: bool in [false,true]:
			for initial: bool in [true,false]:
				var session := Factory.create_fresh_session({"schema_version":1,"studio_id":"roster","studio_name":"Roster","specialty":str(genre),"traits":["resourceful"] if resourceful else [],"seed":"4417"},catalog)
				# This block characterizes historical v2 Maps quotes/transactions.
				var run: RunState = session.run
				run._owned_features.clear()
				for id in StudioSpecialties.preview(genre,2).ids:run._owned_features[id]=true
				run._founding_roster_version=2
				var project := PrimitivePredevelopment.prepare_project("Frozen",genre,&"fantasy",run)
				if not initial: run.finalize_starter_selection()
				var quote := run.get_primitive_reserve_offer(&"maps")
				var cost := 35000 if resourceful else 45000
				check(run.owns_feature(&"levels") and not run.owns_feature(&"maps") and quote.unlocked and quote.price_cents == (cost if initial else 45000),"optional Maps exact quote")
				var cash := run.get_cash_cents(); var cycle := run.get_completed_run_cycles()
				if initial:
					check(run.purchase_starter_feature(&"maps"),"initial Maps purchase")
				else:
					check(run.admit_feature_research(run.get_feature_research_quote(&"maps")),"Maps paid admission")
					check(not run.owns_feature(&"maps") and cash-run.get_cash_cents() == 22500,"queue deposit and no ownership")
					var saved := codec.capture(run); var resumed := codec.hydrate(saved)
					check(resumed != null and codec.capture(resumed) == saved,"v2 paid queue checkpoint exact")
					check(run.research_feature(run.get_feature_research_quote(&"maps")),"Maps paid completion")
				check(run.owns_feature(&"maps") and run.get_cash_cents() == cash-cost and run.get_completed_run_cycles() == cycle+(0 if initial else 1),"exact discounted cents and cycles")
				check(not project.get_feature_supply_ids().has(&"maps") and PrimitivePredevelopment.prepare_project("Next",genre,&"fantasy",run).get_feature_supply_ids().has(&"maps"),"future supply only")
				var before := state(run)
				check(not run.purchase_starter_feature(&"maps") and not run.purchase_primitive_reserve_feature(&"maps") and state(run)==before,"duplicate purchase atomic")
		var poor: RunState = fresh(genre).run
		poor.spend_cash_cents(poor.get_cash_cents()-44999)
		var before := state(poor)
		check(not poor.purchase_starter_feature(&"maps") and state(poor)==before,"one-cent-short Maps rejects atomically")
	var prior_path := OS.get_environment("PN_ROSTER_PRIOR")
	if not prior_path.is_empty():
		var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(prior_path))
		for key: String in prior.saves:
			var run := codec.hydrate(prior.saves[key])
			check(run != null,"actual prior source restores " + key + ": " + codec.error)
			if run == null: continue
			var expected: Dictionary = prior.saves[key].duplicate(true); expected.content_revision = codec.revision()
			check(run.get_founding_roster_version()==1 and codec.capture(run)==expected,"all old owned IDs, queue, traits, finances and RNG preserved " + key)
			var forged: Dictionary = prior.saves[key].duplicate(true); forged.run.founding_roster_version="2"
			check(codec.hydrate(forged)==null,"historical revision cannot claim future founding metadata")
	var session := fresh(&"strategy")
	session.run.finalize_starter_selection()
	check(session.run.admit_feature_research(session.run.get_feature_research_quote(&"maps")),"new world keeps queued Maps")
	var world := Trial.create_legacy_world(session.run,catalog)
	check(session.run.complete_productive_action(Callable(),0,0),"world player cycle")
	world.advance_committed_player_cycle(Trial.policies(world),12)
	var player := codec.capture(session.run)
	var world_saved := WorldCodec.new().capture(world)
	check(not player.is_empty() and not world_saved.is_empty(),"current active-world save")
	if not OS.get_environment("PN_CARD_FRAME_OUTPUT").is_empty():
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"player":player,"world":world_saved,"newer_gate_grant_exceptions":exceptions,"checks":checks,"failures":failures},"\t"))
	print("STUDIO_ROSTER_VERSIONS checks=%d failures=%d"%[checks,failures])
	quit(failures)
