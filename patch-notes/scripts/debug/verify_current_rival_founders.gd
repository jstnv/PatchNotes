extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)
func _run() -> void:
	var path: String="res://scripts/market/rival_founder_profile.gd"
	if not FileAccess.file_exists(path):
		print("RIVAL_FOUNDER_FAIL: explicit separate rival profile is missing")
		quit(1)
		return
	var profile=load(path)
	var factory=load("res://scripts/simulation/run_factory.gd")
	var codec=load("res://scripts/persistence/studio_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var rows: Array=[]
	for genre: String in ["action","adventure","role_playing","strategy","simulation","puzzle","sports","racing"]:
		var recipe: Dictionary={"schema_version":1,"studio_id":"verify-"+genre,"studio_name":"Verify "+genre,"specialty":genre,"traits":["family_funding","cult_following"],"seed":"5607"}
		var player=factory.create_fresh_session(recipe,catalog)
		_check(player!=null and player.run.get_current_year()==1980 and player.run.get_founding_roster_version()==5,"player bootstrap "+genre)
		var expected: Dictionary=StudioSpecialties.preview(StringName(genre),5)
		_check(player.run.get_owned_feature_ids()==expected.ids and expected.scope==12,"player 12 Scope unchanged "+genre)
		recipe.rival_founder_profile=str(profile.ID)
		var session=factory.create_fresh_session(recipe,catalog)
		_check(session!=null,"rival bootstrap "+genre)
		if session==null:continue
		var report: Dictionary=profile.describe(StringName(genre),session.run)
		rows.append(report)
		_check(not report.is_empty() and report.parent_connected and report.scope>=20 and report.scope<=27,"active connected roster "+genre)
		_check(session.run._calendar_start_year==1977 and session.run.get_founding_roster_version()==5,"separate profile epoch "+genre)
		_check(session.run.get_cash_cents()==player.run.get_cash_cents(),"profile grants no funding "+genre)
		var saved: Dictionary=codec.capture(session.run)
		_check(not saved.is_empty(),"profile capture "+genre+": "+codec.error)
		var restored=codec.hydrate(saved) if not saved.is_empty() else null
		_check(restored!=null and restored._rival_founder_profile==profile.ID,"profile cold schema "+genre+": "+codec.error)
		recipe.rival_founder_profile="unknown"
		_check(factory.create_fresh_session(recipe,catalog)==null,"unknown profile rejected "+genre)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var f=FileAccess.open(argument.substr(9),FileAccess.WRITE)
			f.store_string(JSON.stringify({"rows":rows,"failures":failures},"  "));f.close()
	print("RIVAL_FOUNDER_CHECKS failures=",failures)
	quit(0 if failures.is_empty() else 1)
