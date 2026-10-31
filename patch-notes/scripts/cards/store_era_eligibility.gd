extends RefCounted

## Entitlements use immutable committed launch facts, never owned Scope/count.
const PRE_ERA_FEATURE_IDS := ["text", "sprites", "4_color_palette", "8_bit_sound", "8_bit_music", "keyboard_and_mouse", "controller", "scrolling", "menu_system", "local_leaderboards", "split_screen", "score_system", "lives_system", "simple_story", "dialogue", "character_backstories", "multiple_endings", "controls", "enemies", "power_ups", "general_combat", "levels", "maps", "exploration", "secrets", "sound_effects", "music", "colored_text", "animated_sprites", "8_color_palette", "recorded_sounds", "16_bit_music", "save_files", "scripted_ai", "multi_directional_scrolling", "branching_nodes", "difficulty_levels", "high_scores", "turn_based_combat", "character_classes", "character_development", "branching_dialogue"]
const ERAS := [1984, 1990, 2000, 2010, 2020, 2026]

static func qualifies(meta: Dictionary, known_studio_owner: bool) -> bool:
	if meta.has("owner"):
		if meta.owner != &"studio": return false
	elif not known_studio_owner: return false
	if typeof(meta.get("release_cycle")) != TYPE_INT or meta.release_cycle < 0: return false
	if not meta.get("review") is Dictionary: return false
	var review: Dictionary = meta.review
	# A known schema alone cannot prove an internally contradictory frozen Review.
	var completion: Variant = review.get("scope_completion")
	if typeof(completion) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(completion)) or float(completion) != 1.0: return false
	return typeof(review.get("required_scope")) == TYPE_INT and review.required_scope > 0 and typeof(review.get("scope")) == TYPE_INT and review.scope >= review.required_scope

static func assign(qualified: Array) -> Dictionary:
	var ordered := qualified.duplicate(true)
	var seen := {}
	for entry: Variant in ordered:
		if not entry is Dictionary: return {}
		var id: Variant = entry.get("release_id")
		if not id is StringName or id.is_empty() or seen.has(id): return {}
		if typeof(entry.get("release_cycle")) != TYPE_INT or entry.release_cycle < 0: return {}
		seen[id] = true
	ordered.sort_custom(func(a: Dictionary,b: Dictionary): return a.release_cycle < b.release_cycle if a.release_cycle != b.release_cycle else str(a.release_id) < str(b.release_id))
	var assignments := {}
	for index in mini(ordered.size(),ERAS.size()): assignments[ERAS[index]] = ordered[index].release_id
	return {"version":1,"assignments":assignments}

## Call only with committed metadata from the authoritative Run or a validated
## named predecessor. Missing owner historically meant Studio in those schemas.
static func from_releases(metadata: Dictionary) -> Dictionary:
	var qualified: Array = []
	for id: StringName in metadata:
		if qualifies(metadata[id],true): qualified.append({"release_id":id,"release_cycle":metadata[id].release_cycle})
	return assign(qualified)

static func valid(receipts: Dictionary, metadata: Dictionary) -> bool:
	return receipts == from_releases(metadata)

static func metadata_error(entry: Dictionary) -> String:
	if entry.has("min_year") and (not _year(entry.min_year) or entry.min_year < 1980): return "Invalid minimum year"
	if entry.has("era_year") and (not _year(entry.era_year) or int(entry.era_year) not in ERAS or not entry.has("min_year") or entry.min_year < entry.era_year): return "Invalid era year"
	return ""

static func _year(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and absf(float(value)) <= 9007199254740991.0 and float(value) == floor(float(value))

static func predecessor_features_known(state: Dictionary) -> bool:
	for id in state.owned_features:
		if str(id) not in PRE_ERA_FEATURE_IDS: return false
	for entry: Dictionary in state.feature_research:
		if str(entry.feature_id) not in PRE_ERA_FEATURE_IDS: return false
	return true

## Newly introduced finite children have no historical/grant exemption. Existing
## untagged Features keep their original ownership and paid-queue conventions.
static func valid_research(state: Dictionary, definitions: Dictionary) -> bool:
	var completed := {}
	for entry: Dictionary in state.feature_research:
		if entry.payments.size() == entry.actions: completed[entry.feature_id] = true
		var definition: Dictionary = definitions[entry.feature_id]
		if not definition.has("min_year"): continue
		if int(state.get("calendar_start_year",1980)) + entry.admitted_cycle / 24 < int(definition.min_year): return false
		if definition.has("era_year"):
			var release_id: StringName = state.store_era_receipts.assignments.get(int(definition.era_year),&"")
			if not state.release_metadata.has(release_id) or state.release_metadata[release_id].release_cycle > entry.admitted_cycle: return false
		for parent in definition.get("purchase_parents",[]):
			if not state.owned_features.has(StringName(parent)): return false
			for prior: Dictionary in state.feature_research:
				if prior.feature_id == StringName(parent) and (prior.payments.is_empty() or prior.payments.back().cycle > entry.admitted_cycle): return false
	for entry: Dictionary in state.get("engine_features",{}).get("entries",[]):
		if entry.engine_id==&"legacy_engine" and entry.payment!=null:completed[entry.feature_id]=true
		var definition: Dictionary=definitions.get(entry.feature_id,{})
		if not definition.has("min_year"):continue
		if int(state.get("calendar_start_year",1980))+int(entry.admitted_cycle)/24<int(definition.min_year):return false
		if definition.has("era_year"):
			var release_id: StringName=state.store_era_receipts.assignments.get(int(definition.era_year),&"")
			if not state.release_metadata.has(release_id) or state.release_metadata[release_id].release_cycle>entry.admitted_cycle:return false
	for id: StringName in state.owned_features:
		if definitions.has(id) and definitions[id].has("min_year") and not completed.has(id): return false
	return true
