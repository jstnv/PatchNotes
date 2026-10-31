## Current-source candidate policy; fixed experimental shopping and seven-hand Beta.
## Reads current authoritative legality. Not approved production AI.
extends RefCounted
const Synergy := preload("res://scripts/market/rival_synergy_choice.gd")
const BetaChoice := preload("res://scripts/market/rival_beta_synergy_choice.gd")
const FIRST_SCOPE := 30
const JANUARY_SCOPE := 35
const FULL_PRIMITIVE_SCOPE := 30
var _policy: String
var _genre: String
func _init(genre: String="action",policy: String="audio_path") -> void:
	_genre=genre;_policy=policy

func _owned_scope(run: RunState) -> int:
	var result := 0
	for id: StringName in run.get_future_project_feature_ids():
		var card: Dictionary = run._feature_definitions.get(id,{})
		if card.get("phase","") in ["design","alpha"]: result += int(card.get("scope",0))
	return result

func _stat_weight(stat: String) -> int:
	var ratios: Array = PrimitivePredevelopment.find_entry("genres",StringName(_genre)).get("ratios",[])
	var index := ["graphics","sound","technology","design"].find(stat)
	if index >= 0 and ratios.size()==4: return int(ratios[index])
	return 0

func _action_value(run: RunState,id: StringName) -> int:
	var card: Dictionary = run._feature_definitions.get(id,{})
	var score := 0
	for prefix in ["primary","secondary"]:
		score += _stat_weight(str(card.get(prefix+"_stat",""))) * int(card.get(prefix+"_value",0))
	return score

func _best_starter(run: RunState) -> Dictionary:
	var best := {}
	var best_score := -INF
	for name: String in StudioSpecialties.PRIMITIVE_IDS:
		var id := StringName(name)
		var offer: Dictionary = run.get_primitive_reserve_offer(id)
		if not offer.get("can_purchase",false): continue
		var score := float(_action_value(run,id)+25*int(offer.scope))*100000.0/float(maxi(1,int(offer.price_cents)))
		if best.is_empty() or score > best_score or (is_equal_approx(score,best_score) and name < str(best.id)):
			best = offer
			best_score = score
	return best

func _best_research(run: RunState) -> Dictionary:
	var best := {}
	var best_score := -INF
	for name: String in StudioSpecialties.PRIMITIVE_IDS:
		var id := StringName(name)
		if run.owns_feature(id): continue
		var quote: Dictionary = run.get_feature_research_quote(id)
		if not quote.get("can_admit",false) or run.get_cash_cents() < int(quote.down_cents)+100000: continue
		var card: Dictionary = run._feature_definitions.get(id,{})
		var score := float(_action_value(run,id)+25*int(card.get("scope",0)))*100000.0/float(maxi(1,int(quote.remaining_cents)+int(quote.down_cents)))
		if best.is_empty() or score > best_score or (is_equal_approx(score,best_score) and name < str(best.feature_id)):
			best = quote
			best_score = score
	return best

func _loan_choice(run: RunState) -> Dictionary:
	var quote: Dictionary = run.get_bank_quote(150000,12)
	if quote.get("accepted",false): return {"type":&"bank_borrow","payload":{"quote":quote}}
	return {}

func _store_targets(run: RunState) -> Array[StringName]:
	var releases: Array = run.get_released_game_ids()
	if releases.is_empty(): return []
	var receipt: Dictionary = run.get_release_metadata(releases[0]).get("review",{})
	var cores: Array = receipt.get("cores",[])
	var standards: Array = receipt.get("standards",[])
	if cores.size()!=4 or standards.size()!=4: return []
	var graphics_gap := maxi(0,int(standards[0])-int(cores[0]))
	var technology_gap := maxi(0,int(standards[2])-int(cores[2]))
	var ordered: Array[StringName] = []
	if technology_gap>graphics_gap:
		ordered.append(&"scripted_ai")
		ordered.append(&"animated_sprites")
	else:
		ordered.append(&"animated_sprites")
		ordered.append(&"scripted_ai")
	if _policy == "store_one_gap":
		var first: Array[StringName] = []
		first.append(ordered[0])
		return first
	return ordered

