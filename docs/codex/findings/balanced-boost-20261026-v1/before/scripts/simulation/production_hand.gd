## Pure final production arithmetic for an already validated Design/Alpha hand.
## Records need only primary_stat. No legality, lifecycle, RNG or state mutation.
extends RefCounted

const BalancedProduction := preload("res://scripts/cards/balanced_production.gd")
const SPECIALIZATION_MULTIPLIER := 1.5
const CORE_STATS := [&"graphics", &"sound", &"technology", &"design"]

static func specialization_stat(records: Array) -> StringName:
	if records.size() != 4:
		return &""
	var stat: StringName = records[0].primary_stat
	if stat not in CORE_STATS:
		return &""
	for record in records:
		if record.primary_stat != stat:
			return &""
	return stat

static func specialize(scores: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var result: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in scores:
		result[category] = roundi(int(scores[category]) * SPECIALIZATION_MULTIPLIER)
	return result

static func calculate(records: Array, scores: Dictionary, has_feature: bool) -> Dictionary:
	var stat := specialization_stat(records)
	var eligible := has_feature and BalancedProduction.qualifies(scores)
	var additions: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in scores:
		additions[category] = scores[category]
	if not stat.is_empty():
		additions = specialize(scores)
	elif eligible:
		additions = BalancedProduction.redistribute(scores)
	return {
		&"specialization_stat": stat,
		&"balanced_production": stat.is_empty() and eligible,
		&"balanced_eligible": eligible,
		&"score_additions": additions,
	}
