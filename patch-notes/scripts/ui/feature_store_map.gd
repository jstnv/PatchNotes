class_name FeatureStoreMap
extends Control

var store: FeatureStore
var scroll: ScrollContainer
var canvas: Control
var tree: Control
var popup: PanelContainer
var price: RichTextLabel
var zoom_label: Label
var zoom := 1.0
var bounds := Vector2.ZERO
var origins: Dictionary = {}
var center := Vector2.ZERO
var core_radius := 0.0
const INNER_RADIUS := 450.0
const OUTER_RADIUS := 750.0
const BRANCH_STEP := 310.0
const ROW_STEP := 200.0
const LABEL_OFFSET := Vector2(-8, 136)
const LABEL_SIZE := Vector2(144, 36)
var dragging := false
const DRAG_THRESHOLD := 6.0
var _drag_button := MOUSE_BUTTON_NONE
var _drag_origin := Vector2.ZERO
var _drag_scroll := Vector2.ZERO
var _pressed_node: StringName = &""
var _view_revision := 0
var _focus_padding := Vector2.ZERO
var _focus_tween: Tween
var _menu_tween: Tween
var focusing := false

func configure(owner_store: FeatureStore, layout: VBoxContainer) -> void:
	store = owner_store
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	for caption in ["−", "+", "Show all"]:
		var button := Button.new()
		button.text = caption
		toolbar.add_child(button)
		if caption == "Show all": button.pressed.connect(fit_map)
		elif caption == "+": button.pressed.connect(func(): set_zoom(zoom * 1.25))
		else: button.pressed.connect(func(): set_zoom(zoom / 1.25))
	zoom_label = Label.new()
	toolbar.add_child(zoom_label)
	var help := Label.new()
	help.text = "Drag: pan · Wheel: zoom · Arrow keys: browse · Click: inspect"
	help.add_theme_font_size_override("font_size", 12)
	toolbar.add_child(help)
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 16)
	layout.add_child(legend)
	var legend_title := Label.new()
	legend_title.text = "Border: primary score"
	legend_title.add_theme_font_size_override("font_size", 12)
	legend.add_child(legend_title)
	for stat: StringName in FeatureStore.SCORE_COLORS:
		var label := Label.new()
		label.text = "■ " + FeatureStore.score_label(stat)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", FeatureStore.SCORE_COLORS[stat])
		legend.add_child(label)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Reveal focused nodes ourselves: automatic follow_focus ignores map zoom.
	scroll.follow_focus = false
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.custom_minimum_size.y = 150
	layout.add_child(scroll)
	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)
	canvas.resized.connect(_center_canvas)
	tree = Control.new()
	canvas.add_child(tree)
	store._scroll = scroll
	store._tree = tree
	tree.draw.connect(store._draw_connections)
	# This layer is a child of a plain Control, not a Container layout item.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup = PanelContainer.new()
	popup.custom_minimum_size.x = 260
	add_child(popup)
	popup.resized.connect(position_details)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1b1c24")
	style.border_color = Color("d7b679")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	popup.add_theme_stylebox_override("panel", style)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 10)
	popup.add_child(details)
	store._details = Label.new()
	store._details.custom_minimum_size.x = 228
	store._details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(store._details)
	price = RichTextLabel.new()
	price.custom_minimum_size.x = 228
	price.size.x = 228
	price.bbcode_enabled = true
	price.fit_content = true
	price.scroll_active = false
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(price)
	store._buy = Button.new()
	store._buy.pressed.connect(store._purchase)
	details.add_child(store._buy)
	popup.hide()
	store.visibility_changed.connect(func():
		_cancel_drag()
		if not store.visible: dismiss())
	store.resized.connect(func():
		_cancel_drag()
		dismiss())

func decorate(button: Button, card: CardData) -> void:
	button.focus_entered.connect(_on_node_focused.bind(card.id))
	# The artwork stays square; its name belongs below the colored border.
	button.clip_contents = false
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, Color.TRANSPARENT)
	var art := TextureRect.new()
	art.position = Vector2(5, 5)
	art.size = Vector2(118, 118)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not card.artwork_path.is_empty() and ResourceLoader.exists(card.artwork_path, "Texture2D"):
		art.texture = load(card.artwork_path) as Texture2D
	button.add_child(art)
	if art.texture == null:
		var fallback := Label.new()
		fallback.text = FeatureStore.score_label(card.primary_stat)
		fallback.position = Vector2(5, 32)
		fallback.size = Vector2(118, 64)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 22)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(fallback)
	var title := Label.new()
	title.name = "FeatureName"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_constant_override("line_spacing", -2)
	title.text = card.card_name
	title.position = LABEL_OFFSET
	title.size = LABEL_SIZE
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)
	var status := Label.new()
	status.name = "MapStatus"
	status.position = Vector2(6, 5)
	status.size.x = 116
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_size_override("font_size", 10)
	var status_background := StyleBoxFlat.new()
	status_background.bg_color = Color(0.07, 0.08, 0.1, 0.9)
	status.add_theme_stylebox_override("normal", status_background)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(status)

