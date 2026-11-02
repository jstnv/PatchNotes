extends CanvasLayer
const Clock := preload("res://scripts/calendar/calendar_clock.gd")

## Presentation only. The Soundtrack autoload keeps its existing transport.
var studio_label: Label
var date_label: Label
var stage_label: Label
var heading_label: Label
var _surface: ColorRect
var _indicator: Label
var _elapsed := 0.0
var _fade: Tween

func _ready() -> void:
	name = "ContinueLoading"
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_surface = ColorRect.new()
	_surface.name = "Surface"
	_surface.color = FolderUI.color(&"background")
	_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_surface.focus_mode = Control.FOCUS_ALL
	_surface.theme = preload("res://resources/ui/onyx_theme.tres")
	add_child(_surface)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_surface.add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 640
	content.add_theme_constant_override("separation", 16)
	center.add_child(content)
	heading_label = _label(content, "Loading saved Studio", 22)
	heading_label.modulate = FolderUI.color(&"muted")
	studio_label = _label(content, "Saved Studio", 32)
	studio_label.custom_minimum_size.x = 640
	studio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	studio_label.modulate = FolderUI.color(&"mint")
	date_label = _label(content, "", 22)
	date_label.theme_type_variation = &"MetadataLabel"
	_indicator = _label(content, "●  ·  ·", 24)
	_indicator.modulate = FolderUI.color(&"mint")
	_indicator.theme_type_variation = &"MetadataLabel"
	stage_label = _label(content, "Checking saved Studio…", 20)
	stage_label.theme_type_variation = &"Label"
	_surface.grab_focus()
	_surface.modulate.a = 0.0
	_fade = create_tween().set_ignore_time_scale(true)
	_fade.tween_property(_surface, "modulate:a", 1.0, 0.12)

func _label(parent: Control, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_type_variation=&"HeadingLabel" if font_size>=20 else &"Label"
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func show_checkpoint(payload: Dictionary) -> void:
	var saved: Dictionary = payload.get("run", {})
	studio_label.text = str(saved.get("studio_name", "Saved Studio"))
	if not saved.has("completed_run_cycles"):
		date_label.text = ""
		return
	var cycles := int(saved.completed_run_cycles)
	date_label.text = Clock.label(cycles,int(saved.get("calendar_start_year",1980)),Clock.from_saved_profile(saved.get("calendar",{})))

func _input(_event: InputEvent) -> void:
	# CanvasLayer covers pointer input; this also blocks keyboard shortcuts
	# belonging to the menu/Studio while restoration or reveal is in flight.
	get_viewport().set_input_as_handled()

func show_new_studio(studio_name: String) -> void:
	heading_label.text = "Creating your Studio"
	studio_label.text = studio_name.strip_edges()
	date_label.text = Clock.label(0,RunState.START_YEAR,Clock.fresh())
	stage_label.text = "Preparing your new save…"

func _process(delta: float) -> void:
	_elapsed += delta
	_indicator.text = ["●  ·  ·", "·  ●  ·", "·  ·  ●"][int(_elapsed * 5.0) % 3]

func cover() -> void:
	# Finish the actual entrance before a synchronous validator can hold a
	# frame. Otherwise the old menu remains visible under half-faded text.
	if _fade != null and _fade.is_running(): await _fade.finished

func reveal() -> void:
	if _fade != null: _fade.kill()
	_fade = create_tween().set_ignore_time_scale(true)
	_fade.tween_property(_surface, "modulate:a", 0.0, 0.16)
	await _fade.finished
