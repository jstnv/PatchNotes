class_name ContractDefinitions
extends RefCounted

## Code-owned, versioned Contract rule definitions. Disk data cannot add a
## definition or select an evaluator. Returned Dictionaries are detached.
const VERSION := 1
const IRONCLAD := &"balanced_primitive_contract_v1"
const SIDESTREET := &"sidestreet_cash_contract_v1"
const SIDESTREET_BRIEF := &"sidestreet_relationship_brief_trial_v1"
const CROWN := &"crown_quill_primitive_trial_v1"
const NEON := &"neon_circuit_primitive_trial_v1"
const STARWAVE := &"starwave_primitive_trial_v1"
const STATS := [&"graphics", &"sound", &"technology", &"design"]


static func built_in_ids() -> Array[StringName]:
	return [IRONCLAD, SIDESTREET, SIDESTREET_BRIEF, CROWN, NEON, STARWAVE]


static func definition(id: StringName) -> Dictionary:
	var common := {"version": VERSION, "id": id, "required_hands": 2, "scope_target": 12, "core_target": 12, "stored_terms": {}}
	match id:
		IRONCLAD:
			common.merge({"publisher_id": &"ironclad", "title": "Balanced Primitive Contract", "cash_cents": 240000, "advance_cents": 40000, "promotion": 0, "denominator": 96, "score": _score(12, 4, 12, 1)}, true)
		SIDESTREET:
			common.merge({"publisher_id": &"sidestreet", "title": "SideStreet Cash Contract", "cash_cents": 120000, "advance_cents": 0, "promotion": 0, "denominator": 96, "score": _score(12, 4, 12, 1)}, true)
		SIDESTREET_BRIEF:
			# Private pilot: relationship-only. Cash/Promotion terms remain open.
			common.merge({"publisher_id": &"sidestreet", "title": "SideStreet Relationship Brief", "cash_cents": 0, "advance_cents": 0, "promotion": 0, "denominator": 64, "scope_target": 10, "core_target": 6, "score": _score(10, 4, 6, 1)}, true)
		CROWN:
			common.merge({"publisher_id": &"crown_quill", "title": "Crown & Quill Contract", "cash_cents": 192000, "advance_cents": 15000, "promotion": 12, "denominator": 66, "scope_target": 9, "core_target": 8, "score": _score(9, 2, 8, 1, 8, 2), "stored_terms": {"scope": 9, "cash_cents": 192000, "advance_cents": 15000, "promotion": 12, "denominator": 66}}, true)
		NEON:
			common.merge({"publisher_id": &"neon_circuit", "title": "Neon Circuit Contract", "cash_cents": 156000, "advance_cents": 0, "promotion": 20, "denominator": 86, "scope_target": 10, "core_target": 4, "focus_target": 18, "score": _score(10, 2, 0, 0, 0, 0, 18, 3, 4, 1), "stored_terms": {"scope": 10, "cash_cents": 156000, "advance_cents": 0, "promotion": 20, "denominator": 86}}, true)
		STARWAVE:
			common.merge({"publisher_id": &"starwave", "title": "Starwave Entertainment Contract", "cash_cents": 224000, "advance_cents": 0, "promotion": 0, "denominator": 112, "required_hands": 3, "scope_target": 14, "core_target": 14, "score": _score(14, 4, 14, 1), "stored_terms": {"scope": 14, "cash_cents": 224000, "advance_cents": 0, "promotion": 0, "denominator": 112, "required_hands": 3}}, true)
		_: return {}
	return common if is_valid_definition(common) else {}


static func _score(scope_cap: int, scope_weight: int, core_cap: int, core_weight: int, weakest_cap: int = 0, weakest_weight: int = 0, focus_cap: int = 0, focus_weight: int = 0, other_cap: int = 0, other_weight: int = 0) -> Dictionary:
	return {"scope_cap": scope_cap, "scope_weight": scope_weight, "core_cap": core_cap, "core_weight": core_weight, "weakest_cap": weakest_cap, "weakest_weight": weakest_weight, "focus_cap": focus_cap, "focus_weight": focus_weight, "other_cap": other_cap, "other_weight": other_weight}


