class_name ContractState
extends RefCounted

const CONTRACT_ID := &"balanced_primitive_contract_v1"
const SIDESTREET_CONTRACT_ID := &"sidestreet_cash_contract_v1"
const SIDESTREET_INVESTMENT_CENTS := 120000
const REQUIRED_HANDS := 2
const EXPECTED_SCOPE := 12
const EXPECTED_CORE_HALF_UNITS := 12
const PUBLISHER_INVESTMENT_CENTS := 240000
const GUARANTEED_UPFRONT_CENTS := 40000
const COMPLETION_BUDGET_CENTS := PUBLISHER_INVESTMENT_CENTS - GUARANTEED_UPFRONT_CENTS
const COMPLETION_DENOMINATOR := 96
const CORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}
const PASS_IDS: Array[StringName] = [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"]

var _eligible_feature_ids: Dictionary = {}
var _scope := 0
var _core_half_units: Dictionary = {}
var _successful_hands := 0
var _exhausted_feature_ids: Dictionary = {}
var _priorities: Dictionary = {}
var _result: ContractResult
var _upfront_committed := false
var _publisher_connections := false
var _payout_committed := false
var _contract_id: StringName = CONTRACT_ID
var _offer_id: StringName = CONTRACT_ID
var _source_release_id: StringName
var _trial_terms: Dictionary = {}
var _neon_focus := -1


func _init(eligible_feature_ids: Array[StringName] = [], contract_id: StringName = CONTRACT_ID, offer_id: StringName = CONTRACT_ID, source_release_id: StringName = &"") -> void:
	_contract_id = contract_id
	_offer_id = offer_id
	_source_release_id = source_release_id
	for id in eligible_feature_ids:
		if not id.is_empty():
			_eligible_feature_ids[id] = true
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		_core_half_units[category] = 0
		_priorities[category] = PriorityAllocation.INITIAL_PRIORITY


func get_contract_id() -> StringName:
	return _contract_id


func get_offer_id() -> StringName:
	return _offer_id


func get_source_release_id() -> StringName:
	return _source_release_id


func get_scope() -> int:
	return _scope


func get_core_score_half_units(category: ProjectState.CoreScore) -> int:
	return _core_half_units.get(category, 0)


func get_successful_hand_count() -> int:
	return _successful_hands


func get_priority_distribution() -> Dictionary:
	return _priorities.duplicate()


func get_eligible_feature_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_eligible_feature_ids.keys())
	return result


func get_exhausted_feature_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_exhausted_feature_ids.keys())
	return result


func is_feature_eligible(id: StringName) -> bool:
	return _eligible_feature_ids.has(id)


func is_feature_exhausted(id: StringName) -> bool:
	return _exhausted_feature_ids.has(id)


func is_completed() -> bool:
	return _result != null


func get_result() -> ContractResult:
	return _result


func is_payout_committed() -> bool:
	return _payout_committed


func is_upfront_committed() -> bool:
	return _upfront_committed


## RunState calls this only while atomically accepting the one-shot offer.
func commit_upfront() -> bool:
	if _upfront_committed or _successful_hands != 0 or is_completed():
		return false
	_upfront_committed = true
	return true


func can_commit_priorities(distribution: Dictionary) -> bool:
	return not is_completed() and PriorityAllocation.is_valid_distribution(distribution) and distribution != _priorities


func commit_priorities(distribution: Dictionary) -> bool:
	if not can_commit_priorities(distribution):
		return false
	_priorities = distribution.duplicate()
	return true


func plan_hand(cards: Array[CardData]) -> Dictionary:
	if is_completed() or _successful_hands >= REQUIRED_HANDS or cards.size() != 4:
		return {}
	var seen_features: Dictionary = {}
	var specialization_stat := cards[0].primary_stat if not cards.is_empty() else StringName()
	if not CORE_BY_STAT.has(specialization_stat):
		return {}
	for card in cards:
		if not _is_valid_card(card):
			return {}
		if card.primary_stat != specialization_stat:
			specialization_stat = &""
		if card.card_type == &"feature":
			if seen_features.has(card.id):
				return {}
			seen_features[card.id] = true
	var score_additions: Dictionary = {}
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		score_additions[category] = 0
	var scope_addition := 0
	for card in cards:
		if card.scope > RunState.MAX_SIGNED_INT - scope_addition:
			return {}
		scope_addition += card.scope
		var multiplier := 3 if not specialization_stat.is_empty() else 2
		if not _add_score(score_additions, card.primary_stat, card.primary_value, multiplier):
			return {}
		if not card.secondary_stat.is_empty() and not _add_score(score_additions, card.secondary_stat, card.secondary_value, multiplier):
			return {}
	if scope_addition > RunState.MAX_SIGNED_INT - _scope:
		return {}
	var projected_scores := _core_half_units.duplicate()
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		var addition: int = score_additions[category]
		if addition > RunState.MAX_SIGNED_INT - int(projected_scores[category]):
			return {}
		projected_scores[category] += addition
	var completing := _successful_hands + 1 == REQUIRED_HANDS
	var numerator := 0
	var remainder := 0
	var total_payout := 0
	if completing:
		var completion := calculate_for_state(_scope + scope_addition, projected_scores)
		if completion.is_empty():
			return {}
		numerator = completion.numerator
		remainder = completion.remainder_cents
		total_payout = completion.payout_cents
	return {
		"expected_hand_count": _successful_hands,
		"scope_addition": scope_addition,
		"score_additions": score_additions,
		"exhausted_ids": seen_features.keys(),
		"specialization_stat": specialization_stat,
		"completing": completing,
		"completion_numerator": numerator,
		"remainder_cents": remainder,
		"payout_cents": total_payout,
	}


