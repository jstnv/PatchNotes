extends SceneTree
var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := OS.get_environment("PN_PRIOR_SAVE")
	var bytes := FileAccess.get_file_as_bytes(path)
	var envelope: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not envelope is Dictionary:
		push_error("invalid private checkpoint")
		quit(2)
		return
	var raw: String = envelope.get("payload_utf8", "")
	expect(raw.sha256_text() == envelope.get("payload_sha256"), "Predecessor checksum matches")
	var payload: Dictionary = JSON.parse_string(raw)
	var prior_world: Dictionary = payload.rival_world
	expect(prior_world.source_identity == OS.get_environment("PN_EXPECTED_SOURCE"), "Exact predecessor source identity")
	payload.erase("rival_world")
	var adapter := StudioCheckpoint.new()
	var player := adapter.hydrate(payload)
	expect(player != null, "Predecessor player hydrates: " + adapter.error)
	if player == null:
		quit(1)
		return
	var player_after := adapter.capture(player)
	expect(player_after == payload, "Complete player finance, history and RNG round trip exactly")
	var codec: RefCounted = load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var world = codec.restore(prior_world, payload, player, catalog)
	expect(world != null, "Predecessor eight-rival world hydrates: " + codec.error)
	if world == null:
		quit(1)
		return
	var restored_world: Dictionary = codec.capture(world)
	expect(not restored_world.is_empty(), "Eight-rival world captures")
	var actual_source: String = restored_world.get("source_identity", "")
	restored_world.source_identity = prior_world.source_identity
	expect(restored_world == prior_world, "Complete rival finance, history and RNG round trip except source identity")
	expect(not actual_source.is_empty() and actual_source != prior_world.source_identity, "Recapture records new source identity")
	expect(FileAccess.get_file_as_bytes(path) == bytes, "Original checkpoint bytes unchanged")
	print("OWNER_KEY_PRIOR_PARITY ", JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures == 0 else 1)
