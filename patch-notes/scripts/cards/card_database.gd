extends Node

const PRIMITIVE_BETA_SPECS := {
	&"search_for_bugs": {&"name": "Search for Bugs", &"category": CardData.BETA_CATEGORY_QA, &"value": 1, &"renewable": true, &"operation": CardData.QA_OPERATION_SEARCH},
	&"debug": {&"name": "Debug", &"category": CardData.BETA_CATEGORY_QA, &"value": 1, &"renewable": true, &"operation": CardData.QA_OPERATION_DEBUG},
	&"sign_flippers": {&"name": "Sign Flippers", &"category": CardData.BETA_CATEGORY_MARKETING, &"value": 1, &"renewable": true},
	&"posters": {&"name": "Posters", &"category": CardData.BETA_CATEGORY_MARKETING, &"value": 1, &"renewable": true},
	&"press_release": {&"name": "Press Release", &"category": CardData.BETA_CATEGORY_MARKETING, &"value": 2, &"renewable": true},
	&"press_interview": {&"name": "Press Interview", &"category": CardData.BETA_CATEGORY_MARKETING, &"value": 3, &"renewable": false},
	&"playtest_rival_games": {&"name": "Playtest Rival Games", &"category": CardData.BETA_CATEGORY_INSIDER, &"value": 1, &"renewable": false},
	&"study_competition": {&"name": "Study Competition", &"category": CardData.BETA_CATEGORY_INSIDER, &"value": 2, &"renewable": false},
	&"predict_market_trends": {&"name": "Predict Market Trends", &"category": CardData.BETA_CATEGORY_INSIDER, &"value": 2, &"renewable": false},
}

var _cards: Dictionary = {}

func _ready() -> void:
	load_cards("res://data/card_ledger.json")


func load_cards(path: String) -> void:
	_cards.clear()
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open card file: " + path)
		return

	var json_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)

	if parsed == null:
		push_error("Failed to parse cards.json")
		return

	if not parsed is Array:
		push_error("cards.json must contain an Array.")
		return

	var seen_ids: Dictionary = {}
	for entry: Variant in parsed:
		if not entry is Dictionary:
			push_warning("Skipping invalid card entry: expected a Dictionary.")
			continue
		var validation_error := validate_card_definition(entry)
		if not validation_error.is_empty():
			push_warning("Skipping invalid card entry: " + validation_error)
			continue
		var definition_id := StringName(entry["id"])
		if seen_ids.has(definition_id):
			push_warning("Skipping duplicate card id: %s" % definition_id)
			continue
		seen_ids[definition_id] = true

		var card: CardData = _create_card(entry)
		if card == null:
			continue
		if card.id.is_empty():
			push_warning("Skipping card entry with an empty id.")
			continue
		_cards[card.id] = card

	print("Loaded %d cards." % _cards.size())


func _create_card(entry: Dictionary) -> CardData:
	var phase := StringName(entry.get("phase", ""))
	if not CardData.is_valid_phase(phase):
		push_warning("Skipping card entry with invalid phase: %s" % phase)
		return null

	var card := CardData.new()

	card.id = StringName(entry.get("id", ""))
	card.card_name = entry.get("name", "")
	card.card_type = StringName(entry.get("type", ""))
	card.phase = phase
	card.department = StringName(entry.get("department", ""))

	card.primary_stat = StringName(entry.get("primary_stat", ""))
	card.primary_value = entry.get("primary_value", 0)

	card.secondary_stat = StringName(entry.get("secondary_stat", ""))
	card.secondary_value = entry.get("secondary_value", 0)

	card.scope = entry.get("scope", 0)
	card.renewable = entry.get("renewable", false)
	card.beta_category = StringName(entry.get("beta_category", ""))
	card.beta_value = entry.get("beta_value", 0)
	card.qa_operation = StringName(entry.get("qa_operation", ""))

	card.artwork_path = entry.get("artwork", "")

	return card


func validate_card_definition(entry: Dictionary) -> String:
	if not entry.has("id") or not entry["id"] is String or entry["id"].is_empty():
		return "missing or invalid stable id"
	if not entry.has("phase") or not entry["phase"] is String:
		return "card '%s' is missing a valid phase" % entry["id"]
	var phase := StringName(entry["phase"])
	if not CardData.is_valid_phase(phase):
		return "card '%s' has invalid phase '%s'" % [entry["id"], phase]
	var beta_keys := [&"beta_category", &"beta_value", &"qa_operation"]
	if phase != CardData.PHASE_BETA:
		for key: StringName in beta_keys:
			if entry.has(key):
				return "non-Beta card '%s' contains Beta-only field '%s'" % [entry["id"], key]
		return ""
	return _validate_beta_definition(entry)


