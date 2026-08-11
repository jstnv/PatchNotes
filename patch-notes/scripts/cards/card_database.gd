extends Node

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

	for entry: Variant in parsed:
		if not entry is Dictionary:
			push_warning("Skipping invalid card entry: expected a Dictionary.")
			continue

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

	card.artwork_path = entry.get("artwork", "")

	return card

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
	
func get_card_count() -> int:
	return _cards.size()
