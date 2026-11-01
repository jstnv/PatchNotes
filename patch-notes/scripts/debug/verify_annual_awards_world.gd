extends SceneTree

var checks := 0
var failures := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	_test.call_deferred()

func _test() -> void:
	var world := RivalWorld.new()
	expect(world.has_method("get_annual_awards"), "World must own a durable annual award ledger")
	if not world.has_method("get_annual_awards"):
		quit(1)
		return
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var session = preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"annual-legal-player","studio_name":"Annual legal studio","specialty":"action","traits":["college_dropout"],"seed":"4417"},catalog)
	world = preload("res://scripts/market/rival_trial.gd").create_world(session.run,catalog)
	expect(world != null, "Actual certified eight-rival opening remains available")
	if world == null:
		quit(1)
		return
	var ledger := preload("res://scripts/awards/annual_awards_ledger.gd")
	var tampered := world.annual_awards.duplicate(true)
	tampered.first_year += 1
	expect(not ledger.valid(world,tampered), "Fresh inception cannot skip its first eligible year")
	var target := 96 if OS.get_environment("PN_AWARDS_SECOND_YEAR") == "1" else 48
	var policy = preload("res://scripts/simulation/finite_fixture_policy.gd").factory({"genre":"action","theme":"fantasy","name_prefix":"Award career","selection":"features_first","hands":{"design":1,"alpha":1,"beta":1}})
	for step in range(1000):
		if session.run.get_completed_run_cycles() >= target and session.in_studio: break
		if target == 96 and session.run.get_completed_run_cycles() == 48 and session.in_studio and not world.annual_awards.entries[0].complete:
			_save_fixture(session,world,OS.get_environment("PN_AWARDS_FIXTURE_OUTPUT")+".first-year.json")
			for page in range(9): expect(world.advance_awards_stage(), "Complete first ceremony page")
			expect(world.complete_awards_presentation(), "First ceremony completes before the next year")
		var choice: Dictionary = policy.call(session.observation())
		var result: Dictionary = session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		expect(result.get("ok",false), "Legal player command " + str(step))
		if not result.get("ok",false):
			print(result)
			break
		if session.run.get_completed_run_cycles() > world.cycle:
			var tick := world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(world),128)
			expect(tick.get("ok",false), "Committed rival/award boundary " + str(world.cycle))
			if not tick.get("ok",false):
				print(tick)
				break
			if world.cycle == 44: expect(world.annual_awards.entries.is_empty(), "Week1 has no ceremony")
			if world.cycle == 45:
				expect(world.annual_awards.entries.size() == 1, "Week2 settles exactly one annual result")
				if not world.annual_awards.entries.is_empty():
					var annual: Dictionary = world.annual_awards.entries[0]
					expect(annual.result.year == 1980 and annual.result.awards.size() == 7 and annual.stage == 0, "Seven frozen1980 awards and initial durable stage")
					var before := var_to_bytes(world.annual_awards)
					var rng: Dictionary = session.run.random_streams.snapshot()
					var again: Dictionary = preload("res://scripts/awards/annual_awards_ledger.gd").settle(world)
					expect(again.ok and not again.settled and var_to_bytes(world.annual_awards) == before and rng == session.run.random_streams.snapshot(), "Repeated adjudication is inert and RNG-free")
	expect(world.cycle == target and session.in_studio, "Legal career reaches target year and Studio")
	if target == 96: expect(world.annual_awards.entries.size() == 2 and world.annual_awards.entries[0].complete and not world.annual_awards.entries[1].complete, "Second-year pending ceremony preserves first completion")
	if not world.annual_awards.entries.is_empty():
		tampered = world.annual_awards.duplicate(true)
		tampered.entries[0].owners.clear()
		expect(not ledger.valid(world,tampered), "Missing frozen owners rejects without a crash")
		tampered = world.annual_awards.duplicate(true)
		tampered.entries[0].result.cutoff_cycle -= 1
		for owner: Dictionary in tampered.entries[0].owners: owner.offset += 1
		for game: Dictionary in tampered.entries[0].result.games: game.release_cycle -= 1
		expect(not ledger.valid(world,tampered), "Coordinated cutoff/offset forgery rejects")
	_save_fixture(session,world,OS.get_environment("PN_AWARDS_FIXTURE_OUTPUT"))
	print("ANNUAL_AWARDS_WORLD checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)

func _save_fixture(session, world: RivalWorld, output: String) -> void:
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var adapter := StudioCheckpoint.new()
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var player := adapter.capture(session.run)
	var saved := codec.capture(world)
	expect(not player.is_empty() and not saved.is_empty(), "Awarded paired snapshot validates: " + adapter.error + codec.error)
	if not player.is_empty() and not saved.is_empty():
		var restored = codec.restore(JSON.parse_string(JSON.stringify(saved)),JSON.parse_string(JSON.stringify(player)),adapter.hydrate(player),catalog)
		expect(restored != null, "Awarded paired cold Continue: " + codec.error)
		if restored != null:
			expect(restored.annual_awards == world.annual_awards, "Frozen rankings/rewards/stage survive cold Continue")
		if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":saved}))
