class_name FeatureStoreCatalog
extends RefCounted

## Core Feature Ledger (1981–1983). Prices are the prototype store baseline.
## Keep separate from the fixed Primitive draw/contract ledger.
const PATH := "res://data/feature_store_ledger.json"

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
