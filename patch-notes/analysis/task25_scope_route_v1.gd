## Separate legal feasibility search: buy optional Primitive cards, prioritize
## printed Scope over tutorial suggestions. Never changes draw/production rules.
extends "res://analysis/task25_routes_v1.gd"

func _run() -> void:
	arm = "specialty"
	era_policy = "synergy"
	for index in range(int(_arg("--start=", "100")), int(_arg("--start=", "100")) + int(_arg("--count=", "64"))):
		live_cycles = []
		random_inputs.seed = 250930000 + index
		var result := await _roster_route(index)
		result["policy"] = "scope_first_feasibility"
		rows.append(result)
		if not result.valid: failures += 1
		if not result.releases.is_empty() and int(result.releases[0].scope) >= 30: break
	var file := FileAccess.open("res://design-logs/task25-v1/scope-feasibility.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows, "failures": failures, "command": OS.get_cmdline_args()}, "  "))
	print("Scope feasibility routes=", rows.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)

func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, _policy: String, _focus: String) -> Array[int]:
	var best := -INF
	var selected: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					if run.primitive_feature_hand_cost_cents(hand) > run.get_cash_cents(): continue
					var score := 0.0
					for card: CardData in hand: score += card.scope * 1000 + card.primary_value + card.secondary_value
					if score > best: best = score; selected = [a, b, c, d]
	return selected

func _weakest(cards: Array[CardData], _focus: String) -> int:
	var worst := 0
	for index in range(1, cards.size()):
		if cards[index].scope < cards[worst].scope: worst = index
	return worst
