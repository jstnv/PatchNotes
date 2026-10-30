extends "res://scripts/debug/verify_primitive_branches.gd"

const CHANGED := {
	&"local_leaderboards": [&"high_scores"], &"enemies": [&"lives_system"],
	&"general_combat": [&"enemies"], &"difficulty_levels": [&"turn_based_combat", &"scripted_ai"],
}

func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var codec := StudioCheckpoint.new()
	for child: StringName in CHANGED:
		var required: Array = CHANGED[child]
		for mask in range(1 << required.size()):
			var run: RunState = fresh().run
			run.add_cash_cents(2000000, &"other_income", &"tree-fixture")
			run.finalize_starter_selection()
			run._owned_features.erase(child)
			for index in required.size():
				if mask & (1 << index): run._owned_features[required[index]] = true
				else: run._owned_features.erase(required[index])
			var graph := FeatureStoreCatalog.graph(run._feature_definitions, run._feature_offers)
			check(graph.parents[child] == required, "Exact approved parents " + str(child))
			var unlocked := mask == (1 << required.size()) - 1
			var quote := run.get_feature_research_quote(child)
			check(quote.unlocked == unlocked and quote.can_admit == unlocked, "All-parent truth table " + str(child) + ":" + str(mask))
			var before := state(run)
			if not unlocked:
				check(not run.admit_feature_research(quote) and state(run) == before, "Missing-parent rejection preserves full run/RNG")
				continue
			check(run.admit_feature_research(quote) and not run.owns_feature(child), "Deposit admits without ownership")
			var restored := codec.hydrate(codec.capture(run))
			check(restored != null and codec.capture(restored) == codec.capture(run), "Exact new queue round trip")
			check(run.research_feature(run.get_feature_research_quote(child)) and run.owns_feature(child), "Normal research completes child")
	# The acquisition DAG must deduplicate shared Enemies/Lives ancestry.
	var run: RunState = fresh().run
	run._owned_features.clear()
	var acquisition := run.get_feature_acquisition_quote(&"difficulty_levels")
	var ids: Array = acquisition.steps.map(func(row): return row.id)
	check(ids == [&"lives_system", &"enemies", &"general_combat", &"turn_based_combat", &"scripted_ai", &"difficulty_levels"], "Ordered, deduplicated two-parent acquisition path")
	check(not str(acquisition).contains("3 distinct Gameplay"), "No obsolete count-gate text")
	# Real Difficulty credits aggregate across both parents; paid money is frozen.
	run = fresh().run
	run.add_cash_cents(2000000, &"other_income", &"credit-fixture")
	run.finalize_starter_selection()
	run._owned_features.erase(&"difficulty_levels")
	run._owned_features[&"turn_based_combat"] = true
	run._owned_features[&"scripted_ai"] = true
	var q := run.get_feature_research_quote(&"difficulty_levels")
	check(q.base_cents==110000 and q.down_cents==55000 and q.remaining_actions==1,"Difficulty retains exact base, half deposit and one action")
	check(run.admit_feature_research(q),"Difficulty admission with both parents")
	var paid := run.get_feature_research_queue().duplicate(true)
	for parent: StringName in [&"turn_based_combat",&"scripted_ai",&"turn_based_combat",&"scripted_ai",&"scripted_ai",&"scripted_ai"]:
		check(run.record_resolved_feature(ProjectState.new(30),parent,StringName(run._feature_definitions[parent].phase)),"Eligible new project earns parent credit")
	q=run.get_feature_research_quote(&"difficulty_levels")
	check(q.discount_percent==50 and q.due_cents==27500 and run.get_feature_research_queue()==paid,"Combined 50 percent cap affects unpaid installment only")
	var cash := run.get_cash_cents()
	check(run.research_feature(q) and run.get_cash_cents()==cash-27500,"Discounted completion charges exact cents once")
	var source := OS.get_environment("PN_GAMEPLAY_PRIOR_SAVES")
	check(not source.is_empty(), "Pre-change checkpoint evidence supplied")
	if not source.is_empty():
		var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source))
		for child: StringName in CHANGED:
			var owned := codec.hydrate(prior["owned_"+str(child)])
			check(owned!=null and owned.owns_feature(child),"Old owned Feature retained without parent grants")
			var owned_expected: Dictionary = prior["owned_"+str(child)].duplicate(true)
			check(not owned_expected.run.has("publisher_relationships") and not owned_expected.run.has("commission_deals") and not owned_expected.run.has("sidestreet_briefs"),"Pinned owned fixture predates publisher fields")
			owned_expected.run.publisher_relationships = {"version":"1","owner":owned_expected.run.bank_run_id,"events":[]}
			owned_expected.run.commission_deals = []
			owned_expected.run.sidestreet_briefs = []
			for field: String in ["support_deals","support_rights","support_assessments"]:
				check(not owned_expected.run.has(field),"Pinned owned fixture predates "+field)
				owned_expected.run[field] = []
			owned_expected.run.contract_search={"version":"1","owner":owned_expected.run.bank_run_id,"receipts":[],"offers":[],"legacy_offers":[],"intro_offer_id":""}
			check(owned_expected.run.release_metadata.is_empty(),"Pinned owned fixture has no release entitlement")
			owned_expected.run.store_era_receipts={"version":"1","assignments":[]}
			owned_expected.content_revision=codec.revision()
			check(owned!=null and codec.capture(owned)==owned_expected,"Owned checkpoint preserves every field")
			var restored := codec.hydrate(prior[str(child)])
			check(restored != null, "Actual old paid queue restores " + str(child) + ": " + codec.error)
			if restored == null: continue
			var expected: Dictionary = prior[str(child)].duplicate(true)
			check(not expected.run.has("publisher_relationships") and not expected.run.has("commission_deals") and not expected.run.has("sidestreet_briefs"),"Pinned queue fixture predates publisher fields")
			expected.run.publisher_relationships = {"version":"1","owner":expected.run.bank_run_id,"events":[]}
			expected.run.commission_deals = []
			expected.run.sidestreet_briefs = []
			for field: String in ["support_deals","support_rights","support_assessments"]:
				check(not expected.run.has(field),"Pinned queue fixture predates "+field)
				expected.run[field] = []
			expected.run.contract_search={"version":"1","owner":expected.run.bank_run_id,"receipts":[],"offers":[],"legacy_offers":[],"intro_offer_id":""}
			check(expected.run.release_metadata.is_empty(),"Pinned queue fixture has no release entitlement")
			expected.run.store_era_receipts={"version":"1","assignments":[]}
			expected.content_revision = codec.revision()
			check(codec.capture(restored) == expected, "Only revision and empty prospective publisher fields change, all old fields retained")
			check(CHANGED[child].any(func(parent): return not restored.owns_feature(parent)), "Prior queue genuinely lacks a new prerequisite")
			var quote := restored.get_feature_research_quote(child)
			var prior_cash := restored.get_cash_cents()
			var cycle := restored.get_completed_run_cycles()
			check(restored.research_feature(quote) and restored.owns_feature(child) and restored.get_cash_cents() == prior_cash - quote.due_cents and restored.get_completed_run_cycles() == cycle + 1, "Old queue finishes at original unpaid balance, exactly once")
			var before := state(restored)
			check(not restored.research_feature(quote) and state(restored) == before, "Duplicate completion is inert")
	print("GAMEPLAY_TREE checks=%d failures=%d" % [checks, failures])
	quit(failures)
