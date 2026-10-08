## Read-only Promotion sensitivity against pinned Task 34 typed captures.
extends "res://analysis/task34_cohort_advance_v3.gd"

func _run() -> void:
	var input_path := _arg("--input=", "")
	var output_path := _arg("--out=", "")
	var publisher := _arg("--publisher=", "")
	var expected_capture := "83e8df43cb78f9913b634c67c55c71cfd697a3ea80e8af4b989b6556644c776c" if publisher == "crown" else "5c19295b148c3aef24377423d36f24d24f06d4c0849ec94630d76c12ff415a33"
	_check(publisher in ["crown", "neon"], "Declared publisher")
	_check(FileAccess.file_exists(input_path), "Typed capture exists")
	_check(FileAccess.get_sha256(input_path) == expected_capture, "Exact typed capture hash")
	_check(FileAccess.get_sha256("res://analysis/task34_cohort_advance_v3.gd") == "44656d1b7aefbb975a4d28d406830686f92bc881e8ca235c0d48b06bbffa3824", "Pinned continuation harness hash")
	_check(FileAccess.get_sha256("res://analysis/task34_advance_v3.gd") == "e6e163d5d9ef42d393b5563febdb8c9006785ac43954917993a3f254aa010970", "Pinned Contract harness hash")
	if not failures.is_empty():
		_finish(output_path, publisher, [], 2)
		return

	var checkpoints: Array = FileAccess.open(input_path, FileAccess.READ).get_var()
	var key := "crown_quill" if publisher == "crown" else "neon_circuit"
	var first: Dictionary = {}
	var late: Dictionary = {}
	for x: Dictionary in checkpoints:
		if not str(x.label).begins_with("release"):
			continue
		if x.publishers[key].unlocked and first.is_empty():
			first = x
		if x.label == "release4" and x.publishers[key].unlocked:
			late = x
	_check(not first.is_empty() and not late.is_empty(), "Native early and Game 4 eligibility")
	if not failures.is_empty():
		_finish(output_path, publisher, [], 2)
		return

	var phase := ContractPhase.new()
	root.add_child(phase)
	var results: Array = []
	for item: Dictionary in [{"timing":"early", "checkpoint":first}, {"timing":"after_game4", "checkpoint":late}]:
		var x: Dictionary = item.checkpoint
		var neon_unlocked_before: bool = x.publishers.neon_circuit.unlocked
		var no_insertion := _continue(x, {"ledger":x.ledger.duplicate(true), "records":x.records.duplicate(true), "accepted":false, "completed":false}, checkpoints, 0)
		_check(no_insertion.block.is_empty(), "No-insertion suffix accepted")
		_check(no_insertion.ledger == checkpoints[-1].ledger, "No-insertion native finance parity")
		_check(no_insertion.records == checkpoints[-1].records, "No-insertion native sales parity")

		var target := 9 if publisher == "crown" else 10
		var advance := 15000 if publisher == "crown" else 0
		var seed_value := 200929001 if publisher == "crown" else 200929000
		var caps := [0,6,12,18] if publisher == "crown" else [0,10,20,30]
		var contract := _arm(x, phase, publisher, target, advance, "ordinary", seed_value)
		_check(contract.completed, "Legal two-hand Contract completion")
		_check(contract.hands.size() == 2 and contract.hands[0].success and contract.hands[1].success, "Both native hands succeeded")
		var fraction: Array = contract.fraction
		var ctx := {"ledger":contract.ledger, "records":contract.records, "accepted":true, "completed":contract.completed}
		var cash_only := _continue(x, ctx, checkpoints, 0)
		_check(cash_only.block.is_empty(), "Cash-only suffix accepted")
		var rows: Array = []
		var prior_points := -1
		var prior_earned := -1
		var prior_settled := -1
		var prior_cash := -1
		for cap: int in caps:
			var points: int = cap * int(fraction[0]) / int(fraction[1])
			var continuation := _continue(x, ctx, checkpoints, points)
			_check(continuation.block.is_empty(), "Promotion suffix accepted")
			_check(continuation.final.cycle == cash_only.final.cycle, "Common native action calendar")
			_check(continuation.launches.size() == cash_only.launches.size(), "Same subsequent successful launches")
			_check(continuation.rows.size() == cash_only.rows.size(), "Same accepted action suffix")
			_check(continuation.finance_report.available, "Native finance journal replay")
			var applied := 0
			for launch: Dictionary in continuation.launches:
				applied += int(launch.promotion)
			_check(applied + int(continuation.promotion_pending) == points, "Promotion applied once or remains banked")
			_check(points >= prior_points and continuation.final.earned >= prior_earned and continuation.final.settled >= prior_settled and continuation.final.cash >= prior_cash, "Monotonic points and native earnings")
			if cap == 0:
				_check(continuation == cash_only, "Zero cap is exact cash-only control")
			prior_points = points
			prior_earned = continuation.final.earned
			prior_settled = continuation.final.settled
			prior_cash = continuation.final.cash
			rows.append({
				"cap":cap, "awarded_points":points, "promotion_pending":continuation.promotion_pending,
				"next_launch":continuation.launches[0] if not continuation.launches.is_empty() else {},
				"next_launch_meets_neon_awareness_gate":not continuation.launches.is_empty() and int(continuation.launches[0].awareness) >= 125,
				"launches":continuation.launches, "final":continuation.final,
				"earned_delta_cents":int(continuation.final.earned) - int(cash_only.final.earned),
				"settled_delta_cents":int(continuation.final.settled) - int(cash_only.final.settled),
				"cash_delta_cents":int(continuation.final.cash) - int(cash_only.final.cash)})
		results.append({"timing":item.timing,"checkpoint":x.label,"acceptance_cycle":x.cycle,
			"neon_unlocked_before":neon_unlocked_before,
			"target_scope":target,"advance_cents":advance,"policy":"ordinary","seed":seed_value,
			"completion_fraction":fraction,"direct_cash_cents":contract.direct_cash,
			"contract_final":contract.final,"hand_signatures":contract.hands,
			"native_no_insertion_final":no_insertion.final,"cash_only_final":cash_only.final,
			"sweep":rows})
	phase.free()
	_finish(output_path, publisher, results, 0 if failures.is_empty() else 2)

func _finish(output_path: String, publisher: String, results: Array, code: int) -> void:
	var output := {"source_head":"b84d1a5b4e4957b044b4b52c41553cf611aff3ae",
		"publisher":publisher,"checks":check_count,"failures":failures,"results":results}
	FileAccess.open(output_path, FileAccess.WRITE).store_string(JSON.stringify(output))
	print("PROMOTION_V4 ",publisher," results=",results.size()," checks=",check_count," failures=",failures.size())
	quit(code)
