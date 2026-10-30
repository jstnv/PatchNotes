extends SceneTree

var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func meta(scope: Variant = 30, required: Variant = 30, cycle: Variant = 8) -> Dictionary:
	return {"release_cycle":cycle,"review":{"scope":scope,"required_scope":required,"scope_completion":1.0}}

func _run() -> void:
	var rule_path := "res://scripts/cards/store_era_eligibility.gd"
	expect(FileAccess.file_exists(rule_path), "Pure Store era rule exists")
	if failures > 0: quit(failures); return
	var rule = load(rule_path)
	for scope in [29,30,31]:
		expect(rule.qualifies(meta(scope),true)==(scope>=30), "Frozen Scope boundary "+str(scope))
	for required in [0,-1,30.0,"30",null]:
		expect(not rule.qualifies(meta(30,required),true), "Reject unknown/nonpositive/noninteger required Scope "+str(required))
	for scope in [-1,30.0,"30",null]:
		expect(not rule.qualifies(meta(scope),true), "Reject malformed played Scope "+str(scope))
	expect(not rule.qualifies(meta(),false), "Absent owner requires known validated Studio semantics")
	var publisher := meta(); publisher.owner=&"publisher"
	expect(not rule.qualifies(publisher,true), "Publisher commissions excluded")
	var unknown := meta(); unknown.owner=&"unknown"
	expect(not rule.qualifies(unknown,true), "Unknown explicit owner excluded")
	for completion in [0.4,0.999,"1",null]:
		var inconsistent:=meta();inconsistent.review.scope_completion=completion
		expect(not rule.qualifies(inconsistent,true),"Contradictory/unknown frozen Scope completion cannot mint receipt")
	var absent:=meta();absent.review.erase("scope_completion")
	expect(not rule.qualifies(absent,true),"Missing completion provenance grants no receipt")
	var releases: Array[Dictionary] = []
	for id in [&"z",&"a",&"b",&"c",&"d",&"e",&"f"]:
		releases.append({"release_id":id,"release_cycle":4 if id==&"z" else 5})
	var assigned: Dictionary = rule.assign(releases)
	expect(assigned=={"version":1,"assignments":{1984:&"z",1990:&"a",2000:&"b",2010:&"c",2020:&"d",2026:&"e"}}, "Stable chronological/tie ordering and six nonreused slots")
	releases.reverse()
	expect(rule.assign(releases)==assigned, "Input order cannot alter assignments")
	releases.append(releases[0].duplicate())
	expect(rule.assign(releases).is_empty(), "Duplicate release IDs reject")
	expect(rule.assign([{"release_id":&"a","release_cycle":-1}]).is_empty(), "Malformed release chronology rejects")
	var definitions := {&"parent":{"id":"parent"},&"child":{"id":"child","purchase_parent":"parent","min_year":1986,"era_year":1984}}
	expect(not FeatureStoreCatalog.graph(definitions,{}).has("error"), "Valid optional era metadata")
	for edit in [{"era_year":1985},{"era_year":1990},{"min_year":1986.5},{"min_year":1979},{"min_year":1e100},{"era_year":"1984"}]:
		var invalid := definitions.duplicate(true); invalid[&"child"].merge(edit,true)
		expect(FeatureStoreCatalog.graph(invalid,{}).has("error"), "Reject invalid catalog era metadata "+str(edit))
	expect(FeatureStoreCatalog.validate_entries(FeatureStoreCatalog.starting_features(),FeatureStoreCatalog.entries()).is_empty(), "Existing complete catalog stays valid")
	print("STORE_ERA checks=%d failures=%d"%[checks,failures])
	quit(failures)
