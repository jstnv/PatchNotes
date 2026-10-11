## Deterministic test bootstrap. This is not a player save migration or a rival
## starting-resource policy. Every identity, seed and Studio choice is supplied.
extends RefCounted

const Session := preload("res://scripts/simulation/campaign_session.gd")

static func create_fresh_session(recipe: Variant, definitions: RefCounted) -> RefCounted:
	if definitions == null or not recipe is Dictionary or recipe.get("schema_version") != 1: return null
	for field in ["studio_id","studio_name","specialty","seed"]:
		if not recipe.get(field) is String or recipe[field].is_empty(): return null
	if not recipe.seed.is_valid_int() or int(recipe.seed) < 0 or int(recipe.seed) > ProjectState.MAX_SIGNED_INT-RunRandom.STREAMS.size() or not recipe.get("traits") is Array: return null
	var traits: Array[StringName] = []
	for id: Variant in recipe.traits:
		if not id is String: return null
		traits.append(StringName(id))
	var run := RunState.new()
	run.initialize_cash(0)
	if not run.create_studio_with_traits(recipe.studio_name,StringName(recipe.specialty),traits): return null
	# Keep all generated references coherent, including education opening records.
	var generated := String(run._bank_run_id)
	var stable := String(recipe.studio_id)
	run._studio_finance = _replace_identity(run._studio_finance,generated,stable)
	run._bank_run_id = StringName(stable)
	run._employees = EmployeeRoster.create(StringName(stable))
	if recipe.has("incumbent") and not _apply_incumbent(run,recipe.incumbent): return null
	for id in RunRandom.STREAMS: run.random_streams.stream(id).seed = int(recipe.seed)+RunRandom.STREAMS.find(id)
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): return null
	var session := Session.new()
	return session if session.initialize(run,definitions,snapshots) else null

## Candidate bootstrap only. All post-start activity uses the ordinary commands.
static func _apply_incumbent(run: RunState, fixture: Variant) -> bool:
	if not fixture is Dictionary or fixture.size()!=2 or not fixture.get("owned_features") is Array or not fixture.get("historical_titles") is Array: return false
	var added := {}
	for value: Variant in fixture.owned_features:
		if not value is String or value.is_empty(): return false
		var id := StringName(value)
		if added.has(id) or run._owned_features.has(id) or not run._feature_definitions.has(id): return false
		added[id] = true
	for id: StringName in added: run._owned_features[id] = true
	for id: StringName in run._owned_features:
		if not run._feature_offers.has(id): continue
		var parent := StringName(run._feature_offers[id].purchase_parent)
		if not parent.is_empty() and not run._owned_features.has(parent): return false
	var seen := {}
	var archive: Array = []
	for value: Variant in fixture.historical_titles:
		if not value is Dictionary or value.size()!=6: return false
		for key in ["id","title","genre","theme"]:
			if not value.get(key) is String or value[key].is_empty(): return false
		if not _whole_in_range(value.get("year"),1,RunState.START_YEAR-1) or not _whole_in_range(value.get("review_tenths"),0,100): return false
		if seen.has(value.id) or PrimitivePredevelopment.find_entry("genres",StringName(value.genre)).is_empty() or PrimitivePredevelopment.find_entry("themes",StringName(value.theme)).is_empty(): return false
		seen[value.id] = true
		archive.append({"id":StringName(value.id),"title":String(value.title),"genre":StringName(value.genre),"theme":StringName(value.theme),"year":int(value.year),"review_tenths":int(value.review_tenths)})
	run._historical_titles = archive
	run._opening_snapshot = {"version":1,"studio_id":run._bank_run_id,"year":RunState.START_YEAR,"cash_cents":run.get_cash_cents(),"fans":run.get_fans(),"owned_features":run.get_owned_feature_ids(),"research_queue_empty":run._feature_research.is_empty(),"familiarity_empty":run._familiarity.is_empty(),"historical_title_count":archive.size()}
	return true

static func _whole_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=minimum and value<=maximum

## Exactly one input boundary. Active development snapshots are not accepted.
static func create(initial: Dictionary, definitions: RefCounted) -> RefCounted:
	if initial.size() != 1: return null
	if initial.has("recipe"): return create_fresh_session(initial.recipe,definitions)
	if not initial.get("checkpoint") is Dictionary or definitions == null: return null
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): return null
	var session := Session.new()
	return session if session.restore_checkpoint(initial.checkpoint,definitions,snapshots) else null

static func _replace_identity(value: Variant, old: String, replacement: String) -> Variant:
	if value is StringName: return StringName(String(value).replace(old,replacement))
	if value is String: return value.replace(old,replacement)
	if value is Array:
		var result: Array = value.duplicate(true)
		for index in range(result.size()): result[index] = _replace_identity(result[index],old,replacement)
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[_replace_identity(key,old,replacement)] = _replace_identity(value[key],old,replacement)
		return result
	return value
