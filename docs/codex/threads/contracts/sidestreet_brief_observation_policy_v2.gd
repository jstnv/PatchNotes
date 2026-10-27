## Observation-only current-rule policy. Ironclad uses the same Feature-first
## choice in every arm; only SideStreet changes choice. No Brief gameplay added.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
var _config: Dictionary
var _development_first: Callable
var _development_later: Callable
var _ironclad_started := false
var _sidestreet_started := false
var _observed_first_sidestreet := false


static func factory(config: Dictionary) -> Callable:
	if config.get("contract_selection") not in ["features_first", "passes_first"]: return Callable()
	if not config.get("development_first") is Dictionary or not config.get("development_later") is Dictionary: return Callable()
	var first: Callable = Development.factory(config.development_first)
	var later: Callable = Development.factory(config.development_later)
	if not first.is_valid() or not later.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._development_first = first
	policy._development_later = later
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)


func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract":
		var state: Dictionary = view.contract
		if not _observed_first_sidestreet and String(state.offer_id).begins_with("sidestreet_cash_contract_v1:") and int(state.hand_count) == 1:
			_observed_first_sidestreet = true
			print("PN_SIDE_BRIEF_FIRST_HAND " + JSON.stringify({"offer_id":state.offer_id,"scope":state.scope,"core_half_units":state.core_half_units,"redraws":state.successful_redraws,"cycle":state.run_cycle}))
		if state.completed: return {"type":&"dismiss_contract"}
		var candidates: Array = state.candidates.duplicate(true)
		if candidates.is_empty(): return _contract(view, &"begin")
		var passes_first: bool = _config.contract_selection == "passes_first" and String(state.offer_id).begins_with("sidestreet_cash_contract_v1:")
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if bool(a.renewable) != bool(b.renewable):
				return bool(a.renewable) if passes_first else not bool(a.renewable)
			return int(a.token) < int(b.token))
		var selected: Array = candidates.slice(0, 4)
		var tokens: Array[int] = []
		var names: Array[String] = []
		var scope_sum := 0
		for card: Dictionary in selected:
			tokens.append(int(card.token))
			names.append(str(card.definition))
			scope_sum += int(card.scope)
		if String(state.offer_id).begins_with("sidestreet_cash_contract_v1:") and int(state.hand_count) == 0:
			print("PN_SIDE_BRIEF_SELECTION " + JSON.stringify({"offer_id":state.offer_id,"cards":names,"scope_sum":scope_sum}))
		return _contract(view, &"play", {"candidate_ids":tokens})
	if view.phase != &"studio": return _development_for(view).call(view)
	var offers: Array = view.studio_actions.contract_offers
	if view.releases.is_empty():
		for id in _config.get("starter_ids", []):
			if StringName(id) not in view.owned_features:
				return {"type":&"starter_purchase","payload":{"feature_id":id}}
	if view.releases.size() >= 1 and not _ironclad_started:
		for offer: Dictionary in offers:
			if offer.kind == &"ironclad":
				_ironclad_started = true
				return {"type":&"accept_contract","payload":offer}
	if view.releases.size() >= 1 and _ironclad_started and not _sidestreet_started:
		for offer: Dictionary in offers:
			if offer.kind == &"sidestreet":
				_sidestreet_started = true
				return {"type":&"accept_contract","payload":offer}
		return {"type":&"accept_contract","payload":{"kind":"sidestreet","offer_id":""}}
	return _development_for(view).call(view)


func _development_for(view: Dictionary) -> Callable:
	return _development_first if view.releases.is_empty() else _development_later


static func _contract(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var current: Dictionary = view.contract
	return {"type":&"contract","payload":{"request":{"schema_version":1,"type":kind,"offer_id":current.offer_id,"hand_count":current.hand_count,"sequence":current.sequence,"run_cycle":current.run_cycle,"payload":payload}}}
