## Per-engine activation migration, replacement provenance and closed schemas.
extends SceneTree
const Model=preload("res://scripts/engines/engine_feature_state.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
func _initialize() -> void:verify.call_deferred()

func verify() -> void:
	var run:=RunState.new()
	var defs:=run._feature_definitions;var offers:=run._feature_offers
	var old: Dictionary={"version":2,"engines":{},"entries":[],"configurations":[]}
	var library: Array[StringName]=[&"text",&"4_color_palette",&"8_bit_sound",&"16_bit_sound"]
	check(Model.add_record(old,&"engine","Prior Engine",&"proprietary",25,library),"Build V2 replacement fixture")
	old.engines[&"engine"].committed=Model.normalize(library,offers)
	check(Model.valid(old,defs,offers),"Old replacement library is valid")
	check(&"8_bit_sound" not in old.engines[&"engine"].committed,"Old normalized draw pool omits replaced parent")
	var upgraded:=Model.migrate(old,offers)
	check(upgraded.get("version")==3 and Model.valid(upgraded,defs,offers),"V2 replacement fixture migrates to valid V3")
	check(upgraded.engines[&"engine"].committed==old.engines[&"engine"].committed,"Migration preserves exact normalized draw pool")
	check(&"8_bit_sound" in upgraded.engines[&"engine"].enabled and &"16_bit_sound" in upgraded.engines[&"engine"].enabled,"Replacement and parent are both logically enabled")
	var over_cap:=old.duplicate(true);over_cap.engines[&"engine"].capacity=1
	var over_cap_migrated:=Model.migrate(over_cap,offers)
	check(Model.valid(over_cap,defs,offers) and Model.valid(over_cap_migrated,defs,offers) and over_cap_migrated.engines[&"engine"].committed==over_cap.engines[&"engine"].committed,"Historical over-capacity supply remains valid and unchanged")
	var inconsistent:=old.duplicate(true);inconsistent.engines[&"engine"].committed=[] as Array[StringName]
	check(Model.migrate(inconsistent,offers).is_empty(),"Reject migration of inconsistent V2 supply")
	var codec:=CheckpointCodec.new();var schema:=CheckpointSchema.engine_feature_state()
	var wire: Variant=codec.encode(old,schema)
	check(codec.error.is_empty() and CheckpointCodec.new().decode(wire,schema)==old,"Closed schema roundtrips old record")
	wire=codec.encode(upgraded,schema)
	check(codec.error.is_empty() and CheckpointCodec.new().decode(wire,schema)==upgraded,"Closed schema roundtrips enabled V3 record")
	var bad:=upgraded.duplicate(true)
	bad.engines[&"engine"].enabled.append(&"does_not_exist")
	check(not Model.valid(bad,defs,offers),"Reject enabled Features without ownership")
	bad=upgraded.duplicate(true);bad.engines[&"engine"].enabled.erase(&"16_bit_sound")
	check(not Model.valid(bad,defs,offers),"Reject mismatched enabled and committed libraries")
	var removed: Dictionary={"version":2,"engines":{},"entries":[],"configurations":[]}
	var start: Array[StringName]=[&"text",&"4_color_palette"]
	Model.add_record(removed,&"engine","Old respec",&"proprietary",25,start)
	var text_base:=Model.base_price(&"text",defs,offers)
	removed.configurations.append({"id":&"studio:engine-config:engine:1","engine_id":&"engine","revision":1,"cycle":1,"cost_cents":text_base/10+int(text_base%10!=0),"base_cents":text_base,"target":[&"4_color_palette"] as Array[StringName],"added":[] as Array[StringName],"removed":[&"text"] as Array[StringName]})
	removed.engines[&"engine"].revision=1;removed.engines[&"engine"].committed=[&"4_color_palette"] as Array[StringName]
	check(Model.valid(removed,defs,offers,{},1,&"studio"),"Historical paid configuration fixture validates")
	var migrated:=Model.migrate(removed,offers)
	check(Model.valid(migrated,defs,offers,{},1,&"studio") and migrated.configurations==removed.configurations,"V3 preserves configuration journal")
	check(migrated.engines[&"engine"].enabled==[&"4_color_palette"] and migrated.engines[&"engine"].committed==removed.engines[&"engine"].committed,"Removed Feature remains disabled during migration")
	var staged:=removed.duplicate(true)
	staged.engines[&"engine"].staged=[&"text"] as Array[StringName]
	staged.engines[&"engine"].committed=[&"4_color_palette",&"text"] as Array[StringName]
	check(Model.valid(staged,defs,offers,{},1,&"studio"),"Historical V2 staged restoration validates")
	var restored:=Model.migrate(staged,offers)
	check(Model.valid(restored,defs,offers,{},1,&"studio") and restored.engines[&"engine"].committed==staged.engines[&"engine"].committed and &"text" in restored.engines[&"engine"].enabled,"Staged historical restoration remains enabled")
	var old_v1:=removed.duplicate(true);old_v1.version=1
	old_v1.engines[&"engine"].staged=[&"text"] as Array[StringName]
	check(Model.valid(old_v1,defs,offers,{},1,&"studio"),"Historical V1 staged state validates")
	var upgraded_v1:=Model.migrate(old_v1,offers)
	check(Model.valid(upgraded_v1,defs,offers,{},1,&"studio") and &"text" in upgraded_v1.engines[&"engine"].committed,"V1 staged migration retains prior automatic-supply policy")
	print("ENGINE_ENABLED_MIGRATION checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
