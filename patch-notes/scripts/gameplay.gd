extends Control

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

func _ready() -> void:
	var card := CardDatabase.get_card(&"text")

	if card == null:
		push_error("Test card 'text' was not found.")
		return

	var card_view: CardView = CARD_VIEW_SCENE.instantiate()

	$PhaseRoot.add_child(card_view)

	card_view.set_card(card)	
