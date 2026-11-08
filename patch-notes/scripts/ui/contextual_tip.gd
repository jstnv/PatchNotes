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
	set_process(false)

	# Guidance remains readable until the player closes it. Keep the nullable
	# timer field for older presentation probes; no expiry is scheduled.


func show_tip(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	panel.show()
	_place()
	set_process(true)


func dismiss() -> void:
	if timer != null:
		timer.stop()
	if panel != null:
		panel.hide()
	set_process(false)

func _process(_delta: float) -> void:
	# Focused guidance can enter and leave while the persistent tip is open.
	_place()

func dock_below_menu_controls(value: bool) -> void:
	lower_dock=value;_place()
func _place() -> void:
	if panel==null:return
	var top:=maxf(300.0,get_viewport().get_visible_rect().size.y-290.0) if lower_dock else 154.0
	# Production cards fan and rotate. Keep their actual title bounds visible,
	# including their selection and idle motion, while the tip is open.
	var hud := get_parent()
	var phase: Variant = hud.get("phase") if hud != null else null
	var production: bool = panel.visible and is_instance_valid(phase) and (phase is DesignPhase or phase is AlphaPhase or phase is BetaPhase)
	panel.offset_left = -460.0 if production else -360.0
	var tip_rect:=panel.get_global_rect()
	if production:
		var fan: Node = phase.get_node_or_null("%HandContainer")
		if fan != null:
			var upper: float = hud.scoreboard.get_global_rect().end.y + 8.0
			var upper_rect := Rect2(Vector2(tip_rect.position.x, upper), tip_rect.size)
			var upper_clear := true
			var lower := 154.0
			for card: Node in fan.get_children():
				if not card is CardView or not card.is_visible_in_tree() or not card.is_node_ready(): continue
				var title: Control = card.card_name_label
				var transform := title.get_global_transform_with_canvas()
				var bounds := Rect2(transform * Vector2.ZERO, Vector2.ZERO)
				bounds = bounds.expand(transform * Vector2(title.size.x, 0.0))
				bounds = bounds.expand(transform * title.size)
				bounds = bounds.expand(transform * Vector2(0.0, title.size.y))
				if bounds.end.x > tip_rect.position.x and bounds.position.x < tip_rect.end.x:
					lower = maxf(lower, bounds.end.y + 16.0)
					if upper_rect.intersects(bounds.grow(8.0)): upper_clear = false
			var synergy: Control = hud.synergy_notification.banner
			if synergy.is_visible_in_tree() and upper_rect.intersects(synergy.get_global_rect()): upper_clear = false
			top = upper if upper_clear else lower
	for overlay in get_tree().get_nodes_in_group(&"focused_guidance_overlay"):
		if not overlay is CanvasLayer or not overlay.visible:continue
		var guidance: Variant=overlay.get("panel")
		if not is_instance_valid(guidance) or not guidance.is_visible_in_tree():continue
		var bounds: Rect2=guidance.get_global_rect()
		if bounds.end.x>tip_rect.position.x and bounds.position.x<tip_rect.end.x:
			top=maxf(top,bounds.end.y+4.0)
	if not is_equal_approx(panel.offset_top,top) or not is_equal_approx(panel.offset_bottom,top+106.0):
		panel.offset_top=top;panel.offset_bottom=top+106.0