func choose(session: RefCounted,view: Dictionary) -> Dictionary:
	var run: RunState = session.run
	if view.phase == &"studio":
		if run.needs_starter_selection():
			if _owned_scope(run) < FULL_PRIMITIVE_SCOPE:
				var starter := _best_starter(run)
				if not starter.is_empty(): return {"type":&"starter_purchase","payload":{"feature_id":starter.id}}
				var loan := _loan_choice(run) if run.get_cash_cents()<300000 else {}
				if not loan.is_empty(): return loan
				return {"type":&"blocked","payload":{"reason":"Cannot legally buy declared founding printed Scope before first project"}}
			if run.get_cash_cents() < 300000:
				var loan := _loan_choice(run)
				if not loan.is_empty(): return loan
		else:
			var queue: Array = run.get_feature_research_queue()
			if not queue.is_empty():
				var quote: Dictionary = run.get_feature_research_quote(StringName(queue[0].feature_id))
				if quote.get("can_research",false): return {"type":&"research","payload":{"quote":quote}}
				return {"type":&"blocked","payload":{"reason":"Paid Research installment unaffordable"}}
			if _policy in ["store_one_gap","store_two_gaps"] and view.releases.size() >= 1:
				var targets := _store_targets(run)
				if targets.is_empty(): return {"type":&"blocked","payload":{"reason":"First-release Core/standards receipt unavailable"}}
				for id: StringName in targets:
					if run.owns_feature(id): continue
					var quote: Dictionary = run.get_feature_research_quote(id)
					if not quote.get("can_admit",false): return {"type":&"blocked","payload":{"reason":"Declared Store target unavailable: "+str(id)}}
					if run.get_cash_cents() < int(quote.down_cents)+int(quote.remaining_cents)+100000:
						return {"type":&"blocked","payload":{"reason":"Store target plus known-bill reserve unaffordable: "+str(id)}}
					return {"type":&"admit_research","payload":{"quote":quote}}
			if _owned_scope(run) < JANUARY_SCOPE:
				var research := _best_research(run)
				if not research.is_empty(): return {"type":&"admit_research","payload":{"quote":research}}
				if _policy == "audio_path":
					for id: StringName in [&"main_theme",&"multiple_soundtracks"]:
						if run.owns_feature(id): continue
						var quote: Dictionary = run.get_feature_research_quote(id)
						if not quote.get("can_admit",false): return {"type":&"blocked","payload":{"reason":"Declared Audio Store path unavailable: "+str(id)}}
						if run.get_cash_cents() < int(quote.down_cents)+int(quote.remaining_cents)+100000:
							var audio_loan := _loan_choice(run)
							if not audio_loan.is_empty(): return audio_loan
							return {"type":&"blocked","payload":{"reason":"Declared Audio path plus known-bill reserve unaffordable: "+str(id)}}
						return {"type":&"admit_research","payload":{"quote":quote}}
				if run.get_cash_cents() < 300000:
					var loan := _loan_choice(run)
					if not loan.is_empty(): return loan
		if not run.can_complete_productive_cycle(0): return {"type":&"blocked","payload":{"reason":"Cannot fund next legal project Begin"}}
		return {"type":&"begin_development","payload":{"name":"Prelude %s %d" % [_genre.capitalize(),view.releases.size()+1],"genre":_genre,"theme":"fantasy"}}
	if view.phase == &"contract": return {"type":&"blocked","payload":{"reason":"Unexpected Contract phase"}}
	var current: Dictionary = view.development
	if current.finalized:
		if view.phase == &"beta":
			if int(current.scope) < int(current.required_scope): return {"type":&"blocked","payload":{"reason":"Hard full-Scope launch gate"}}
			return _development(view,&"launch")
		if view.phase == &"alpha" and int(current.scope) < int(current.required_scope): return {"type":&"blocked","payload":{"reason":"Hard full-Scope Alpha gate"}}
		return _development(view,&"enter_next_phase")
	if current.confirmation_pending: return _development(view,&"confirm_exit")
	if not current.active: return _development(view,&"begin")
	if view.phase in [&"design",&"alpha"]:
		var feature_tokens := _feature_hand(current,session)
		if not feature_tokens.is_empty(): return _development(view,&"play",{"candidate_ids":feature_tokens})
		if current.can_exit:return _development(view,&"request_exit")
		if not session.development.hand._available_features.is_empty():
			if int(current.redraws)>0:
				for card: Dictionary in current.candidates:
					if card.type == "pass": return _development(view,&"redraw",{"candidate_ids":[int(card.token)]})
			var pass_tokens := _pass_hand(current,session)
			if not pass_tokens.is_empty(): return _development(view,&"play",{"candidate_ids":pass_tokens})
			return {"type":&"blocked","payload":{"reason":"Undrawn finite Feature but no legal funded search"}}
		if view.phase == &"alpha" and int(current.scope)<int(current.required_scope): return {"type":&"blocked","payload":{"reason":"Exhausted Alpha supply under frozen Scope"}}
		if current.can_exit: return _development(view,&"request_exit")
		return {"type":&"blocked","payload":{"reason":"No legal phase exit after supply exhaustion"}}
	var beta_hands := int(current.hand_revision)-1
	if beta_hands >= 7 and current.can_exit: return _development(view,&"request_exit")
	var cards: Array = current.candidates.filter(func(card: Dictionary) -> bool: return card.type == "beta" and BetaPriorityAllocation.category_enabled(StringName(card.beta_category)))
	if cards.size()<4: return {"type":&"blocked","payload":{"reason":"Fewer than four legal Beta candidates"}}
	var reference: Array = cards.slice(0,4)
	var tokens: Array[int] = BetaChoice.pick(current,reference,StringName(view.run_id),true)
	if tokens.size()!=4: return {"type":&"blocked","payload":{"reason":"No valid Beta hand"}}
	return _development(view,&"play",{"candidate_ids":tokens})

