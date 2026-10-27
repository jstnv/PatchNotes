extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var path:=OS.get_environment("PN_STARTER_BASELINE")
	var codec:=StudioCheckpoint.new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	if "--capture" in OS.get_cmdline_user_args():
		var saves:={}
		for genre: StringName in StudioSpecialties.RULES:
			var s=Factory.create_fresh_session({"schema_version":1,"studio_id":"scope-old-"+str(genre),"studio_name":"Old scope","specialty":str(genre),"traits":[],"seed":"4417"},catalog)
			expect(s!=null,"Actual preceding Studio creates")
			saves[str(genre)+"-fresh"]=codec.capture(s.run)
			var bought:=false
			for entry: Dictionary in FeatureStoreCatalog.starting_features():
				var id:=StringName(entry.id)
				var quote: Dictionary=s.run.get_primitive_reserve_offer(id)
				if not s.run.owns_feature(id) and quote.can_purchase and s.run.purchase_starter_feature(id):
					bought=true;break
			expect(bought,"Actual preceding optional purchase succeeds")
			saves[str(genre)+"-purchased"]=codec.capture(s.run)
		FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"saves":saves}))
	else:
		var before:=FileAccess.get_sha256(path)
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		for key: String in data.saves:
			var saved: Dictionary=data.saves[key]
			var run:=codec.hydrate(saved)
			expect(run!=null,"Old Studio hydrates: "+key)
			if run==null:continue
			expect(run.get_founding_roster_version()==3 and codec.capture(run)==saved,"Old ownership, purchases, cash and RNG remain byte-exact: "+key)
			var old:=codec.capture(run)
			expect(not run.set_studio_name("Again",&"action") and codec.capture(run)==old,"No reduced-pool regrant on old save: "+key)
			expect(PrimitivePredevelopment.prepare_project("Saved supply",run.get_studio_specialty(),&"fantasy",run).get_feature_supply_ids()==run.get_owned_feature_ids(),"Old acquired supply stays complete: "+key)
		expect(before==FileAccess.get_sha256(path),"Original old save artifacts stay unchanged")
	print("STARTER_OLD_ROSTERS checks=%d failures=%d"%[checks,failures])
	quit(failures)
