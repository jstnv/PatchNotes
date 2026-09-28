## Read-only failure fixtures for authored later Department cards.
## The findings are expected unsupported behavior, not gameplay changes.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var db: Node = root.get_node("CardDatabase")
	var run := RunState.new()
	var multi := {"id": "character_classes", "name": "Character Classes", "type": "feature", "phase": "alpha", "department": "gameplay", "primary_stat": "technology", "primary_value": 2, "secondary_stat": "design", "secondary_value": 3, "scope": 2, "renewable": false, "purchase_parent": "general_combat", "gameplay_features_required": 0, "base_price_cents": 170000}
	var definitions: Dictionary = run.get("_feature_definitions")
	definitions[&"character_classes"] = multi
	run.set("_feature_definitions", definitions)
	var offers: Dictionary = run.get("_feature_offers")
	offers[&"character_classes"] = multi
	run.set("_feature_offers", offers)
	var owned: Dictionary = run.get("_owned_features")
	owned[&"general_combat"] = true
	run.set("_owned_features", owned)
	var missing_save := run.get_feature_store_offer(&"character_classes")
	owned[&"save_files"] = true
	run.set("_owned_features", owned)
	var familiar: Dictionary = run.get("_familiarity")
	familiar[&"general_combat"] = 2
	familiar[&"save_files"] = 3
	run.set("_familiarity", familiar)
	var both_owned := run.get_feature_store_offer(&"character_classes")
	var boss := {"id": "boss_battles", "name": "Boss Battles", "type": "feature", "phase": "alpha", "department": "gameplay", "primary_stat": "graphics", "primary_value": 3, "secondary_stat": "sound", "secondary_value": 3, "tertiary_stat": "technology", "tertiary_value": 3, "scope": 3, "renewable": false}
	var boss_error: String = db.call("validate_card_definition", boss)
	var parsed: CardData = db.call("_create_card", boss)
	var has_tertiary := false
	for property: Dictionary in parsed.get_property_list():
		if property.name == "tertiary_stat": has_tertiary = true
	var output := {"source_revision": "ba616515ed1b039fd0da7cf03f73288fd7ccd8e4", "missing_save_files_quote": missing_save, "both_owned_2_plus_3_credits_quote": both_owned, "boss_definition_validation_error": boss_error, "boss_card_primary": parsed.primary_value, "boss_card_secondary": parsed.secondary_value, "boss_tertiary_property_exists": has_tertiary, "expected_multi_parent_gate_supported": not missing_save.unlocked, "expected_combined_familiarity_supported": both_owned.discount_percent == 50, "expected_three_core_supported": has_tertiary}
	var file := FileAccess.open("res://design-logs/feature_later_schema_probe_v1.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	file.close()
	print("LATER SCHEMA PROBE gate=%s familiarity=%s three_core=%s" % [output.expected_multi_parent_gate_supported, output.expected_combined_familiarity_supported, output.expected_three_core_supported])
	quit(0)
