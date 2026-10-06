class_name PriorityInfluenceChart
extends Control

# Presentation only: these are allocation shares, not exact candidate odds.
const CORE_NAMES: Array[String] = ["Graphics", "Sound", "Tech", "Design"]
const CORE_COLORS: Array[Color] = [Color("f08e9b"), Color("e9c46a"), Color("74c9e8"), Color("bda1ef")]
const BETA_NAMES: Array[String] = ["QA", "Marketing", "Insider"]
const BETA_COLORS: Array[Color] = [Color("7ed6be"), Color("e9c46a"), Color("bda1ef")]
const UNUSED_COLOR := Color("535966")
var weights: Array[float] = []
var category_names: Array[String] = []
var total := 0.0
var _colors: Array[Color] = []
var _controls: Array = []
var _refresh_queued := false

func _init() -> void:
	name = "PriorityInfluenceChart"
	custom_minimum_size = Vector2(200, 208)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS

func bind_controls(controls: Array, names: Array[String], colors: Array[Color]) -> void:
	for control: Range in _controls:
		if control.value_changed.is_connected(_schedule_refresh): control.value_changed.disconnect(_schedule_refresh)
	_controls = controls.duplicate()
	category_names = names.duplicate()
	_colors = colors.duplicate()
	for control: Range in _controls:
		control.value_changed.connect(_schedule_refresh)
	refresh_from_controls()

func _schedule_refresh(_value: float) -> void:
	# Phase handlers can synchronize several sliders in one callback.
	if _refresh_queued: return
	_refresh_queued = true
	refresh_from_controls.call_deferred()

func refresh_from_controls() -> void:
	_refresh_queued = false
	weights.clear()
	total = 0.0
	var lines: Array[String] = ["Priority influence affects future draws, not scores or exact card odds."]
	for i in range(_controls.size()):
		var value: float = _controls[i].value
		weights.append(value)
		total += value
		lines.append("%s: %d priority points" % [category_names[i], value])
	if total < 100: lines.append("Gray: %d unallocated points." % (100 - total))
	elif total > 100: lines.append("Over budget: the pie previews relative shares. Allocate exactly 100 to continue.")
	tooltip_text = "\n".join(lines)
	queue_redraw()

func get_chart_shares() -> Array[float]:
	var shares: Array[float] = []
	for value: float in weights: shares.append(value / maxf(100.0, total))
	if total < 100: shares.append((100.0 - total) / 100.0)
	return shares

func _draw() -> void:
	var font := get_theme_default_font()
	var ink := Color("f1e5cd")
	_centered_text(font, "Priority influence", 18, 15, ink)
	var origin := Vector2(size.x / 2.0, 104)
	var radius := 70.0
	var angle := -PI / 2.0
	var shares := get_chart_shares()
	for i in range(shares.size()):
		var sweep := shares[i] * TAU
		if sweep <= 0: continue
		var color: Color = _colors[i] if i < _colors.size() else UNUSED_COLOR
		var points := PackedVector2Array([origin])
		var segments := maxi(2, ceili(sweep * 32.0))
		for step in range(segments + 1):
			points.append(origin + Vector2.from_angle(angle + sweep * step / segments) * radius)
		draw_colored_polygon(points, color)
		draw_line(origin, points[1], Color("191a22"), 2.0, true)
		draw_arc(origin, radius, angle, angle + sweep, segments + 1, color, 1.0, true)
		if shares[i] >= 0.09:
			var caption := "%d%%" % roundi(shares[i] * 100)
			var extent := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
			var anchor := origin + Vector2.from_angle(angle + sweep / 2.0) * radius * 0.65
			draw_string(font, anchor + Vector2(-extent.x / 2.0, 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("15161b") if i < _colors.size() else ink)
		angle += sweep
	var status := "100 points allocated"
	if total < 100: status = "%d points unallocated" % (100 - total)
	elif total > 100: status = "%d / 100 · Over budget" % total
	_centered_text(font, status, 190, 13, ink if is_equal_approx(total, 100) else Color("ffc779"))
	_centered_text(font, "Relative shares" if total > 100 else "Future draws · not scores", 207, 11, Color("aaaab6"))

func _centered_text(font: Font, text: String, baseline: float, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
