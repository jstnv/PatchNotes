## Analysis-only eight-rival timing fixture for a frozen simulator bundle.
## Synthetic archives are valid save records, not authored cohort proposals.
extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Trial := preload("res://scripts/market/rival_trial.gd")
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const RIVAL_COUNT := 8
const CYCLE_LIMIT := 12

var checks := 0
var failures := 0

func expect(value: bool, label: String) -> void:
	checks += 1
	if value:
		return
	failures += 1
	push_error("G4 eight-rival CPU: " + label)

func _initialize() -> void:
	await process_frame
	create_timer(180.0).timeout.connect(func() -> void: push_error("G4 eight-rival CPU internal timeout"); quit(2))
	var report: Dictionary = {
		"schema_version": "1", "fixture": "g4-eight-rival-cpu-v1",
		"measurement": "in-process elapsed microseconds; not processor CPU time",
		"synthetic_archives_test_only": true, "rival_count": RIVAL_COUNT,
		"cycle_limit": CYCLE_LIMIT, "zero_step_limit": Trial.ZERO_STEPS,
		"source_identity": Replay.source_identity(),
		"godot_version": Engine.get_version_info().string,
		"cycles": [], "rival_recipes": []
	}
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var player_recipe: Dictionary = {
		"schema_version": 1, "studio_id": "g4-cpu-player",
		"studio_name": "G4 CPU Player", "specialty": "action",
		"traits": [], "seed": "90901"
	}
	report.player_recipe = player_recipe.duplicate(true)
	var player: RefCounted = Factory.create_fresh_session(player_recipe, catalog)
	expect(player != null, "legal player Studio recipe")
	if player == null:
		_finish(report)
		return

	var sessions: Dictionary = {}
	var archive: Dictionary = {}
	for index in range(RIVAL_COUNT):
		var id := StringName("g4-cpu-rival-%02d" % index)
		var genre := "action" if index % 2 == 0 else "adventure"
		var rival_recipe: Dictionary = {
			"schema_version": 1, "studio_id": str(id),
			"studio_name": "G4 CPU Rival %02d" % index,
			"specialty": genre,
			"traits": ["family_funding", "cult_following"],
			"seed": str(4417 + index * 1009)
		}
		report.rival_recipes.append(rival_recipe.duplicate(true))
		var session: RefCounted = Factory.create_fresh_session(rival_recipe, catalog)
		expect(session != null, "legal rival Studio recipe %d" % index)
		if session == null:
			_finish(report)
			return
		sessions[id] = session
		archive[id] = [{
			"id": StringName("g4-cpu-history-%02d" % index),
			"title": "G4 CPU History %02d" % index,
			"year": 1979, "genre": StringName(genre),
			"theme": &"fantasy", "review_tenths": 70
		}]

	var world := RivalWorld.new()
	expect(world.initialize(player.run, sessions), "eight independent rival Studios initialize")
	if world.player == null:
		_finish(report)
		return
	world.historical_archive = archive
	var policies: Dictionary = Trial.policies(world)
	expect(world.studios.size() == RIVAL_COUNT and policies.size() == RIVAL_COUNT, "eight finite trial policies")
	report.initial_state_digest = _state_digest(world)
	report.initial_rng_digest = _rng_digest(world)
	report.static_bytes_after_setup = OS.get_static_memory_usage()
	var starting_codec := WorldCodec.new()
	var starting_payload: Dictionary = starting_codec.capture(world)
	expect(not starting_payload.is_empty(), "eight-rival starting Studio world is save-valid: " + starting_codec.error)
	if starting_payload.is_empty():
		_finish(report)
		return
	var player_codec := StudioCheckpoint.new()
	var player_payload: Dictionary = player_codec.capture(player.run)
	expect(not player_payload.is_empty(), "starting player Studio checkpoint")
	if not player_payload.is_empty():
		expect(starting_codec.validate(starting_payload, player_payload).is_empty(), "starting eight-rival world validates with player")
	if failures > 0:
		_finish(report)
		return

	for index in range(CYCLE_LIMIT):
		var previous_cycle: int = player.run.get_completed_run_cycles()
		var player_start: int = Time.get_ticks_usec()
		var player_ok: bool = player.run.complete_productive_action(Callable(), 0, previous_cycle)
		var player_elapsed: int = Time.get_ticks_usec() - player_start
		expect(player_ok, "player productive boundary %d" % (index + 1))
		if not player_ok:
			break
		var world_start: int = Time.get_ticks_usec()
		var result: Dictionary = world.advance_committed_player_cycle(policies, Trial.ZERO_STEPS)
		var world_elapsed: int = Time.get_ticks_usec() - world_start
		expect(result.get("ok", false), "world advance %d: %s" % [index + 1, str(result.get("reason", ""))])
		if not result.get("ok", false):
			break
		expect(world.cycle == player.run.get_completed_run_cycles(), "player/rival calendar sync %d" % (index + 1))
		var blocked: Array = []
		var productive_count := 0
		for studio: Dictionary in result.get("studios", []):
			if studio.get("productive", false):
				productive_count += 1
			if not str(studio.get("blocked_reason", "")).is_empty():
				blocked.append({"studio_id": str(studio.studio_id), "reason": str(studio.blocked_reason)})
		report.cycles.append({
			"cycle": world.cycle,
			"player_productive_elapsed_us": player_elapsed,
			"world_advance_elapsed_us": world_elapsed,
			"productive_rivals": productive_count,
			"blocked": blocked,
			"new_releases": result.get("new_releases", []).size(),
			"total_live_releases": world.live_releases.size(),
			"static_bytes_after_advance": OS.get_static_memory_usage(),
			"state_digest": _state_digest(world),
			"rng_digest": _rng_digest(world)
		})

	expect(report.cycles.size() == CYCLE_LIMIT, "all 12 committed calendar cycles complete")
	report.final_state_digest = _state_digest(world)
	report.final_rng_digest = _rng_digest(world)
	report.final_live_releases = _release_rows(world)
	report.static_bytes_at_end = OS.get_static_memory_usage()
	report.peak_static_bytes = OS.get_static_memory_peak_usage()
	var codec := WorldCodec.new()
	var payload: Dictionary = codec.capture(world)
	expect(not payload.is_empty(), "final eight-rival Studio world is save-valid: " + codec.error)
	if not payload.is_empty():
		report.world_payload_json_utf8_bytes = JSON.stringify(payload).to_utf8_buffer().size()
		var final_player: Dictionary = StudioCheckpoint.new().capture(player.run)
		expect(not final_player.is_empty(), "final player Studio checkpoint")
		if not final_player.is_empty():
			expect(codec.validate(payload, final_player).is_empty(), "final eight-rival world validates with player")
	_finish(report)

