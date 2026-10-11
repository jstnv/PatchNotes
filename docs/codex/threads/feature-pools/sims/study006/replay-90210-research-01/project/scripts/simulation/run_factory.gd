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
	for id in RunRandom.STREAMS: run.random_streams.stream(id).seed = int(recipe.seed)+RunRandom.STREAMS.find(id)
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers(): return null
	var session := Session.new()
	return session if session.initialize(run,definitions,snapshots) else null

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
