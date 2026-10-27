extends "res://scripts/debug/verify_primitive_branches.gd"

func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var records := {}
	var adapter := StudioCheckpoint.new()
	for child: StringName in [&"multiple_endings", &"secrets", &"8_bit_music", &"8_bit_sound", &"scrolling", &"sprites"]:
		var run: RunState = fresh().run
		# Controlled absence fixture: existing Studio at the actual old admission rules.
		for id: StringName in [child, &"branching_dialogue", &"exploration", &"music", &"sound_effects", &"text", &"4_color_palette"]:
			run._owned_features.erase(id)
		run.finalize_starter_selection()
		check(run.admit_feature_research(run.get_feature_research_quote(child)), "old parentless admission " + str(child))
		records[child] = adapter.capture(run)
		check(not records[child].is_empty(), "old saved queue " + str(child))
	for genre: StringName in StudioSpecialties.RULES:
		records["roster_" + str(genre)] = adapter.capture(fresh(genre).run)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	print("STORE_CONE_PRIOR checks=%d failures=%d" % [checks,failures])
	quit(failures)
