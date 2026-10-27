extends "res://scripts/debug/verify_rival_gameplay_activation.gd"

const Replay := preload("res://scripts/simulation/development_replay.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var path := OS.get_environment("PN_PAUSE_BASELINE")
	if "--capture" in OS.get_cmdline_user_args():
		node_added.connect(_replace_store)
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game._on_studio_created("Pause transition baseline", &"action", [], game._active_phase)
		expect(game.checkpoints.flush(), "Pre-edit initial save is durable")
		var inspection: Dictionary = game.checkpoints.store.inspect()
		expect(inspection.status == &"valid", "Genuine pre-edit Studio checkpoint")
		if inspection.status == &"valid":
			FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(inspection.payload))
			print("BASELINE_SOURCE ", inspection.payload.rival_world.source_identity)
		game.checkpoints.store.release_writer()
	else:
		var hash_before := FileAccess.get_sha256(path)
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var coordinator := CheckpointCoordinator.new()
		coordinator.rival_catalog = root.get_node("CardDatabase").get_development_catalog()
		coordinator.store = TestStore.new("user://saves/pause-restore", coordinator._validate_payload)
		expect(coordinator._validate_payload(original).is_empty(), "Normal full payload validation admits exact predecessor")
		var saved := coordinator.store.save(original)
		expect(saved.status == &"saved", "Normal isolated Store accepts unchanged pre-edit payload")
		var generation_hash := FileAccess.get_sha256(coordinator.store.inspect().get("path", ""))
		var generations := coordinator.store._generations()
		var restored := coordinator.load_current()
		expect(restored != null and coordinator.rival_world != null, "Fresh process Continue restores player and active rivals")
		if restored != null and coordinator.rival_world != null:
			var expected_player := original.duplicate(true)
			expected_player.erase("rival_world")
			expect(StudioCheckpoint.new().capture(restored) == expected_player, "Exact player state including finance and RNG retained")
			var actual_world: Dictionary = WorldCodec.new().capture(coordinator.rival_world)
			var expected_world: Dictionary = original.rival_world.duplicate(true)
			expect(actual_world.source_identity == Replay.source_identity(), "Capture pins actual new executable identity")
			actual_world.erase("source_identity")
			expected_world.erase("source_identity")
			expect(actual_world == expected_world, "Exact world and RNG retained except executable marker")
		var unknown := original.duplicate(true)
		unknown.rival_world.source_identity = "unknown-pause-transition-source"
		expect(not coordinator._validate_payload(unknown).is_empty(), "Unknown source remains rejected")
		expect(coordinator.store._generations() == generations, "Continue publishes no replacement generation")
		expect(FileAccess.get_sha256(coordinator.store.inspect().get("path", "")) == generation_hash, "Continue leaves generation bytes unchanged")
		expect(FileAccess.get_sha256(path) == hash_before, "Original pre-edit checkpoint artifact unchanged")
		coordinator.store.release_writer()
		coordinator.free()
	print("PAUSE_RESTORE checks=%d failures=%d" % [checks, failures])
	quit(failures)