static func is_valid_definition(found: Dictionary) -> bool:
	if found.get("version") != VERSION or found.get("id", &"") == &"" or str(found.get("publisher_id", "")).is_empty() or str(found.get("title", "")).is_empty(): return false
	for key in ["required_hands", "scope_target", "core_target", "cash_cents", "advance_cents", "promotion", "denominator"]:
		if typeof(found.get(key)) != TYPE_INT or int(found[key]) < 0: return false
	if int(found.required_hands) == 0 or int(found.scope_target) == 0 or int(found.denominator) == 0 or int(found.advance_cents) > int(found.cash_cents): return false
	if not found.get("stored_terms") is Dictionary or not found.get("score") is Dictionary: return false
	var score: Dictionary = found.score
	for key in ["scope_cap", "scope_weight", "core_cap", "core_weight", "weakest_cap", "weakest_weight", "focus_cap", "focus_weight", "other_cap", "other_weight"]:
		if typeof(score.get(key)) != TYPE_INT or int(score[key]) < 0: return false
	if int(score.scope_cap) != int(found.scope_target): return false
	var maximum: int = int(score.scope_cap) * int(score.scope_weight)
	if int(score.focus_weight) > 0:
		if int(score.core_weight) != 0 or int(score.weakest_weight) != 0 or int(score.focus_cap) <= 0 or int(score.other_cap) <= 0: return false
		maximum += int(score.focus_cap) * int(score.focus_weight) + 3 * int(score.other_cap) * int(score.other_weight)
	else:
		if int(score.focus_cap) != 0 or int(score.other_weight) != 0 or int(score.core_cap) <= 0: return false
		maximum += 4 * int(score.core_cap) * int(score.core_weight) + int(score.weakest_cap) * int(score.weakest_weight)
	if maximum != int(found.denominator): return false
	var stored: Dictionary = found.stored_terms
	if not stored.is_empty():
		for key in ["scope", "cash_cents", "advance_cents", "promotion", "denominator"]:
			var source: String = "scope_target" if key == "scope" else key
			if stored.get(key) != found[source]: return false
		if int(found.required_hands) != int(stored.get("required_hands", 2)): return false
	return true


static func first_unlock_contract_id(publisher: StringName) -> StringName:
	match publisher:
		&"crown_quill": return CROWN
		&"neon_circuit": return NEON
		&"starwave": return STARWAVE
	return &""


static func stored_terms(id: StringName) -> Dictionary:
	var found := definition(id)
	return found.get("stored_terms", {}).duplicate(true)


static func required_hands(id: StringName) -> int:
	return int(definition(id).get("required_hands", 0))


static func scope_target(id: StringName) -> int:
	return int(definition(id).get("scope_target", 0))


static func core_target(id: StringName, category: int, focus: int = -1) -> int:
	var found := definition(id)
	if found.is_empty() or category < 0 or category > 3: return 0
	if id == NEON and category == focus: return int(found.focus_target)
	return int(found.core_target)


static func title(id: StringName, focus: int = -1) -> String:
	var found := definition(id)
	if found.is_empty(): return ""
	if id == NEON:
		if focus < 0 or focus >= STATS.size(): return ""
		return String(found.title) + " — " + String(STATS[focus]).capitalize()
	return String(found.title)


static func evaluate(id: StringName, scope: Variant, cores: Dictionary, focus: int = -1, advance_override: int = -1) -> Dictionary:
	var found := definition(id)
	if found.is_empty() or typeof(scope) != TYPE_INT or scope < 0 or cores.size() != 4: return {}
	if id == NEON and (focus < 0 or focus > 3): return {}
	for category in range(4):
		if typeof(cores.get(category)) != TYPE_INT or cores[category] < 0: return {}
	var score: Dictionary = found.score
	var numerator: int = int(score.scope_weight) * mini(scope, int(score.scope_cap))
	if int(score.focus_weight) > 0:
		for category in range(4):
			numerator += int(score.focus_weight) * mini(cores[category], int(score.focus_cap)) if category == focus else int(score.other_weight) * mini(cores[category], int(score.other_cap))
	else:
		var weakest: int = int(score.weakest_cap)
		for category in range(4):
			numerator += int(score.core_weight) * mini(cores[category], int(score.core_cap))
			if int(score.weakest_weight) > 0: weakest = mini(weakest, cores[category])
		numerator += int(score.weakest_weight) * weakest
	var denominator: int = int(found.denominator)
	if numerator < 0 or numerator > denominator: return {}
	var advance: int = int(found.advance_cents) if advance_override < 0 else advance_override
	if advance < 0 or advance > int(found.cash_cents): return {}
	var remainder: int = (int(found.cash_cents) - advance) * numerator / denominator
	return {"numerator": numerator, "denominator": denominator, "remainder_cents": remainder, "payout_cents": advance + remainder, "promotion": int(found.promotion) * numerator / denominator}
