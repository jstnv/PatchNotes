class_name ContextualTip
extends CanvasLayer

var panel: PanelContainer
var title_label: Label
var body_label: Label
var dismiss_button: Button
var lower_dock := false
var timer: Timer


func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.name = "ContextualTipPanel"
	panel.theme = preload("res://resources/ui/onyx_theme.tres")
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
	title_label.theme_type_variation=&"HeadingLabel"
	title_label.add_theme_font_size_override("font_size",16)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", FolderUI.color(&"mint"))
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
	get_viewport().size_changed.connect(_place)

	# Guidance remains readable until the player closes it. Keep the nullable
	# timer field for older presentation probes; no expiry is scheduled.


func show_tip(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	panel.show()


func dismiss() -> void:
	if timer != null:
		timer.stop()
	if panel != null:
		panel.hide()

func dock_below_menu_controls(value: bool) -> void:
	lower_dock=value;_place()
func _place() -> void:
	if panel==null:return
	var top:=maxf(300.0,get_viewport().get_visible_rect().size.y-290.0) if lower_dock else 154.0
	panel.offset_top=top;panel.offset_bottom=top+106.0
