class_name CardFan
extends Container

const CARD_SIZE := Vector2(240, 336)
var _tweens: Dictionary = {}
var _pressed: CardView

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	child_entered_tree.connect(_connect_card)
	for child in get_children(): _connect_card(child)

func _connect_card(child: Node) -> void:
	if not child is CardView: return
	_ignore_pointer(child)
	child.ready.connect(func(): _ignore_pointer(child); child.input_button.focus_mode = Control.FOCUS_ALL, CONNECT_ONE_SHOT)
	if not child.selection_changed.is_connected(queue_sort): child.selection_changed.connect(queue_sort)
	child.tree_exiting.connect(func():
		if _tweens.has(child):
			_tweens[child].kill()
			_tweens.erase(child), CONNECT_ONE_SHOT)

func _ignore_pointer(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore_pointer(child)

func card_at(point: Vector2) -> CardView:
	# Control GUI input ignores CanvasItem z_index; route hits using visual order.
	var cards := get_children()
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

func arrange() -> void:
	var count := get_child_count()
	var factor := clampf((size.y - 100.0) / CARD_SIZE.y, 0.45, 0.76)
	var spacing := minf(124.0, (size.x - CARD_SIZE.x * factor - 70.0) / maxf(1, count - 1))
	for i in range(count):
		var card := get_child(i) as CardView
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
		if _tweens.has(card): _tweens[card].kill()
		if not card.has_meta("fan_placed"):
			card.position = target
			card.rotation = angle
			card.scale = Vector2.ONE * factor
			card.set_meta("fan_placed", true)
		else:
			var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tweens[card] = tween
			tween.tween_property(card, "position", target, 0.16)
			tween.tween_property(card, "rotation", angle, 0.16)
			tween.tween_property(card, "scale", Vector2.ONE * factor, 0.16)
