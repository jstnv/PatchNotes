extends "res://scripts/debug/verify_campaign_continuation.gd"
func _initialize() -> void:probe.call_deferred()
func probe() -> void:
	for hands in [2,3,4]:
		var recipe:={"schema_version":1,"studio_id":"continuation_fixture","studio_name":"Continuation","specialty":"action","traits":[],"seed":"4417"}
		var session:=fresh(recipe);tape=Replay.begin(session)
		act(session,&"begin_development",{"name":"First","genre":&"action","theme":&"fantasy"})
		for index in 3:
			if index>0:dev(session,&"enter_next_phase")
			dev(session,&"begin")
			for i in hands:dev(session,&"play",{"candidate_ids":session.development.hand.candidate_ids.slice(0,4)})
			dev(session,&"request_exit")
			if session.development.awaiting_confirmation:dev(session,&"confirm_exit")
		act(session,&"launch");act(session,&"acknowledge_publishers")
		act(session,&"hire",{"quote":session.run.get_production_hire_quote()})
		act(session,&"admit_research",{"quote":session.run.get_feature_research_quote(&"save_files")})
		complete_contract(session,{"kind":&"ironclad"})
		print("ROUTE ",hands," failures=",failures," quote=",session.quote_bank(150000,24))
		if failures:break
	quit(failures)
