## Read-only constructed domain probe. Run against the bd450a9 source snapshot.
extends SceneTree

var checks: Array[Dictionary] = []
var failures := 0
var trace: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks.append({"label": label, "pass": ok})
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func _records_next(previous: Dictionary, cycle: int) -> Dictionary:
	var next := {}
	for id: StringName in previous:
		next[id] = ReleasedGameSales.next_cycle(previous[id], cycle, cycle % 2 == 0)
		check(not next[id].is_empty(), "Native sales record advances: %s cycle %d" % [id, cycle])
	return next

func _weak_multimonth() -> Dictionary:
	var state := StudioFanbase.create()
	state.fans = 10000
	var record := ReleasedGameSales.create(&"weak", 400, 40, 100, 10000)
	state = StudioFanbase.register_release(state, record, 10000)
	check(not state.is_empty(), "Weak constructed release registers")
	var previous := {&"weak": record}
	var rows: Array[Dictionary] = []
	var flat_seen := false
	var previous_boundary_reach := 0
	for cycle in range(1, 41):
		var before := state.duplicate(true)
		var next := _records_next(previous, cycle)
		state = StudioFanbase.plan(state, previous, next, cycle)
		check(not state.is_empty(), "Weak fan preflight accepts cycle %d" % cycle)
		if state.is_empty(): break
		if cycle % 2 == 0:
			var entry: Dictionary = state.releases[&"weak"]
			var reach := int(entry.neutral.earned_units)
			var target := reach * 15 / 100
			var row: Dictionary = state.months[-1]
			check(int(entry.loss_exposure_accounted) == target, "Cumulative target matches trial rate at month %d" % (cycle / 2))
			check(int(row.lost) == target - int(before.releases[&"weak"].loss_exposure_accounted), "Only incremental target is charged at month %d" % (cycle / 2))
			check(int(row.ending) == 10000 - target and row.gained == 0, "Ending Fans reconcile at month %d" % (cycle / 2))
			rows.append({"cycle": cycle, "actual_cumulative_units": next[&"weak"].earned_units,
				"neutral_cumulative_reach": reach, "neutral_monthly_units": reach - previous_boundary_reach,
				"cumulative_loss_target": target, "ledger": row.duplicate(true)})
			# Replay and lossless dictionary reconstruction preserve cycle identity.
			var frozen := state.duplicate(true)
			check(StudioFanbase.plan(state, previous, next, cycle).is_empty() and state == frozen, "Repeated callback rejects without mutation at month %d" % (cycle / 2))
			var rebuilt: Dictionary = bytes_to_var(var_to_bytes(state))
			check(rebuilt == state, "Lossless snapshot reconstructs at month %d" % (cycle / 2))
			check(StudioFanbase.plan(rebuilt, previous, next, cycle).is_empty() and rebuilt == frozen, "Reconstructed repeated callback rejects at month %d" % (cycle / 2))
			var later := _records_next(next, cycle + 1)
			check(StudioFanbase.plan(rebuilt, next, later, cycle + 1) == StudioFanbase.plan(state, next, later, cycle + 1), "Reconstructed next callback matches uninterrupted state at month %d" % (cycle / 2))
			if rows.size() > 2 and reach == int(rows[-2].neutral_cumulative_reach):
				check(row.lost == 0, "Flat reach causes zero additional loss")
				flat_seen = true
				break
			previous_boundary_reach = reach
		previous = next
	check(rows.size() >= 3 and rows[1].neutral_cumulative_reach > rows[0].neutral_cumulative_reach, "At least two months grow estimated reach")
	check(flat_seen, "Native decay reaches a flat cumulative-reach month within the bound")
	return {"inputs": {"starting_fans": 10000, "review_tenths": 40, "month_one_units": 400, "awareness": 100, "market_bp": 10000}, "rows": rows, "final": state}

