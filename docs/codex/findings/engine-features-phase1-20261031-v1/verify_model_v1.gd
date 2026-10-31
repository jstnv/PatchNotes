extends SceneTree
var checks:=0
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	var path:="res://scripts/engines/engine_feature_state.gd"
	check(ResourceLoader.exists(path),"Authoritative per-engine Feature registry exists")
	if ResourceLoader.exists(path):
		var model: GDScript=load(path)
		var definitions: Dictionary={};var offers: Dictionary={}
		for entry: Dictionary in FeatureStoreCatalog.starting_features()+FeatureStoreCatalog.entries():definitions[StringName(entry.id)]=entry
		for entry: Dictionary in FeatureStoreCatalog.entries():offers[StringName(entry.id)]=entry
		var state: Dictionary=model.create([&"text",&"4_color_palette"] as Array[StringName],[&"legacy_engine"] as Array[StringName],&"studio")
		check(model.valid(state,definitions,offers),"Legacy access becomes explicit unchanged proprietary snapshot")
		check(model.add_record(state,&"prop_b","Second engine",&"proprietary",20,[] as Array[StringName]),"Code-owned second proprietary foundation")
		check(not model.has_feature(state,&"prop_b",&"text") and model.has_feature(state,&"legacy_engine",&"text"),"Implementations are engine-specific")
		check(model.add_record(state,&"public_fixture","Public fixture",&"public",25,[&"text"] as Array[StringName]),"Fixed public library foundation")
		check(not model.stage(state,&"public_fixture",[&"text"] as Array[StringName],definitions,offers),"Fixed library cannot stage configuration")
		check(not model.stage(state,&"prop_b",[&"text"] as Array[StringName],definitions,offers),"Unimplemented Feature cannot be staged")
		check(model.discounted(100001,80)==20000 and model.discounted(100001,100)==20000,"Whole-base effective discount caps at80 percent with integer cents")
		check(not model.add_record(state,&"prop_b","Duplicate",&"proprietary",20,[] as Array[StringName]),"Duplicate engine rejects")
		check(model.valid(state,definitions,offers),"Registry preserves all invariants")
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));quit(0 if failures.is_empty() else 1)
