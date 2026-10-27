## External policy for the private SideStreet Relationship Brief pilot only.
## Chooses observed cards by definition from the current visible seven-card deal.
## Missing offers/cards reject the case; the policy never substitutes a draw.
extends RefCounted

const Development := preload("res://scripts/simulation/finite_fixture_policy.gd")
const FIRST_BRIEF_HAND := ["power_ups", "split_screen", "text", "sound_pass"]
const SECOND_BRIEF_HANDS := {
	"full": ["controller", "menu_system", "multiple_endings", "sound_pass"],
	"half": ["controller", "menu_system", "multiple_endings", "sound_effects"],
	"miss": ["controller", "menu_system", "multiple_endings", "music"],
	"redraw": ["controller", "menu_system", "multiple_endings", "sound_pass"],
	"partial": ["controller", "sound_effects", "sound_pass", "technology_pass"],
}

var _config: Dictionary
var _first_development: Callable
var _later_development: Callable
var _ironclad_started := false
var _brief_started := false
var _brief_reported := false
var _brief_offer_id: StringName = &""
var _second_hand_redraw_done := false


static func factory(config: Dictionary) -> Callable:
	if not SECOND_BRIEF_HANDS.has(str(config.get("scenario", ""))): return Callable()
	if not config.get("starter_ids") is Array: return Callable()
	if not config.get("development_first") is Dictionary or not config.get("development_later") is Dictionary: return Callable()
	var first: Callable = Development.factory(config.development_first)
	var later: Callable = Development.factory(config.development_later)
	if not first.is_valid() or not later.is_valid(): return Callable()
	var policy: RefCounted = load("res://scripts/debug/experiment_policy/supplied_policy.gd").new()
	policy._config = config.duplicate(true)
	policy._first_development = first
	policy._later_development = later
	return func(view: Dictionary) -> Dictionary: return policy.choose(view)


func choose(view: Dictionary) -> Dictionary:
	if view.phase == &"contract": return _choose_contract(view)
	if view.phase != &"studio":
		return (_first_development if view.releases.is_empty() else _later_development).call(view)
	if view.releases.is_empty():
		for id: Variant in _config.starter_ids:
			if StringName(id) not in view.owned_features:
				return {"type": &"starter_purchase", "payload": {"feature_id": id}}
	if view.releases.size() >= 1 and not _ironclad_started:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if StringName(offer.kind) == &"ironclad":
				_ironclad_started = true
				return {"type": &"accept_contract", "payload": offer}
		print("PN_BRIEF_PILOT_MISSING_IRONCLAD " + JSON.stringify({"cycle": view.run_cycle, "releases": view.releases.size()}))
		return {"type": &"accept_contract", "payload": {"kind": &"ironclad", "offer_id": &""}}
	if _ironclad_started and not _brief_started:
		for offer: Dictionary in view.studio_actions.contract_offers:
			if StringName(offer.kind) == &"sidestreet_brief":
				_brief_started = true
				_brief_offer_id = StringName(offer.offer_id)
				print("PN_BRIEF_PILOT_ACCEPT " + JSON.stringify({"scenario": _config.scenario, "offer_id": str(_brief_offer_id), "cycle": view.run_cycle, "cash_cents": view.cash_cents}))
				return {"type": &"accept_contract", "payload": {"kind": &"sidestreet_brief", "offer_id": _brief_offer_id}}
		print("PN_BRIEF_PILOT_MISSING_BRIEF " + JSON.stringify({"cycle": view.run_cycle, "offers": view.studio_actions.contract_offers}))
		return {"type": &"accept_contract", "payload": {"kind": &"sidestreet_brief", "offer_id": &""}}
	if _brief_started and not _brief_reported:
		_brief_reported = true
		print("PN_BRIEF_PILOT_STUDIO_RESULT " + JSON.stringify({"scenario": _config.scenario, "cycle": view.run_cycle, "cash_cents": view.cash_cents, "reputation": view.get("publisher_reputation_bp", {})}))
	return (_first_development if view.releases.is_empty() else _later_development).call(view)


func _choose_contract(view: Dictionary) -> Dictionary:
	var state: Dictionary = view.contract
	var is_brief: bool = not _brief_offer_id.is_empty() and StringName(state.offer_id) == _brief_offer_id
	if state.completed:
		if is_brief:
			print("PN_BRIEF_PILOT_COMPLETE " + JSON.stringify({"scenario": _config.scenario, "offer_id": str(_brief_offer_id), "scope": state.scope, "core_half_units": state.core_half_units, "successful_redraws": state.successful_redraws, "cycle": state.run_cycle}))
		return {"type": &"dismiss_contract"}
	var candidates: Array = state.candidates.duplicate(true)
	if candidates.is_empty(): return _contract(view, &"begin")
	if is_brief and int(state.hand_count) == 1 and str(_config.scenario) == "redraw" and not _second_hand_redraw_done:
		for card: Dictionary in candidates:
			if str(card.definition) == "technology_pass":
				_second_hand_redraw_done = true
				print("PN_BRIEF_PILOT_REDRAW " + JSON.stringify({"offer_id": str(_brief_offer_id), "card": str(card.definition), "token": int(card.token)}))
				return _contract(view, &"redraw", {"candidate_ids": [int(card.token)]})
		print("PN_BRIEF_PILOT_MISSING_REDRAW_CARD " + JSON.stringify({"offer_id": str(_brief_offer_id), "candidates": candidates}))
		return _contract(view, &"redraw", {"candidate_ids": [-1]})
	var selected: Array = []
	if is_brief:
		var requested: Array = FIRST_BRIEF_HAND if int(state.hand_count) == 0 else SECOND_BRIEF_HANDS[str(_config.scenario)]
		var available: Array = candidates.duplicate(true)
		for wanted: String in requested:
			var found := -1
			for index in range(available.size()):
				if str(available[index].definition) == wanted:
					found = index
					break
			if found < 0:
				print("PN_BRIEF_PILOT_MISSING_CARD " + JSON.stringify({"scenario": _config.scenario, "hand": state.hand_count, "wanted": wanted, "candidates": candidates}))
				return _contract(view, &"play", {"candidate_ids": [-1]})
			selected.append(available[found])
			available.remove_at(found)
	else:
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if bool(a.renewable) != bool(b.renewable): return not bool(a.renewable)
			return int(a.token) < int(b.token))
		selected = candidates.slice(0, 4)
	var tokens: Array[int] = []
	var names: Array[String] = []
	for card: Dictionary in selected:
		tokens.append(int(card.token))
		names.append(str(card.definition))
	if is_brief:
		print("PN_BRIEF_PILOT_HAND " + JSON.stringify({"scenario": _config.scenario, "offer_id": str(_brief_offer_id), "hand": state.hand_count, "cards": names, "scope_before": state.scope, "redraws": state.successful_redraws}))
	return _contract(view, &"play", {"candidate_ids": tokens})


static func _contract(view: Dictionary, kind: StringName, payload: Dictionary = {}) -> Dictionary:
	var state: Dictionary = view.contract
	return {"type": &"contract", "payload": {"request": {"schema_version": 1, "type": kind, "offer_id": state.offer_id, "hand_count": state.hand_count, "sequence": state.sequence, "run_cycle": state.run_cycle, "payload": payload}}}
