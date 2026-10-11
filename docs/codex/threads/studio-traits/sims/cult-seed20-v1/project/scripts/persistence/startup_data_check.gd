class_name StartupDataCheck
extends RefCounted

const PATHS := {
	"res://data/card_ledger.json": TYPE_ARRAY,
	"res://data/feature_store_ledger.json": TYPE_ARRAY,
	"res://data/primitive_predevelopment.json": TYPE_DICTIONARY,
	PrimitiveSnapshotDatabase.COMPETITOR_LEDGER_PATH: TYPE_ARRAY,
	PrimitiveSnapshotDatabase.FORECAST_LEDGER_PATH: TYPE_ARRAY,
}

static func inspect(database: Node, overrides: Dictionary = {}) -> String:
	var parsed := {}
	for canonical: String in PATHS:
		var path: String = overrides.get(canonical,canonical)
		var file := FileAccess.open(path,FileAccess.READ)
		if file == null: return "Missing or unreadable game data: " + canonical
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK: return "Invalid JSON game data: " + canonical
		if typeof(json.data) != PATHS[canonical] or json.data.is_empty(): return "Invalid game data structure: " + canonical
		parsed[canonical] = json.data
	if database == null: return "Card database is unavailable."
	for path in ["res://data/card_ledger.json","res://data/feature_store_ledger.json"]:
		var errors: Array = database.validate_card_definitions(parsed[path])
		if not errors.is_empty(): return "Invalid card definitions: " + path + " (" + str(errors[0]) + ")"
	var pre: Dictionary = parsed[PrimitivePredevelopment.PATH]
	for kind in ["genres","themes"]:
		if not pre.get(kind) is Array or pre[kind].is_empty(): return "Missing pre-development choices: " + kind
		for entry in pre[kind]:
			if not entry is Dictionary or not entry.get("id") is String or not entry.get("name") is String: return "Invalid pre-development choice: " + kind
	var snapshots := PrimitiveSnapshotDatabase.new()
	if not snapshots.validate_competitor_data(parsed[PrimitiveSnapshotDatabase.COMPETITOR_LEDGER_PATH]) or not snapshots.validate_forecast_data(parsed[PrimitiveSnapshotDatabase.FORECAST_LEDGER_PATH]):
		return "Invalid competitor or market forecast definitions."
	return ""
