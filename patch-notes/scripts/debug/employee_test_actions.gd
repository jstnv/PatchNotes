extends RefCounted
static func fresh_two_releases(catalog: RefCounted,employee_trial: bool=true) -> RunState:
	var factory=preload("res://scripts/simulation/run_factory.gd")
	var policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
	var session=factory.create_fresh_session({"schema_version":1,"studio_id":"employee_checks","studio_name":"Employees Studio","specialty":"action","traits":[],"seed":"4417","employee_trial":employee_trial},catalog)
	var choose=policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Employee Check","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	for step in range(100):
		if session.in_studio and session.run.get_released_game_ids().size()==2:return session.run
		var choice: Dictionary=choose.call(session.observation())
		var result: Dictionary=session.execute(session.command(choice.type,choice.get("payload",{})))
		assert(result.ok,"Legal two-release prefix must succeed: "+str(result))
	assert(false,"Two-release prefix exceeded its bound")
	return null
