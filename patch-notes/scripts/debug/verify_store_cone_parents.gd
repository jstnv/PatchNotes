extends "res://scripts/debug/verify_primitive_branches.gd"

const CHANGES := {
	&"multiple_endings": &"branching_dialogue", &"secrets": &"exploration",
	&"8_bit_music": &"music", &"8_bit_sound": &"sound_effects",
	&"scrolling": &"text", &"sprites": &"4_color_palette",
}

func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var codec := StudioCheckpoint.new()
	for child: StringName in CHANGES:
		var parent: StringName = CHANGES[child]
		for initial in [true,false]:
			var run: RunState = fresh().run
			# Controlled absent ownership / cash fixture to exercise the full chain.
			run.add_cash_cents(2000000, &"other_income", &"cone-fixture")
			var graph := FeatureStoreCatalog.graph(run._feature_definitions, run._feature_offers)
			check(graph.parents[child] == [parent], "exact approved parent " + str(child))
			var chain: Array = FeatureStoreCatalog.ordered_ancestors([child], graph.parents).order
			for id: StringName in chain: run._owned_features.erase(id)
			if not initial: run.finalize_starter_selection()
			var before := state(run)
			check(not run.get_primitive_reserve_offer(child).unlocked, "missing parent quote")
			check(not run.purchase_starter_feature(child) and not run.admit_feature_research(run.get_feature_research_quote(child)) and state(run) == before, "missing-parent rejection is atomic")
			var acquisition := run.get_feature_acquisition_quote(child)
			var ids: Array = []
			for row: Dictionary in acquisition.steps: ids.append(row.id)
			check(ids == chain, "exact ordered transitive acquisition chain " + str(child))
			if initial and child == &"multiple_endings":
				check(not run.purchase_starter_feature(parent), "later Branching Dialogue is not an initial Primitive buy")
				run.finalize_starter_selection()
			for id: StringName in chain:
				if run.needs_starter_selection():
					var cycle := run.get_completed_run_cycles()
					check(run.purchase_starter_feature(id) and run.get_completed_run_cycles() == cycle, "zero-cycle Primitive purchase " + str(id))
				else:
					var quote := run.get_feature_research_quote(id)
					check(quote.can_admit and run.admit_feature_research(quote), "legal ordered admission " + str(id))
					check(not run.owns_feature(id), "deposit does not grant ownership")
					if id == parent:
						before = state(run)
						check(not run.get_feature_research_quote(child).can_admit and not run.admit_feature_research(run.get_feature_research_quote(child)) and state(run) == before, "queued parent is not ownership")
					var restored := codec.hydrate(codec.capture(run))
					check(restored != null and codec.capture(restored) == codec.capture(run), "exact current queue hydration")
					check(run.research_feature(run.get_feature_research_quote(id)), "complete one-action research " + str(id))
			check(run.owns_feature(child), "chain ends in real child ownership " + str(child))
	var path := OS.get_environment("PN_CONE_PRIOR_SAVES")
	if not path.is_empty():
		var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for key: String in prior:
			var restored := codec.hydrate(prior[key])
			check(restored != null, "actual pre-change checkpoint restores " + key + ": " + codec.error)
			if restored == null: continue
			var expected: Dictionary = prior[key].duplicate(true)
			expected.content_revision = codec.revision()
			check(codec.capture(restored) == expected, "only content marker changes " + key)
			if key.begins_with("roster_"):
				check(restored.get_owned_feature_ids() == fresh(StringName(key.trim_prefix("roster_"))).run.get_owned_feature_ids(), "unchanged fresh/legacy specialty roster " + key)
			else:
				var child := StringName(key)
				check(not restored.owns_feature(CHANGES[child]), "old paid queue truly lacks new parent")
				var q := restored.get_feature_research_quote(child)
				var cash := restored.get_cash_cents()
				var cycles := restored.get_completed_run_cycles()
				check(restored.research_feature(q) and restored.owns_feature(child) and restored.get_cash_cents() == cash - q.due_cents and restored.get_completed_run_cycles() == cycles + 1, "grandfather queue, original unpaid balance and exactly one productive cycle " + key)
				var before := state(restored)
				check(not restored.research_feature(q) and state(restored) == before, "duplicate completion rejects")
	print("STORE_CONE_PARENTS checks=%d failures=%d" % [checks,failures])
	quit(failures)
