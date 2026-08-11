class_name CardView
extends Control

signal card_pressed(card_view: CardView)

@export var renewable_texture: Texture2D
@export var nonrenewable_texture: Texture2D

var card_data: CardData
var _selected: bool = false

@onready var artwork_fallback: Panel = %ArtworkFallback
@onready var artwork: TextureRect = %Artwork
@onready var card_name_label: Label = %CardName
@onready var secondary_score: Control = %SecondaryScore
@onready var primary_score_value: Label = %PrimaryScoreValue
@onready var primary_score_type: Label = %PrimaryScoreType
@onready var secondary_score_value: Label = %SecondaryScoreValue
@onready var secondary_score_type: Label = %SecondaryScoreType
@onready var scope_value: Label = %ScopeValue
@onready var renewability_icon: TextureRect = %Renewability
@onready var department_label: Label = %Department
@onready var input_button: Button = %InputButton
@onready var selection_outline: Panel = %SelectionOutline


func _ready() -> void:
	input_button.pressed.connect(_on_input_button_pressed)
	selection_outline.visible = _selected
	refresh()


func set_card(card: CardData) -> void:
	card_data = card

	if is_node_ready():
		refresh()


func set_selected(selected: bool) -> void:
	_selected = selected
	if is_node_ready():
		selection_outline.visible = _selected


func is_selected() -> bool:
	return _selected


func refresh() -> void:
	if card_data == null:
		visible = false
		return

	visible = true
	card_name_label.text = card_data.card_name
	primary_score_value.text = "+%d" % card_data.primary_value
	primary_score_type.text = _display_name(card_data.primary_stat)

	var has_secondary_score := not card_data.secondary_stat.is_empty()
	secondary_score.visible = has_secondary_score
	if has_secondary_score:
		secondary_score_value.text = "+%d" % card_data.secondary_value
		secondary_score_type.text = _display_name(card_data.secondary_stat)

	scope_value.text = str(card_data.scope)
	department_label.text = _display_name(card_data.department)
	department_label.visible = not card_data.department.is_empty()

	_refresh_renewability()
	_refresh_artwork()


func _refresh_renewability() -> void:
	var icon_texture := renewable_texture if card_data.renewable else nonrenewable_texture
	renewability_icon.texture = icon_texture
	renewability_icon.tooltip_text = "Renewable" if card_data.renewable else "Nonrenewable"


func _refresh_artwork() -> void:
	artwork.texture = null
	artwork_fallback.visible = true
	if card_data.artwork_path.is_empty():
		return
	if not ResourceLoader.exists(card_data.artwork_path, "Texture2D"):
		push_warning("Artwork not found for card '%s': %s" % [card_data.id, card_data.artwork_path])
		return

	var loaded_artwork := load(card_data.artwork_path) as Texture2D
	if loaded_artwork == null:
		push_warning("Artwork is not a Texture2D for card '%s': %s" % [card_data.id, card_data.artwork_path])
		return
	artwork.texture = loaded_artwork
	artwork_fallback.visible = false


func _on_input_button_pressed() -> void:
	card_pressed.emit(self)


func _display_name(value: StringName) -> String:
	return str(value).replace("_", " ").capitalize()
