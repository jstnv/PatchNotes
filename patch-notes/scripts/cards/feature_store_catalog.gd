class_name FeatureStoreCatalog
extends RefCounted

## Core Feature Ledger (1981–1983). Prices are the prototype store baseline.
## Keep separate from the fixed Primitive draw/contract ledger.
## Retained definitions support old saves and frozen projects; not new supply.
const RETIRED_IDS: Array[StringName] = [&"music", &"sound_effects", &"8_bit_music", &"16_bit_music"]

static func is_active(id: StringName) -> bool:
	return id not in RETIRED_IDS

static func future_supply(owned: Array[StringName], offers: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var replaced: Array[StringName] = []
	for id: StringName in owned:
		if is_active(id) and offers.get(id,{}).has("replaces_id"):
			replaced.append(StringName(offers[id].replaces_id))
	for id: StringName in owned:
		if is_active(id) and id not in replaced: result.append(id)
	return result

const PATH := "res://data/feature_store_ledger.json"
## Acquisition only: specialty grants and historical ownership are retained.
const PRIMITIVE_PARENTS := {
	&"dialogue": &"simple_story", &"character_backstories": &"simple_story",
	&"maps": &"levels", &"exploration": &"levels",
	&"multiple_endings": &"branching_dialogue", &"secrets": &"exploration",
	&"8_bit_music": &"music",
	&"scrolling": &"text", &"sprites": &"4_color_palette",
	&"local_leaderboards": &"high_scores", &"enemies": &"lives_system",
	&"general_combat": &"enemies", &"power_ups": &"categorized_scores",
}

## Ordered AND parents for existing Primitive cards; historical grants stay owned.
const PRIMITIVE_PARENT_SETS := {&"split_screen": [&"branching_nodes", &"scrolling"]}

static func entries() -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Array else []

static func starting_features() -> Array:
	var result: Array = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/card_ledger.json"))
	if parsed is Array:
		for entry: Dictionary in parsed:
			if entry.get("type") == "feature" and entry.get("phase") in ["design", "alpha"]:
				result.append(entry)
	return result

## Validate the entire prerequisite graph before any quote can use it. The first
## named parent is the sole map anchor; every additional parent is an AND gate.
static func graph(definitions: Dictionary, offers: Dictionary) -> Dictionary:
	var parents := {}
	for id: StringName in definitions:
		parents[id] = []
	for id: StringName in offers:
		if not definitions.has(id): return {"error":"Missing Feature definition: " + str(id)}
	for id: StringName in definitions:
		var entry: Dictionary = offers.get(id, definitions[id])
		var era_error: String = preload("res://scripts/cards/store_era_eligibility.gd").metadata_error(entry)
		if not era_error.is_empty(): return {"error":era_error + ": " + str(id)}
		var legacy: Variant = entry.get("purchase_parent", PRIMITIVE_PARENTS.get(id, ""))
		if not legacy is String and not legacy is StringName: return {"error":"Invalid parent: " + str(id)}
		var named: Array = []
		if entry.has("purchase_parents") or PRIMITIVE_PARENT_SETS.has(id):
			var requested: Variant = entry.get("purchase_parents", PRIMITIVE_PARENT_SETS.get(id, []))
			if not requested is Array or requested.size() not in [1, 2, 3]:
				return {"error":"Expected one to three named parents: " + str(id)}
			for value: Variant in requested:
				if not value is String and not value is StringName: return {"error":"Invalid named parent: " + str(id)}
				named.append(StringName(value))
			if not str(legacy).is_empty() and StringName(legacy) != named[0]: return {"error":"Parent anchor mismatch: " + str(id)}
		elif not str(legacy).is_empty():
			named.append(StringName(legacy))
		var seen := {}
		for parent: StringName in named:
			if parent.is_empty() or parent == id or seen.has(parent) or not definitions.has(parent):
				return {"error":"Duplicate, missing or self parent: " + str(id)}
			seen[parent] = true
		if not named.is_empty() and int(entry.get("gameplay_features_required", 0)) > 0:
			return {"error":"Named parents cannot also use a Gameplay count: " + str(id)}
		parents[id] = named
	# Iterative postorder also catches cycles without risking recursive overflow.
	var ordered := ordered_ancestors(parents.keys(), parents)
	if ordered.has("error"): return ordered
	return {"parents":parents}

static func ordered_ancestors(ids: Array, parents: Dictionary) -> Dictionary:
	var stack: Array = []
	for id in ids: stack.append([StringName(id), false])
	var visiting := {}
	var visited := {}
	var order: Array[StringName] = []
	while not stack.is_empty():
		var frame: Array = stack.pop_back()
		var id: StringName = frame[0]
		if visited.has(id): continue
		if not parents.has(id): return {"error":"Missing parent: " + str(id)}
		if frame[1]:
			visiting.erase(id)
			visited[id] = true
			order.append(id)
			continue
		if visiting.has(id): return {"error":"Cyclic parents: " + str(id)}
		visiting[id] = true
		stack.append([id, true])
		for index in range(parents[id].size() - 1, -1, -1): stack.append([parents[id][index], false])
	return {"order":order}

static func validate_entries(starters: Array, store_entries: Array) -> String:
	var definitions := {}
	var offers := {}
	for entry: Dictionary in starters + store_entries:
		if entry.get("type") != "feature": continue
		var id := StringName(entry.get("id", ""))
		if id.is_empty() or definitions.has(id): return "Duplicate or empty Feature id: " + str(id)
		definitions[id] = entry
	for entry: Dictionary in store_entries: offers[StringName(entry.id)] = entry
	return str(graph(definitions, offers).get("error", ""))
