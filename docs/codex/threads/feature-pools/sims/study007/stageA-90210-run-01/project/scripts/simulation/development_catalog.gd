## Immutable definition snapshot supplied by the existing CardDatabase loader.
## Keeps primitive order separate from Store-only cards for legacy projects.
extends RefCounted

var cards: Dictionary[StringName,CardData] = {}
var primitive: Array[CardData] = []

func _init(base: Array[CardData] = [], additional: Array[CardData] = []) -> void:
	primitive.assign(base)
	for card in base + additional: cards[card.id] = card

func get_card(id: StringName) -> CardData:
	return cards.get(id)

func get_cards_by_phase(phase: StringName) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in primitive:
		if card.phase==phase: result.append(card)
	return result

func get_project_features_for_phase(project: ProjectState, phase: StringName) -> Array[CardData]:
	var result: Array[CardData] = []
	if project==null or not project.has_predevelopment_identity():
		for card in primitive:
			if card.phase==phase and card.card_type==&"feature": result.append(card)
	else:
		for id in project.get_feature_supply_ids():
			var card:=get_card(id)
			if card!=null and card.phase==phase and card.card_type==&"feature": result.append(card)
	return result

func passes() -> Array[CardData]:
	var result: Array[CardData] = []
	for card in primitive:
		if card.phase==CardData.PHASE_DESIGN and card.card_type==&"pass": result.append(card)
	return result
