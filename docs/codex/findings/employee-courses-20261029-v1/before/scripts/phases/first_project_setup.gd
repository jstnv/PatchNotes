class_name FirstProjectSetup
extends Control

signal development_requested(source: Control, base_name: String, genre: StringName, theme_id: StringName)

var overlay: PredevelopmentOverlay

func _ready() -> void:
	theme = preload("res://resources/ui/workspace_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var start := Button.new()
	start.text = "Set Up First Game"
	start.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	start.offset_left = -140
	start.offset_right = 140
	start.offset_top = -24
	start.offset_bottom = 24
	add_child(start)
	overlay = PredevelopmentOverlay.new()
	add_child(overlay)
	overlay.back_button.text = "Cancel"
	overlay.begin_requested.connect(func(base_name: String, genre: StringName, theme_id: StringName):
		development_requested.emit(self, base_name, genre, theme_id))
	overlay.cancelled.connect(func():
		overlay.hide()
		start.grab_focus())
	start.pressed.connect(overlay.open)
	overlay.open()

func show_development_error(message: String) -> void:
	overlay.error_label.text = message
