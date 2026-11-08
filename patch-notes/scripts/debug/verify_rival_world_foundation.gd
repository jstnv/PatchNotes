extends SceneTree

const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
const World := preload("res://scripts/market/rival_world.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

var checks := 0
var failures := 0

func expect(condition: bool, label: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error("Rival foundation: " + label)

func recipe(id: String, specialty: String, seed_value: String) -> Dictionary:
	return {"schema_version":1,"studio_id":id,"studio_name":id,"specialty":specialty,"traits":[],"seed":seed_value}

func policy(specialty: String, prefix: String) -> Callable:
	return Fixture.factory({"genre":specialty,"theme":"fantasy","name_prefix":prefix,"selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})

func _initialize() -> void:
	await process_frame
	create_timer(20.0).timeout.connect(func() -> void: push_error("Rival foundation verifier timed out"); quit(2))
	var cards = root.get_node("CardDatabase")
	var catalog: RefCounted = cards.get_development_catalog()
	var player: RefCounted = Factory.create_fresh_session(recipe("foundation-player","action","1001"),catalog)
	var action: RefCounted = Factory.create_fresh_session(recipe("foundation-action","action","2002"),catalog)
	var adventure: RefCounted = Factory.create_fresh_session(recipe("foundation-adventure","adventure","3003"),catalog)
	expect(player != null and action != null and adventure != null,"three independent legal Studios bootstrap")
	if player == null or action == null or adventure == null: quit(1); return
	var world: RefCounted = World.new()
	expect(world.initialize(player.run,{&"foundation-action":action,&"foundation-adventure":adventure}),"shared world accepts unique independent ledgers")
	var duplicate: RefCounted = World.new()
	expect(not duplicate.initialize(player.run,{&"foundation-action":action,&"other":action}),"shared RunState cannot be registered twice")
	var before: Dictionary = world.observation()
	expect(not world.advance_committed_player_cycle({},8).ok and world.observation() == before,"menu/failed action cannot advance rivals")
	var p := policy("action","Player")
	var a := policy("action","Action")
	var b := policy("adventure","Adventure")
	var total_releases := 0
	for index in range(15):
		var prior: int = player.run.get_completed_run_cycles()
		var reached := false
		for step in range(12):
			var chosen: Dictionary = p.call(player.observation())
			var player_result: Dictionary = player.execute(player.command(StringName(chosen.type),chosen.get("payload",{})))
			expect(player_result.ok,"player fixture follows actual campaign commands")
			if not player_result.ok: break
			if player.run.get_completed_run_cycles() == prior + 1:
				reached = true
				break
		expect(reached,"player commits exactly one productive cycle")
		if not reached: break
		if index == 0:
			var unchanged: Dictionary = world.observation()
			expect(not world.advance_committed_player_cycle({&"foundation-action":a,&"foundation-adventure":b},0).ok and world.observation() == unchanged,"missing zero-step bound rejects before world mutation")
		var result: Dictionary = world.advance_committed_player_cycle({&"foundation-action":a,&"foundation-adventure":b},8)
		expect(result.ok,"rivals settle the same committed calendar cycle")
		if not result.ok: break
		expect(world.cycle == player.run.get_completed_run_cycles() and action.run.get_completed_run_cycles() == world.cycle and adventure.run.get_completed_run_cycles() == world.cycle,"three clocks agree")
		for studio: Dictionary in result.studios:
			var count := 0
			for entry: Dictionary in studio.actions:
				for event: Dictionary in entry.events:
					if event.get("type") == "productive_cycle": count += 1
			expect(count <= 1,"at most one productive rival action")
		for release: Dictionary in result.new_releases:
			total_releases += 1
			expect(release.release_cycle <= world.cycle and release.release_id in world.live_releases,"actual frozen release enters world history once")
			var owner: RefCounted = action if release.studio_id == &"foundation-action" else adventure
			var sales: Dictionary = owner.run.get_released_game_sales(release.release_id)
			expect(owner.run.get_release_metadata(release.release_id).release_cycle == release.release_cycle and sales.review_tenths == release.review_tenths,"world Review comes from legal release")
			expect(sales.earned_cycles == 0 and sales.entitlement_cents == 0,"new rival release earns no same-boundary sales")
		var stable: Dictionary = world.observation()
		expect(not world.advance_committed_player_cycle({&"foundation-action":a,&"foundation-adventure":b},8).ok and world.observation() == stable,"same player cycle cannot grant a second turn")
	expect(total_releases >= 2 and action.run.get_released_game_ids().size() >= 1 and adventure.run.get_released_game_ids().size() >= 1,"both rivals complete actual Design, Alpha, Beta and launch")
	expect(action.run._bank_run_id != adventure.run._bank_run_id and action.run._studio_finance != adventure.run._studio_finance and action.run.random_streams.snapshot() != adventure.run.random_streams.snapshot(),"finance and RNG remain independent")
	var player_cycle: int = player.run.get_completed_run_cycles()
	for step in range(12):
		var chosen: Dictionary = p.call(player.observation())
		var committed: Dictionary = player.execute(player.command(StringName(chosen.type),chosen.get("payload",{})))
		expect(committed.ok,"blocked-state control player command is legal")
		if not committed.ok or player.run.get_completed_run_cycles() == player_cycle + 1: break
	var rng_before: Dictionary = adventure.run.random_streams.snapshot()
	var release_count: int = adventure.run.get_released_game_ids().size()
	var blocked_policy := func(_view: Dictionary) -> Dictionary: return {"type":&"unsupported"}
	var blocked: Dictionary = world.advance_committed_player_cycle({&"foundation-action":a,&"foundation-adventure":blocked_policy},8)
	expect(blocked.ok and blocked.studios[1].blocked_reason == "No legal policy choice" and not blocked.studios[1].productive,"invalid rival choice becomes an explicit idle turn")
	expect(adventure.run.random_streams.snapshot() == rng_before and adventure.run.get_released_game_ids().size() == release_count,"blocked choice mints no RNG or release")
	print("RIVAL_WORLD_FOUNDATION checks=%d failures=%d cycles=%d releases=%d digest=%s" % [checks,failures,world.cycle,total_releases,Replay.digest({"world":world.observation(),"player":Replay.state(player),"action":Replay.state(action),"adventure":Replay.state(adventure)})])
	quit(0 if failures == 0 else 1)
