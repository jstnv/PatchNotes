## Development boundary rules shared by scenes and the replay runner.
## The catalog is a RefCounted provider containing canonical immutable CardData.
extends RefCounted

const PERFECT_PRODUCTION_THRESHOLD := 0.05
const PERFECT_BUG_PRESSURE_MULTIPLIER := 0.80
const BUG_VARIANCE_NEGATIVE_TWO_THRESHOLD := 0.08
const BUG_VARIANCE_NEGATIVE_ONE_THRESHOLD := 0.25
const BUG_VARIANCE_ZERO_THRESHOLD := 0.75
const BUG_VARIANCE_POSITIVE_ONE_THRESHOLD := 0.92
const FINITE_IDS = preload("res://scripts/simulation/beta_hand_command.gd").FINITE_IDS
var _project_state: ProjectState
var _exhausted_card_ids: Dictionary[StringName,bool] = {}
var _exhausted_feature_ids: Dictionary[StringName,bool] = {}
var catalog: RefCounted

func _build_design_feature_history() -> Dictionary:
	var card_database := catalog
	var definitions: Array[CardData] = []
	definitions.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_DESIGN))
	var eligible_ids: Dictionary[StringName, bool] = {}
	for card in definitions:
		if (
			card == null
			or card.id.is_empty()
			or card.phase != CardData.PHASE_DESIGN
			or card.card_type != &"feature"
			or card.renewable
			or eligible_ids.has(card.id)
		):
			push_warning("Cannot finalize invalid Design Feature definition history.")
			return {&"valid": false}
		eligible_ids[card.id] = true
	for exhausted_id: StringName in _exhausted_card_ids:
		if not eligible_ids.has(exhausted_id):
			push_warning("Exhausted ID is not an eligible Design Feature: %s" % exhausted_id)
			return {&"valid": false}

	var implemented_ids: Array[StringName] = []
	var unimplemented_ids: Array[StringName] = []
	for id: StringName in eligible_ids:
		if _exhausted_card_ids.has(id):
			implemented_ids.append(id)
		else:
			unimplemented_ids.append(id)
	implemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	unimplemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	if not _is_valid_design_feature_history(implemented_ids, unimplemented_ids, definitions):
		return {&"valid": false}
	return {
		&"valid": true,
		&"implemented_ids": implemented_ids,
		&"unimplemented_ids": unimplemented_ids,
	}


func _is_valid_design_feature_history(implemented_ids: Array, unimplemented_ids: Array, definitions: Array[CardData]) -> bool:
	var card_database := catalog
	var expected_ids: Dictionary[StringName, bool] = {}
	for card in definitions:
		expected_ids[card.id] = true
	var seen: Dictionary[StringName, bool] = {}
	for raw_id: Variant in implemented_ids + unimplemented_ids:
		if typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME:
			return false
		var id := StringName(raw_id)
		if id.is_empty() or seen.has(id):
			return false
		var card: CardData = card_database.call(&"get_card", id)
		if card == null or card.phase != CardData.PHASE_DESIGN or card.card_type != &"feature" or card.renewable:
			return false
		seen[id] = true
	if seen.size() != expected_ids.size():
		return false
	for id: StringName in expected_ids:
		if not seen.has(id):
			return false
	return true


func _calculate_design_finalization(stochastic_roll: float, variance_roll: float) -> Dictionary:
	if (
		not is_finite(stochastic_roll)
		or stochastic_roll < 0.0
		or stochastic_roll >= 1.0
		or not is_finite(variance_roll)
		or variance_roll < 0.0
		or variance_roll >= 1.0
	):
		return {&"valid": false}

	var perfect_production := _is_perfect_production()
	var accumulated_bug_pressure := _project_state.get_accumulated_bug_pressure()
	var adjusted_bug_pressure := accumulated_bug_pressure
	if perfect_production:
		adjusted_bug_pressure *= PERFECT_BUG_PRESSURE_MULTIPLIER
	var rounded_bug_base := floori(adjusted_bug_pressure)
	var fraction := adjusted_bug_pressure - rounded_bug_base
	if stochastic_roll < fraction:
		rounded_bug_base += 1
	var hidden_bugs := maxi(0, rounded_bug_base + _get_bug_variance(variance_roll))
	return {
		&"valid": true,
		&"perfect_production": perfect_production,
		&"adjusted_bug_pressure": adjusted_bug_pressure,
		&"hidden_bugs": hidden_bugs,
	}


func _is_perfect_production() -> bool:
	var scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		scores[category] = _project_state.get_core_score(category)
	return _are_core_scores_perfect(scores)


func _are_core_scores_perfect(scores: Dictionary) -> bool:
	var total := 0
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		total += scores.get(category, 0)
	var mean := total / 4.0
	var lower_bound := mean * (1.0 - PERFECT_PRODUCTION_THRESHOLD)
	var upper_bound := mean * (1.0 + PERFECT_PRODUCTION_THRESHOLD)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score: int = scores.get(category, 0)
		if score < lower_bound or score > upper_bound:
			return false
	return true


