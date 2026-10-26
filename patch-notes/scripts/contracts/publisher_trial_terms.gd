class_name PublisherTrialTerms
extends RefCounted

const CROWN := ContractDefinitions.CROWN
const NEON := ContractDefinitions.NEON
const STARWAVE := ContractDefinitions.STARWAVE
const STATS := ContractDefinitions.STATS

static func terms(id: StringName) -> Dictionary:
	return ContractDefinitions.stored_terms(id)

static func contract_id(publisher: StringName) -> StringName:
	return ContractDefinitions.first_unlock_contract_id(publisher)

static func focus(eligible: Array[StringName]) -> int:
	var totals: Array[int] = [0,0,0,0]
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		if StringName(entry.id) not in eligible: continue
		var index := STATS.find(StringName(entry.primary_stat))
		if index>=0: totals[index] += int(entry.primary_value)
	var selected := 0
	for index in range(1,4):
		if totals[index]>totals[selected]: selected = index
	return selected

static func completion(id: StringName, scope: int, cores: Dictionary, selected: int = -1) -> Dictionary:
	if id not in [CROWN, NEON, STARWAVE]: return {}
	return ContractDefinitions.evaluate(id, scope, cores, selected)