func layout_map(children: Dictionary) -> void:
	# Membership comes from the Primitive ledger, not ownership or graph-root status.
	# New roots (Save Files) and the multi-Feature gate stay outside this core.
	var primitive: Dictionary = {}
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		primitive[StringName(entry.id)] = true
	var controls: Array[Control] = []
	for index in range(store.LANE_ORDER.size()):
		var lane: StringName = store.LANE_ORDER[index]
		var direction := Vector2.UP.rotated(TAU * index / store.LANE_ORDER.size())
		origins[lane] = direction * OUTER_RADIUS
		var heading := Label.new()
		heading.text = str(lane).to_upper()
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.size = Vector2(240, 32)
		heading.position = direction * 240.0 - heading.size / 2.0
		tree.add_child(heading)
		controls.append(heading)
		var outer: Array[StringName] = []
		var inner: Array[StringName] = []
		for id: StringName in store.LANE_MEMBERS[lane]:
			if not primitive.has(id): continue
			if children.has(id): outer.append(id)
			else: inner.append(id)
		var count := outer.size() + inner.size()
		while outer.size() < maxi(ceili(count / 2.0), count - 3):
			outer.append(inner.pop_front())
		_place_core_row(outer, direction, OUTER_RADIUS, children)
		_place_core_row(inner, direction, INNER_RADIUS, children)
		# Independent roots have no invented edge back to a Primitive Feature.
		var extra_roots: Array[StringName] = []
		for id: StringName in store.LANE_MEMBERS[lane]:
			if not primitive.has(id) and not store._edges.any(func(edge: Array): return edge[1] == id):
				extra_roots.append(id)
		if lane == &"Gameplay": extra_roots.append(&"gameplay_gate")
		for i in range(extra_roots.size()):
			var spoke := direction.rotated(0.38 + i * 0.25)
			_place_branch(extra_roots[i], spoke * (OUTER_RADIUS + BRANCH_STEP), children)
	for id: StringName in store._nodes:
		controls.append(store._nodes[id])
		if primitive.has(id):
			core_radius = maxf(core_radius, (store._nodes[id].position + store.NODE_SIZE / 2.0).length() + 108.0)
	controls.append(store._gate)
	var hub := Label.new()
	hub.text = "PRIMITIVE CORE\nBranches grow outward"
	hub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hub.add_theme_font_size_override("font_size", 26)
	hub.size = Vector2(340, 80)
	hub.position = -hub.size / 2.0
	tree.add_child(hub)
	controls.append(hub)
	var area := Rect2(Vector2.ONE * -core_radius, Vector2.ONE * core_radius * 2.0)
	for control in controls:
		area = area.merge(node_footprint(control) if control is Button else control.get_rect())
	area = area.grow(60.0)
	center = -area.position
	for control in controls: control.position += center
	for lane: StringName in origins: origins[lane] += center
	bounds = area.size
	store._lane_heading.hide()
	tree.size = bounds
	# Wait for Containers to lay out before measuring the first overview.
	_initial_overview()

func _initial_overview() -> void:
	var revision := _view_revision
	await get_tree().process_frame
	await get_tree().process_frame
	if revision == _view_revision: fit_map()

func _center_canvas() -> void:
	if tree != null:
		tree.position = _focus_padding + (canvas.size - bounds * zoom - _focus_padding * 2.0).max(Vector2.ZERO) / 2.0

func _place_core_row(ids: Array[StringName], direction: Vector2, radius: float, children: Dictionary) -> void:
	var tangent := direction.rotated(PI / 2.0)
	for i in range(ids.size()):
		var point := direction * radius + tangent * (i - (ids.size() - 1) / 2.0) * ROW_STEP
		_place_branch(ids[i], point, children)

func _place_branch(id: StringName, point: Vector2, children: Dictionary) -> void:
	var node: Control = store._gate if id == &"gameplay_gate" else store._nodes[id]
	node.position = point - node.size / 2.0
	var descendants: Array = children.get(id, [])
	for i in range(descendants.size()):
		var direction := point.normalized().rotated((i - (descendants.size() - 1) / 2.0) * 0.24)
		_place_branch(descendants[i], direction * (point.length() + BRANCH_STEP), children)

