extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
var results: Array = []

func check(ok: bool, label: String) -> void:
	results.append({"pass":ok,"check":label})
	if not ok: printerr("FAIL: "+label)

func read_variant(path: String) -> Dictionary:
	var wrapper: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	return bytes_to_var(Marshalls.base64_to_raw(wrapper.payload))

func project(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key: Variant in value:
			if key not in ["_publisher_relationships","_relationship_commit_in_progress"]: result[key] = project(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item: Variant in value: result.append(project(item))
		return result
	return value

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	for id: String in ["action-4417","sports-1112"]:
		var b: String = args[0].path_join("cases").path_join(id)
		var c: String = args[1].path_join("cases").path_join(id)
		var baseline := read_variant(b.path_join("final_state.variant.json"))
		var candidate := read_variant(c.path_join("final_state.variant.json"))
		check(project(baseline) == project(candidate),id+" all runtime fields equal excluding two declared additive fields")
		var bt := read_variant(b.path_join("replay.tape.json"))
		var ct := read_variant(c.path_join("replay.tape.json"))
		check(bt.steps.size() == ct.steps.size() and bt.initial_rng == ct.initial_rng,id+" same tape length and initial RNG")
		for i in range(mini(bt.steps.size(),ct.steps.size())):
			var left: Dictionary = bt.steps[i].duplicate(true); left.erase("state")
			var right: Dictionary = ct.steps[i].duplicate(true); right.erase("state")
			check(left == right,id+" command/result/RNG "+str(i))
		var old_envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(b.path_join("studio_checkpoint.json")))
		check(Factory.create({"checkpoint":old_envelope},catalog) == null,id+" incompatible simulation envelope still rejects")
	var old_world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[3]))
	var adapter := StudioCheckpoint.new()
	var upgraded := adapter.upgrade_relationship_predecessor(old_world.player)
	var codec := WorldCodec.new()
	check(not codec.validate(old_world.world,upgraded).is_empty(),"old world source cannot be paired with new player content revision")
	var bad: Dictionary = old_world.world.duplicate(true)
	bad.studios[0].run.content_revision = adapter.revision()
	check(not codec.validate(bad,old_world.player).is_empty(),"old world source cannot mix rival content revisions")
	var failures := 0
	for result: Dictionary in results:
		if not result["pass"]: failures += 1
	var file := FileAccess.open(args[2],FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":results,"failures":failures})); file.close()
	print("P1 runtime audit checks=%d failures=%d" % [results.size(),failures])
	quit(0 if failures == 0 else 1)
