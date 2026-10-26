class_name FeatureStoreCatalog
extends RefCounted

## Core Feature Ledger (1981–1983). Prices are the prototype store baseline.
## Keep separate from the fixed Primitive draw/contract ledger.
const PATH := "res://data/feature_store_ledger.json"
## Acquisition only: specialty grants and historical ownership are retained.
const PRIMITIVE_PARENTS := {
	&"dialogue": &"simple_story", &"character_backstories": &"simple_story",
	&"maps": &"levels", &"exploration": &"levels",
	&"multiple_endings": &"branching_dialogue", &"secrets": &"exploration",
	&"8_bit_music": &"music", &"8_bit_sound": &"sound_effects",
	&"scrolling": &"text", &"sprites": &"4_color_palette",
	&"local_leaderboards": &"high_scores", &"enemies": &"lives_system",
	&"general_combat": &"enemies",
}

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
## named parent is the sole map anchor; the second is an additional AND gate.
static func graph(definitions: Dictionary, offers: Dictionary) -> Dictionary:
	var parents := {}
	for id: StringName in definitions:
		parents[id] = []
	for id: StringName in offers:
		if not definitions.has(id): return {"error":"Missing Feature definition: " + str(id)}
	for id: StringName in definitions:
		var entry: Dictionary = offers.get(id, definitions[id])
		var legacy: Variant = entry.get("purchase_parent", PRIMITIVE_PARENTS.get(id, ""))
		if not legacy is String and not legacy is StringName: return {"error":"Invalid parent: " + str(id)}
		var named: Array = []
		if entry.has("purchase_parents"):
			if not entry.purchase_parents is Array or entry.purchase_parents.size() not in [1, 2]:
				return {"error":"Expected one or two named parents: " + str(id)}
			for value: Variant in entry.purchase_parents:
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
