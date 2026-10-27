extends Control

## Read-only text poses sampled from the presentation music clock.
const STEP := 60.0 / 140.0
const RISE_HEIGHT := 74.0
const LANDING_DROP := 10.0
const COLORS := [Color("#eb8b9b"), Color("#efcd66"), Color("#74d3de"), Color("#bfa3ed")]
const CORE := [&"graphics", &"sound", &"technology", &"design"]
const NAMES := ["GFX", "SOUND", "TECH", "DESIGN"]
var tokens: Array[Dictionary] = []
var hub: Dictionary
var phase := "base"
var synergy_start := -1.0
var exit_start := -1.0
var balanced := false
var divisor := 1
var multiplier_text := "×1.5"
var exit_complete := false
var category_values: Array = []

func configure(hand: Array, bases: Array, finals: Array, categories: Array) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	category_values = categories.duplicate()
	for index in range(hand.size()):
		var token := _token()
		token.merge({"ghost":hand[index], "base":bases[index], "final":finals[index], "started":-1.0})
		var card: CardData = hand[index].card_data
		var category := CORE.find(card.primary_stat)
		token.color = COLORS[category] if category >= 0 else Color("#f5ce69")
		token.caption = "CORE" if category >= 0 else "FOUND" if card.qa_operation == &"search" else "FIXED" if card.qa_operation == &"debug" else "MKTG"
		tokens.append(token)
	hub = _token()
	hub.color = Color("#f5ce69")
	hub.caption = "TOTAL CORE"

func _token() -> Dictionary:
	var window := Control.new()
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.clip_contents = true
	add_child(window)
	var result := {"window":window}
	for key in ["value", "mult", "unit"]:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_outline_color", Color("#111820"))
		label.add_theme_constant_override("outline_size", 5)
		window.add_child(label)
		result[key] = label
	window.hide()
	return result

func reveal(index: int, started: float) -> void:
	tokens[index].started = started

func begin_synergy(is_balanced: bool, started: float) -> void:
	balanced = is_balanced
	synergy_start = started
	phase = "balanced" if balanced else "specialization"

func begin_exit(started: float) -> void:
	exit_start = started
	phase = "exit"

func finish_exit() -> void:
	exit_complete = true
	hub.window.hide()
	for token in tokens: token.window.hide()

func rejoin(seconds: float) -> void:
	for token in tokens:
		if token.started >= 0: token.started += seconds
	if synergy_start >= 0: synergy_start += seconds
	if exit_start >= 0: exit_start += seconds

func _anchor(token: Dictionary) -> Vector2:
	var ghost: Control = token.ghost
	return (ghost.position + ghost.pivot_offset - Vector2(0, ghost.size.y * ghost.scale.y / 2.0 + 44.0)).round()

