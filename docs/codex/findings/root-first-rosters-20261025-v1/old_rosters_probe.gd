extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var output := ""; var input := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
		if arg.begins_with("--input="): input=arg.trim_prefix("--input=")
	var codec := StudioCheckpoint.new()
	if not input.is_empty():
		var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
		for payload: Dictionary in prior.saves:
			var restored := codec.hydrate(payload)
			assert(restored != null and codec.capture(restored)==payload, "Exact old EXE v2 ownership/state/RNG preserved")
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"saves":prior.saves.size(),"source":Replay.source_identity(),"prior_source":prior.source}))
	else:
		assert(StudioSpecialties.ROSTER_VERSION==2,"Producer must use actual historical EXE")
		var saves := []
		for genre: StringName in StudioSpecialties.RULES:
			var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"old-"+str(genre),"studio_name":"Old Roster","specialty":str(genre),"traits":[],"seed":"4417"},root.get_node("CardDatabase").get_development_catalog())
			var run: RunState=session.run
			saves.append(codec.capture(run))
			var purchased := false
			for card: Dictionary in FeatureStoreCatalog.starting_features():
				if run.owns_feature(StringName(card.id)):continue
				if run.purchase_starter_feature(StringName(card.id)):
					purchased=true;break
			assert(purchased,"Every old genre retains an optional acquisition")
			saves.append(codec.capture(run))
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"saves":saves}))
	print("OLD_ROSTERS_PASS")
	quit()
