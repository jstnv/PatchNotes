extends SceneTree
## Compare the live replay validator to the exact pre-optimization implementation.
## Large real-shaped fixtures are optional and must be explicit private paths.
const Prior := preload("res://scripts/debug/fixtures/studio_fanbase_before_private_replay.gd")
const Market := preload("res://scripts/market/market_transaction_trial.gd")
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Awards := preload("res://scripts/awards/award_receipts.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func clear_proofs() -> void:
	# This isolated, single-threaded test intentionally compares cold verdicts.
	Prior._replays.clear(); Prior._replay_bytes = 0
	StudioFanbase._replays.clear(); StudioFanbase._replay_bytes = 0
	ReleasedGameSales._validated_records.clear(); ReleasedGameSales._validated_lookup.clear(); ReleasedGameSales._validated_record_bytes = 0
	ReleasedGameSales._factor_history_proofs.clear(); ReleasedGameSales._factor_history_order.clear(); ReleasedGameSales._factor_history_bytes = 0
	Market._factor_proofs.clear(); Market._factor_order.clear(); Market._factor_bytes = 0

func compare(label: String, state: Dictionary, records: Dictionary, metadata: Dictionary, cycle: int, starting: int, closed: Dictionary, close: int, expected: bool) -> void:
	var before := var_to_bytes([state, records, metadata, closed])
	clear_proofs()
	var old := Prior.validate(state, records, metadata, cycle, starting, closed, close)
	var middle := var_to_bytes([state, records, metadata, closed])
	clear_proofs()
	var current := StudioFanbase.validate(state, records, metadata, cycle, starting, closed, close)
	var after := var_to_bytes([state, records, metadata, closed])
	check(old == expected and current == old and before == middle and middle == after, label)

func fixture(close: int = -1) -> Dictionary:
	var state := StudioFanbase.create()
	var record := ReleasedGameSales.create(&"sample", 800, 70, 100, 10000)
	state = StudioFanbase.register_release(state, record, 0)
	var records := {&"sample": record}
	var metadata := {&"sample": {"release_cycle": 0, "review": {"launch_fans": 0, "fan_awareness": 0}}}
	var closed := {&"sample": true} if close >= 0 else {}
	for cycle in range(1, 9):
		var next := {}
		if close >= 0 and cycle > close:
			next[&"sample"] = records[&"sample"].duplicate(true)
		else:
			next[&"sample"] = ReleasedGameSales.next_cycle(records[&"sample"], cycle, cycle % 2 == 0)
		state = StudioFanbase.plan(state, records, next, cycle, closed if close >= 0 and cycle > close else {})
		records = next
	return {"state": state, "records": records, "metadata": metadata, "closed": closed, "close": close}

func compare_fixture(path: String, rival: bool) -> void:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary or not value.has("player") or (rival and not value.has("world")):
		check(false, "Private fixture is readable")
		return
	var adapter := StudioCheckpoint.new()
	var payload: Dictionary = value.world.studios[0].run if rival else value.player
	var decoded: Dictionary = adapter._decode_payload(payload, rival)
	if decoded.is_empty():
		check(false, "Private fixture decodes: " + adapter.error)
		return
	var r: Dictionary = decoded.run
	compare("Private %s full ledger" % ("rival" if rival else "player"), r.fanbase, r.released_games, r.release_metadata, r.completed_run_cycles, StudioTraits.starting_fans(r.studio_traits), r.closed_historical_ids, r.historical_close_cycle, true)
	var altered: Dictionary = r.fanbase.duplicate(true)
	altered.fans += 1
	compare("Private %s forged fans" % ("rival" if rival else "player"), altered, r.released_games, r.release_metadata, r.completed_run_cycles, StudioTraits.starting_fans(r.studio_traits), r.closed_historical_ids, r.historical_close_cycle, false)

func run() -> void:
	for close in [-1, 4]:
		var f := fixture(close)
		check(not f.state.is_empty(), "Synthetic ledger built (closure %d)" % close)
		if f.state.is_empty(): continue
		compare("Exact ledger replay (closure %d)" % close, f.state, f.records, f.metadata, 8, 0, f.closed, f.close, true)
		var wrong: Dictionary = f.state.duplicate(true)
		wrong.fans += 1
		compare("Forged fans rejected (closure %d)" % close, wrong, f.records, f.metadata, 8, 0, f.closed, f.close, false)
		wrong = f.state.duplicate(true)
		wrong.months[0].gained += 1
		compare("Forged month rejected (closure %d)" % close, wrong, f.records, f.metadata, 8, 0, f.closed, f.close, false)
		var invalid: Dictionary = f.records.duplicate(true)
		invalid[&"sample"].earned_units += 1
		compare("Forged sales rejected (closure %d)" % close, f.state, invalid, f.metadata, 8, 0, f.closed, f.close, false)
	var annual := StudioFanbase.plan(StudioFanbase.create(0, Clock.fresh()), {}, {}, 1)
	var receipt := {"id": &"annual-awards:1980", "year": 1980, "cycle": 1, "nominations": 1, "wins": 1, "fans": 50, "awareness": 5, "before": []}
	annual = Awards.plan(annual, receipt)
	check(not annual.is_empty(), "Annual-award fixture built")
	if not annual.is_empty():
		compare("Annual-award ledger replays exactly", annual, {}, {}, 1, 0, {}, -1, true)
		var forged := annual.duplicate(true)
		forged.annual_awards[0].fans += 1
		compare("Forged annual award rejected", forged, {}, {}, 1, 0, {}, -1, false)
	var state := StudioFanbase.create()
	var before := var_to_bytes(state)
	var old := Prior.plan(state, {}, {}, 1)
	var current := StudioFanbase.plan(state, {}, {}, 1)
	check(old == current and not current.is_empty() and var_to_bytes(state) == before, "Public plan returns matching detached output")
	var original := ReleasedGameSales.create(&"a", 100, 70, 0, 10000)
	state = StudioFanbase.register_release(state, original, 0)
	var previous := {&"a": original}
	var next := {&"a": ReleasedGameSales.next_cycle(original, 1, false), &"z": {}}
	before = var_to_bytes([state, previous, next])
	old = Prior.plan(state, previous, next, 1)
	current = StudioFanbase.plan(state, previous, next, 1)
	check(old.is_empty() and current.is_empty() and var_to_bytes([state, previous, next]) == before, "Mid-plan failure is atomic for all public inputs")
	var path := OS.get_environment("PN_FANBASE_REPLAY_FIXTURE")
	if not path.is_empty():
		compare_fixture(path, false)
		compare_fixture(path, true)
	var legacy := OS.get_environment("PN_FANBASE_LEGACY_FIXTURE")
	if not legacy.is_empty(): compare_fixture(legacy, false)
	print("FANBASE_PRIVATE_REPLAY checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
