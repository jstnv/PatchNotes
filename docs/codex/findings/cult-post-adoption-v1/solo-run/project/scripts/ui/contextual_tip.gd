class_name ContextualTip
extends CanvasLayer

const DISPLAY_SECONDS := 8.0

var panel: PanelContainer
var title_label: Label
var body_label: Label
var dismiss_button: Button
var timer: Timer


func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.name = "ContextualTipPanel"
	panel.theme = preload("res://resources/ui/workspace_theme.tres")
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -360.0
	panel.offset_right = -16.0
	# Sit below the four-second synergy banner (which ends at y=148).
	panel.offset_top = 154.0
	panel.offset_bottom = 260.0
	# The toast may overlap a card at narrow widths; only its close button takes input.
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	var heading := HBoxContainer.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(heading)
	title_label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color("#f5bd59"))
	heading.add_child(title_label)
	dismiss_button = Button.new()
	dismiss_button.name = "DismissTipButton"
	dismiss_button.text = "×"
	dismiss_button.tooltip_text = "Dismiss tip"
	dismiss_button.custom_minimum_size = Vector2(28, 28)
	dismiss_button.pressed.connect(dismiss)
	heading.add_child(dismiss_button)
	body_label = Label.new()
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.custom_minimum_size.y = 58.0
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 14)
	content.add_child(body_label)
	panel.hide()

	timer = Timer.new()
	timer.name = "TipTimer"
	timer.one_shot = true
	timer.wait_time = DISPLAY_SECONDS
	timer.timeout.connect(dismiss)
	add_child(timer)


func show_tip(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	panel.show()
	timer.start()


func dismiss() -> void:
	if timer != null:
		timer.stop()
	if panel != null:
		panel.hide()