func _concurrent(with_gain: bool, reverse: bool) -> Dictionary:
	var state := StudioFanbase.create()
	state.fans = 10
	var a := ReleasedGameSales.create(&"poor_a", 0, 0, 100, 10000)
	var b := ReleasedGameSales.create(&"poor_b", 0, 0, 100, 10000)
	var previous: Dictionary = {&"poor_b": b, &"poor_a": a} if reverse else {&"poor_a": a, &"poor_b": b}
	if with_gain:
		previous[&"gain_c"] = ReleasedGameSales.create(&"gain_c", 1000, 70, 100, 10000)
	for id: StringName in previous:
		state = StudioFanbase.register_release(state, previous[id], 10)
		check(not state.is_empty(), "Concurrent fixture registers %s" % id)
	for cycle in range(1, 5):
		var next := _records_next(previous, cycle)
		state = StudioFanbase.plan(state, previous, next, cycle)
		check(not state.is_empty(), "Concurrent fan preflight accepts cycle %d" % cycle)
		previous = next
	var row: Dictionary = state.months[0]
	var requested: int = state.releases[&"poor_a"].loss_exposure_accounted + state.releases[&"poor_b"].loss_exposure_accounted
	var detail_lost := 0
	for detail: Dictionary in row.releases: detail_lost += int(detail.lost_fans)
	check(requested == 14 and requested > 10, "Two cumulative trial targets exceed starting Fans")
	check(row.starting == 10 and row.lost == 10 and detail_lost == 10, "Concurrent losses use and cap at the shared ten-Fan snapshot")
	check(row.ending == row.gained and row.ending >= 0, "Same-boundary gain does not enlarge loss capacity")
	check(state.months[1].lost == 0, "Accounted weak exposure does not charge again next month")
	if with_gain: check(row.gained == 79 and row.ending == 79, "79 simultaneous gains survive the ten-Fan loss cap")
	else: check(row.gained == 0 and row.ending == 0, "Loss-only concurrent arm ends at zero")
	return {"with_gain": with_gain, "reverse_insertion": reverse, "requested_loss_target": requested, "months": state.months, "final": state}

func _neutral() -> Dictionary:
	var state := StudioFanbase.create()
	state.fans = 1000
	var record := ReleasedGameSales.create(&"neutral", 750, 50, 100, 10000)
	state = StudioFanbase.register_release(state, record, 1000)
	var previous := {&"neutral": record}
	for cycle in range(1, 5):
		var next := _records_next(previous, cycle)
		state = StudioFanbase.plan(state, previous, next, cycle)
		check(not state.is_empty(), "Neutral fan preflight accepts cycle %d" % cycle)
		previous = next
	for row: Dictionary in state.months:
		check(row.gained == 0 and row.lost == 0 and row.ending == 1000, "Review 5.0 remains neutral with existing Fans and sales")
	return {"inputs": {"fans": 1000, "review_tenths": 50, "units": 750}, "months": state.months}

func _run() -> void:
	trace["weak_multimonth"] = _weak_multimonth()
	trace["concurrent_loss"] = _concurrent(false, false)
	trace["concurrent_gain_loss"] = _concurrent(true, false)
	trace["reverse_concurrent_gain_loss"] = _concurrent(true, true)
	check(trace.concurrent_gain_loss.months == trace.reverse_concurrent_gain_loss.months, "Concurrent result is independent of input insertion order")
	trace["neutral"] = _neutral()
	trace["checks"] = checks
	trace["failures"] = failures
	trace["engine"] = Engine.get_version_info()
	trace["source_sha256"] = {}
	for path: String in ["res://scripts/fanbase/studio_fanbase.gd", "res://scripts/sales/released_game_sales.gd", "res://scripts/debug/verify_studio_fanbase.gd"]:
		trace.source_sha256[path] = FileAccess.get_sha256(path)
	var output := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.substr(9)
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write declared trace path")
		quit(2)
		return
	file.store_string(JSON.stringify(trace, "  "))
	print("Incremental loss: %d checks, %d failures" % [checks.size(), failures])
	quit(0 if failures == 0 else 1)