func _get_bug_variance(roll: float) -> int:
	if roll < 0.08:
		return -2
	if roll < 0.25:
		return -1
	if roll < 0.75:
		return 0
	if roll < 0.92:
		return 1
	return 2


func _build_alpha_feature_history(report_errors: bool = true) -> Dictionary:
	var card_database := catalog
	if card_database == null:
		if report_errors:
			push_warning("Cannot finalize Alpha Feature history without CardDatabase.")
		return {&"valid": false}
	var definitions: Array[CardData] = []
	definitions.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_ALPHA))
	var eligible_ids: Dictionary[StringName, bool] = {}
	for card: CardData in definitions:
		if (
			card == null
			or card.id.is_empty()
			or card.phase != CardData.PHASE_ALPHA
			or card.card_type != &"feature"
			or card.renewable
			or eligible_ids.has(card.id)
		):
			if report_errors:
				push_warning("Cannot finalize invalid Alpha Feature definition history.")
			return {&"valid": false}
		eligible_ids[card.id] = true
	for exhausted_id: StringName in _exhausted_feature_ids:
		if not eligible_ids.has(exhausted_id):
			if report_errors:
				push_warning("Exhausted ID is not an eligible Alpha Feature: %s" % exhausted_id)
			return {&"valid": false}

	var implemented_ids: Array[StringName] = []
	var unimplemented_ids: Array[StringName] = []
	for id: StringName in eligible_ids:
		if _exhausted_feature_ids.has(id):
			implemented_ids.append(id)
		else:
			unimplemented_ids.append(id)
	implemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	unimplemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return {
		&"valid": true,
		&"implemented_ids": implemented_ids,
		&"unimplemented_ids": unimplemented_ids,
	}


func _calculate_alpha_finalization(stochastic_roll: float, variance_roll: float) -> Dictionary:
	if (
		_project_state == null
		or not is_finite(stochastic_roll)
		or stochastic_roll < 0.0
		or stochastic_roll >= 1.0
		or not is_finite(variance_roll)
		or variance_roll < 0.0
		or variance_roll >= 1.0
	):
		return {&"valid": false}
	var pressure := _project_state.get_accumulated_alpha_bug_pressure()
	if not is_finite(pressure) or pressure < 0.0:
		return {&"valid": false}
	var base := floori(pressure)
	var fraction := pressure - base
	var rounded := base + (1 if stochastic_roll < fraction else 0)
	var variance := _get_alpha_bug_variance(variance_roll)
	var generated := maxi(0, rounded + variance)
	return {
		&"valid": true,
		&"pressure": pressure,
		&"base": base,
		&"rounded": rounded,
		&"variance": variance,
		&"generated": generated,
	}


func _get_alpha_bug_variance(roll: float) -> int:
	if roll < BUG_VARIANCE_NEGATIVE_TWO_THRESHOLD:
		return -2
	if roll < BUG_VARIANCE_NEGATIVE_ONE_THRESHOLD:
		return -1
	if roll < BUG_VARIANCE_ZERO_THRESHOLD:
		return 0
	if roll < BUG_VARIANCE_POSITIVE_ONE_THRESHOLD:
		return 1
	return 2


func _build_launch_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var current_scope := _project_state.get_current_scope()
	var required_scope := _project_state.get_required_scope()
	if current_scope < required_scope:
		warnings.append("Project Scope is incomplete: %d / %d." % [current_scope, required_scope])
		warnings.append("Scope shortfall: %d." % (required_scope - current_scope))
	var known_bugs := _project_state.get_known_bugs()
	if known_bugs > 0:
		warnings.append("Known Bugs remaining: %d. Unresolved Known Bugs will remain at launch." % known_bugs)
	if _project_state.get_marketing_output() == 0:
		warnings.append("No Marketing activity has been completed. Launch reach may be reduced.")
	return warnings


func _validate_exhausted_beta_ids(database: RefCounted) -> bool:
	for id: StringName in _project_state.get_exhausted_beta_card_ids():
		var card: CardData = database.call(&"get_card", id)
		if card == null or card.phase != CardData.PHASE_BETA or card.renewable or not FINITE_IDS.has(id):
			return false
	return true


func _validate_feature_histories(database: RefCounted) -> bool:
	var histories := [
		[_project_state.get_implemented_design_feature_ids(), _project_state.get_unimplemented_design_feature_ids(), CardData.PHASE_DESIGN],
		[_project_state.get_implemented_alpha_feature_ids(), _project_state.get_unimplemented_alpha_feature_ids(), CardData.PHASE_ALPHA],
	]
	for history: Array in histories:
		var seen: Dictionary[StringName, bool] = {}
		for collection: Array in [history[0], history[1]]:
			for id: StringName in collection:
				var card: CardData = database.call(&"get_card", id)
				if seen.has(id) or card == null or card.phase != history[2] or card.card_type != &"feature":
					return false
				seen[id] = true
	return true


