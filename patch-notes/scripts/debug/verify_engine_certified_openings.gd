## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_engine_certified_openings.gd
extends SceneTree

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void: _verify.call_deferred()

func _verify() -> void:
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var ids := {}
	for number in range(20):
		var id := "engine-opening-%d" % number
		var index: int = id.sha256_text().substr(0,8).hex_to_int() % 2
		if not ids.has(index): ids[index] = id
	check(ids.size() == 2,"Both certified opening selectors have a deterministic player ID")
	for index in [0,1]:
		var recipe := {"schema_version":1,"studio_id":ids[index],"studio_name":"Opening Player","specialty":"action","traits":[],"seed":"5607"}
		var session: RefCounted = preload("res://scripts/simulation/run_factory.gd").create_fresh_session(recipe,catalog)
		var loader := preload("res://scripts/market/rival_opening_loader.gd").new()
		var world: RivalWorld = loader.create(session.run,catalog) if session != null else null
		check(world != null and world.studios.size() == 8,"Certified opening %d restores with legacy Pass Budget provenance: %s" % [index,loader.error])
		if world == null: continue
		for engine_id in [&"action_engine",&"puzzle_engine"]:
			var listing: Dictionary = preload("res://scripts/engines/engine_marketplace.gd").find(engine_id)
			check(preload("res://scripts/engines/engine_marketplace.gd").creator_matches_world(listing,world),"Opening %d retains the actual engine creator %s" % [index,engine_id])
	print("Engine certified openings: %d failures" % failures)
	quit(1 if failures else 0)