func _feature_hand(current: Dictionary,session: RefCounted) -> Array[int]:
	var hand: RefCounted = session.development.hand
	var cards: Array = current.candidates
	var best: Array[int] = []
	var count := 0
	var value := -INF
	for a in range(cards.size()-3):
		for b in range(a+1,cards.size()-2):
			for c in range(b+1,cards.size()-1):
				for d in range(c+1,cards.size()):
					var offered: Array = [cards[a],cards[b],cards[c],cards[d]]
					var selected: Array[CardData] = []
					var tokens: Array[int] = []
					var features := 0
					for card: Dictionary in offered:
						var slot: int = hand.candidate_ids.find(int(card.token))
						if slot < 0: break
						selected.append(hand._candidate_cards[slot])
						tokens.append(int(card.token))
						if card.type == "feature": features += 1
					if selected.size()!=4 or features==0 or not hand.calculate_base(selected).get("valid",false): continue
					var cost: int = session.run.primitive_feature_hand_cost_cents(selected,session.development.project.get_release_id())
					if cost<0 or cost>int(current.cash_cents): continue
					var assessed: Dictionary = Synergy._assess(current,offered)
					var score := float(assessed.get("proxy",0.0))+float(mini(int(hand.calculate_base(selected).get("scope",0)),maxi(0,int(current.required_scope)-int(current.scope))))*0.03
					if _policy == "core_shop_hand":
						var printed_gain := 0
						for selected_card: CardData in selected:
							if selected_card.card_type != &"feature": continue
							printed_gain += _stat_weight(str(selected_card.primary_stat))*selected_card.primary_value
							printed_gain += _stat_weight(str(selected_card.secondary_stat))*selected_card.secondary_value
						score += float(printed_gain)*0.01
					tokens.sort()
					if features>count or (features==count and score>value):
						best=tokens
						count=features
						value=score
	return best

func _pass_hand(current: Dictionary,session: RefCounted) -> Array[int]:
	var hand: RefCounted = session.development.hand
	var cards: Array = current.candidates.filter(func(card: Dictionary) -> bool: return card.type == "pass")
	if cards.size()<4: return []
	var tokens: Array[int] = []
	var selected: Array[CardData] = []
	for card: Dictionary in cards.slice(0,4):
		var slot: int = hand.candidate_ids.find(int(card.token))
		if slot<0: return []
		tokens.append(int(card.token))
		selected.append(hand._candidate_cards[slot])
	if not hand.calculate_base(selected).get("valid",false): return []
	var cost: int = session.run.primitive_feature_hand_cost_cents(selected,session.development.project.get_release_id())
	if cost<0 or cost>int(current.cash_cents): return []
	tokens.sort()
	return tokens

func _development(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	if kind == &"launch": return {"type":&"launch"}
	var current: Dictionary = view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":payload}}}
