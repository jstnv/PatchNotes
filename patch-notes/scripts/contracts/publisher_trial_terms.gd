class_name PublisherTrialTerms
extends RefCounted

const CROWN := &"crown_quill_primitive_trial_v1"
const NEON := &"neon_circuit_primitive_trial_v1"
const STATS := [&"graphics",&"sound",&"technology",&"design"]

static func terms(id: StringName) -> Dictionary:
	if id==CROWN: return {"scope":9,"cash_cents":192000,"advance_cents":15000,"promotion":12,"denominator":66}
	if id==NEON: return {"scope":10,"cash_cents":156000,"advance_cents":0,"promotion":20,"denominator":86}
	return {}

static func contract_id(publisher: StringName) -> StringName:
	return CROWN if publisher==PublisherCatalog.CROWN_QUILL else NEON if publisher==PublisherCatalog.NEON_CIRCUIT else &""

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
	var t := terms(id)
	if t.is_empty() or scope<0 or cores.size()!=4: return {}
	for category in range(4):
		if typeof(cores.get(category))!=TYPE_INT or cores[category]<0: return {}
	# Approved fixed shares simplify exactly: 18*Scope/9 and 20*Scope/10.
	# All arithmetic below is integral, capped before multiplication.
	var numerator := 2*mini(scope,t.scope)
	if id==CROWN:
		var smallest := 8
		for category in range(4):
			var capped := mini(cores[category],8)
			numerator += capped
			smallest = mini(smallest,capped)
		numerator += 2*smallest
	else:
		if selected<0 or selected>3: return {}
		for category in range(4): numerator += 3*mini(cores[category],18) if category==selected else mini(cores[category],4)
	var remainder: int = (int(t.cash_cents)-int(t.advance_cents))*numerator/int(t.denominator)
	return {"numerator":numerator,"denominator":t.denominator,"remainder_cents":remainder,"payout_cents":int(t.advance_cents)+remainder,"promotion":int(t.promotion)*numerator/int(t.denominator)}