func _rise(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	var peak := 1.0 + LANDING_DROP / RISE_HEIGHT
	# Reach the apex halfway through the same rise interval, leaving a
	# full quarter subdivision to fall visibly into place under soft gravity.
	if t < 0.5:
		var up := t * 2.0
		return peak * (2.0 * up - up * up)
	var down := (t - 0.5) * 2.0
	return peak - (peak - 1.0) * down * down

func _toward_merge(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return 1.0 - cos(t * PI / 2.0)

func _away_from_merge(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return sin(t * PI / 2.0)

func _value_text(value: int) -> String:
	if divisor == 2:
		@warning_ignore("integer_division")
		var whole := value / 2
		return "+%d%s" % [whole, ".5" if value % 2 else ""]
	return "+%d" % value

func _pose(token: Dictionary, at: Vector2, value: int, multiplier: String = "", split: float = 0.0, mult_y: float = 0.0, shake: float = 0.0) -> void:
	var width := minf(180.0, size.x / (tokens.size() + 0.2)) if token != hub else minf(260.0, size.x)
	var border := size.y
	if token.has("ghost"):
		border = _anchor(token).y + 44.0
	else:
		for item in tokens: border = minf(border, _anchor(item).y + 44.0)
	token.window.position = Vector2(roundf(at.x - width / 2.0), 0)
	token.window.size = Vector2(width, maxf(0.0, border))
	token.window.show()
	var box := width / 2.0 - 4.0
	var offset := width / 4.0 * split
	for key in ["value", "mult"]:
		var label: Label = token[key]
		label.size = Vector2(box, 38)
		label.pivot_offset = label.size / 2.0
		label.text = _value_text(value) if key == "value" else multiplier
		var horizontal := -offset if key == "value" else offset
		label.position = Vector2(width / 2.0 - box / 2.0 + horizontal, at.y - 19.0 + (0.0 if key == "value" else mult_y)).round()
		var font: Font = label.get_theme_font("font")
		var natural := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		label.add_theme_font_size_override("font_size", int(clampf(28.0 * box / maxf(box, natural), 14.0, 28.0)))
		label.add_theme_color_override("font_color", token.color)
		label.scale = Vector2.ONE * (1.0 + 0.13 * absf(shake))
		label.rotation = shake * 0.045
	token.mult.visible = not multiplier.is_empty()
	# Keep the small caption clear of the multiplier while it crosses its lane.
	token.unit.visible = multiplier.is_empty() or is_zero_approx(mult_y)
	token.unit.text = token.caption
	token.unit.position = Vector2(0, at.y + 18.0).round()
	token.unit.size = Vector2(width, 18)
	token.unit.add_theme_font_size_override("font_size", 12)
	token.unit.add_theme_color_override("font_color", token.color)

func sample(now: float) -> void:
	if exit_complete: return
	if exit_start >= 0:
		hub.window.hide()
		var age := maxf(0.0, (now - exit_start) / STEP)
		for index in range(tokens.size()):
			var token: Dictionary = tokens[index]
			if age >= 1.0:
				token.window.hide()
				continue
			var at := _anchor(token)
			# Continuous toss: apex at 25%, then accelerate behind the border.
			at.y += 100.0 * (2.0 * age * age - age)
			_pose(token, at, int(category_values[index % 4]) if balanced else int(token.final))
		return
	if synergy_start >= 0:
		var age := maxf(0.0, (now - synergy_start) / STEP)
		if balanced: _balanced(age)
		else:
			for token in tokens:
				var at := _anchor(token)
				if age < 1.0:
					_pose(token, at, token.base, multiplier_text, _away_from_merge(age * 4.0), RISE_HEIGHT * (1.0 - _rise(age * 2.0)))
				elif age < 2.0:
					_pose(token, at, token.base, multiplier_text, 1.0 - _toward_merge(age - 1.0))
				else:
					var shake := sin((age - 2.0) * 32.0) * exp(-(age - 2.0) * 4.0)
					_pose(token, at, token.final, "", 0, 0, shake)
		return
	for token in tokens:
		if token.started < 0: continue
		var age := maxf(0.0, (now - float(token.started)) / (STEP / 2.0))
		var at := _anchor(token)
		at.y += RISE_HEIGHT * (1.0 - _rise(age))
		_pose(token, at, token.base)

func _balanced(age: float) -> void:
	var center := Vector2(size.x / 2.0, size.y)
	var sum := 0
	var boosted := 0
	for token in tokens:
		center.y = minf(center.y, _anchor(token).y)
		sum += int(token.base)
	for value in category_values: boosted += int(value)
	center.y = maxf(22.0, center.y - 12.0)
	if age < 0.5:
		for token in tokens: _pose(token, _anchor(token).lerp(center, _toward_merge(age * 2.0)), token.base)
		return
	for token in tokens: token.window.hide()
	if age < 1.0:
		_pose(hub, center, sum, "×1.25", _away_from_merge((age - 0.5) * 2.0))
	elif age < 1.5:
		# Hold the completed mitosis for half a subdivision, then accelerate
		# inward and still reach the existing merge boundary at subdivision 2.
		_pose(hub, center, sum, "×1.25", 1.0)
	elif age < 2.0:
		_pose(hub, center, sum, "×1.25", 1.0 - _toward_merge((age - 1.5) * 2.0))
	elif age < 2.15:
		_pose(hub, center, boosted, "", 0, 0, sin((age - 2.0) * 32.0))
	else:
		hub.window.hide()
		var travel := clampf((age - 2.15) / 0.85, 0.0, 1.0)
		for index in range(tokens.size()):
			var token: Dictionary = tokens[index]
			token.color = COLORS[index % 4]
			token.caption = NAMES[index % 4]
			_pose(token, center.lerp(_anchor(token), _away_from_merge(travel)), int(category_values[index % 4]))