func draw_core() -> void:
	if core_radius <= 0.0: return
	tree.draw_circle(center, core_radius, Color(0.17, 0.20, 0.26, 0.28))
	tree.draw_arc(center, core_radius, 0, TAU, 160, Color("414b5c"), 2, true)

func node_footprint(node: Control) -> Rect2:
	return Rect2(node.position + Vector2(LABEL_OFFSET.x, 0), Vector2(LABEL_SIZE.x, LABEL_OFFSET.y + LABEL_SIZE.y))

func edge_port(rect: Rect2, direction: Vector2) -> Vector2:
	var half := rect.size / 2.0
	var reach := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	return rect.get_center() + direction * (reach + 8.0)

func navigate(lane: StringName) -> void:
	set_zoom(1.0)
	var origin: Vector2 = tree.position + origins[lane] - _map_rect().size / 2.0
	_scroll_after_layout(origin, _view_revision)

func set_zoom(value: float, anchor: Vector2 = Vector2(-1, -1)) -> void:
	_cancel_drag()
	dismiss()
	_view_revision += 1
	if anchor.x < 0: anchor = _map_rect().size / 2.0
	var previous := zoom
	var previous_origin := tree.position
	zoom = clampf(value, 0.1, 2.0)
	var offset := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	tree.scale = Vector2.ONE * zoom
	canvas.custom_minimum_size = bounds * zoom + _focus_padding * 2.0
	canvas.size = canvas.custom_minimum_size.max(_map_rect().size)
	_center_canvas()
	zoom_label.text = "%d%%" % roundi(zoom * 100)
	var next := (offset + anchor - previous_origin) * zoom / previous + tree.position - anchor
	_scroll_after_layout(next, _view_revision)

func _scroll_after_layout(offset: Vector2, revision: int) -> void:
	await get_tree().process_frame
	if revision != _view_revision: return
	scroll.scroll_horizontal = roundi(offset.x)
	scroll.scroll_vertical = roundi(offset.y)

func fit_map() -> void:
	_focus_padding = Vector2.ZERO
	set_zoom(minf((scroll.size.x - 20) / bounds.x, (scroll.size.y - 20) / bounds.y))
	_scroll_after_layout(Vector2.ZERO, _view_revision)

func dismiss() -> void:
	_stop_focus_animation()
	if not store._selected.is_empty() and store._nodes.has(store._selected) and is_instance_valid(store._nodes[store._selected]):
		var button: Button = store._nodes[store._selected]
		for key in ["normal", "hover", "pressed"]:
			var style := button.get_theme_stylebox(key) as StyleBoxFlat
			if style != null:
				style.set_border_width_all(3)
	store._selected = &""
	popup.hide()

func show_details() -> void:
	store._buy.disabled = true
	price.text = ""
	if store._selected.is_empty():
		popup.hide()
		return
	var card: CardData = get_node("/root/CardDatabase").get_card(store._selected)
	var stats := "%d %s" % [card.primary_value, FeatureStore.score_label(card.primary_stat)]
	if card.secondary_value != 0: stats += " · %d %s" % [card.secondary_value, FeatureStore.score_label(card.secondary_stat)]
	store._details.text = card.card_name + "\n" + stats + " · %d Scope" % card.scope
	var offer := store._run.get_feature_store_offer(store._selected)
	if store._run.owns_feature(store._selected):
		store._details.text += "\nOwned"
		store._buy.text = "Already owned"
	elif offer.is_empty():
		var reserve := store._run.get_primitive_reserve_offer(store._selected)
		price.text = CashFormatter.format_exact_cents(reserve.price_cents)
		store._details.text += "\n0 cycles" if reserve.initial else "\n1 cycle"
		store._buy.disabled = not reserve.can_purchase
		store._buy.text = "Purchase" if reserve.can_purchase else "Insufficient cash"
	else:
		store._details.text += "\n" + str(offer.prerequisite) + "\n1 cycle"
		var base := CashFormatter.format_exact_cents(offer.base_price_cents)
		price.text = "[s]%s[/s]  [color=#7ed6be]−%d%% familiarity[/color]\n[b]%s[/b]" % [base, offer.discount_percent, CashFormatter.format_exact_cents(offer.price_cents)] if offer.discount_percent > 0 else base
		store._buy.disabled = not offer.unlocked or not offer.affordable or store._run.needs_starter_selection()
		store._buy.text = "After first game" if store._run.needs_starter_selection() else "Requires prerequisite" if not offer.unlocked else "Insufficient cash" if not offer.affordable else "Purchase"
	price.visible = not price.text.is_empty()
	popup.show()
	popup.reset_size()
	position_details.call_deferred()

