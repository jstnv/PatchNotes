class_name ContractChallenges
extends RefCounted

## Frozen trial terms and deterministic integer grading. A ContractState owns
## its accepted copy; later catalog changes cannot alter an accepted offer.
const VERSION := 1
const NO_REDRAWS := &"no_redraws_v1"
const BALANCED_CORES := &"balanced_cores_v1"
const CORE_SCOPE_RATIO := &"core_scope_ratio_v1"
const TARGET_CORES := &"target_cores_v1"
const SCOPE_CEILING := &"scope_ceiling_v1"
const FULL := 10000
# Bounds keep every intermediate in evaluate below the signed 64-bit limit.
const MAX_INPUT := 1000000
const BONUS_CASH_CENTS := 10000
const BONUS_PROMOTION := 4


static func terms_for_contract(contract_id: StringName) -> Dictionary:
	var specs := specs_for_contract(contract_id)
	if specs.is_empty(): return {}
	var relationship_only := contract_id == ContractDefinitions.SIDESTREET_BRIEF
	return {"version":VERSION,"specs":specs,"cash_cap_cents":0 if relationship_only else BONUS_CASH_CENTS,"promotion_cap":0 if relationship_only else BONUS_PROMOTION}


static func description(contract_id: StringName) -> String:
	match contract_id:
		ContractDefinitions.SIDESTREET: return "Challenge: no successful redraws and final Scope at most 12. Scope 13–16 reduces the grade; any redraw earns no challenge bonus."
		ContractDefinitions.SIDESTREET_BRIEF: return "Relationship Brief: no successful redraws and final Scope at most 10. Scope 11 halves the promise; Scope 12 or any redraw misses it."
		ContractDefinitions.CROWN: return "Challenge: keep the four final Core scores balanced. Full grade when highest minus lowest is at most 2.0; it fades over another 4.0."
		ContractDefinitions.NEON: return "Challenge: total final Core score must reach 1.5 times final Scope. A lower ratio earns a proportional grade."
		ContractDefinitions.STARWAVE: return "Challenge: aim for 7.0 in every final Core. Above and below count equally; total deviation of 8.0 earns no bonus."
	return ""


static func reward(terms: Dictionary, scope: int, cores: Dictionary, successful_redraws: int) -> Dictionary:
	if terms.is_empty(): return {"grade_bp":0,"cash_cents":0,"promotion":0}
	if not _valid_terms(terms): return {}
	var profile := evaluate_profile(terms.specs, scope, cores, successful_redraws)
	if profile.is_empty(): return {}
	return {"grade_bp":profile.grade_bp,"cash_cents":int(terms.cash_cap_cents) * int(profile.grade_bp) / FULL,
		"promotion":int(terms.promotion_cap) * int(profile.grade_bp) / FULL}


static func _valid_terms(terms: Dictionary) -> bool:
	var caps := [terms.get("cash_cap_cents"),terms.get("promotion_cap")]
	return terms.get("version") == VERSION and caps in [[BONUS_CASH_CENTS,BONUS_PROMOTION],[0,0]] and terms.get("specs") is Array


static func specs_for_contract(contract_id: StringName) -> Array[Dictionary]:
	match contract_id:
		ContractDefinitions.IRONCLAD:
			return []
		ContractDefinitions.SIDESTREET:
			return [{"version": VERSION, "kind": NO_REDRAWS}, {"version": VERSION, "kind": SCOPE_CEILING, "maximum": 12, "fade_excess": 4}]
		ContractDefinitions.SIDESTREET_BRIEF:
			return [{"version": VERSION, "kind": NO_REDRAWS}, {"version": VERSION, "kind": SCOPE_CEILING, "maximum": 10, "fade_excess": 2}]
		ContractDefinitions.CROWN:
			return [{"version": VERSION, "kind": BALANCED_CORES, "allowed_gap": 4, "fade_gap": 8}]
		ContractDefinitions.NEON:
			return [{"version": VERSION, "kind": CORE_SCOPE_RATIO, "core_units": 3, "scope_units": 1}]
		ContractDefinitions.STARWAVE:
			return [{"version": VERSION, "kind": TARGET_CORES, "targets": {0:14,1:14,2:14,3:14}, "fade_total": 16}]
	return []


static func evaluate(spec: Dictionary, scope: Variant, cores: Dictionary, successful_redraws: Variant = 0) -> Dictionary:
	if not _valid_inputs(scope, cores, successful_redraws): return {}
	if spec.get("version") != VERSION or not spec.get("kind") is StringName: return {}
	var kind: StringName = spec.kind
	var grade := -1
	var observed := 0
	match kind:
		NO_REDRAWS:
			if spec.size() != 2: return {}
			observed = successful_redraws
			grade = FULL if observed == 0 else 0
		BALANCED_CORES:
			if not _valid_nonnegative(spec.get("allowed_gap")) or not _valid_positive(spec.get("fade_gap")): return {}
			var low: int = cores[0]
			var high: int = cores[0]
			for category in range(1, 4):
				low = mini(low, cores[category])
				high = maxi(high, cores[category])
			observed = high - low
			grade = _fade(maxi(0, observed - int(spec.allowed_gap)), int(spec.fade_gap))
		CORE_SCOPE_RATIO:
			if not _valid_positive(spec.get("core_units")) or not _valid_positive(spec.get("scope_units")): return {}
			for category in range(4): observed += cores[category]
			var required := int(scope) * int(spec.core_units)
			if required == 0:
				grade = FULL if observed > 0 else 0
			else:
				grade = mini(FULL, observed * int(spec.scope_units) * FULL / required)
		TARGET_CORES:
			if not spec.get("targets") is Dictionary or not _valid_positive(spec.get("fade_total")): return {}
			var targets: Dictionary = spec.targets
			if targets.size() != 4: return {}
			for category in range(4):
				if not _valid_nonnegative(targets.get(category)): return {}
				observed += absi(cores[category] - int(targets[category]))
			grade = _fade(observed, int(spec.fade_total))
		SCOPE_CEILING:
			if not _valid_nonnegative(spec.get("maximum")) or not _valid_positive(spec.get("fade_excess")): return {}
			observed = scope
			grade = _fade(maxi(0, observed - int(spec.maximum)), int(spec.fade_excess))
		_: return {}
	return {"version": VERSION, "kind": kind, "grade_bp": grade, "observed": observed, "met": grade == FULL}


static func evaluate_profile(specs: Array, scope: Variant, cores: Dictionary, successful_redraws: Variant = 0) -> Dictionary:
	if specs.is_empty() or specs.size() > 4: return {}
	var parts: Array[Dictionary] = []
	var grade := FULL
	var seen: Dictionary = {}
	for item in specs:
		if not item is Dictionary: return {}
		var result := evaluate(item, scope, cores, successful_redraws)
		if result.is_empty() or seen.has(result.kind): return {}
		seen[result.kind] = true
		parts.append(result)
		grade = mini(grade, int(result.grade_bp))
	return {"version": VERSION, "grade_bp": grade, "met": grade == FULL, "parts": parts}


static func _valid_inputs(scope: Variant, cores: Dictionary, successful_redraws: Variant) -> bool:
	if not _valid_nonnegative(scope) or not _valid_nonnegative(successful_redraws) or cores.size() != 4: return false
	for category in range(4):
		if not _valid_nonnegative(cores.get(category)): return false
	return true


static func _valid_nonnegative(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 0 and value <= MAX_INPUT


static func _valid_positive(value: Variant) -> bool:
	return _valid_nonnegative(value) and value > 0


static func _fade(excess: int, width: int) -> int:
	return maxi(0, FULL - mini(FULL, excess * FULL / width))
