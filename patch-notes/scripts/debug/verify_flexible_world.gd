extends SceneTree
const WorldCodec = preload("res://scripts/market/rival_world_checkpoint.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)
func _initialize() -> void:
	await process_frame
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/flex-hands-20261101-v1/preceding-world.json"))
	var adapter := StudioCheckpoint.new()
	var player := adapter.hydrate(prior.player)
	var codec := WorldCodec.new()
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var world = codec.restore(prior.world, prior.player, player, catalog)
	check(world != null, "Exact preceding award-bearing eight-rival world restores: " + codec.error)
	if world != null:
		check(adapter.capture(world.player) == prior.player, "Prior player finance/Fans/banks/RNG/engine DTO remains exact")
		var current: Dictionary = codec.capture(world)
		check(not current.is_empty(), "Migrated world current capture validates: " + codec.error)
		if not current.is_empty():
			for i in prior.world.studios.size():
				check(current.studios[i].run == prior.world.studios[i].run, "Prior rival run retained " + str(i))
				check(current.studios[i].development == prior.world.studios[i].development, "Prior active phase, candidates and2/K8 counters retained " + str(i))
			check(current.annual_awards == prior.world.annual_awards, "Frozen results, payouts and presentation state retained")
			var again = codec.restore(JSON.parse_string(JSON.stringify(current)), prior.player, adapter.hydrate(prior.player), catalog)
			check(again != null and codec.capture(again) == current, "Current cold round trip is exact and pays nothing again")
			var bad := current.duplicate(true)
			bad.source_identity = "unknown-flex-source"
			check(not codec.validate(bad, prior.player).is_empty(), "Unknown predecessor source still rejects")
	print("FLEXIBLE_WORLD checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
