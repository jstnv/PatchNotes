extends SceneTree

func _initialize() -> void:
	var results: Array = []
	for script in [preload("res://scripts/phases/design_phase.gd"), preload("res://scripts/phases/alpha_phase.gd")]:
		var phase = script.new()
		var project := ProjectState.new(30)
		phase.set("_project_state", project)
		for values in [[0,0,0,0], [4,4,4,4], [17,20,20,23], [16,20,20,24], [5,5,5,6], [5,5,6,6], [5,6,6,6], [1,3,5,7], [8], [8,3]]:
			for same_primary in [false, true]:
				for feature in [false, true]:
					var cards: Array[CardData] = []
					for i in range(4):
						var card := CardData.new()
						card.primary_stat = [&"graphics", &"sound", &"technology", &"design"][0 if same_primary else i]
						card.card_type = &"feature" if feature and i == 0 else &"pass"
						cards.append(card)
					var scores: Dictionary[ProjectState.CoreScore, int] = {}
					for i in range(values.size()):
						scores[i] = values[i]
					var before := scores.duplicate()
					var result: Dictionary = phase.call("_calculate_final_action_production", {&"cards": cards, &"score_additions": scores, &"has_feature": feature})
					assert(scores == before, "Calculation mutated input")
					for i in range(4):
						assert(project.get_core_score(i) == 0, "Calculation mutated project")
					results.append(result)
		phase.free()
	var expected = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/debug/fixtures/production_hand_pre_extraction.json"))
	# Preserve the frozen extraction fixture; only its explicitly superseded
	# Balanced reward changes. Trigger flags and every other field stay exact.
	for row in expected:
		if row.balanced_production:
			var total := 0
			for value in row.score_additions.values(): total += int(value)
			@warning_ignore("integer_division")
			var boosted := total * 5 / 4
			for category in range(4):
				@warning_ignore("integer_division")
				row.score_additions[str(category)] = boosted / 4 + (1 if category < boosted % 4 else 0)
	var output_path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(results, "\t"))
	if JSON.parse_string(JSON.stringify(results)) != JSON.parse_string(JSON.stringify(expected)):
		push_error("FAIL: Production fixture with approved 1.25 Balanced delta failed")
		quit(1)
		return
	print("PASS: production characterization with Balanced 1.25 delta: %d cases, input and project unchanged" % results.size())
	quit()
