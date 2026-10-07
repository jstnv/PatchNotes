class_name HandPresentation
extends Control

## Presentation consumes confirmed state differences. It never resolves cards,
## spends cash/redraws, advances time, exhausts supply, or calls gameplay twice.
signal finished
signal busy_changed
signal card_step(index: int, event: String)

const CARD_SCENE := preload("res://scenes/cards/card_view.tscn")
const CORE := [&"graphics", &"sound", &"technology", &"design"]
var busy := false
var action_kind := ""
var display_values: Dictionary = {}
var trace: Array[Dictionary] = []
var _fan: Control
var _ghosts: Array[CardView] = []
var _hand: Array[CardView] = []
var _cards: Array[CardData] = []
var _timeline: Array[Dictionary] = []
var _tween: Tween
var _update: Callable
var _restore: Callable
var _prior_focus: Control
var _sources: Array = []
var _specialization := false
var _bonus_timeline: Array[Dictionary] = []
var capturing := false
var _specialization_header: Callable

func note_specialization(header: Callable) -> void:
	if capturing:
		_specialization = true
		_specialization_header = header

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	focus_mode = Control.FOCUS_ALL
	hide()
	resized.connect(func(): if busy: cancel())

func _gui_input(_event: InputEvent) -> void:
	if busy: accept_event()

func play(kind: String, fan: Control, selected: Array, action: Callable, snapshot: Callable, update: Callable, restore: Callable) -> bool:
	if busy or selected.is_empty() or not action.is_valid() or not snapshot.is_valid(): return false
	var before: Dictionary = snapshot.call()
	if before.is_empty(): return false
	_fan = fan
	_update = update
	_restore = restore
	trace.clear()
	_specialization = false
	_sources = fan.ordered_cards() if fan is CardFan else fan.get_children()
	# Capture the old pool before the authoritative action replaces/frees it.
	for source: CardView in _sources:
		var ghost: CardView = CARD_SCENE.instantiate()
		ghost.set_card(source.card_data)
		add_child(ghost)
		ghost.size = CardFan.CARD_SIZE
		ghost.pivot_offset = ghost.size / 2.0
		ghost.position = get_global_transform().affine_inverse() * source.get_global_transform() * (source.size / 2.0) - ghost.size / 2.0
		ghost.scale = source.get_global_transform().get_scale() / get_global_transform().get_scale()
		ghost.rotation = source.get_global_transform().get_rotation() - get_global_transform().get_rotation()
		ghost.input_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.set_selected(source in selected)
		_ghosts.append(ghost)
		if source in selected:
			_hand.append(ghost)
			_cards.append(source.card_data)
	# Hold the old scoreboard before project/run signals publish the committed totals.
	display_values = before.duplicate()
	if _update.is_valid(): _update.call(display_values, {})
	capturing = true
	action.call()
	capturing = false
	var after: Dictionary = snapshot.call()
	var accepted: bool = after.get("_redraws") != before.get("_redraws") if kind == "redraw" else after.get("_cycle") != before.get("_cycle")
	if not accepted:
		_clear()
		return false
	busy = true
	action_kind = kind
	_prior_focus = get_viewport().gui_get_focus_owner()
	show()
	grab_focus()
	fan.hide()
	_timeline = build_timeline(_cards, before, after)
	_bonus_timeline.clear()
	for i in range(_cards.size()):
		var bonus := {}
		for key in _timeline[i]:
			# Only split uncapped production/Marketing gains. QA has ordered,
			# capped effects, so its resolved contribution stays in the first pass.
			var extra: int = maxi(0, int(_timeline[i][key]) - _weight(_cards[i], key)) if _specialization and (key in CORE or key == &"marketing") else 0
			bonus[key] = extra
			_timeline[i][key] -= extra
		_bonus_timeline.append(bonus)
	busy_changed.emit()
	_animate(kind)
	return true

static func project_snapshot(project: ProjectState, run: RunState) -> Dictionary:
	if project == null: return {}
	var result := {&"scope": project.get_current_scope(), &"fixed": project.get_fixed_bugs(),
		&"discovered": project.get_known_bugs() + project.get_fixed_bugs(), &"marketing": project.get_marketing_output(),
		"_cycle": project.get_current_cycle(), "_redraws": run.get_available_redraws() if run != null else 0}
	for i in range(4): result[CORE[i]] = project.get_core_score(i)
	return result

