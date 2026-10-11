extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")
const Original := preload("res://scripts/debug/fixtures/replay_before_m4b.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Fixture := preload("res://scripts/simulation/finite_fixture_policy.gd")
var checks := 0
var failures := 0

class Probe extends RefCounted:
	var nested := {"items":[3,{"value":7}]}
	var random := RandomNumberGenerator.new()

func expect(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+message)

func compare(session: RefCounted) -> void:
	var old_state := Original.state(session)
	var new_state := Replay.state(session)
	expect(JSON.stringify(old_state) == JSON.stringify(new_state),"Canonical state matches independent pre-optimization projection")
	expect(Original.digest(old_state) == Replay.digest(new_state),"Exact state digest unchanged")

func _initialize() -> void:
	await process_frame
	var probe := Probe.new()
	probe.random.seed = 921
	var repeated: Array = [probe,{"again":probe}]
	var projected: Array = Replay.freeze(repeated)
	expect(JSON.stringify(projected) == JSON.stringify(Original.freeze(repeated)),"Repeated mutable Object, RNG, nested arrays project identically")
	projected[0].nested.items[1].value.integer = "999"
	expect(projected[1].again.nested.items[1].value.integer == "7" and probe.nested.items[1].value == 7,"Cached occurrences remain deeply detached from each other and authority")
	var previous := Replay.digest(repeated)
	probe.nested.items[1].value = 11
	probe.random.randi()
	expect(Replay.digest(repeated) != previous and Replay.digest(repeated) == Original.digest(repeated),"No cached data survives a new call or live nested/RNG mutation")
	var typed: Array[StringName] = [&"sound",&"graphics"]
	var values: Array = [RunState.MAX_SIGNED_INT,-RunState.MAX_SIGNED_INT,0.0,-0.0,INF,-INF,NAN,typed,{3:&"integer_key"},null]
	expect(JSON.stringify(Replay.freeze(values)) == JSON.stringify(Original.freeze(values)),"Int64, float bit patterns, StringName, typed arrays and dictionary keys unchanged")
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var card: CardData = catalog.cards.values()[0]
	expect(Replay.freeze(card) == str(card.id),"CardData special projection remains its ID")
	var initial := {"recipe":{"schema_version":1,"studio_id":"efficiency","studio_name":"Efficiency fixture","specialty":"action","traits":[],"seed":"4417"}}
	var session: RefCounted = Factory.create(initial,catalog)
	var policy := Fixture.factory({"genre":"action","theme":"fantasy","name_prefix":"Efficiency game","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	compare(session)
	var commands := 0
	for _step in range(100):
		if session.in_studio and session.run.get_released_game_ids().size() >= 2: break
		var choice: Dictionary = policy.call(session.observation())
		var result: Dictionary = session.execute(session.command(StringName(choice.type),choice.get("payload",{})))
		expect(result.ok,"Fixture legal command accepted")
		commands += 1
		compare(session)
		if commands == 1:
			var random: RandomNumberGenerator = session.run.random_streams.stream(&"design_deal")
			var old_seed: int = random.seed
			var old_state: int = random.state
			random.seed = 812
			compare(session)
			random.seed = old_seed
			random.state = old_state
	expect(session.in_studio and session.run.get_released_game_ids().size() == 2,"Two-release projection route reaches Studio")
	var before := Replay.digest(Replay.state(session))
	var checkpoint: Dictionary = session.export_checkpoint()
	var restored: RefCounted = Factory.create({"checkpoint":checkpoint},catalog)
	expect(restored != null and Replay.digest(Replay.state(restored)) == before,"Studio checkpoint survives projection optimization unchanged")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"ok":failures == 0,"checks":checks,"failures":failures,"commands":commands},"\t"))
	print("Simulation efficiency verification: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
