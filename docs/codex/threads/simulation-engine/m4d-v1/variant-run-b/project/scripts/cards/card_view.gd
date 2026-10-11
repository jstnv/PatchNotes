class_name CardView
extends Control

signal card_pressed(card_view: CardView)
signal selection_changed

@export var renewable_texture: Texture2D
@export var nonrenewable_texture: Texture2D

var card_data: CardData
var _selected: bool = false

@onready var artwork_fallback: TextureRect = %Background
@onready var artwork: TextureRect = %Artwork
@onready var card_name_label: Label = %CardName
@onready var primary_score: Control = $PrimaryScore
@onready var secondary_score: Control = %SecondaryScore
@onready var primary_score_value: Label = %PrimaryScoreValue
@onready var primary_score_type: Label = %PrimaryScoreType
@onready var secondary_score_value: Label = %SecondaryScoreValue
@onready var secondary_score_type: Label = %SecondaryScoreType
@onready var scope_value: Label = %ScopeValue
@onready var scope_display: Control = $Scope
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
	if _selected == selected: return
	_selected = selected
	if is_node_ready():
		selection_outline.visible = _selected
	selection_changed.emit()


func is_selected() -> bool:
	return _selected


func shake_no() -> void:
	var original_x := position.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", original_x - 8.0, 0.05)
	tween.tween_property(self, "position:x", original_x + 8.0, 0.08)
	tween.tween_property(self, "position:x", original_x, 0.05)


func refresh() -> void:
	if card_data == null:
		visible = false
		return

	visible = true
	_fit_label(card_name_label, card_data.card_name, 15, 10, 2)
	# A reused view must not retain text from an earlier two-score card.
	secondary_score_value.text = ""
	secondary_score_type.text = ""
	if card_data.phase == CardData.PHASE_BETA:
		_refresh_beta_data()
		_refresh_renewability()
		_refresh_card_tooltip()
		_refresh_artwork()
		return
	primary_score.visible = true
	scope_display.visible = true
	primary_score_value.text = "+%d" % card_data.primary_value
	_fit_label(primary_score_type, _score_name(card_data.primary_stat), 11, 9)

	var has_secondary_score := not card_data.secondary_stat.is_empty()
	secondary_score.visible = has_secondary_score
	if has_secondary_score:
		secondary_score_value.text = "+%d" % card_data.secondary_value
		_fit_label(secondary_score_type, _score_name(card_data.secondary_stat), 11, 9)

	scope_value.text = "S%d" % card_data.scope
	_fit_label(department_label, _display_name(card_data.department), 14, 10)
	department_label.visible = not card_data.department.is_empty()

	_refresh_renewability()
	_refresh_card_tooltip()
	_refresh_artwork()


func _refresh_beta_data() -> void:
	primary_score.visible = true
	primary_score_value.text = "V%d" % card_data.beta_value
	_fit_label(primary_score_type, _score_name(card_data.beta_category), 11, 9)
	secondary_score.visible = false
	scope_display.visible = false
	scope_value.text = ""
	if card_data.beta_category == CardData.BETA_CATEGORY_QA:
		department_label.text = _display_name(card_data.qa_operation)
	else:
		department_label.text = _display_name(card_data.beta_category)
	_fit_label(department_label, department_label.text, 14, 10)
	department_label.visible = true


func _refresh_renewability() -> void:
	var icon_texture := renewable_texture if card_data.renewable else nonrenewable_texture
	renewability_icon.texture = icon_texture
	renewability_icon.tooltip_text = "Renewable" if card_data.renewable else "Nonrenewable"


func _refresh_card_tooltip() -> void:
	var lifecycle := "Renewable: may return in later draws." if card_data.renewable else "Finite: exhausts after a successful play in this project."
	var detail := ""
	var synergy := ""
	if card_data.phase == CardData.PHASE_BETA:
		detail = "%s card · printed value %d." % [_display_name(card_data.beta_category), card_data.beta_value]
		match card_data.beta_category:
			CardData.BETA_CATEGORY_QA: synergy = "Synergy: four QA cards trigger QA Specialization, strengthening Search and Debug."
			CardData.BETA_CATEGORY_MARKETING: synergy = "Synergy: four Marketing cards trigger Marketing Specialization, boosting combined Marketing Output."
			CardData.BETA_CATEGORY_INSIDER: synergy = "Synergy: a 2/1/1 QA, Marketing and Insider mix earns Balanced Operations."
	else:
		detail = "%s · %d Scope · +%d %s" % ["Feature" if card_data.card_type == &"feature" else "Pass", card_data.scope, card_data.primary_value, _display_name(card_data.primary_stat)]
		if not card_data.secondary_stat.is_empty():
			detail += " · +%d %s" % [card_data.secondary_value, _display_name(card_data.secondary_stat)]
		synergy = "Synergy: the first score is primary. Four cards with primary %s trigger Specialization; secondary scores do not decide the match." % _display_name(card_data.primary_stat)
	var department := _display_name(card_data.department)
	if card_data.phase == CardData.PHASE_BETA and not card_data.qa_operation.is_empty():
		department = _display_name(card_data.qa_operation)
	input_button.tooltip_text = "%s\n%s\n%s\n%s\n%s\nSelect cards to build a four-card hand." % [card_data.card_name, department, detail, lifecycle, synergy]


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
	# The kit background remains below artwork, including transparent artwork.


func _on_input_button_pressed() -> void:
	if input_button.disabled: return
	card_pressed.emit(self)


func _display_name(value: StringName) -> String:
	return str(value).replace("_", " ").capitalize()


func _score_name(value: StringName) -> String:
	if value == &"graphics": return "GFX"
	if value == &"technology": return "TECH"
	if value == CardData.BETA_CATEGORY_MARKETING: return "MKTG"
	return _display_name(value).to_upper()


func _fit_label(label: Label, full_text: String, preferred: int, minimum: int, max_lines := 1) -> void:
	# Fit using the actual bundled font; local rectangles never grow or move.
	# Full wording remains available in the card tooltip.
	var text := full_text.to_upper()
	label.tooltip_text = full_text
	label.set_meta("text_abbreviated", false)
	var font := label.get_theme_font("font")
	for font_size in range(preferred, minimum - 1, -1):
		var lines: Array[String] = [""]
		for word in text.split(" ", false):
			var candidate := word if lines[-1].is_empty() else lines[-1] + " " + word
			if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x and not lines[-1].is_empty():
				lines.append(word)
			else:
				lines[-1] = candidate
		var height := font.get_height(font_size) * lines.size() + label.get_theme_constant("line_spacing") * (lines.size()-1)
		var fits := lines.size() <= max_lines and height <= label.size.y
		for line in lines:
			fits = fits and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= label.size.x
		if fits:
			label.add_theme_font_size_override("font_size", font_size)
			label.text = "\n".join(lines)
			return
	label.add_theme_font_size_override("font_size", minimum)
	while not text.is_empty() and font.get_string_size(text + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, minimum).x > label.size.x:
		text = text.left(-1)
	label.text = text + "..."
	label.set_meta("text_abbreviated", true)
