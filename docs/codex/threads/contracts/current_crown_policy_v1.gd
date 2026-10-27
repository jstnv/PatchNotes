## Contracts design-thread route policy. Reads only the detached campaign observation.
## No gameplay source, player save, future draw, or mutable Run access.
extends RefCounted

static func factory(config: Dictionary) -> Callable:
	if config.get("strategy") not in ["visible", "synergy_qa"]: return Callable()
	var hands: Dictionary = {}
	return func(view: Dictionary) -> Dictionary: return choose(view, config, hands)

static func choose(view: Dictionary, config: Dictionary, hands: Dictionary) -> Dictionary:
	if view.phase == &"studio":
		return {"type": &"begin_development", "payload": {"name": "Crown strategy 1", "genre": "sports", "theme": "fantasy"}}
	if view.phase == &"contract": return {"type": &"unsupported_contract"}
	var current: Dictionary = view.development
	if current.finalized:
		return {"type": &"launch"} if current.phase == "beta" else _development(view, &"enter_next_phase")
	if current.confirmation_pending: return _development(view, &"confirm_exit")
	if not current.active: return _development(view, &"begin")
	var key := "%s:%s" % [view.project_id, current.phase]
	var target: int = 5 if current.phase == "design" else 6
	if int(hands.get(key, 0)) >= target: return _development(view, &"request_exit")
	var candidates: Array = current.candidates
	if candidates.size() < 4: return {"type": &"invalid_short_hand"}
	var indices: Array[int] = [0, 1, 2, 3]
	if config.strategy == "synergy_qa": indices = _best_four(candidates, current)
	var tokens: Array[int] = []
	for index in indices: tokens.append(int(candidates[index].token))
	hands[key] = int(hands.get(key, 0)) + 1
	return _development(view, &"play", {"candidate_ids": tokens})

static func _best_four(cards: Array, current: Dictionary) -> Array[int]:
	var best := -INF
	var selected: Array[int] = [0, 1, 2, 3]
	var ratios: Array[float] = [25.0, 25.0, 30.0, 20.0]
	var stats: Array[String] = ["graphics", "sound", "technology", "design"]
	for a in range(cards.size() - 3):
		for b in range(a + 1, cards.size() - 2):
			for c in range(b + 1, cards.size() - 1):
				for d in range(c + 1, cards.size()):
					var indices: Array[int] = [a, b, c, d]
					var score := 0.0
					if current.phase == "beta":
						var qa := 0
						for index in indices:
							var card: Dictionary = cards[index]
							if card.beta_category == "qa":
								qa += 1
								if card.definition == "debug": score += 12.0 if int(current.known_bugs) > 0 else 4.0
								elif card.definition == "search_for_bugs": score += 8.0
								else: score += float(card.beta_value)
							elif card.beta_category == "marketing": score += float(card.beta_value) * 0.7
							else: score += float(card.beta_value) * 0.4
						score += float(qa) * 3.0
						if qa == 4: score += 5.0
					else:
						var scope := 0
						var same := true
						var first_stat: String = str(cards[a].primary_stat)
						var printed: Array[float] = [0.0, 0.0, 0.0, 0.0]
						for index in indices:
							var card: Dictionary = cards[index]
							scope += int(card.scope)
							if str(card.primary_stat) != first_stat: same = false
							for stat_index in range(4):
								if str(card.primary_stat) == stats[stat_index]: printed[stat_index] += float(card.primary_value)
								if str(card.secondary_stat) == stats[stat_index]: printed[stat_index] += float(card.secondary_value)
						var weighted := 0.0
						for stat_index in range(4): weighted += printed[stat_index] * ratios[stat_index] / 25.0
						score = float(mini(scope, maxi(0, 30 - int(current.scope)))) * 4.0 + weighted * (1.5 if same else 1.0) + (10.0 if same else 0.0)
					if score > best:
						best = score
						selected = indices
	return selected

static func _development(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.development
	return {"type": &"development", "payload": {"request": {"schema_version": 1, "type": kind, "project_id": view.project_id, "phase": current.phase, "sequence": current.sequence, "project_cycle": current.project_cycle, "run_cycle": current.run_cycle, "payload": payload}}}
