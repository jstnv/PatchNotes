extends Node

var _cards: Dictionary = {}

func _ready() -> void:
	load_cards("res://data/card_ledger.json")


func load_cards(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open card file: " + path)
		return

	var json_text := file.get_as_text()
	var parsed = JSON.parse_string(json_text)

	if parsed == null:
		push_error("Failed to parse cards.json")
		return

	if not parsed is Array:
		push_error("cards.json must contain an Array.")
		return

	for entry in parsed:
		var card := create_card(entry)
		_cards[card.id] = card

	print("Loaded %d cards." % _cards.size())


func create_card(entry: Dictionary) -> CardData:
	var card := CardData.new()

	card.id = StringName(entry.get("id", ""))
	card.card_name = entry.get("name", "")
	card.card_type = StringName(entry.get("type", ""))
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


func get_cards_by_department(department: StringName) -> Array[CardData]:
	var result: Array[CardData] = []

	for card in _cards.values():
		if card.department == department:
			result.append(card)

	return result
	
func get_card_count() -> int:
	return _cards.size()