func position_details() -> void:
	if focusing or (_menu_tween != null and _menu_tween.is_running()): return
	if store._selected.is_empty() or not store.is_visible_in_tree(): return
	var node_rect: Rect2 = store._nodes[store._selected].get_global_rect()
	var limits := store.get_global_rect().grow(-8)
	var point := Vector2(node_rect.end.x + 12, node_rect.position.y)
	if point.x + popup.size.x > limits.end.x: point.x = node_rect.position.x - popup.size.x - 12
	point.x = clampf(point.x, limits.position.x, maxf(limits.position.x, limits.end.x - popup.size.x))
	point.y = clampf(point.y, limits.position.y, maxf(limits.position.y, limits.end.y - popup.size.y))
	popup.global_position = point

func _map_rect() -> Rect2:
	var rect := scroll.get_global_rect()
	if scroll.get_v_scroll_bar().visible: rect.size.x -= scroll.get_v_scroll_bar().size.x
	if scroll.get_h_scroll_bar().visible: rect.size.y -= scroll.get_h_scroll_bar().size.y
	return rect

func _node_at(point: Vector2) -> StringName:
	if not _map_rect().has_point(point): return &""
	for id: StringName in store._nodes:
		if store._nodes[id].get_global_rect().has_point(point): return id
	return &""

func _cancel_drag() -> void:
	dragging = false
	_drag_button = MOUSE_BUTTON_NONE
	_pressed_node = &""

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: _cancel_drag()

func _on_node_focused(id: StringName) -> void:
	store._select_node(id)

func _focus_node(id: StringName) -> void:
	store._nodes[id].grab_focus()
	# A dismissed popup can leave this node focused already.
	if store._selected != id: store._select_node(id)

func _stop_focus_animation() -> void:
	if _focus_tween != null and _focus_tween.is_valid(): _focus_tween.kill()
	if _menu_tween != null and _menu_tween.is_valid(): _menu_tween.kill()
	focusing = false
	if popup != null: popup.modulate.a = 1.0
	if store._buy != null:
		store._buy.mouse_filter = Control.MOUSE_FILTER_STOP
		store._buy.focus_mode = Control.FOCUS_ALL

func focus_selection(id: StringName) -> void:
	_stop_focus_animation()
	_view_revision += 1
	focusing = true
	popup.modulate.a = 0.0
	store._buy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store._buy.focus_mode = Control.FOCUS_NONE
	var view_size := _map_rect().size
	var old_zoom := zoom
	var old_center := (Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) + view_size / 2.0 - tree.position) / zoom
	var final_zoom := minf(1.25, (view_size.y - 24.0) / (LABEL_OFFSET.y + LABEL_SIZE.y))
	final_zoom = maxf(0.6, final_zoom)
	# Leave room on the right for the detail menu, including at outermost nodes.
	_focus_padding = view_size / 2.0
	var target: Vector2 = store._nodes[id].get_rect().get_center() + Vector2((popup.size.x + 20.0) / (2.0 * final_zoom), 15.0)
	_focus_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_method(func(weight: float): _camera_frame(lerpf(old_zoom, final_zoom, weight), old_center.lerp(target, weight)), 0.0, 1.0, 0.30)
	_focus_tween.tween_callback(_slide_menu.bind(id))

func _camera_frame(value: float, world_center: Vector2) -> void:
	zoom = value
	tree.scale = Vector2.ONE * zoom
	canvas.custom_minimum_size = bounds * zoom + _focus_padding * 2.0
	canvas.size = canvas.custom_minimum_size.max(_map_rect().size)
	_center_canvas()
	var offset := world_center * zoom + tree.position - _map_rect().size / 2.0
	scroll.scroll_horizontal = roundi(offset.x)
	scroll.scroll_vertical = roundi(offset.y)
	zoom_label.text = "%d%%" % roundi(zoom * 100)

func _slide_menu(id: StringName) -> void:
	if store._selected != id or not store.is_visible_in_tree(): return
	focusing = false
	position_details()
	var destination := popup.position
	# Unfold rightward from the selected node's right-hand border.
	popup.position.x = store._nodes[id].get_global_rect().end.x - global_position.x - 28.0
	popup.modulate.a = 0.0
	_menu_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_menu_tween.tween_property(popup, "position", destination, 0.20)
	_menu_tween.tween_property(popup, "modulate:a", 1.0, 0.20)
	_menu_tween.chain().tween_callback(func():
		store._buy.mouse_filter = Control.MOUSE_FILTER_STOP
		store._buy.focus_mode = Control.FOCUS_ALL)

