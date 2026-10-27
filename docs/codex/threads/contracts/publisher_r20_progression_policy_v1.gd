## Contracts-thread, observation-only route for TWO full SideStreet Briefs.
## External single-file policy; only existing res:// finite-fixture code is loaded.
## No hidden state, player save, redraw, Bank, research or alternate seed.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
const STAT_INDEX := {"graphics":0,"sound":1,"technology":2,"design":3}
const PREFERRED_FIRST := ["power_ups","split_screen","text","sound_pass"]

var _config: Dictionary
var _development_first: Callable
var _development_later: Callable
var _ironclad_accepted := false
var _ironclad_completed := false
var _briefs_completed := 0
var _brief_offer_ids: Array[StringName] = []
var _active_kind: StringName = &""
var _active_offer_id: StringName = &""
var _r20_reported := false


static func factory(config: Dictionary) -> Callable:
	if not config.get("starter_ids") is Array or not config.get("development_first") is Dictionary or not config.get("development_later") is Dictionary:
		return Callable()
	var first := Development.factory(config.development_first)
	var later := Development.factory(config.development_later)
	if not first.is_valid() or not later.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._development_first = first
	policy._development_later = later
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)


func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract": return _choose_contract(view)
	if view.phase != &"studio": return _development_for(view).call(view)
	var releases: Array = view.releases
	if releases.is_empty():
		for id: Variant in _config.starter_ids:
			if StringName(id) not in view.owned_features:
				return {"type":&"starter_purchase","payload":{"feature_id":id}}
		return _development_first.call(view)
	if not _ironclad_completed:
		if _ironclad_accepted or releases.size() != 1: return _stop(view,"Ironclad did not complete after Game 1")
		for offer: Dictionary in view.studio_actions.contract_offers:
			if StringName(offer.kind) == &"ironclad":
				_ironclad_accepted = true
				_active_kind = &"ironclad"
				_active_offer_id = &"balanced_primitive_contract_v1"
				return {"type":&"accept_contract","payload":{"kind":&"ironclad"}}
		return _stop(view,"Visible Ironclad offer missing")
	if _briefs_completed == 0:
		if releases.size() != 1 or _reputation(view) != 0: return _stop(view,"Unexpected state before Brief 1")
		return _accept_brief(view,1)
	if _briefs_completed == 1:
		if _reputation(view) != 1000: return _stop(view,"Brief 1 did not award exactly 1000 reputation bp")
		if releases.size() == 1: return _development_later.call(view)
		if releases.size() == 2: return _accept_brief(view,2)
		return _stop(view,"Expected Game 2 before Brief 2")
	if _briefs_completed == 2:
		if _reputation(view) != 2000: return _stop(view,"Brief 2 did not bring Reputation to 2000 bp")
		if releases.size() == 2:
			if not _r20_reported:
				_r20_reported = true
				print("PN_R20_REACHED " + JSON.stringify({"run_cycle":view.run_cycle,"cash_cents":view.cash_cents,"reputation_bp":_reputation(view),"brief_offer_ids":_brief_offer_ids}))
			return _development_later.call(view)
		return _stop(view,"Runner should stop at Studio after Game 3")
	return _stop(view,"Unexpected additional Brief")


func _accept_brief(view: Dictionary, ordinal: int) -> Dictionary:
	var latest_release: StringName = StringName(view.releases[-1].id)
	for offer: Dictionary in view.studio_actions.contract_offers:
		if StringName(offer.kind) != &"sidestreet_brief": continue
		if not offer.get("quote") is Dictionary: return _stop(view,"Brief quote missing")
		var offer_id := StringName(offer.get("offer_id",&""))
		if offer_id.is_empty() or offer_id in _brief_offer_ids or StringName(offer.quote.get("source_release_id",&"")) != latest_release:
			return _stop(view,"Brief offer identity/source release mismatch")
		_active_kind = &"sidestreet_brief"
		_active_offer_id = offer_id
		_brief_offer_ids.append(offer_id)
		print("PN_R20_BRIEF_ACCEPT " + JSON.stringify({"ordinal":ordinal,"offer_id":str(offer_id),"source_release_id":str(latest_release),"run_cycle":view.run_cycle,"cash_cents":view.cash_cents}))
		return {"type":&"accept_contract","payload":{"kind":&"sidestreet_brief","offer_id":offer_id}}
	return _stop(view,"Expected visible SideStreet Brief offer missing")


