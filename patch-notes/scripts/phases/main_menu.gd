class_name MainMenu
extends Control

signal studio_created(name: String, specialty: StringName)
signal tutorial_requested

var _name_input: LineEdit
var _error: Label
var _setup: VBoxContainer
var _specialty: OptionButton
var _preview: Label
var _emphasis: Label

func _ready() -> void:
	theme = preload("res://resources/ui/workspace_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.name = "MenuLayout"
	layout.custom_minimum_size = Vector2(720, 0)
	layout.add_theme_constant_override("separation", 10)
	center.add_child(layout)
	var title := Label.new()
	title.text = "Patch Notes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	layout.add_child(title)
	var start := Button.new()
	start.name = "StartGame"
	start.text = "Start Game"
	start.custom_minimum_size.y = 52
	layout.add_child(start)
	var tutorial := Button.new()
	tutorial.name = "HowToPlay"
	tutorial.text = "How to Play"
	tutorial.tooltip_text = "Open the optional tutorial reference."
	tutorial.custom_minimum_size.y = 44
	tutorial.pressed.connect(func(): tutorial_requested.emit())
	layout.add_child(tutorial)
	_setup = VBoxContainer.new()
	_setup.name = "StudioSetup"
	_setup.add_theme_constant_override("separation", 8)
	layout.add_child(_setup)
	var prompt := Label.new()
	prompt.text = "Name your studio"
	_setup.add_child(prompt)
	_name_input = LineEdit.new()
	_name_input.name = "StudioName"
	_name_input.placeholder_text = "Studio name"
	_name_input.max_length = 80
	_name_input.tooltip_text = "Name your studio. You can start producing games after entering Studio."
	_setup.add_child(_name_input)
	_specialty = OptionButton.new()
	_specialty.name = "StudioSpecialty"
	_specialty.add_item("Choose your permanent Genre specialty")
	_specialty.set_item_disabled(0, true)
	for genre: Dictionary in PrimitivePredevelopment.catalog().genres:
		_specialty.add_item(genre.name)
		_specialty.set_item_metadata(_specialty.item_count - 1, StringName(genre.id))
	_specialty.select(0)
	_specialty.item_selected.connect(func(_index: int): _refresh_preview())
	_setup.add_child(_specialty)
	_emphasis = Label.new()
	_emphasis.name = "SpecialtyEmphasis"
	_setup.add_child(_emphasis)
	var preview_scroll := ScrollContainer.new()
	preview_scroll.custom_minimum_size = Vector2(700, 130)
	_setup.add_child(preview_scroll)
	_preview = Label.new()
	_preview.name = "SpecialtyRoster"
	_preview.custom_minimum_size.x = 670
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.add_child(_preview)
	_refresh_preview()
	_error = Label.new()
	_error.name = "ErrorLabel"
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup.add_child(_error)
	var enter := Button.new()
	enter.name = "EnterStudio"
	enter.text = "Enter Studio"
	enter.custom_minimum_size.y = 44
	_setup.add_child(enter)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	_setup.add_child(back)
	_setup.hide()
	start.pressed.connect(func():
		start.hide()
		_setup.show()
		_name_input.grab_focus())
	back.pressed.connect(func():
		_setup.hide()
		_specialty.select(0)
		_refresh_preview()
		_error.text = ""
		start.show()
		start.grab_focus())
	enter.pressed.connect(_submit)
	_name_input.text_submitted.connect(func(_text: String): _submit())

func _submit() -> void:
	var value := _name_input.text.strip_edges()
	if value.is_empty():
		_error.text = "Enter a studio name."
		return
	if _specialty.selected <= 0:
		_error.text = "Choose one permanent Genre specialty."
		return
	_error.text = ""
	studio_created.emit(value, _specialty.get_item_metadata(_specialty.selected))

func _refresh_preview() -> void:
	if _specialty.selected <= 0:
		_emphasis.text = "Your specialty grants a free starting Feature roster."
		_preview.text = "Choose a specialty to preview every starting Feature.\nEach game can use any Genre. The specialty provides no score or sales bonus."
		return
	var preview := StudioSpecialties.preview(_specialty.get_item_metadata(_specialty.selected))
	if preview.is_empty():
		_emphasis.text = "Specialty roster unavailable."
		_preview.text = ""
		return
	_emphasis.text = "%s · %d Features · %d printed Scope · Free" % [preview.emphasis, preview.count, preview.scope]
	_preview.text = ", ".join(preview.names) + "\n\nPermanent studio specialty; each game's Genre is chosen separately.\nStarting cards only: no bonus to scores or sales."

func show_error(message: String) -> void:
	_error.text = message
