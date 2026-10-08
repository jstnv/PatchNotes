class_name SynergyNotification
extends CanvasLayer

var banner: PanelContainer
var title_label: Label
var detail_label: Label
var timer: Timer
var _popup: Tween

func _ready() -> void:
	layer = 10
	banner = PanelContainer.new()
	banner.name = "SynergyBanner"
	banner.theme = preload("res://resources/ui/workspace_theme.tres")
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -290
	banner.offset_right = 290
	banner.offset_top = 86
	banner.offset_bottom = 148
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(content)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("#f5bd59"))
	title_label.add_theme_font_size_override("font_size", 22)
	content.add_child(title_label)
	detail_label = Label.new()
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_color_override("font_color", Color("#79d4da"))
	content.add_child(detail_label)
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = HandPresentation.SPECIALIZATION_SECONDS
	timer.timeout.connect(banner.hide)
	add_child(timer)
	banner.hide()

func show_message(title: String, detail: String) -> void:
	title_label.text = title
	detail_label.text = detail
	banner.show()
	if _popup != null and _popup.is_valid(): _popup.kill()
	banner.pivot_offset = banner.size / 2.0
	banner.scale = Vector2.ONE * 0.8
	banner.modulate.a = 0.0
	_popup = create_tween().set_parallel()
	_popup.tween_property(banner, "scale", Vector2.ONE, HandPresentation.BEAT_SECONDS / 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_popup.tween_property(banner, "modulate:a", 1.0, HandPresentation.BEAT_SECONDS / 2.0)
	timer.start()
