extends SceneTree
func _initialize() -> void:
	await process_frame
	var rows=[]
	for traits in [[],["expensive_lease"]]:
		var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"rent-career-"+str(traits.size()),"studio_name":"Rent observation","specialty":"action","traits":traits,"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
		var policy=preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Observation","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
		var outcome=s.drive(policy,120,2)
		var a=StudioCheckpoint.new();var payload=a.capture(s.run)
		rows.append({"traits":traits,"outcome":outcome,"player":payload,"report":s.run.get_studio_finance_report(),"cash":s.run.get_cash_cents(),"cycles":s.run.get_completed_run_cycles(),"releases":s.run.get_released_games().size()})
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify(rows));quit(0)
