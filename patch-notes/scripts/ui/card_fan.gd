class_name CardFan
extends Container

const CARD_SIZE := Vector2(240, 336)
const WAVE_HEIGHT := 6.0
const WAVE_PERIOD := 3.6
const WAVE_SPACING := 0.62
var _wave_time := 0.0
var _poses: Dictionary = {}
var _tweens: Dictionary = {}
var _pressed: CardView
var _visual_order: Array[CardView] = []
var _scope_sort_next := false

func cycle_organization() -> String:
	if _scope_sort_next:
		organize_by_scope()
	else:
		organize_by_primary()
	_scope_sort_next = not _scope_sort_next
	return "Sort by Scope" if _scope_sort_next else "Sort by Category"

func organize_by_scope() -> void:
	var cards := ordered_cards()
	var scopes: Array[int] = []
	for card in cards:
		if card.card_data.scope not in scopes: scopes.append(card.card_data.scope)
	scopes.sort()
	scopes.reverse()
	_visual_order.clear()
	for amount in scopes:
		for card in cards:
			if card.card_data.scope == amount: _visual_order.append(card)
	arrange()

func organize_by_primary() -> void:
	# Stable visual grouping only: authoritative candidate slots stay untouched.
	var cards := ordered_cards()
	_visual_order.clear()
	for category in [&"graphics", &"sound", &"technology", &"design"]:
		for card in cards:
			if card.card_data.primary_stat == category: _visual_order.append(card)
	for card in cards:
		if card not in _visual_order: _visual_order.append(card)
	arrange()

func ordered_cards() -> Array[CardView]:
	var result: Array[CardView] = []
	for card in _visual_order:
		if is_instance_valid(card) and card.get_parent() == self: result.append(card)
	for card in get_children():
		if card is CardView and card not in result: result.append(card)
	return result

func retain_order(previous: Array) -> void:
	_visual_order.clear()
	for card in previous:
		if is_instance_valid(card) and card.get_parent() == self: _visual_order.append(card)
	_visual_order = ordered_cards()
	arrange(true)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	child_entered_tree.connect(_connect_card)
	for child in get_children(): _connect_card(child)

func _process(delta: float) -> void:
	# HandPresentation hides the real fan while it animates its captured cards.
	if not is_visible_in_tree(): return
	_wave_time = fmod(_wave_time + delta, WAVE_PERIOD)
	for card in ordered_cards(): _apply_wave(card)

func _apply_wave(card: CardView) -> void:
	if not _poses.has(card): return
	var pose: Dictionary = _poses[card]
	var phase: float = _wave_time * TAU / WAVE_PERIOD - pose.index * WAVE_SPACING
	var strength := 0.45 if card.is_selected() else 1.0
	card.position.y = pose.position.y + sin(phase) * WAVE_HEIGHT * strength
	card.rotation = pose.angle + cos(phase) * deg_to_rad(0.65) * strength

func _set_base_position(value: Vector2, card: CardView) -> void:
	_poses[card].position = value
	card.position = value
	_apply_wave(card)

func _set_base_angle(value: float, card: CardView) -> void:
	_poses[card].angle = value
	_apply_wave(card)

func _connect_card(child: Node) -> void:
	if not child is CardView: return
	_ignore_pointer(child)
	child.ready.connect(func(): _ignore_pointer(child); child.input_button.focus_mode = Control.FOCUS_ALL, CONNECT_ONE_SHOT)
	if not child.selection_changed.is_connected(queue_sort): child.selection_changed.connect(queue_sort)
	child.tree_exiting.connect(func():
		_poses.erase(child)
		if _tweens.has(child):
			_tweens[child].kill()
			_tweens.erase(child), CONNECT_ONE_SHOT)

func _ignore_pointer(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_pointer(child)

func card_at(point: Vector2) -> CardView:
	# Control GUI input ignores CanvasItem z_index; route hits using visual order.
	# Godot can attach its tooltip PopupPanel here; only cards participate.
	var cards := ordered_cards()
	cards.sort_custom(func(a: CardView, b: CardView): return a.z_index > b.z_index)
	for card: CardView in cards:
		if Rect2(Vector2.ZERO, card.size).has_point(card.get_transform().affine_inverse() * point): return card
	return null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var card := card_at(event.position)
		tooltip_text = card.input_button.tooltip_text if card != null else ""
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var card := card_at(event.position)
		if event.pressed: _pressed = card
		else:
			if is_instance_valid(_pressed) and card == _pressed:
				card.input_button.grab_focus()
				card.card_pressed.emit(card)
			_pressed = null
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_inside_tree(): arrange()

func arrange(immediate := false) -> void:
	var cards := ordered_cards()
	var count := cards.size()
	var factor := clampf((size.y - 100.0) / CARD_SIZE.y, 0.45, 0.76)
	var spacing := minf(124.0, (size.x - CARD_SIZE.x * factor - 70.0) / maxf(1, count - 1))
	for i in range(count):
		var card := cards[i]
		if card == null: continue
		var offset := i - (count - 1) / 2.0
		var spread := offset / maxf(1.0, (count - 1) / 2.0)
		var center := Vector2(size.x / 2.0 + spacing * offset, size.y / 2.0 + 24.0 + spread * spread * 16.0)
		if card.is_selected(): center.y -= 48.0
		var target := center - CARD_SIZE / 2.0
		var angle := spread * deg_to_rad(9.0)
		card.size = CARD_SIZE
		card.pivot_offset = CARD_SIZE / 2.0
		card.z_index = i + (20 if card.is_selected() else 0)
		if not immediate and not card.is_selected() and card.has_meta("fan_entering") and _tweens.has(card) and _tweens[card].is_running(): continue
		if _tweens.has(card): _tweens[card].kill()
		if not _poses.has(card):
			_poses[card] = {"position": card.position, "angle": card.rotation, "index": i}
		_poses[card].index = i
		if immediate or not card.has_meta("fan_placed"):
			var entrance := not immediate and not card.has_meta("fan_placed") and is_visible_in_tree()
			_set_base_position(target, card)
			_set_base_angle(angle, card)
			card.scale = Vector2.ONE * factor
			card.set_meta("fan_placed", true)
			if entrance:
				var start := Vector2(target.x, -CARD_SIZE.y - global_position.y)
				_set_base_position(start, card)
				card.set_meta("fan_entering", true)
				var entry := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				_tweens[card] = entry
				entry.tween_interval(i * 0.045)
				entry.tween_method(_set_base_position.bind(card), start, target, 0.34)
				entry.tween_callback(func(): card.remove_meta("fan_entering"))
		else:
			var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tweens[card] = tween
			tween.tween_method(_set_base_position.bind(card), _poses[card].position, target, 0.16)
			tween.tween_method(_set_base_angle.bind(card), _poses[card].angle, angle, 0.16)
			tween.tween_property(card, "scale", Vector2.ONE * factor, 0.16)
