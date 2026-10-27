extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Policy := preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var results := []
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	for genre: StringName in StudioSpecialties.RULES:
		var spec := {"schema_version":1,"studio_id":"root-campaign-"+str(genre),"studio_name":"Root Campaign","specialty":str(genre),"traits":[],"seed":"4417"}
		var session=Factory.create_fresh_session(spec,catalog)
		var tape := Replay.begin(session)
		var policy := Policy.factory({"genre":str(genre),"theme":"fantasy","name_prefix":"Root campaign","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
		for i in 200:
			if session.in_studio and session.run.get_released_game_ids().size()==1:break
			var chosen: Dictionary=policy.call(session.observation())
			var result := Replay.record(session,tape,session.command(StringName(chosen.type),chosen.get("payload",{})))
			assert(result.ok,JSON.stringify(result))
		assert(session.in_studio and session.run.get_released_game_ids().size()==1,"Bounded first-release route completes")
		var repeat_session=Factory.create_fresh_session(spec,catalog)
		var replay := Replay.replay(repeat_session,tape)
		assert(replay.ok,JSON.stringify(replay))
		assert(StudioCheckpoint.new().capture(session.run)==StudioCheckpoint.new().capture(repeat_session.run),"Exact final state/RNG")
		results.append({"genre":genre,"commands":tape.steps.size(),"cycles":session.run.get_completed_run_cycles(),"replay":true,"final_state":replay.final_state,"release":session.run.get_release_metadata(session.run.get_released_game_ids()[0])})
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"source":Replay.source_identity(),"seed":4417,"policy":"finite-development-fixture v1, features_first, 2/2/2 hands","scope":"Eight bounded legal model routes and exact action replay; not balance or graphical acceptance","results":results}))
	print("EIGHT_GENRE_CAMPAIGNS_PASS")
	quit()