func commit_hand(cards: Array[CardData], expected_remainder_cents: int) -> bool:
	if not _upfront_committed:
		return false
	var plan := plan_hand(cards)
	if plan.is_empty() or plan.expected_hand_count != _successful_hands or plan.remainder_cents != expected_remainder_cents:
		return false
	_scope += plan.scope_addition
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		_core_half_units[category] += plan.score_additions[category]
	for id: StringName in plan.exhausted_ids:
		_exhausted_feature_ids[id] = true
	_successful_hands += 1
	if plan.completing:
		var completion := calculate_for_state(_scope,_core_half_units)
		_result = ContractResult.new(_scope, _core_half_units, plan.completion_numerator, plan.payout_cents, plan.remainder_cents, get_advance_cents(), int(completion.get("denominator",96)), int(completion.get("promotion",0)))
		_payout_committed = true
	return true


static func calculate_completion(scope: Variant, core_half_units: Dictionary) -> Dictionary:
	return _calculate_completion_for_budget(scope, core_half_units, COMPLETION_BUDGET_CENTS, GUARANTEED_UPFRONT_CENTS)


static func calculate_sidestreet_completion(scope: Variant, core_half_units: Dictionary) -> Dictionary:
	return _calculate_completion_for_budget(scope, core_half_units, SIDESTREET_INVESTMENT_CENTS, 0)


static func _calculate_completion_for_budget(scope: Variant, core_half_units: Dictionary, budget_cents: int, upfront_cents: int) -> Dictionary:
	if typeof(scope) != TYPE_INT or scope < 0 or core_half_units.size() != PriorityAllocation.CORE_CATEGORIES.size():
		return {}
	var numerator := 4 * mini(int(scope), EXPECTED_SCOPE)
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not core_half_units.has(category) or typeof(core_half_units[category]) != TYPE_INT or core_half_units[category] < 0:
			return {}
		numerator += mini(int(core_half_units[category]), EXPECTED_CORE_HALF_UNITS)
	if numerator < 0 or numerator > COMPLETION_DENOMINATOR:
		return {}
	var remainder := (budget_cents * numerator) / COMPLETION_DENOMINATOR
	return {"numerator": numerator, "remainder_cents": remainder, "payout_cents": upfront_cents + remainder}


func _is_valid_card(card: CardData) -> bool:
	if card == null or card.primary_value < 0 or card.scope < 0 or not CORE_BY_STAT.has(card.primary_stat):
		return false
	if card.secondary_stat.is_empty() != (card.secondary_value == 0):
		return false
	if not card.secondary_stat.is_empty() and (not CORE_BY_STAT.has(card.secondary_stat) or card.secondary_value < 0):
		return false
	if card.card_type == &"feature":
		return is_feature_eligible(card.id) and not is_feature_exhausted(card.id) and not card.renewable and card.phase in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA]
	return card.card_type == &"pass" and card.renewable and card.id in PASS_IDS


func _add_score(additions: Dictionary, stat: StringName, value: int, multiplier: int) -> bool:
	if value < 0 or value > RunState.MAX_SIGNED_INT / multiplier:
		return false
	var category: ProjectState.CoreScore = CORE_BY_STAT[stat]
	var amount := value * multiplier
	if amount > RunState.MAX_SIGNED_INT - int(additions[category]):
		return false
	additions[category] += amount
	return true

func freeze_trial(focus: int) -> bool:
	var terms := PublisherTrialTerms.terms(_contract_id)
	if terms.is_empty() or _upfront_committed or not _trial_terms.is_empty(): return false
	if _contract_id==PublisherTrialTerms.NEON and (focus<0 or focus>3): return false
	_trial_terms = terms
	_neon_focus = focus if _contract_id==PublisherTrialTerms.NEON else -1
	return true

func calculate_for_state(scope: int, cores: Dictionary) -> Dictionary:
	if _contract_id in [PublisherTrialTerms.CROWN,PublisherTrialTerms.NEON]:
		if _trial_terms!=PublisherTrialTerms.terms(_contract_id): return {}
		return PublisherTrialTerms.completion(_contract_id,scope,cores,_neon_focus)
	if _contract_id==SIDESTREET_CONTRACT_ID: return calculate_sidestreet_completion(scope,cores)
	if _contract_id==CONTRACT_ID: return _calculate_completion_for_budget(scope,cores,PUBLISHER_INVESTMENT_CENTS-get_advance_cents(),get_advance_cents())
	return {}

func get_advance_cents() -> int:
	if not _trial_terms.is_empty(): return _trial_terms.advance_cents
	return 0 if _contract_id==SIDESTREET_CONTRACT_ID else GUARANTEED_UPFRONT_CENTS + (15000 if _publisher_connections else 0)

func get_scope_target() -> int: return int(_trial_terms.get("scope",EXPECTED_SCOPE))

func get_core_target(category: int) -> int:
	if _contract_id==PublisherTrialTerms.CROWN: return 8
	if _contract_id==PublisherTrialTerms.NEON: return 18 if category==_neon_focus else 4
	return EXPECTED_CORE_HALF_UNITS

func get_title() -> String:
	if _contract_id==PublisherTrialTerms.CROWN: return "Crown & Quill Contract"
	if _contract_id==PublisherTrialTerms.NEON: return "Neon Circuit Contract — "+String(PublisherTrialTerms.STATS[_neon_focus]).capitalize()
	return "SideStreet Cash Contract" if _contract_id==SIDESTREET_CONTRACT_ID else "Balanced Primitive Contract"