func _reveal_node(id: StringName) -> void:
	_view_revision += 1
	var offset := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	var button: Button = store._nodes[id]
	# Work in scaled canvas coordinates. ScrollContainer can defer child layout
	# until the next frame, so global rectangles lag rapid key-repeat events.
	var footprint := node_footprint(button)
	var rect := Rect2(tree.position + footprint.position * zoom, footprint.size * zoom)
	var viewport_rect := Rect2(offset, _map_rect().size).grow(-12)
	if rect.position.x < viewport_rect.position.x: offset.x += rect.position.x - viewport_rect.position.x
	elif rect.end.x > viewport_rect.end.x: offset.x += rect.end.x - viewport_rect.end.x
	if rect.position.y < viewport_rect.position.y: offset.y += rect.position.y - viewport_rect.position.y
	elif rect.end.y > viewport_rect.end.y: offset.y += rect.end.y - viewport_rect.end.y
	scroll.scroll_horizontal = roundi(offset.x)
	scroll.scroll_vertical = roundi(offset.y)
	position_details.call_deferred()

func navigate_direction(direction: Vector2) -> void:
	var anchor := store._selected
	if anchor.is_empty():
		var focused := get_viewport().gui_get_focus_owner()
		for id: StringName in store._nodes:
			if store._nodes[id] == focused:
				anchor = id
				break
	var center := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) + _map_rect().size / 2.0
	if not anchor.is_empty(): center = tree.position + (store._nodes[anchor].position + store.NODE_SIZE / 2.0) * zoom
	var target: StringName = &""
	var best := INF
	for id: StringName in store._nodes:
		if id == anchor: continue
		var delta: Vector2 = tree.position + (store._nodes[id].position + store.NODE_SIZE / 2.0) * zoom - center
		var score := delta.length_squared()
		if not anchor.is_empty():
			var forward := delta.dot(direction)
			if forward <= 1.0: continue
			var sideways := absf(delta.cross(direction))
			# Prefer the requested row/column before distant diagonal branches.
			score = forward + sideways * 2.0 + (100000.0 if sideways > forward else 0.0)
		if score < best:
			best = score
			target = id
	if not target.is_empty(): _focus_node(target)

func _input_layer(node: Node) -> int:
	while node != null:
		if node is CanvasLayer: return node.layer
		node = node.get_parent()
	return 0

func _input(event: InputEvent) -> void:
	if store == null or not store.is_visible_in_tree(): return
	# Focused overlays (such as Tutorial) own input above the map.
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _input_layer(focused) > _input_layer(self):
		_cancel_drag()
		return
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == _drag_button:
			var clicked := _pressed_node if not dragging and _node_at(event.position) == _pressed_node else &""
			_cancel_drag()
			if not clicked.is_empty(): _focus_node(clicked)
			get_viewport().set_input_as_handled()
			return
		var over_menu := popup.visible and popup.modulate.a > 0.05 and popup.get_global_rect().has_point(event.position)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not over_menu: dismiss()
		if over_menu or not _map_rect().has_point(event.position): return
		if event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			_view_revision += 1
			_drag_button = event.button_index
			_drag_origin = event.position
			_drag_scroll = Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
			_pressed_node = _node_at(event.position) if event.button_index == MOUSE_BUTTON_LEFT else &""
			dragging = event.button_index == MOUSE_BUTTON_MIDDLE
			if dragging or _pressed_node.is_empty(): scroll.grab_focus()
			if dragging: dismiss()
			# Own the entire gesture so a drag starting on artwork cannot click it.
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_zoom(zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), event.position - scroll.global_position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _drag_button != MOUSE_BUTTON_NONE:
		var delta: Vector2 = event.position - _drag_origin
		if not dragging and delta.length() >= DRAG_THRESHOLD:
			dragging = true
			scroll.grab_focus()
			dismiss()
		if dragging:
			scroll.scroll_horizontal = roundi(_drag_scroll.x - delta.x)
			scroll.scroll_vertical = roundi(_drag_scroll.y - delta.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
		var directions := {KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT, KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN}
		if directions.has(event.keycode):
			_cancel_drag()
			navigate_direction(directions[event.keycode])
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_cancel_drag()
			dismiss()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_drag()
		dismiss()