func _state_digest(world: RivalWorld) -> String:
	var rows: Dictionary = {}
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	for id: StringName in ids:
		rows[str(id)] = Replay.digest(Replay.state(world.studios[id]))
	return Replay.digest({"player": Replay.digest(world.player),
		"world": Replay.digest(world.observation()), "studios": rows})

func _rng_digest(world: RivalWorld) -> String:
	var rows: Dictionary = {"player": world.player.random_streams.snapshot()}
	var ids: Array = world.studios.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	for id: StringName in ids:
		rows[str(id)] = world.studios[id].run.random_streams.snapshot()
	return Replay.digest(rows)

func _release_rows(world: RivalWorld) -> Array:
	var rows: Array = []
	for item: Dictionary in world.observation().live_releases:
		rows.append({"studio_id": str(item.studio_id),
			"release_id": str(item.release_id),
			"release_cycle": int(item.release_cycle),
			"review_tenths": int(item.review_tenths)})
	return rows

func _finish(report: Dictionary) -> void:
	report.checks = checks
	report.failures = failures
	report.ok = failures == 0 and report.cycles.size() == CYCLE_LIMIT
	var destination := OS.get_environment("PN_G4_WORLD_CPU_REPORT")
	if destination.is_empty():
		push_error("G4 eight-rival CPU report destination missing")
		quit(2)
		return
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		push_error("G4 eight-rival CPU report cannot be written")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	var wrote: bool = file.get_error() == OK
	file.close()
	if not wrote:
		push_error("G4 eight-rival CPU report write failed")
		quit(2)
		return
	print("G4_EIGHT_RIVAL_CPU checks=%d failures=%d cycles=%d releases=%d" % [
		checks, failures, report.cycles.size(), report.get("final_live_releases", []).size()])
	quit(0 if report.ok else 1)
