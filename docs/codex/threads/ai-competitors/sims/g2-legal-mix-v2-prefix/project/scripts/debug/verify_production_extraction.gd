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
	assert(JSON.parse_string(JSON.stringify(results)) == expected, "Pre-extraction production parity failed")
	var output_path := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(results, "\t"))
	print("PASS: production characterization: %d cases, input and project unchanged" % results.size())
	quit()