static func _weight(card: CardData, key: StringName) -> int:
	if key == &"scope": return card.scope
	if key == &"marketing": return card.beta_value if card.beta_category == CardData.BETA_CATEGORY_MARKETING else 0
	if key == &"fixed": return card.beta_value if card.qa_operation == &"debug" else 0
	if key == &"discovered": return card.beta_value if card.qa_operation == &"search" else 0
	return (card.primary_value if card.primary_stat == key else 0) + (card.secondary_value if card.secondary_stat == key else 0)

static func build_timeline(cards: Array[CardData], before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	# Allocate the already-resolved hand gain by cumulative printed contribution.
	# This carries hand-level rounding into the display without inventing extra points.
	var rows: Array[Dictionary] = []
	for i in range(cards.size()): rows.append({})
	for key: StringName in before:
		if str(key).begins_with("_"): continue
		var total_weight := 0
		for card in cards: total_weight += _weight(card, key)
		var cumulative := 0
		var last := 0
		var gain: int = int(after.get(key, before[key])) - int(before[key])
		for i in range(cards.size()):
			cumulative += _weight(cards[i], key)
			@warning_ignore("integer_division")
			var resolved: int = (gain / total_weight) * cumulative + ((gain % total_weight) * cumulative) / total_weight if total_weight > 0 else (gain if i == cards.size() - 1 else 0)
			rows[i][key] = resolved - last
			last = resolved
	return rows

func _animate(kind: String) -> void:
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_parallel()
	var center := size / 2.0
	var scale_value := minf(0.68, (size.x - 70.0) / (_hand.size() * 258.0))
	var remaining := _ghosts.filter(func(card): return card not in _hand)
	for ghost in _ghosts:
		if ghost in _hand:
			var index := _hand.find(ghost)
			var target := center + Vector2((index - (_hand.size() - 1) / 2.0) * 258.0 * scale_value, -10.0) - ghost.size / 2.0
			ghost.z_index = 20 + index
			_tween.tween_property(ghost, "position", target, 0.30)
			_tween.tween_property(ghost, "scale", Vector2.ONE * scale_value, 0.30)
			_tween.tween_property(ghost, "rotation", 0.0, 0.30)
		else:
			var offset: float = remaining.find(ghost) - (remaining.size() - 1) / 2.0
			_tween.tween_property(ghost, "position", Vector2(size.x / 2.0 + offset * 58.0, size.y - 85.0 + offset * offset * 3.0) - ghost.size / 2.0, 0.30)
			_tween.tween_property(ghost, "rotation", offset * deg_to_rad(7.0), 0.30)
			_tween.tween_property(ghost, "scale", Vector2.ONE * 0.34, 0.30)
			_tween.tween_property(ghost, "modulate:a", 0.65, 0.30)
	_tween.chain().tween_callback(func(): _record(-1, "centered"))
	if kind == "redraw":
		_tween.chain()
		for ghost in _hand:
			_tween.parallel().tween_property(ghost, "position:x", size.x + 260.0 + _hand.find(ghost) * 150.0, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	else:
		for i in range(_hand.size()):
			var ghost := _hand[i]
			_tween.chain().tween_callback(_record.bind(i, "rise"))
			_tween.chain().tween_property(ghost, "position:y", -28.0, 0.15).as_relative()
			_tween.chain().tween_callback(_score_card.bind(i))
			_tween.chain().tween_property(ghost, "position:y", 28.0, 0.19).as_relative().set_ease(Tween.EASE_IN)
			_tween.chain().tween_callback(_record.bind(i, "grounded"))
		if _specialization:
			for i in range(_hand.size()):
				_tween.chain().tween_callback(_score_bonus.bind(i))
				_tween.chain().tween_interval(0.24)
		_tween.chain().tween_interval(0.18)
		# A purely visual victory wave after every resolved score/bonus is shown.
		for i in range(_hand.size()):
			var ghost := _hand[i]
			_tween.chain().tween_callback(_record.bind(i, "exit_bounce"))
			_tween.chain().tween_property(ghost, "position:y", -22.0, 0.10).as_relative()
			_tween.chain().tween_property(ghost, "position:y", 22.0, 0.13).as_relative().set_ease(Tween.EASE_IN)
			_tween.chain().tween_callback(_record.bind(i, "exit_grounded"))
		_tween.chain().tween_callback(_record.bind(-1, "exit_slide"))
		_tween.chain()
		for ghost in _hand:
			_tween.parallel().tween_property(ghost, "position:x", size.x + CardFan.CARD_SIZE.x, 0.38).as_relative().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_return_fan)

func _return_fan() -> void:
	if not is_instance_valid(_fan):
		_clear()
		return
	var targets: Array = _fan.ordered_cards() if _fan is CardFan else _fan.get_children()
	# Only surviving instances return. A fresh copy of the same renewable card
	# is still a new draw, not the card the player reserved.
	var returning: Array = []
	var matches := {}
	for i in range(_sources.size()):
		if _ghosts[i] in _hand: continue
		if is_instance_valid(_sources[i]) and _sources[i] in targets:
			returning.append(_sources[i])
			matches[_sources[i]] = i
	if _fan is CardFan: _fan.retain_order(returning)
	targets = _fan.ordered_cards() if _fan is CardFan else targets
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var retained: Array = []
	for source in targets:
		var target: Vector2 = get_global_transform().affine_inverse() * source.get_global_transform() * (source.size / 2.0) - CardFan.CARD_SIZE / 2.0
		var old_index: int = matches.get(source, -1)
		var ghost: CardView
		var is_new := old_index < 0
		if not is_new:
			ghost = _ghosts[old_index]
			retained.append(ghost)
			# Reuse the visible bottom-fan card, preserving its current transform.
		else:
			ghost = CARD_SCENE.instantiate()
			ghost.set_card(source.card_data)
			add_child(ghost)
			ghost.size = CardFan.CARD_SIZE
			ghost.pivot_offset = ghost.size / 2.0
			# New candidates drop into their own slot from above the viewport.
			ghost.position = Vector2(target.x, -ghost.size.y - get_global_transform().origin.y)
			ghost.scale = Vector2.ONE * 0.34
			ghost.modulate.a = 0.0
			_ghosts.append(ghost)
		ghost.z_index = targets.find(source)
		if is_new: _tween.chain().tween_callback(_record.bind(targets.find(source), "deal"))
		else:
			_tween.parallel().tween_callback(_record.bind(targets.find(source), "return_from_bottom"))
			_tween.parallel()
		_tween.tween_property(ghost, "position", target, 0.22)
		_tween.parallel().tween_property(ghost, "rotation", source.get_global_transform().get_rotation() - get_global_transform().get_rotation(), 0.22)
		_tween.parallel().tween_property(ghost, "scale", source.get_global_transform().get_scale() / get_global_transform().get_scale(), 0.22)
		_tween.parallel().tween_property(ghost, "modulate:a", 1.0, 0.22)
	for ghost in _ghosts:
		if ghost not in retained and ghost not in _hand and ghost.get_index() < _sources.size():
			_tween.parallel().tween_property(ghost, "modulate:a", 0.0, 0.18)
	_tween.chain().tween_callback(func(): _record(-1, "fan_restored"); _clear())

func _score_bonus(index: int) -> void:
	if index == 0 and _specialization_header.is_valid():
		_specialization_header.call()
		_specialization_header = Callable()
	var deltas := _bonus_timeline[index]
	var parts: Array[String] = []
	for key in deltas:
		display_values[key] += deltas[key]
		if deltas[key] > 0: parts.append("+%d %s" % [deltas[key], str(key).capitalize()])
	if _update.is_valid(): _update.call(display_values.duplicate(), deltas)
	if not parts.is_empty():
		var label := Label.new()
		label.text = "\n".join(parts)
		label.add_theme_color_override("font_color", Color("#f5bd59"))
		label.add_theme_font_size_override("font_size", 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hand[index].add_child(label)
		label.position = Vector2(8, 90)
		var pop := label.create_tween().set_parallel()
		pop.tween_property(label, "position:y", 65.0, 0.22)
		pop.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.4)
	_record(index, "bonus")

func _record(index: int, event: String) -> void:
	trace.append({"index": index, "event": event, "msec": Time.get_ticks_msec()})
	card_step.emit(index, event)

func _score_card(index: int) -> void:
	var deltas: Dictionary = _timeline[index]
	for key in deltas: display_values[key] += deltas[key]
	if _update.is_valid(): _update.call(display_values.duplicate(), deltas)
	_record(index, "score")

func cancel() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_clear()

func _exit_tree() -> void:
	if busy: cancel()

func _clear() -> void:
	var was_busy := busy
	busy = false
	action_kind = ""
	display_values.clear()
	for ghost in _ghosts:
		if is_instance_valid(ghost):
			remove_child(ghost)
			ghost.queue_free()
	_ghosts.clear()
	_hand.clear()
	_cards.clear()
	_timeline.clear()
	_bonus_timeline.clear()
	_specialization_header = Callable()
	_sources.clear()
	if is_instance_valid(_fan): _fan.show()
	hide()
	if _restore.is_valid(): _restore.call()
	if is_instance_valid(_prior_focus) and _prior_focus.is_inside_tree() and _prior_focus.is_visible_in_tree(): _prior_focus.grab_focus()
	_prior_focus = null
	if was_busy:
		busy_changed.emit()
		finished.emit()
