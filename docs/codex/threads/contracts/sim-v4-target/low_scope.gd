## Analysis-only target sensitivity. Native Contract hands and finance; candidate scoring inherited.
extends "res://analysis/task34_advance_v3.gd"

func _choose(cards: Array[CardData], state: ContractState, _name: String, _target: int, _focus: int, _policy: String) -> Array[int]:
	var best_scope := 1000000
	var best_core := -1
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var plan := state.plan_hand(hand)
					if plan.is_empty(): continue
					var scope := int(plan.scope_addition)
					var core := 0
					for value in plan.score_additions: core += int(value)
					if scope <= 0 or core <= 0: continue
					if scope < best_scope or (scope == best_scope and core > best_core):
						best_scope = scope
						best_core = core
						choice = [a, b, c, d]
	return choice

func _run() -> void:
	var input_path := _arg("--input=", "")
	var output_path := _arg("--out=", "")
	var publisher := _arg("--publisher=", "crown")
	var key := "crown_quill" if publisher == "crown" else "neon_circuit"
	var checkpoints: Array = FileAccess.open(input_path, FileAccess.READ).get_var()
	var first: Dictionary = {}
	for x: Dictionary in checkpoints:
		if not str(x.label).begins_with("release"): continue
		if x.publishers[key].unlocked:
			first = x
			break
	_check(not first.is_empty(), "Native publisher eligibility")
	var results: Array = []
	if not first.is_empty():
		var phase := ContractPhase.new()
		root.add_child(phase)
		for seed_value in [200929000, 200929001, 200929002]:
			var pair: Array = []
			for target in ([9, 10] if publisher == "crown" else [10, 11]):
				var result := _arm(first, phase, publisher, target, 0, "low_scope", seed_value)
				result["source_checkpoint"] = first.label
				results.append(result)
				pair.append(result)
			_check(pair[0].hands.size() == pair[1].hands.size(), "Paired hand count")
			if pair[0].hands.size() == pair[1].hands.size():
				for i in range(pair[0].hands.size()):
					for field in ["initial_pool", "pool", "selected", "scope_if_committed", "half_if_committed", "success"]:
						_check(pair[0].hands[i][field] == pair[1].hands[i][field], "Paired native hand " + field)
			_check(pair[0].draw_events == pair[1].draw_events, "Paired native draw trace")
			_check(pair[0].direct_cash >= pair[1].direct_cash, "Harder target cannot raise cash")
			_check(pair[0].promotion_conditional >= pair[1].promotion_conditional, "Harder target cannot raise Promotion")
		phase.free()
	var out := {"study":"sim-v4-target", "publisher":publisher, "eligible":not first.is_empty(), "checks":check_count, "failures":failures, "results":results}
	FileAccess.open(output_path, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("TARGET_V4 publisher=", publisher, " eligible=", not first.is_empty(), " arms=", results.size(), " checks=", check_count)
	quit(0 if failures.is_empty() else 2)
