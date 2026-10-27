## Exact historical inputs, detached profiles, prospective migration only.
extends SceneTree

const Migration := preload("res://scripts/market/market_save_migration_trial.gd")
const OldStudio := preload("res://scripts/market/legacy_pre_market_studio_validator.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var checks := 0
var failures: Array = []
var output := ""
var label := "prior-world"
var mode := "run"
var catalog: RefCounted
var records: Dictionary = {}

func expect(value: bool, message: String) -> void:
	checks += 1
	print("MIGRATION_CHECK %d %s %s" % [checks,"PASS" if value else "FAIL",message])
	if not value:
		failures.append(message)
		push_error("Migration: " + message)

func repo(path: String) -> String:
	return ProjectSettings.globalize_path("res://../" + path).simplify_path()

func source_path() -> String:
	match label:
		"prior-world": return repo("docs/codex/findings/queue-20261018-v2/prior-v2.json")
		"current-world": return repo("docs/codex/findings/queue-20261018-v2/roster-closeout.json")
		"synergy-world": return repo("docs/codex/findings/queue-20261018-v2/profile-ai-world-before/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.21.json")
		"bank-recovered": return repo("docs/codex/findings/bank-age2-20261018-v1/route-v1.json.studio.json")
		"bank-only": return repo("docs/codex/findings/bank-age2-20261018-v1/bank-only-v1.json.initial.json")
		"founder-v1": return repo("docs/codex/threads/ai-competitors/sims/market-density-v31-historical-input-20261018-v1/profile/APPDATA/Godot/app_userdata/Patch Notes/market-founder1-original.json")
		"world-v1": return repo("docs/codex/threads/ai-competitors/sims/market-density-v31-historical-input-20261018-v1/profile/APPDATA/Godot/app_userdata/Patch Notes/market-world1-original.json")
		"founder-v2": return repo("docs/codex/findings/title-studio-audio-20261018-v1/before/verify_legacy_world.json")
	return ""

func read_pair(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var value: Dictionary = JSON.parse_string(text)
	if value.has("payload_utf8"):
		var payload: Dictionary = CheckpointCodec.new().open_envelope(text)
		var world: Dictionary = payload.rival_world
		payload.erase("rival_world")
		return {"player":payload, "world":world, "store":true}
	if value.has("studio_payload"): return {"player":value.studio_payload, "world":{}, "envelope":value}
	return {"player":value.player, "world":value.world}

func strip_new_player(value: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	result.erase("content_revision")
	result.erase("sequence")
	for sale: Dictionary in result.run.released_games: sale.value.erase("market_factors")
	for fan: Dictionary in result.run.fanbase.releases: fan.value.neutral.erase("market_factors")
	return result

func strip_new_world(value: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	result.erase("source_identity")
	result.erase("market")
	result.erase("market_origin")
	for row: Dictionary in result.studios:
		row.run = strip_new_player(row.run)
		if row.development != null:
			for field: String in ["_market_standards","_market_snapshot_id","_market_details"]: row.development.project.erase(field)
	return result

func save_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
	file.close()

func coordinator(path: String) -> CheckpointCoordinator:
	var result := CheckpointCoordinator.new()
	result.rival_catalog = catalog
	result.store = StudioCheckpointStore.new(path, result._validate_payload)
	return result

func _initialize() -> void:
	await process_frame
	output = OS.get_environment("PN_CARD_FRAME_OUTPUT")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): label = arg.trim_prefix("--case=")
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	if output.is_empty(): quit(2); return
	catalog = root.get_node("CardDatabase").get_development_catalog()
	records.source_start = Replay.source_identity()
	print("MIGRATION_SOURCE_START " + str(records.source_start))
	if mode == "cold":
		cold()
	else:
		run()
	expect(records.source_start == Replay.source_identity(), "runtime source unchanged during check")
	records.merge({"case":label,"mode":mode,"checks":checks,"failures":failures,"source":Replay.source_identity()},true)
	save_json(output,records)
	print("MARKET_MIGRATION %s %s checks=%d failures=%d" % [label,mode,checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	var path := source_path()
	expect(not path.is_empty() and FileAccess.file_exists(path), "original exists")
	if path.is_empty(): return
	var before_hash := FileAccess.get_sha256(path)
	var original := read_pair(path)
	records.original_path = path
	records.original_sha256 = before_hash
	var migration := Migration.new()
	var upgraded: Dictionary
	if original.world.is_empty():
		upgraded = migration.upgrade_player_only(original.envelope)
	else:
		upgraded = migration.upgrade_pair(original.player, original.world, catalog)
	expect(not upgraded.is_empty(), "upgrade original: " + migration.error)
	if upgraded.is_empty(): return
	expect(strip_new_player(upgraded.player) == strip_new_player(original.player), "player all preexisting fields identical")
	expect(upgraded.player.rng == original.player.rng, "player RNG identical")
	expect(upgraded.player.run.studio_finance == original.player.run.studio_finance, "Bank/payroll/education/finance identical")
	expect(upgraded.player.run.release_metadata == original.player.run.release_metadata, "all old frozen Reviews unchanged")
	expect(upgraded.player.run.get("founding_roster_version") == original.player.run.get("founding_roster_version"), "founding provenance unchanged")
	if not original.world.is_empty():
		expect(strip_new_world(upgraded.world) == strip_new_world(original.world), "rival hands/cores/ownership/history/Founder/RNG identical")
		for row: Dictionary in upgraded.world.studios:
			if row.development != null:
				expect(row.development.project._market_details.historical and row.development.project._market_details.standards == row.development.project._market_details.base, "active old rival keeps base standards")
		var corrupt: Dictionary = original.world.duplicate(true)
		corrupt.source_identity = "unknown-source"
		expect(migration.upgrade_pair(original.player,corrupt,catalog).is_empty(), "unknown source rejected")
		corrupt = original.world.duplicate(true)
		corrupt.studios[0].run.content_revision = "bad-content"
		expect(migration.upgrade_pair(original.player,corrupt,catalog).is_empty(), "mixed rival content rejected")
		corrupt = original.world.duplicate(true)
		corrupt.market = {}
		expect(migration.upgrade_pair(original.player,corrupt,catalog).is_empty(), "mixed old/new world rejected")
		corrupt = original.world.duplicate(true)
		for row: Dictionary in corrupt.studios:
			if row.development != null:
				row.development.project._market_details = {}
				break
		if corrupt != original.world:
			expect(migration.upgrade_pair(original.player,corrupt,catalog).is_empty(), "mixed project fields rejected")
	var bad_player: Dictionary = original.player.duplicate(true)
	bad_player.run.cash_cents = str(int(bad_player.run.cash_cents) + 1)
	expect(migration.upgrade_store_player(bad_player).is_empty(), "old cash/finance corruption rejected")
	if not original.player.run.released_games.is_empty():
		bad_player = original.player.duplicate(true)
		bad_player.run.released_games[0].value.earned_units = str(int(bad_player.run.released_games[0].value.earned_units)+1)
		expect(migration.upgrade_store_player(bad_player).is_empty(), "old earned units corruption rejected")
		bad_player = original.player.duplicate(true)
		bad_player.run.released_games[0].value.market_factors = []
		expect(migration.upgrade_store_player(bad_player).is_empty(), "mixed old sales shape rejected")
	var combined: Dictionary = upgraded.player.duplicate(true)
	if not original.world.is_empty(): combined.rival_world = upgraded.world
	var stored_original: Dictionary = original.player.duplicate(true)
	if not original.world.is_empty(): stored_original.rival_world = original.world
	var directory := output + ".store"
	DirAccess.make_dir_recursive_absolute(directory)
	var sequence: int = int(stored_original.sequence)
	var old_path := directory.path_join("checkpoint.%d.json" % sequence)
	if original.get("store",false):
		expect(DirAccess.copy_absolute(path,old_path) == OK, "copy exact original store bytes")
	else:
		var file := FileAccess.open(old_path,FileAccess.WRITE)
		file.store_string(CheckpointCodec.new().envelope(stored_original))
		file.close()
	var old_hash := FileAccess.get_sha256(old_path)
	var c := coordinator(directory)
	var inspected := c.store.inspect()
	expect(inspected.status == &"valid", "normal Store recognizes validated old payload: " + str(inspected.get("reason","")))
	var restored := c.load_current()
	expect(restored != null, "normal Continue old generation: " + c.failure)
	if restored == null: c.store.release_writer();c.free();return
	expect(FileAccess.get_sha256(old_path) == old_hash and c.store._generations() == [sequence], "Continue preserves original bytes and generation")
	var roundtrip := StudioCheckpoint.new().capture(restored)
	expect(strip_new_player(roundtrip) == strip_new_player(original.player), "normal Continue exact player accounting/identity/RNG")
	if not original.world.is_empty():
		var world_roundtrip := WorldCodec.new().capture(c.rival_world)
		expect(strip_new_world(world_roundtrip) == strip_new_world(original.world), "normal Continue exact world hands/identity/RNG")
	# Exercise the normal coordinator publication, explicitly marking its next
	# Studio boundary pending. This is storage verification, not a player action.
	c.in_studio = true
	c.pending = true
	expect(c.flush(), "next ordinary pending Studio commit")
	expect(c.store._generations() == [sequence,sequence+1], "new content published only at following generation")
	expect(FileAccess.get_sha256(old_path) == old_hash, "old generation preserved through first upgraded commit")
	var committed := c.store.inspect()
	expect(committed.status == &"valid" and committed.payload.content_revision == StudioCheckpoint.new().revision(), "new generation carries current revision")
	if committed.status == &"valid":
		save_json(output + ".expected.json",committed.payload)
		records.cold_input = output + ".expected.json"
		records.cold_store = directory
	# Fault injection stays in this detached Store. Failed publication may leave
	# an ignored .tmp file; no generation or gameplay state may change.
	if label == "prior-world":
		c.store.fault = &"before_rename"
		var failed := c.store.save(committed.payload)
		expect(failed.status == &"io_error", "injected pre-rename write failure")
		expect(c.store._generations() == [sequence,sequence+1], "write failure preserves committed generations")
		expect(c.store.inspect().payload == committed.payload, "write failure retains exact latest state")
		c.store.fault = &""
		var corrupt_path := directory.path_join("checkpoint.%d.json" % (sequence+2))
		var file := FileAccess.open(corrupt_path,FileAccess.WRITE)
		file.store_string("deliberately damaged isolated generation")
		file.close()
		var backup := c.store.inspect()
		expect(backup.status == &"invalid" and backup.has("backup") and backup.backup.payload == committed.payload, "damaged latest yields validated backup without automatic restore")
		expect(c.store.recover_backup().status == &"saved", "explicit detached backup recovery publishes new generation")
		expect(FileAccess.file_exists(corrupt_path), "damaged evidence retained")
		var recovered := c.store.inspect()
		expect(strip_new_player(recovered.payload) == strip_new_player(committed.payload), "recovery exact player accounting")
		save_json(output + ".expected.json", recovered.payload)
	c.store.release_writer()
	c.free()
	expect(FileAccess.get_sha256(path) == before_hash, "original source file unchanged")

func cold() -> void:
	var input := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--input="): input = arg.trim_prefix("--input=")
	expect(not input.is_empty() and FileAccess.file_exists(input), "cold expected input exists")
	if input.is_empty(): return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input))
	var directory := input.trim_suffix(".expected.json") + ".store"
	var c := coordinator(directory)
	var state := c.store.inspect()
	expect(state.status == &"valid" and state.payload == expected, "fresh process sees exact committed payload")
	var generations := c.store._generations()
	var restored := c.load_current()
	expect(restored != null, "fresh process Continue")
	if restored != null:
		var actual := StudioCheckpoint.new().capture(restored)
		var player: Dictionary = expected.duplicate(true)
		player.erase("rival_world")
		actual.sequence = player.sequence
		expect(actual == player, "cold player all fields exact")
		if expected.has("rival_world"):
			expect(WorldCodec.new().capture(c.rival_world) == expected.rival_world, "cold world all fields exact")
	expect(c.store._generations() == generations, "cold Continue did not publish generation")
	c.store.release_writer()
	c.free()
