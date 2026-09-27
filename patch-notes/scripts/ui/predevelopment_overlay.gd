class_name PredevelopmentOverlay
extends PanelContainer

signal begin_requested(base_name: String, genre: StringName, theme: StringName)
signal cancelled

var name_input: LineEdit
var genre_input: OptionButton
var theme_input: OptionButton
var error_label: Label
var begin_button: Button
var back_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll.add_child(layout)
	_add_label(layout, "Pre-Development", 26)
	_add_label(layout, "Set up your game. These choices are locked when development begins.", 16)
	_add_label(layout, "Game name", 16)
	name_input = LineEdit.new()
	name_input.name = "GameName"
	name_input.placeholder_text = "Enter a game name"
	layout.add_child(name_input)
	_add_label(layout, "Genre", 16)
	genre_input = _add_options(layout, "genres")
	_add_label(layout, "Theme", 16)
	theme_input = _add_options(layout, "themes")
	_add_label(layout, "Begin Development: 1 calendar cycle • New project starts at cycle 0 • No cash required\nEditing or cancelling: 0 cycles • Themes have no gameplay effects yet", 16)
	error_label = _add_label(layout, "", 16)
	error_label.add_theme_color_override("font_color", Color("ffc779"))
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	begin_button = Button.new()
	begin_button.name = "BeginDevelopment"
	begin_button.text = "Begin Development"
	begin_button.custom_minimum_size = Vector2(240, 44)
	begin_button.pressed.connect(_confirm)
	actions.add_child(begin_button)
	var back := Button.new()
	back_button = back
	back.name = "CancelPredevelopment"
	back.text = "Back to Studio"
	back.custom_minimum_size = Vector2(180, 44)
	back.pressed.connect(func(): cancelled.emit())
	actions.add_child(back)
	name_input.text_changed.connect(func(_text: String): error_label.text = "")

func _add_label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _add_options(parent: Node, kind: String) -> OptionButton:
	var options := OptionButton.new()
	options.name = kind.capitalize()
	for entry: Dictionary in PrimitivePredevelopment.catalog()[kind]:
		options.add_item(entry.name)
		options.set_item_metadata(options.item_count - 1, StringName(entry.id))
	parent.add_child(options)
	return options

func open() -> void:
	error_label.text = ""
	show()
	name_input.grab_focus()

func _confirm() -> void:
	var genre: StringName = genre_input.get_selected_metadata()
	var theme: StringName = theme_input.get_selected_metadata()
	error_label.text = PrimitivePredevelopment.validation_error(name_input.text, genre, theme)
	if not error_label.text.is_empty():
		name_input.grab_focus()
		return
	begin_requested.emit(name_input.text.strip_edges(), genre, theme)