func _choose_contract(view: Dictionary) -> Dictionary:
	var state: Dictionary = view.contract
	if _active_kind.is_empty() or StringName(state.offer_id) != _active_offer_id:
		return _stop(view,"Active Contract identity mismatch")
	if state.completed:
		if _active_kind == &"ironclad":
			_ironclad_completed = true
		elif _active_kind == &"sidestreet_brief":
			if int(state.required_hands) != 2 or int(state.hand_count) != 2 or int(state.successful_redraws) != 0 or int(state.scope) != 10 or not _cores_complete(state.core_half_units):
				return _stop(view,"Brief did not complete at exact full Scope/Core/no-redraw grade")
			_briefs_completed += 1
			print("PN_R20_BRIEF_FULL " + JSON.stringify({"ordinal":_briefs_completed,"offer_id":str(_active_offer_id),"scope":state.scope,"core_half_units":state.core_half_units,"run_cycle":state.run_cycle}))
		else:
			return _stop(view,"Unexpected Contract kind")
		_active_kind = &""
		_active_offer_id = &""
		return {"type":&"dismiss_contract"}
	var candidates: Array = state.candidates.duplicate(true)
	if candidates.is_empty(): return _contract(view,&"begin")
	if candidates.size() != 7: return _stop(view,"Expected seven visible Contract candidates")
	var selected: Array = []
	if _active_kind == &"ironclad":
		candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			if bool(a.renewable) != bool(b.renewable): return not bool(a.renewable)
			return int(a.token) < int(b.token))
		selected = candidates.slice(0,4)
	else:
		if int(state.successful_redraws) != 0 or int(state.hand_count) not in [0,1]: return _stop(view,"Brief redraw or hand count unexpectedly changed")
		selected = _best_brief_hand(state,candidates)
		if selected.is_empty(): return _stop(view,"No visible legal four-card set can satisfy this full-Brief step")
	var tokens: Array[int] = []
	var names: Array[String] = []
	for card: Dictionary in selected:
		tokens.append(int(card.token))
		names.append(str(card.definition))
	if _active_kind == &"sidestreet_brief":
		print("PN_R20_BRIEF_HAND " + JSON.stringify({"ordinal":_briefs_completed+1,"hand":state.hand_count,"cards":names,"scope_before":state.scope,"cores_before":state.core_half_units}))
	return _contract(view,&"play",{"candidate_ids":tokens})


func _best_brief_hand(state: Dictionary,candidates: Array) -> Array:
	var best: Array = []
	var best_rank := 9223372036854775807
	for a in range(candidates.size()-3):
		for b in range(a+1,candidates.size()-2):
			for c in range(b+1,candidates.size()-1):
				for d in range(c+1,candidates.size()):
					var hand := [candidates[a],candidates[b],candidates[c],candidates[d]]
					var projected := _project(state,hand)
					if projected.is_empty() or int(projected.scope) > 10: continue
					var deficits := 0
					var excess := 0
					for score: int in projected.cores:
						deficits += maxi(0,6-score)
						excess += maxi(0,score-6)
					var rank := 0
					if int(state.hand_count) == 0:
						if int(projected.scope) < 3 or int(projected.scope) > 7: continue
						# Best visible first hand: all four Cores, then Scope near 5.
						rank = deficits * 1000 + absi(int(projected.scope)-5) * 100 + mini(excess,99)
						if _same_definitions(hand,PREFERRED_FIRST): rank -= 50
					else:
						# Full completion AND full promise require exact Scope 10.
						if int(projected.scope) != 10 or deficits != 0: continue
						rank = excess
					if rank < best_rank:
						best_rank = rank
						best = hand
	return best


func _project(state: Dictionary,hand: Array) -> Dictionary:
	var cores: Array[int] = []
	for index in range(4): cores.append(int(state.core_half_units.get(index,0)))
	var scope := int(state.scope)
	var shared_primary := str(hand[0].primary_stat)
	for card: Dictionary in hand:
		if str(card.primary_stat) != shared_primary: shared_primary = ""
	var multiplier := 3 if not shared_primary.is_empty() else 2
	for card: Dictionary in hand:
		var primary := str(card.primary_stat)
		if not STAT_INDEX.has(primary) or int(card.primary_value) < 0 or int(card.scope) < 0: return {}
		scope += int(card.scope)
		cores[int(STAT_INDEX[primary])] += multiplier * int(card.primary_value)
		var secondary := str(card.secondary_stat)
		if not secondary.is_empty():
			if not STAT_INDEX.has(secondary) or int(card.secondary_value) < 0: return {}
			cores[int(STAT_INDEX[secondary])] += multiplier * int(card.secondary_value)
	return {"scope":scope,"cores":cores}


func _cores_complete(cores: Dictionary) -> bool:
	for index in range(4):
		if int(cores.get(index,0)) < 6: return false
	return true


func _same_definitions(hand: Array,names: Array) -> bool:
	for name: String in names:
		var found := false
		for card: Dictionary in hand:
			if str(card.definition) == name: found = true
		if not found: return false
	return true


func _development_for(view: Dictionary) -> Callable:
	return _development_first if view.releases.is_empty() else _development_later


func _reputation(view: Dictionary) -> int:
	var ledgers: Dictionary = view.get("publisher_reputation_bp",{})
	return int(ledgers.get(&"sidestreet",0))


func _stop(view: Dictionary,reason: String) -> Dictionary:
	print("PN_R20_ROUTE_STOP " + JSON.stringify({"reason":reason,"phase":str(view.phase),"run_cycle":view.run_cycle,"releases":view.releases.size(),"briefs_completed":_briefs_completed,"reputation_bp":_reputation(view)}))
	# Explicit unsupported action makes the case fail and retain this boundary.
	return {"type":&"publisher_r20_route_unmet"}


static func _contract(view: Dictionary,kind: StringName,payload: Dictionary = {}) -> Dictionary:
	var state: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":state.offer_id,"hand_count":state.hand_count,"sequence":state.sequence,"run_cycle":state.run_cycle,"payload":payload}}}
