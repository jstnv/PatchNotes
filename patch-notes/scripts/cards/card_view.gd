class_name CardView
extends Control


var card_data: CardData


@onready var card_name_label: Label = %CardName

@onready var primary_score_value: Label = %PrimaryScoreValue
@onready var primary_score_type: Label = %PrimaryScoreType

@onready var secondary_score_value: Label = %SecondaryScoreValue
@onready var secondary_score_type: Label = %SecondaryScoreType

@onready var scope_value: Label = %ScopeValue
@onready var renewability_icon: TextureRect = %Renewability


func _ready() -> void:
	if card_data != null:
		refresh()


func set_card(card: CardData) -> void:
	card_data = card

	if is_node_ready():
		refresh()


func refresh() -> void:
	if card_data == null:
		return

	# Card name
	card_name_label.text = card_data.card_name

	# Primary score
	primary_score_value.text = "+%d" % card_data.primary_value
	primary_score_type.text = str(card_data.primary_stat).to_upper()

	# Secondary score
	var has_secondary_score := card_data.secondary_value != 0

	secondary_score_value.visible = has_secondary_score
	secondary_score_type.visible = has_secondary_score

	if has_secondary_score:
		secondary_score_value.text = "+%d" % card_data.secondary_value
		secondary_score_type.text = str(card_data.secondary_stat).to_upper()

	# Scope
	scope_value.text = str(card_data.scope)

	# Renewability will be connected once we assign
	# renewable / nonrenewable textures.
