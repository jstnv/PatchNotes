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
var priority_sliders: Array[HSlider] = []
var priority_labels: Array[Label] = []
var priority_total: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var shell := VBoxContainer.new()
	margin.add_child(shell)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll.add_child(layout)
	_add_label(layout, "Pre-Development", 26)
	_add_label(layout, "Set up your game. These choices are locked when development begins.", 16)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 8)
	columns.add_child(identity)
	var priorities := VBoxContainer.new()
	priorities.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priorities.add_theme_constant_override("separation", 8)
	columns.add_child(priorities)
	_add_label(identity, "Game name", 16)
	name_input = LineEdit.new()
	name_input.name = "GameName"
	name_input.placeholder_text = "Enter a game name"
	name_input.tooltip_text = "Give this game a name. You can edit it until development begins."
	identity.add_child(name_input)
	_add_label(identity, "Genre", 16)
	genre_input = _add_options(identity, "genres")
	genre_input.tooltip_text = "Genre affects Review through the game's final Core Scores."
	_add_label(identity, "Theme", 16)
	theme_input = _add_options(identity, "themes")
	theme_input.tooltip_text = "Choose a Theme for this game's identity. Themes have no gameplay effect yet."
	_add_label(priorities, "Initial Design priorities", 20)
	_add_label(priorities, "Priorities weight future draws, not scores.\nAllocate 100 total, 5-50 each in steps of 5.", 14)
	priorities.tooltip_text = "Graphics: visuals. Sound: audio. Tech: systems. Design: gameplay. Core scores measure quality; Scope measures how much game you build."
	for i in range(4):
		var row := HBoxContainer.new()
		priorities.add_child(row)
		var value := _add_label(row, "", 16)
		value.custom_minimum_size.x = 160
		priority_labels.append(value)
		var slider := HSlider.new()
		slider.min_value = 5
		slider.max_value = 50
		slider.step = 5
		slider.value = 25
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		priority_sliders.append(slider)
		slider.value_changed.connect(func(_value: float): _refresh_priorities())
	priority_total = _add_label(priorities, "", 16)
	_add_label(layout, "Begin Development: 1 calendar cycle • New project starts at cycle 0 • No cash required\nEditing or cancelling: 0 cycles • Themes have no gameplay effects yet", 16)
	error_label = _add_label(layout, "", 16)
	error_label.add_theme_color_override("font_color", Color("ffc779"))
	var actions := HBoxContainer.new()
	shell.add_child(actions)
	begin_button = Button.new()
	begin_button.name = "BeginDevelopment"
	begin_button.text = "Begin Development"
	begin_button.tooltip_text = "Locks this game's name, Genre and Theme and advances one calendar cycle."
	begin_button.custom_minimum_size = Vector2(240, 44)
	begin_button.pressed.connect(_confirm)
	actions.add_child(begin_button)
	var back := Button.new()
	back_button = back
	back.name = "CancelPredevelopment"
	back.text = "Back to Studio"
	back.tooltip_text = "Return to Studio without spending cash or advancing time."
	back.custom_minimum_size = Vector2(180, 44)
	back.pressed.connect(func(): cancelled.emit())
	actions.add_child(back)
	_refresh_priorities()
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

func get_initial_priorities() -> Dictionary:
	var result := {}
	for i in range(priority_sliders.size()): result[i] = int(priority_sliders[i].value)
	return result

func _refresh_priorities() -> void:
	var total := 0
	for i in range(priority_sliders.size()):
		var value := int(priority_sliders[i].value)
		total += value
		priority_labels[i].text = "%s: %d" % [["Graphics", "Sound", "Tech", "Design"][i], value]
	priority_total.text = "Allocated: %d / 100" % total
	if begin_button != null: begin_button.disabled = total != 100
	if total == 100 and error_label != null and error_label.text == "Allocate exactly 100 priority points before beginning.": error_label.text = ""

func _confirm() -> void:
	if not PriorityAllocation.is_valid_distribution(get_initial_priorities()):
		error_label.text = "Allocate exactly 100 priority points before beginning."
		return
	var genre: StringName = genre_input.get_selected_metadata()
	var theme: StringName = theme_input.get_selected_metadata()
	error_label.text = PrimitivePredevelopment.validation_error(name_input.text, genre, theme)
	if not error_label.text.is_empty():
		name_input.grab_focus()
		return
	begin_requested.emit(name_input.text.strip_edges(), genre, theme)
