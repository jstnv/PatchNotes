extends SceneTree
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks: Array = []
func _initialize() -> void: execute.call_deferred()
func check(ok: bool, label: String) -> void:
	checks.append({"pass":ok,"label":label})
	if not ok: printerr("FAIL: ",label)
func without_support(current: Dictionary, previous: Dictionary) -> Dictionary:
	var normalized := current.duplicate(true)
	for key: String in ["support_deals","support_rights","support_assessments"]:
		check(normalized.run.get(key) == [],"named predecessor initializes empty "+key)
		normalized.run.erase(key)
	normalized.content_revision = previous.content_revision
	return normalized
func execute() -> void:
	var args := OS.get_cmdline_user_args()
	var adapter := StudioCheckpoint.new()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var inputs: Array = []
	for kind in ["world-operator","compiled-world"]:
		for suffix in [".fixture.json",".operator-fixture.json"]:
			var path: String = args[1]+"/"+kind+"/result.json"+suffix
			var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			var original := fixture.duplicate(true)
			inputs.append({"path":path,"sha256":FileAccess.get_sha256(path),"source":fixture.world.source_identity})
			check(adapter.validate(fixture.player).is_empty(),"actual prior player validates through frozen P2/P3")
			var player := adapter.hydrate(fixture.player)
			check(player != null and without_support(adapter.capture(player),fixture.player) == fixture.player,"actual player fields/RNG unchanged; no backfilled deals or awards")
			var codec := WorldCodec.new()
			var restored := codec.restore(fixture.world,fixture.player,player,catalog)
			check(restored != null,"actual prior populated Founder/active world restores: "+codec.error)
			if restored != null:
				var current := codec.capture(restored)
				for index in range(current.studios.size()):
					current.studios[index].run = without_support(current.studios[index].run,fixture.world.studios[index].run)
				current.source_identity = fixture.world.source_identity
				check(current == fixture.world,"every prior world/ownership/rights/market/RNG field unchanged")
			var unknown: Dictionary = fixture.world.duplicate(true)
			unknown.source_identity = "unknown-support-source"
			check(codec.restore(unknown,fixture.player,player,catalog) == null,"unknown source still rejects")
			var bad_player: Dictionary = fixture.player.duplicate(true)
			bad_player.content_revision = adapter.revision()
			var bad_world: Dictionary = fixture.world.duplicate(true)
			for row: Dictionary in bad_world.studios: row.run.content_revision = adapter.revision()
			check(codec.restore(bad_world,bad_player,player,catalog) == null,"joint forged current revision on old world rejects")
			bad_world = fixture.world.duplicate(true)
			bad_world.studios[0].run.content_revision = adapter.revision()
			check(codec.restore(bad_world,fixture.player,player,catalog) == null,"mismatched active rival revision rejects")
			check(original == fixture,"all migration/rejection inputs preserved")
	# The new actual EXE's earned generation is also a named P2/P3 predecessor.
	var actual_path := args[1].get_base_dir()+"/pn-p4-execution-20261024-v1/actual-exe-1152/actual-later-sales.generation.json"
	var codec := CheckpointCodec.new()
	var actual := codec.open_envelope(FileAccess.get_file_as_string(actual_path))
	check(codec.error.is_empty(),"actual EXE generation envelope opens")
	var actual_run := adapter.hydrate(actual)
	check(actual_run != null,"actual EXE earned player hydrates")
	if actual_run != null:
		var captured := adapter.capture(actual_run)
		check(captured.sequence == "1" and actual.sequence == "10","capture proposes sequence1; actual disk store allocated generation10")
		# Generation numbering is assigned by the Store, not owned by RunState.
		captured.sequence = actual.sequence
		check(without_support(captured,actual) == actual,"actual EXE earned player fields/RNG migrate exactly, preserving original store sequence")
	var failures := checks.filter(func(row: Dictionary) -> bool:return not row["pass"]).size()
	FileAccess.open(args[0]+"/migration-result.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"inputs":inputs,"actual_generation_sha256":FileAccess.get_sha256(actual_path),"source":Replay.source_identity()},"\t"))
	print("P4 migration checks: ",checks.size()," failures: ",failures)
	quit(0 if failures == 0 else 1)
