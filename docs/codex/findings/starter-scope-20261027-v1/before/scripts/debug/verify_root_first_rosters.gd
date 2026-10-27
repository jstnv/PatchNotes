extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
var checks := 0
var failures := 0
func _initialize() -> void: _run.call_deferred()
func expect(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _run() -> void:
	var fixture_path := "res://scripts/debug/fixtures/studio_specialties_v3.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="): fixture_path = arg.trim_prefix("--input=")
	var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var schema := StudioCheckpoint.new()
	var graph := FeatureStoreCatalog.graph(RunState.new()._feature_definitions,RunState.new()._feature_offers)
	assert(not graph.has("error"))
	for genre: String in fixtures:
		var session=Factory.create_fresh_session({"schema_version":1,"studio_id":"root-"+genre,"studio_name":"Root Studio","specialty":genre,"traits":[],"seed":"4417"},catalog)
		var run: RunState=session.run
		var view := StudioSpecialties.preview(StringName(genre))
		var ids: Array=view.ids.map(func(id):return str(id));ids.sort()
		expect(view.roster_version==3 and run.get_founding_roster_version()==3,"New starts use explicit v3: "+genre)
		expect(ids==fixtures[genre].ids and view.scope==fixtures[genre].scope and view.count==fixtures[genre].count,"Independent exact v3 roster/count/Scope: "+genre)
		for id: StringName in run.get_owned_feature_ids():
			expect(graph.parents[id].all(func(parent):return run.owns_feature(parent)),"Every owned starting node has all named parents: "+genre+"/"+str(id))
			expect(run.get_feature_familiarity(id)==0,"Starting grants never credit plays: "+genre+"/"+str(id))
		var saved := schema.capture(run)
		var restored := schema.hydrate(saved)
		expect(not saved.is_empty() and saved.run.founding_roster_version=="3" and restored!=null and schema.capture(restored)==saved,"V3 exact saved-state/RNG round trip: "+genre)
		var prior := saved.duplicate(true)
		StudioSpecialties.preview(StringName(genre))
		expect(not run.set_studio_name("Duplicate",&"action") and schema.capture(run)==prior,"No passive or repeat grant: "+genre)
		expect(run.owns_feature(&"sound_effects") and not run.owns_feature(&"multiple_endings") and not run.owns_feature(&"save_files"),"Root sound and no free advanced/crossover branch: "+genre)
		var project:=PrimitivePredevelopment.prepare_project("Root supply",StringName(genre),&"fantasy",run)
		expect(project.get_feature_supply_ids()==run.get_owned_feature_ids(),"New project uses the exact granted pool: "+genre)
		if genre in ["adventure","role_playing","puzzle"]:
			expect(not run.owns_feature(&"8_bit_sound") and run.get_primitive_reserve_offer(&"8_bit_sound").unlocked,"Sound Effects starts the path to unowned 8-Bit Sound: "+genre)
			var cash:=run.get_cash_cents();var cycle:=run.get_completed_run_cycles()
			var quote:=run.get_primitive_reserve_offer(&"8_bit_sound")
			expect(run.purchase_starter_feature(&"8_bit_sound") and run.get_cash_cents()==cash-int(quote.price_cents) and run.get_completed_run_cycles()==cycle,"Existing child purchase price/timing remain intact: "+genre)
	print("ROOT_FIRST_ROSTERS checks=%d failures=%d"%[checks,failures])
	quit(failures)