func validate_card_definitions(entries: Array) -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}
	for entry: Variant in entries:
		if not entry is Dictionary:
			errors.append("definition is not a Dictionary")
			continue
		var error := validate_card_definition(entry)
		if not error.is_empty():
			errors.append(error)
			continue
		var id := StringName(entry["id"])
		if seen_ids.has(id):
			errors.append("duplicate stable id '%s'" % id)
		else:
			seen_ids[id] = true
	return errors


func _validate_beta_definition(entry: Dictionary) -> String:
	var id: String = entry["id"]
	var id_key := StringName(id)
	if not PRIMITIVE_BETA_SPECS.has(id_key):
		return "Beta card '%s' is not in the locked Primitive roster" % id
	if not entry.has("name") or not entry["name"] is String or entry["name"].is_empty():
		return "Beta card '%s' requires a display name" % id
	if entry.get("type", "") != "beta":
		return "Beta card '%s' must have type 'beta'" % id
	if not entry.has("beta_category") or not entry["beta_category"] is String:
		return "Beta card '%s' is missing a valid beta_category" % id
	var category := StringName(entry["beta_category"])
	if not CardData.is_valid_beta_category(category):
		return "Beta card '%s' has unknown beta_category '%s'" % [id, category]
	if not entry.has("beta_value") or not _is_nonnegative_integral_number(entry["beta_value"]):
		return "Beta card '%s' requires a nonnegative integer beta_value" % id
	if not entry.has("scope") or not _is_nonnegative_integral_number(entry["scope"]) or entry["scope"] != 0:
		return "Beta card '%s' requires integer Scope 0" % id
	if not entry.has("renewable") or typeof(entry["renewable"]) != TYPE_BOOL:
		return "Beta card '%s' requires explicit boolean renewability" % id
	for production_key: String in ["primary_stat", "primary_value", "secondary_stat", "secondary_value"]:
		if entry.has(production_key):
			return "Beta card '%s' cannot contain Core production field '%s'" % [id, production_key]
	if category == CardData.BETA_CATEGORY_QA:
		if not entry.has("qa_operation") or not entry["qa_operation"] is String:
			return "QA card '%s' is missing a valid qa_operation" % id
		var operation := StringName(entry["qa_operation"])
		if not CardData.is_valid_qa_operation(operation):
			return "QA card '%s' has unknown qa_operation '%s'" % [id, operation]
		if id == "search_for_bugs" and operation != CardData.QA_OPERATION_SEARCH:
			return "Search for Bugs must use the Search operation"
		if id == "debug" and operation != CardData.QA_OPERATION_DEBUG:
			return "Debug must use the Debug operation"
	elif entry.has("qa_operation"):
		return "non-QA Beta card '%s' cannot contain qa_operation" % id
	var spec: Dictionary = PRIMITIVE_BETA_SPECS[id_key]
	if entry["name"] != spec[&"name"] or category != spec[&"category"] or entry["beta_value"] != spec[&"value"] or entry["renewable"] != spec[&"renewable"]:
		return "Beta card '%s' does not match its locked Primitive definition" % id
	if spec.has(&"operation") and StringName(entry["qa_operation"]) != spec[&"operation"]:
		return "QA card '%s' does not match its locked operation" % id
	return ""


func _is_nonnegative_integral_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return value >= 0
	if typeof(value) == TYPE_FLOAT:
		return is_finite(value) and value >= 0.0 and value == floor(value)
	return false

func get_card(id: StringName) -> CardData:
	if not _cards.has(id):
		push_warning("Card not found: %s" % id)
		return null

	return _cards[id]


func get_all_cards() -> Array[CardData]:
	var result: Array[CardData] = []

	for card in _cards.values():
		result.append(card)

	return result


func get_cards_by_type(card_type: StringName) -> Array[CardData]:
	var result: Array[CardData] = []

	for card in _cards.values():
		if card.card_type == card_type:
			result.append(card)

	return result


func get_cards_by_phase(phase: StringName) -> Array[CardData]:
	var result: Array[CardData] = []

	if not CardData.is_valid_phase(phase):
		push_warning("Cannot query cards with invalid phase: %s" % phase)
		return result

	for card in _cards.values():
		if card.phase == phase:
			result.append(card)

	return result


func get_cards_by_phase_and_types(phase: StringName, card_types: Array[StringName]) -> Array[CardData]:
	var result: Array[CardData] = []

	for card in get_cards_by_phase(phase):
		if card.card_type in card_types:
			result.append(card)

	return result


func get_cards_by_department(department: StringName) -> Array[CardData]:
	var result: Array[CardData] = []

	for card in _cards.values():
		if card.department == department:
			result.append(card)

	return result


func get_beta_cards_by_category(category: StringName) -> Array[CardData]:
	var result: Array[CardData] = []
	if not CardData.is_valid_beta_category(category):
		push_warning("Cannot query Beta cards with invalid category: %s" % category)
		return result
	for card: CardData in get_cards_by_phase(CardData.PHASE_BETA):
		if card.beta_category == category:
			result.append(card)
	return result
	
func get_card_count() -> int:
	return _cards.size()
