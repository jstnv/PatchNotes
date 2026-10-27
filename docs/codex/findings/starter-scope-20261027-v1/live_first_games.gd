extends "res://scripts/debug/verify_campaign_live_parity.gd"

func _initialize() -> void:
	await process_frame
	var results:={}
	for genre: StringName in StudioSpecialties.RULES:
		route_id="scope12-"+str(genre)
		segment=0
		var recipe:={"schema_version":1,"studio_id":route_id,"studio_name":"Scope parity","specialty":str(genre),"traits":[],"seed":"4417"}
		var coordinator:=start_route(recipe)
		expect(game.run_state.get_founding_roster_version()==4 and session.run.get_founding_roster_version()==4,"Both current founding paths use version4")
		# Existing legal2/2/2 scene/headless hand route; no Bank, purchases or funding.
		await full_project("Reduced",false,genre)
		if failures:break
		expect(session.run.get_released_game_ids().size()==1,"Reduced pool registers its first release")
		expect(coordinator.flush(),"Reduced-pool Studio checkpoint flush")
		continue_studio(session.export_checkpoint())
		results[str(genre)]={"scope":StudioSpecialties.preview(genre).scope,"version":session.run.get_founding_roster_version(),"cash_cents":session.run.get_cash_cents(),"cycle":session.run.get_completed_run_cycles(),"state":snapshot(false)}
		game.free();await process_frame
		if failures:break
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"comparisons":comparisons,"failures":failures,"genres":results,"policy":"Current v4, seed4417,2/2/2 hands; legal first-release and Continue parity, not optimal balance"},"\t"))
	print("SCOPE12_LIVE_PARITY comparisons=%d genres=%d failures=%d"%[comparisons,results.size(),failures])
	quit(failures)
