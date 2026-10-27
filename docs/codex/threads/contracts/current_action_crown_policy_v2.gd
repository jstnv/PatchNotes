## Bounded Action Game-2 route policy. Reads only detached public observations.
## No gameplay source, player save, future draw, or mutable Run access.
extends RefCounted

static func factory(config: Dictionary) -> Callable:
	if config.get("strategy") != "action_game2": return Callable()
	var state: Dictionary = {"hands": {}, "redrawn": {}, "ironclad_started": false, "research_done": false}
	return func(view: Dictionary) -> Dictionary: return choose(view, state)

static func choose(view: Dictionary, state: Dictionary) -> Dictionary:
	if view.phase == &"studio":
		var released: int = view.releases.size()
		if released == 1:
			if not state.ironclad_started:
				state.ironclad_started = true
				for offer in view.studio_actions.contract_offers:
					if offer.kind == &"ironclad": return {"type": &"accept_contract", "payload": offer}
			if not state.research_done:
				for quote in view.research_quotes:
					if str(quote.get("feature_id", "")) != "recorded_sounds": continue
					if quote.get("head", false): return {"type": &"research", "payload": {"quote": quote}}
					if quote.get("can_admit", false): return {"type": &"admit_research", "payload": {"quote": quote}}
				state.research_done = true
		return {"type": &"begin_development", "payload": {"name": "Crown Action %d" % [released + 1], "genre": "action", "theme": "fantasy"}}
	if view.phase == &"contract":
		if view.contract.completed: return {"type": &"dismiss_contract"}
		var contract_cards: Array = view.contract.candidates
		if contract_cards.is_empty(): return _contract(view, &"begin")
		var contract_tokens: Array[int] = []
		for index in range(mini(4, contract_cards.size())): contract_tokens.append(int(contract_cards[index].token))
		return _contract(view, &"play", {"candidate_ids": contract_tokens})
	var current: Dictionary = view.development
	var game_number: int = view.releases.size() + 1
	if current.finalized:
		return {"type": &"launch"} if current.phase == "beta" else _development(view, &"enter_next_phase")
	if current.confirmation_pending: return _development(view, &"confirm_exit")
	if not current.active: return _development(view, &"begin")
	var key := "%s:%s" % [view.project_id, current.phase]
	var target: int = (3 if current.phase == "design" else 2 if current.phase == "alpha" else 1) if game_number == 1 else (5 if current.phase == "design" else 3 if current.phase == "alpha" else 5)
	if int(state.hands.get(key, 0)) >= target: return _development(view, &"request_exit")
	var candidates: Array = current.candidates
	if candidates.size() < 4: return {"type": &"invalid_short_hand"}
	if game_number == 2 and current.phase in ["design", "beta"] and not state.redrawn.has(key) and int(current.redraws) > 0:
		state.redrawn[key] = true
		return _development(view, &"redraw", {"candidate_ids": [int(candidates[-1].token)]})
	var indices: Array[int] = [0, 1, 2, 3]
	if game_number == 2: indices = _best_four(candidates, current)
	var tokens: Array[int] = []
	for index in indices: tokens.append(int(candidates[index].token))
	state.hands[key] = int(state.hands.get(key, 0)) + 1
	return _development(view, &"play", {"candidate_ids": tokens})

static func _best_four(cards: Array, current: Dictionary) -> Array[int]:
	var best := -INF
	var selected: Array[int] = [0, 1, 2, 3]
	var ratios: Array[float] = [25.0, 25.0, 25.0, 25.0]
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
								elif card.definition == "search_for_bugs": score += 11.0 if int(current.known_bugs) > 0 else 7.0
								else: score += float(card.beta_value)
							elif card.beta_category == "marketing": score += float(card.beta_value) * (0.7 if int(current.known_bugs) > 0 else 3.0)
							else: score += float(card.beta_value) * 0.4
						if int(current.known_bugs) > 0:
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

static func _contract(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type": &"contract", "payload": {"request": {"schema_version": 1, "type": kind, "offer_id": current.offer_id, "hand_count": current.hand_count, "sequence": current.sequence, "run_cycle": current.run_cycle, "payload": payload}}}
