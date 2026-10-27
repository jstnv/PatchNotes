extends "res://scripts/debug/verify_primitive_branches.gd"
func _initialize() -> void:
	await process_frame
	catalog = root.get_node("CardDatabase").get_development_catalog()
	var result := {"source":Replay.source_identity(),"rosters":{},"saves":{}}
	for genre: StringName in StudioSpecialties.RULES:
		var session := fresh(genre)
		result.rosters[str(genre)] = StudioSpecialties.preview(genre)
		result.saves[str(genre)] = StudioCheckpoint.new().capture(session.run)
		check(not result.saves[str(genre)].is_empty(), "Real v1 founding checkpoint " + str(genre))
	var session := fresh(&"strategy")
	session.run.finalize_starter_selection()
	var quote: Dictionary = session.run.get_feature_research_quote(&"colored_text")
	check(session.run.admit_feature_research(quote), "v1 paid queue")
	result.saves.queued_strategy = StudioCheckpoint.new().capture(session.run)
	var world := preload("res://scripts/market/rival_trial.gd").create_world(session.run,catalog)
	check(session.run.complete_productive_action(Callable(),0,0), "advance actual rival world")
	world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(world),12)
	result.player = StudioCheckpoint.new().capture(session.run)
	result.world = preload("res://scripts/market/rival_world_checkpoint.gd").new().capture(world)
	check(not result.player.is_empty() and not result.world.is_empty(), "v1 active-world checkpoint")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("ROSTER_V1_SOURCE checks=%d failures=%d"%[checks,failures])
	quit(failures)
