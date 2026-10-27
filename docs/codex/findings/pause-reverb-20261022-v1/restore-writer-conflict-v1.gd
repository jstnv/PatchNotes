## Presentation-only source compatibility against actual prior market saves.
## Run seed, then cold in a fresh Godot process with the same explicit --store.
## The original pair and any player save directory are never written.
extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const PRIOR_SOURCES := [
	"5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536",
	"d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72",
]
var checks := 0
var failures: Array = []
var report := {}

func arg(prefix: String) -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with(prefix): return value.substr(prefix.length())
	return ""

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("PAUSE_REVERB_RESTORE " + message)
	print("RESTORE_CHECK %d %s %s" % [checks, "PASS" if ok else "FAIL", message])

func world_without_source(world: Dictionary) -> Dictionary:
	var result := world.duplicate(true)
	result.erase("source_identity")
	return result

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var input := arg("--input=")
	var output := arg("--output=")
	var directory := arg("--store=")
	var mode := arg("--mode=")
	if input.is_empty() or output.is_empty() or directory.is_empty() or mode not in ["seed", "cold"]:
		push_error("Explicit --input, --output, --store and --mode=seed|cold required")
		quit(2)
		return
	var initial_hash := FileAccess.get_sha256(input)
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(input))
	if not loaded is Dictionary or not loaded.get("player") is Dictionary or not loaded.get("world") is Dictionary:
		push_error("Expected original acceptance player/world pair")
		quit(2)
		return
	var original: Dictionary = loaded
	var identity := Replay.source_identity()
	report = {"input":input, "input_sha256":initial_hash, "source_identity":identity,
		"prior_source":original.world.source_identity, "store":directory, "mode":mode}
	expect(original.world.source_identity in PRIOR_SOURCES, "input has a named actual previous source")
	expect(original.player.content_revision == StudioCheckpoint.new().revision(), "presentation edit preserves content revision")
	var coordinator := CheckpointCoordinator.new()
	coordinator.rival_catalog = root.get_node("CardDatabase").get_development_catalog()
	coordinator.store = StudioCheckpointStore.new(directory, coordinator._validate_payload)
	var combined: Dictionary = original.player.duplicate(true)
	combined.rival_world = original.world.duplicate(true)
	if mode == "seed":
		expect(coordinator.store.inspect().status == &"empty", "seed starts in an empty isolated Store")
		if failures.is_empty():
			var result := coordinator.store.save(combined)
			expect(result.status == &"saved" and result.sequence == 1, "normal Store accepts exact old pair at generation one: " + str(result))
	var inspection := coordinator.store.inspect()
	expect(inspection.status == &"valid", "normal Store validates prior source: " + str(inspection.get("reason", "")))
	if inspection.status == &"valid":
		expect(inspection.payload == combined, "stored original pair has no payload changes")
		var path: String = inspection.path
		var generation_hash := FileAccess.get_sha256(path)
		var generations := coordinator.store._generations()
		var restored := coordinator.load_current()
		expect(restored != null and coordinator.rival_world != null, "normal Continue restores original player and active world")
		if restored != null and coordinator.rival_world != null:
			var actual_player := StudioCheckpoint.new().capture(restored)
			var actual_world := WorldCodec.new().capture(coordinator.rival_world)
			expect(actual_player == original.player, "captured player exact including finance, releases, Fans and RNG")
			expect(world_without_source(actual_world) == world_without_source(original.world), "captured world exact except executable source marker")
			expect(actual_world.source_identity == identity, "new capture uses actual current source")
			report.player_digest = Replay.digest(actual_player)
			report.world_digest_without_source = Replay.digest(world_without_source(actual_world))
		expect(FileAccess.get_sha256(path) == generation_hash, "Continue leaves original generation bytes unchanged")
		expect(coordinator.store._generations() == generations, "Continue publishes no replacement generation")
		report.generation_sha256 = generation_hash
		report.generations = generations
	# Keep rejection checks on separate copies and preserve strict current-market
	# owner provenance; an allowed presentation source is not a schema bypass.
	var bad := combined.duplicate(true)
	bad.rival_world.source_identity = "unknown-presentation-source"
	var before := Replay.digest(bad)
	expect(not coordinator._validate_payload(bad).is_empty(), "unknown world source still rejected")
	expect(Replay.digest(bad) == before, "unknown-source rejection does not mutate payload")
	bad = combined.duplicate(true)
	var snapshot: Variant = CheckpointCodec.new().decode(bad.rival_world.market, WorldCodec._market_schema())
	expect(snapshot is Dictionary and not snapshot.facts.is_empty(), "original snapshot has actual release facts for corruption check")
	if snapshot is Dictionary and not snapshot.facts.is_empty():
		snapshot.facts[0].review_tenths = (snapshot.facts[0].review_tenths + 1) % 101
		snapshot.id = Market.identifier(snapshot.cycle_start, snapshot.facts)
		expect(Market.valid(snapshot), "corruption retains valid market shape and recomputed hash")
		bad.rival_world.market = CheckpointCodec.new().encode(snapshot, WorldCodec._market_schema())
		before = Replay.digest(bad)
		expect(not coordinator._validate_payload(bad).is_empty(), "valid-hash corrupted market rejected against original owners")
		expect(Replay.digest(bad) == before, "market-corruption rejection does not mutate payload")
	coordinator.store.release_writer()
	coordinator.free()
	expect(FileAccess.get_sha256(input) == initial_hash, "original acceptance artifact unchanged")
	expect(Replay.source_identity() == identity, "runtime source remains stable throughout check")
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open restore report")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PAUSE_REVERB_RESTORE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
