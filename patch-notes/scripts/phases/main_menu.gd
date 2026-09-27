class_name MainMenu
extends Control

signal studio_created(name: String)

var _name_input: LineEdit
var _error: Label
var _setup: VBoxContainer

func _ready() -> void:
	theme = preload("res://resources/ui/workspace_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var layout := VBoxContainer.new()
	layout.name = "MenuLayout"
	layout.custom_minimum_size = Vector2(360, 0)
	layout.add_theme_constant_override("separation", 18)
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
	_setup = VBoxContainer.new()
	_setup.name = "StudioSetup"
	_setup.add_theme_constant_override("separation", 12)
	layout.add_child(_setup)
	var prompt := Label.new()
	prompt.text = "Name your studio"
	_setup.add_child(prompt)
	_name_input = LineEdit.new()
	_name_input.name = "StudioName"
	_name_input.placeholder_text = "Studio name"
	_name_input.max_length = 80
	_setup.add_child(_name_input)
	_error = Label.new()
	_error.name = "ErrorLabel"
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup.add_child(_error)
	var enter := Button.new()
	enter.name = "EnterStudio"
	enter.text = "Enter Studio"
	enter.custom_minimum_size.y = 52
	_setup.add_child(enter)
	var back := Button.new()
	back.text = "Back"
	_setup.add_child(back)
	_setup.hide()
	start.pressed.connect(func():
		start.hide()
		_setup.show()
		_name_input.grab_focus())
	back.pressed.connect(func():
		_setup.hide()
		start.show()
		start.grab_focus())
	enter.pressed.connect(_submit)
	_name_input.text_submitted.connect(func(_text: String): _submit())

func _submit() -> void:
	var value := _name_input.text.strip_edges()
	if value.is_empty():
		_error.text = "Enter a studio name."
		return
	_error.text = ""
	studio_created.emit(value)

func show_error(message: String) -> void:
	_error.text = message
