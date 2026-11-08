class_name FeatureStoreMap
extends Control

const GridLayout := preload("res://scripts/ui/feature_store_layout.gd")
var edge_routes: Dictionary = {}
var trails: Control

var store: FeatureStore
var scroll: ScrollContainer
var canvas: Control
var tree: Control
var popup: PanelContainer
var guidance_scroll: ScrollContainer
var parent_links: Control
var _parent_tween: Tween
var _parents_expanded := false
var _parent_focus_requested := false
var _parent_revision := 0
const PARENT_GAP := 12.0
const PARENT_BUTTON_GAP := 8.0
var description_scroll: ScrollContainer
var _back: Button
var _description_resize_queued := false
var shopping_details: Label
var price: RichTextLabel
var _missing_targets: Array[StringName] = []
var _dependency_kind: StringName = &"missing"
var _activation_quote: Dictionary = {}
var zoom_label: Label
var zoom := 1.0
var bounds := Vector2.ZERO
var origins: Dictionary = {}
var center := Vector2.ZERO
var center_square:=Rect2()
var category_regions: Dictionary = {}
var category_headers: Dictionary = {}
var category_paths: Array[PackedVector2Array] = []
var category_cones: Dictionary = {}
const CATEGORY_DIRECTIONS := {
	&"Visuals": Vector2.LEFT, &"Audio": Vector2.RIGHT,
	&"Technology & Tools": Vector2.UP,
	&"Gameplay": Vector2.LEFT, &"Story & World": Vector2.RIGHT,
}
const COLUMN_STEP := 212.0
const ROW_STEP := 212.0
const LABEL_OFFSET := Vector2(-8, 136)
const LABEL_SIZE := Vector2(144, 36)
var dragging := false
const DRAG_THRESHOLD := 6.0
var _drag_button := MOUSE_BUTTON_NONE
var _drag_origin := Vector2.ZERO
var _drag_scroll := Vector2.ZERO
var _pressed_node: StringName = &""
var _view_revision := 0
var _scroll_request := 0
var _focus_padding := Vector2.ZERO
var _focus_tween: Tween
var _menu_tween: Tween
var focusing := false

func configure(owner_store: FeatureStore, layout: VBoxContainer, map_host: Control) -> void:
	store = owner_store
	var toolbar := HBoxContainer.new()
	toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(toolbar)
	for caption in ["−", "+", "Show all"]:
		var button := Button.new()
		button.text = caption
		toolbar.add_child(button)
		if caption == "Show all": button.pressed.connect(fit_map)
		elif caption == "+": button.pressed.connect(func(): set_zoom(zoom * 1.25))
		else: button.pressed.connect(func(): set_zoom(zoom / 1.25))
	store._debug.reparent(toolbar)
	zoom_label = Label.new()
	FeatureStore.outlined_text(zoom_label)
	toolbar.add_child(zoom_label)
	var help := Label.new()
	help.text = "Drag: pan · Wheel: zoom · Arrow keys: browse · Click: inspect"
	help.add_theme_font_size_override("font_size", 12)
	toolbar.add_child(help)
	var legend := HBoxContainer.new()
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_theme_constant_override("separation", 16)
	layout.add_child(legend)
	var legend_title := Label.new()
	legend_title.text = "Border: primary score"
	legend_title.theme_type_variation = &"ScoreHeading"
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
	# The map occupies the whole body; the transparent toolbar is a sibling above it.
	map_host.add_child(scroll)
	map_host.move_child(scroll, 0)
	scroll.resized.connect(_queue_description_fit)
	layout.resized.connect(_queue_description_fit)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(canvas)
	canvas.resized.connect(_center_canvas)
	tree = Control.new()
	canvas.add_child(tree)
	trails = preload("res://scripts/ui/feature_store_trails.gd").new()
	tree.add_child(trails)
	trails.map_view = scroll
	# Parent visibility signals can precede propagation to descendants.
	store.visibility_changed.connect(func(): trails.sync_processing.call_deferred())
	trails.visibility_changed.connect(func(): trails.sync_processing.call_deferred())
	store._scroll = scroll
	store._tree = tree
	tree.draw.connect(store._draw_connections)
	# This layer is a child of a plain Control, not a Container layout item.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup = PanelContainer.new()
	popup.add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	popup.custom_minimum_size.x = 260
	add_child(popup)
	popup.resized.connect(position_details)
	var style := StyleBoxFlat.new()
	style.bg_color = FolderUI.color(&"secondary")
	style.border_color = FolderUI.color(&"border")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	popup.add_theme_stylebox_override("panel", style)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 10)
	popup.add_child(details)
	description_scroll=ScrollContainer.new()
	description_scroll.name="FeatureDescription"
	description_scroll.focus_mode=Control.FOCUS_ALL
	description_scroll.gui_input.connect(_description_input)
	description_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	description_scroll.custom_minimum_size.x=310
	description_scroll.resized.connect(_queue_description_fit)
	details.add_child(description_scroll)
	store._details = Label.new()
	store._details.custom_minimum_size.x = 228
	store._details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	store._details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	description_scroll.add_child(store._details)
	store._details.minimum_size_changed.connect(_queue_description_fit)
	price = RichTextLabel.new()
	price.custom_minimum_size.x = 228
	price.size.x = 228
	price.bbcode_enabled = true
	price.fit_content = true
	price.scroll_active = false
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(price)
	guidance_scroll = ScrollContainer.new()
	guidance_scroll.name = "DependencyList"
	guidance_scroll.custom_minimum_size = Vector2(310,140)
	guidance_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guidance_scroll.follow_focus = true
	var guidance_content := VBoxContainer.new()
	guidance_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guidance_scroll.add_child(guidance_content)
	# A sibling overlay unfolds to the right, without growing the detail panel.
	parent_links = Control.new()
	parent_links.name = "PrerequisiteLinks"
	parent_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(parent_links)
	parent_links.hide()
	details.add_child(guidance_scroll)
	shopping_details = Label.new()
	shopping_details.name = "ShoppingDetails"
	shopping_details.custom_minimum_size.x = 290
	shopping_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shopping_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shopping_details.add_theme_font_size_override("font_size",13)
	guidance_content.add_child(shopping_details)
	var back := Button.new()
	_back=back
	back.name = "BackToMapButton"
	back.text = "Back to Map"
	back.tooltip_text = "Close these Feature details without purchasing."
	back.pressed.connect(func():
		dismiss()
		scroll.grab_focus())
	details.add_child(back)
	store._buy = Button.new()
	store._buy.custom_minimum_size = Vector2(310,40)
	store._buy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	store._buy.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	store._buy.pressed.connect(_activate_action)
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
	title.theme_type_variation=&"HeadingLabel"
	title.add_theme_font_size_override("font_size", 14)
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
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_size_override("font_size", 10)
	var status_background := StyleBoxFlat.new()
	status_background.bg_color = Color(0.07, 0.08, 0.1, 0.9)
	status.add_theme_stylebox_override("normal", status_background)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(status)

func decorate_and_gate(button: Button, parents: Array) -> void:
	var badge := Label.new()
	badge.name = "AndGate"
	badge.text = "AND: %d parents" % parents.size()
	badge.position = Vector2(6, 96)
	badge.size = Vector2(116, 25)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", FolderUI.color(&"text"))
	var background := StyleBoxFlat.new()
	background.bg_color = FolderUI.color(&"secondary")
	badge.add_theme_stylebox_override("normal", background)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)

func _parent_details(offer: Dictionary) -> String:
	for child in parent_links.get_children():
		parent_links.remove_child(child)
		child.queue_free()
	var rows: Array[String] = []
	for contribution: Dictionary in offer.get("parent_contributions", []):
		rows.append("%s: %s; %d project credit(s)" % [contribution.name, "owned" if contribution.owned else "MISSING", contribution.credits])
	if not rows.is_empty():
		rows.append("Familiarity: %d%% (10%% per parent-project credit; 80%% cap on the whole new implementation price). Paid deposits are never refunded; old paid queues keep their original terms." % offer.discount_percent)
	return "\n".join(rows)

func layout_map(_children: Dictionary) -> void:
	var layout := GridLayout.cells(store._nodes.keys())
	assert(not layout.has("error"),str(layout.get("error","")))
	if layout.has("error"): return
	for id: StringName in store._nodes:
		store._nodes[id].position=Vector2(layout.cells[id])*GridLayout.PITCH
	var graph := FeatureStoreCatalog.graph(store._run._feature_definitions,store._run._feature_offers)
	for lane: StringName in store.LANE_ORDER:
		var direction: Vector2 = CATEGORY_DIRECTIONS[lane]
		var across := _across(lane)
		var root_area := Rect2()
		var root_count := 0
		for id: StringName in store.LANE_MEMBERS[lane]:
			if not graph.parents[id].is_empty(): continue
			var footprint := node_footprint(store._nodes[id])
			root_area=footprint if root_count==0 else root_area.merge(footprint)
			root_count+=1
		var area := node_footprint(store._nodes[store.LANE_MEMBERS[lane][0]])
		for id: StringName in store.LANE_MEMBERS[lane]:
			area = area.merge(node_footprint(store._nodes[id]))
		# The cone reserves room for later children without inventing prerequisites.
		# Side cones open away from the crown; their inner edge contains roots only.
		var cone_points := PackedVector2Array()
		for rect: Rect2 in [area.grow(32.0), root_area.grow(32.0)]:
			if direction == Vector2.UP:
				if rect == root_area.grow(32.0):
					cone_points.append(Vector2(rect.position.x, rect.end.y))
					cone_points.append(rect.end)
				else:
					cone_points.append(rect.position - Vector2(COLUMN_STEP, 0))
					cone_points.append(Vector2(rect.end.x + COLUMN_STEP, rect.position.y))
			else:
				var inner_edge := rect.end.x if direction == Vector2.LEFT else rect.position.x
				var outer := rect.position.x if direction == Vector2.LEFT else rect.end.x
				if rect == root_area.grow(32.0):
					cone_points.append(Vector2(inner_edge, rect.position.y))
					cone_points.append(Vector2(inner_edge, rect.end.y))
				else:
					cone_points.append(Vector2(outer, rect.position.y - (ROW_STEP if across.y < 0 else 0.0)))
					cone_points.append(Vector2(outer, rect.end.y + (ROW_STEP if across.y > 0 else 0.0)))
		# Include every actual node footprint, even if a family gains another fork.
		for id: StringName in store.LANE_MEMBERS[lane]:
			var rect := node_footprint(store._nodes[id]).grow(24.0)
			cone_points.append_array(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
		category_cones[lane] = Geometry2D.convex_hull(cone_points)
		area = Rect2(cone_points[0], Vector2.ZERO)
		for point: Vector2 in cone_points: area = area.expand(point)
		if lane == &"Technology & Tools":
			area.position.y -= 64.0
			area.size.y += 64.0
		else:
			if direction == Vector2.RIGHT: area.position.x -= 80.0
			area.size.x += 80.0
		category_regions[lane] = area
		var heading := Label.new()
		heading.name = "Category" + str(store.LANE_ORDER.find(lane))
		heading.text = str(lane)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heading.theme_type_variation=&"HeadingLabel"
		heading.add_theme_font_size_override("font_size", 36)
		if lane == &"Technology & Tools":
			heading.size = Vector2(640,56)
		elif lane in [&"Gameplay", &"Story & World"]:
			heading.size = Vector2(320,56)
		else:
			heading.size = Vector2(224,56)
			heading.rotation = -PI/2.0 if direction == Vector2.LEFT else PI/2.0
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.add_child(heading)
		category_headers[lane] = heading
		origins[lane] = area.get_center()
	# The center holds category labels, never a purchasable root or Feature.
	center_square=GridLayout.center_square()
	center=center_square.get_center()
	var anchor_ids:={&"Visuals":&"4_color_palette",&"Audio":&"8_bit_sound",&"Technology & Tools":&"keyboard_and_mouse",&"Gameplay":&"lives_system",&"Story & World":&"simple_story"}
	var anchors:={}
	var inner:=center_square.grow(-16.0)
	for lane: StringName in store.LANE_ORDER:
		var root_rect:=node_footprint(store._nodes[anchor_ids[lane]])
		anchors[lane]=root_rect
		var heading: Label=category_headers[lane]
		var rect:=header_rect(heading)
		var half:=rect.size/2.0
		var wanted:=root_rect.get_center()
		if lane==&"Technology & Tools":wanted=Vector2(center.x,inner.position.y+half.y)
		elif lane==&"Visuals":wanted.x=inner.position.x+half.x
		elif lane==&"Audio":wanted.x=inner.end.x-half.x
		else:wanted.y=inner.end.y-half.y
		wanted=Vector2(clampf(wanted.x,inner.position.x+half.x,inner.end.x-half.x),clampf(wanted.y,inner.position.y+half.y,inner.end.y-half.y))
		heading.position+=wanted-rect.get_center()
	category_paths.clear()
	for lane: StringName in store.LANE_ORDER:
		var root_rect: Rect2=anchors[lane]
		var port: Vector2
		var anchor: Vector2
		if lane==&"Technology & Tools":
			port=Vector2(center.x,center_square.position.y)
			anchor=Vector2(center.x,root_rect.end.y+8.0)
		elif lane in [&"Visuals",&"Audio"]:
			var left: bool=lane==&"Visuals"
			port=Vector2(center_square.position.x if left else center_square.end.x,root_rect.get_center().y)
			anchor=Vector2(root_rect.end.x+8.0 if left else root_rect.position.x-8.0,port.y)
		else:
			# The lower roots sit just outside the square, above its bottom edge.
			# Leave from the lower perimeter and route around it to each root.
			port=Vector2(clampf(root_rect.get_center().x,center_square.position.x+64.0,center_square.end.x-64.0),center_square.end.y)
			anchor=Vector2(root_rect.get_center().x,root_rect.end.y+8.0)
			var corridor_y:=center_square.end.y+GridLayout.PITCH/2.0
			category_paths.append(PackedVector2Array([port,Vector2(port.x,corridor_y),Vector2(anchor.x,corridor_y),anchor]))
			continue
		category_paths.append(PackedVector2Array([port,anchor]))
	var extent: Rect2 = category_regions[&"Technology & Tools"]
	for area: Rect2 in category_regions.values(): extent = extent.merge(area)
	extent = extent.merge(center_square).grow(32.0)
	var half_width := maxf(absf(extent.position.x), absf(extent.end.x))
	extent.position.x = -half_width
	extent.size.x = half_width * 2.0
	var offset := -extent.position
	for lane: StringName in store.LANE_ORDER: _move_category(lane, offset)
	center += offset
	center_square.position+=offset
	for i in range(category_paths.size()):
		for j in range(category_paths[i].size()): category_paths[i][j] += offset
	var footprints := {}
	for id: StringName in store._nodes: footprints[id]=node_footprint(store._nodes[id])
	var headers: Array[Rect2]=[]
	for header: Label in category_headers.values(): headers.append(header_rect(header))
	var routed := GridLayout.routes(layout.cells,footprints,store._edges,offset,headers,center_square)
	assert(not routed.has("error"),str(routed.get("error","")))
	if routed.has("error"): return
	edge_routes=routed.routes
	bounds = extent.size
	store._lane_heading.hide()
	tree.size = bounds
	trails.size = bounds
	# Wait for Containers to lay out before measuring the first overview.
	_initial_overview()

func _initial_overview() -> void:
	var revision := _view_revision
	await get_tree().process_frame
	await get_tree().process_frame
	if revision == _view_revision:
		# Frame the organizing square plus the nearest actual root in each tree.
		var frame: Rect2=center_square
		var graph:=FeatureStoreCatalog.graph(store._run._feature_definitions,store._run._feature_offers)
		for lane: StringName in store.LANE_ORDER:
			var closest:=Rect2();var distance:=INF
			for id: StringName in store.LANE_MEMBERS[lane]:
				if not graph.parents[id].is_empty():continue
				var footprint:=node_footprint(store._nodes[id])
				var next: float=footprint.get_center().distance_squared_to(center)
				if next<distance:closest=footprint;distance=next
			if closest.has_area():frame=frame.merge(closest)
		frame=frame.grow(40.0)
		var available:=(_map_rect().size-Vector2(56,210)).max(Vector2(100,100))
		set_zoom(minf(0.74,minf(available.x/frame.size.x,available.y/frame.size.y)))
		center_after_layout(frame.get_center()-Vector2(0,45.0/zoom), _view_revision)

func _center_canvas() -> void:
	if tree != null:
		var inset := Vector2(0, _toolbar_height())
		tree.position = inset + _focus_padding + (canvas.size - inset - bounds * zoom - _focus_padding * 2.0).max(Vector2.ZERO) / 2.0

func _toolbar_height() -> float:
	return 0.0 # Floating controls do not reserve graph space.

func _camera_center() -> Vector2:
	return (_map_rect().size + Vector2(0, _toolbar_height())) / 2.0

func _over_toolbar_control(point: Vector2) -> bool:
	return store._over_floating_control(point)


func _move_category(lane: StringName, offset: Vector2) -> void:
	for id: StringName in store.LANE_MEMBERS[lane]: store._nodes[id].position += offset
	category_headers[lane].position += offset
	category_regions[lane].position += offset
	origins[lane] += offset
	for i in range(category_cones[lane].size()): category_cones[lane][i] += offset

func _across(lane: StringName) -> Vector2:
	if lane == &"Technology & Tools": return Vector2.RIGHT * COLUMN_STEP
	return Vector2.UP * ROW_STEP if lane in [&"Visuals", &"Audio"] else Vector2.DOWN * ROW_STEP

func draw_core() -> void:
	# Keep all four edges visible even when the overview scales below one pixel.
	var corners:=PackedVector2Array([center_square.position,Vector2(center_square.end.x,center_square.position.y),center_square.end,Vector2(center_square.position.x,center_square.end.y),center_square.position])
	tree.draw_polyline(corners,Color("667688"),maxf(4.0,1.5/zoom),true)
	# The layout regions reserve space only. Nodes and connecting lines are the
	# visual tree; no enclosing cone fill or category border obscures them.
	for path: PackedVector2Array in category_paths:
		tree.draw_polyline(path, Color("667688"), 4.0, true)

func header_rect(header: Label) -> Rect2:
	return Transform2D(header.rotation, header.position) * Rect2(Vector2.ZERO, header.size)

func _category_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2029")
	style.border_color = Color("394453")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func node_footprint(node: Control) -> Rect2:
	return Rect2(node.position + Vector2(LABEL_OFFSET.x, 0), Vector2(LABEL_SIZE.x, LABEL_OFFSET.y + LABEL_SIZE.y))

func edge_port(rect: Rect2, direction: Vector2) -> Vector2:
	var half := rect.size / 2.0
	var reach := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	return rect.get_center() + direction * (reach + 8.0)

func navigate(lane: StringName) -> void:
	set_zoom(1.0)
	center_after_layout(origins[lane], _view_revision)

func center_after_layout(world_center: Vector2, revision: int) -> void:
	# Camera jumps must use settled canvas/scrollbar ranges, as card focus does.
	# Invalidate the wheel anchor request before centering this explicit target.
	_scroll_request += 1
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _view_revision: return
	_camera_frame(zoom, world_center)
	await get_tree().process_frame
	if revision == _view_revision: _camera_frame(zoom, world_center)

func set_zoom(value: float, anchor: Vector2 = Vector2(-1, -1)) -> void:
	_cancel_drag()
	dismiss()
	_view_revision += 1
	if anchor.x < 0: anchor = _camera_center()
	var previous := zoom
	var previous_origin := tree.position
	zoom = clampf(value, 0.025, 2.0)
	var offset := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	tree.scale = Vector2.ONE * zoom
	tree.queue_redraw()
	canvas.custom_minimum_size = bounds * zoom + _focus_padding * 2.0 + Vector2(0, _toolbar_height())
	canvas.size = canvas.custom_minimum_size.max(_map_rect().size)
	_center_canvas()
	zoom_label.text = "%d%%" % roundi(zoom * 100)
	var next := (offset + anchor - previous_origin) * zoom / previous + tree.position - anchor
	_scroll_after_layout(next, _view_revision)

func _scroll_after_layout(offset: Vector2, revision: int) -> void:
	_scroll_request += 1
	var request := _scroll_request
	# Scrollbar ranges follow the resized canvas on the next container pass.
	# A newer navigation request supersedes the zoom anchor request.
	await get_tree().process_frame
	await get_tree().process_frame
	if revision != _view_revision or request != _scroll_request: return
	scroll.scroll_horizontal = roundi(offset.x)
	scroll.scroll_vertical = roundi(offset.y)

func fit_map() -> void:
	_focus_padding = Vector2.ZERO
	set_zoom(minf((scroll.size.x - 20) / bounds.x, (scroll.size.y - _toolbar_height() - 20) / bounds.y))
	_scroll_after_layout(Vector2.ZERO, _view_revision)

func dismiss() -> void:
	_close_parent_links()
	_close_dependency_list()
	_stop_focus_animation()
	if not store._selected.is_empty() and store._nodes.has(store._selected) and is_instance_valid(store._nodes[store._selected]):
		var button: Button = store._nodes[store._selected]
		for key in ["normal", "hover", "pressed"]:
			var style := button.get_theme_stylebox(key) as StyleBoxFlat
			if style != null:
				style.set_border_width_all(3)
	store._selected = &""
	popup.hide()
	store._refresh_spending_advice()

func show_details() -> void:
	_close_parent_links()
	_close_dependency_list()
	store._buy.disabled = true
	price.text = ""
	_missing_targets.clear()
	_dependency_kind = &"missing"
	_activation_quote = {}
	var blockers: Array[String] = []
	if store._selected.is_empty():
		popup.hide()
		return
	description_scroll.scroll_vertical=0
	var card: CardData = get_node("/root/CardDatabase").get_card(store._selected)
	var score_parts: Array[String] = []
	for entry in card.core_contributions(): score_parts.append("%d %s" % [entry.value, FeatureStore.score_label(entry.stat)])
	var stats := " · ".join(score_parts)
	store._details.text = card.card_name + "\n" + stats + " · %d Scope" % card.scope
	var single: Array[CardData] = [card]
	var catalog_entry: Dictionary = store._run._feature_offers.get(card.id,{})
	var play_cost := CashFormatter.format_exact_cents(int(catalog_entry.play_cost_cents)) if catalog_entry.has("play_cost_cents") else "TBD" if not catalog_entry.is_empty() else CashFormatter.format_exact_cents(store._run.primitive_feature_hand_cost_cents(single))
	store._details.text += "\nPlay cost: " + play_cost
	if catalog_entry.has("replaces_id"):
		store._details.text += "\nReplaces 8-Bit Sound in future project draws."
	var offer := store._run.get_feature_store_offer(store._selected,store._engine_id)
	var parent_text := _parent_details(offer)
	var reserve := store._run.get_primitive_reserve_offer(store._selected,store._engine_id)
	if not reserve.is_empty():
		_missing_targets.assign(reserve.missing_parents)
	else:
		for parent: Dictionary in offer.get("parent_contributions",[]):
			if not parent.owned: _missing_targets.append(parent.id)
	var engine_row: Dictionary=store._run.get_engine_feature_state().engines[store._engine_id]
	if engine_row.kind!=&"proprietary":
		_missing_targets.clear();store._buy.disabled=true
		store._buy.text="In fixed library" if store._run.owns_feature(store._selected,store._engine_id) else "Not in this fixed library"
	elif store._run.owns_feature(store._selected,store._engine_id):
		_missing_targets.clear()
		_activation_quote=store._run.get_engine_feature_activation_quote(store._selected,store._engine_id)
		var active_children: Array = _activation_quote.get("active_children",[])
		var inactive_parents: Array = _activation_quote.get("inactive_parents",[])
		if _activation_quote.get("enabled",false):
			if not active_children.is_empty():
				_missing_targets.assign(active_children)
				_dependency_kind=&"children"
			else:
				store._buy.text="Disable"
				store._buy.disabled=not _activation_quote.get("can_toggle",false)
		else:
			if not inactive_parents.is_empty():
				var names := _dependency_names(inactive_parents)
				store._details.text += "\nEnable required parent Features: " + ", ".join(names)
			if _activation_quote.get("scope_blocked",false):
				store._buy.text="Reached scope limit"
				store._buy.disabled=true
				store._details.text += "\nEnabling needs %d / %d Scope." % [int(_activation_quote.get("projected_scope",0)),int(_activation_quote.get("scope_capacity",0))]
			elif not inactive_parents.is_empty():
				_missing_targets.assign(inactive_parents)
				_dependency_kind=&"parents"
			else:
				store._buy.text="Enable"
				store._buy.disabled=not _activation_quote.get("can_toggle",false)
	elif offer.is_empty() and reserve.get("initial",false):
		store._buy.disabled = not reserve.can_purchase
		if not reserve.unlocked: blockers.append("Locked — " + str(reserve.prerequisite))
		if not reserve.affordable: blockers.append("Insufficient cash")
		store._buy.text = ("Purchase" if reserve.can_purchase else "Locked" if not reserve.unlocked else "Insufficient cash") + " · " + CashFormatter.format_exact_cents(reserve.price_cents)
	else:
		var quote := store._run.get_feature_research_quote(store._selected,store._engine_id)
		if quote.queued: _missing_targets.clear()
		store._buy.disabled = not (quote.can_research if quote.queued else quote.can_admit)
		blockers = store.queue_block_reasons(quote)
		store._buy.text = "Implement" if quote.head else "Queued" if quote.queued else "Implement" if quote.can_admit else store.queue_status(quote)
		store._buy.text += " · " + CashFormatter.format_exact_cents(quote.due_cents if quote.queued else quote.down_cents)
		store._buy.text += " - 1 cycle" if quote.queued else " down"
	if not _missing_targets.is_empty():
		var names := _dependency_names(_missing_targets)
		if _dependency_kind==&"children":store._buy.text="(%d) active child nodes" % _missing_targets.size()
		elif _dependency_kind==&"parents":store._buy.text="Enable parents: " + ", ".join(names)
		else:store._buy.text = "Missing: " + ", ".join(names)
		store._buy.disabled = false
	if not store._run.owns_feature(store._selected,store._engine_id):
		for reason in blockers:
			if offer.has("min_year") and ("Available in" in reason or "qualifying" in reason): store._details.text += "\n" + reason
	store._buy.tooltip_text = parent_text + ("\n" if not parent_text.is_empty() else "") + "\n".join(blockers)
	shopping_details.text = ""
	shopping_details.hide()
	price.hide()
	guidance_scroll.hide()
	# Long AND names and multi-Core rows must fit above the bottom HUD.
	# Use available width before wrapping them into an over-tall detail panel.
	popup.custom_minimum_size.x=342.0 if _missing_targets.size()==3 else clampf(_map_rect().size.x*0.5,342.0,480.0)
	_queue_description_fit()
	popup.show()
	popup.reset_size()
	position_details.call_deferred()

func _activate_action() -> void:
	if _missing_targets.is_empty():
		if not _activation_quote.is_empty():
			store._run.set_engine_feature_active(_activation_quote)
			store._refresh()
			return
		store._purchase()
		return
	if _dependency_kind==&"children" and int(_activation_quote.get("linked_children_count",0))>2:
		_show_dependency_list()
		return
	if _missing_targets.size() == 1:
		if store._nodes.has(_missing_targets[0]): _focus_node(_missing_targets[0])
		else: _show_dependency_list()
		return
	if _missing_targets.size() > 2:
		_show_dependency_list()
		return
	if _parents_expanded:
		_close_parent_links()
		return
	_parents_expanded = true
	_parent_focus_requested = store._buy.has_focus()
	_parent_revision += 1
	for id: StringName in _missing_targets:
		var link := Button.new()
		link.text = _dependency_name(id)
		link.disabled = not store._nodes.has(id)
		if link.disabled: link.tooltip_text = "This Feature is not displayed on the current map."
		link.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		link.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		link.mouse_filter = Control.MOUSE_FILTER_IGNORE
		link.focus_mode = Control.FOCUS_NONE
		link.modulate.a = 0.0
		link.pressed.connect(_focus_node.bind(id))
		parent_links.add_child(link)
	_layout_parent_links()
	# Reuse the existing camera framing so the selected card, panel, links and
	# entrance overshoot all have room, including at the outer map edges.
	focus_selection(store._selected)

func _dependency_name(id: StringName) -> String:
	return str(store._run._feature_definitions.get(id,{}).get("name",id))

func _dependency_names(ids: Array) -> Array[String]:
	var names: Array[String] = []
	for id: StringName in ids:names.append(_dependency_name(id))
	return names

func _close_dependency_list() -> void:
	if not is_instance_valid(guidance_scroll):return
	var content := guidance_scroll.get_child(0)
	for child: Node in content.get_children():
		if child!=shopping_details:
			content.remove_child(child)
			child.queue_free()
	guidance_scroll.hide()

func _show_dependency_list() -> void:
	if guidance_scroll.visible:
		_close_dependency_list()
		_queue_description_fit()
		return
	var content := guidance_scroll.get_child(0)
	shopping_details.text = "Active child nodes" if _dependency_kind==&"children" else "Required parent Features"
	shopping_details.show()
	for id: StringName in _missing_targets:
		var button := Button.new()
		button.text = _dependency_name(id)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = not store._nodes.has(id)
		if button.disabled:button.tooltip_text = "This Feature is not displayed on the current map."
		button.pressed.connect(_focus_node.bind(id))
		content.add_child(button)
	guidance_scroll.show()
	_queue_description_fit()
	popup.reset_size()
	position_details.call_deferred()

func _close_parent_links() -> void:
	_parent_revision += 1
	_parents_expanded = false
	_parent_focus_requested = false
	if _parent_tween != null and _parent_tween.is_valid(): _parent_tween.kill()
	if parent_links == null: return
	parent_links.hide()
	for child in parent_links.get_children():
		parent_links.remove_child(child)
		child.queue_free()
	if store._buy != null: store._buy.focus_neighbor_right = NodePath()

func _layout_parent_links() -> void:
	var count := parent_links.get_child_count()
	if count == 0: return
	var card_width: float = FeatureStore.NODE_SIZE.x if count==3 else store._nodes[store._selected].get_global_rect().size.x
	var room := _map_rect().size.x - popup.size.x - card_width - PARENT_GAP * 3.0 - MenuTransitions.ENTRANCE_DISTANCE
	var width := floorf(clampf((room - PARENT_BUTTON_GAP * (count - 1)) / count, 96.0, 160.0))
	var height := maxf(40.0, store._buy.size.y)
	for button: Button in parent_links.get_children():
		button.size.x = width
		height = maxf(height, button.get_combined_minimum_size().y)
	for index in count:
		var button: Button = parent_links.get_child(index)
		button.position = Vector2(index * (width + PARENT_BUTTON_GAP), 0)
		button.size = Vector2(width, height)
		var previous: Control = store._buy if index == 0 else parent_links.get_child(index - 1)
		button.focus_neighbor_left = button.get_path_to(previous)
		previous.focus_neighbor_right = previous.get_path_to(button)
	parent_links.size = Vector2(count * width + (count - 1) * PARENT_BUTTON_GAP, height)

func _parent_width() -> float:
	return parent_links.size.x + PARENT_GAP + MenuTransitions.ENTRANCE_DISTANCE if _parents_expanded else 0.0

func _position_parent_links() -> void:
	if not _parents_expanded: return
	parent_links.global_position = Vector2(popup.get_global_rect().end.x + PARENT_GAP, store._buy.global_position.y)

func _reveal_parent_links() -> void:
	if not _parents_expanded or not popup.visible: return
	_layout_parent_links()
	position_details()
	_position_parent_links()
	parent_links.show()
	var revision := _parent_revision
	_parent_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for index in parent_links.get_child_count():
		var button: Button = parent_links.get_child(index)
		var destination := button.position.x
		button.position.x += MenuTransitions.ENTRANCE_DISTANCE
		_parent_tween.tween_property(button, "position:x", destination, MenuTransitions.ENTRANCE_SECONDS).set_delay(index * 0.05)
		_parent_tween.tween_property(button, "modulate:a", 1.0, MenuTransitions.ENTRANCE_SECONDS).set_delay(index * 0.05)
	_parent_tween.chain().tween_callback(func():
		if revision != _parent_revision or not _parents_expanded: return
		for button: Button in parent_links.get_children():
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.focus_mode = Control.FOCUS_ALL
		# Camera framing temporarily disables the action. Restore its keyboard
		# focus only if the user has not moved focus elsewhere during entrance.
		if _parent_focus_requested and get_viewport().gui_get_focus_owner() == null:
			store._buy.grab_focus()
		_parent_focus_requested = false)

func _description_input(event: InputEvent) -> void:
	var amount:=0
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_DOWN: amount=40
			KEY_UP: amount=-40
			KEY_PAGEDOWN: amount=roundi(description_scroll.size.y)
			KEY_PAGEUP: amount=-roundi(description_scroll.size.y)
			KEY_HOME: description_scroll.scroll_vertical=0
			KEY_END: description_scroll.scroll_vertical=roundi(description_scroll.get_v_scroll_bar().max_value)
			_: return
	elif event.is_action_pressed("ui_down"): amount=40
	elif event.is_action_pressed("ui_up"): amount=-40
	else: return
	description_scroll.scroll_vertical+=amount
	description_scroll.accept_event()

func _queue_description_fit() -> void:
	if _description_resize_queued: return
	_description_resize_queued=true
	_fit_description.call_deferred()

func _fit_description() -> void:
	_description_resize_queued=false
	if not is_inside_tree() or _back==null: return
	var usable:=_map_rect().size.y-_toolbar_height()
	var overhead:=32.0+20.0+_back.get_combined_minimum_size().y+store._buy.get_combined_minimum_size().y+16.0
	if guidance_scroll.visible:overhead+=guidance_scroll.custom_minimum_size.y+10.0
	var height:=minf(store._details.get_combined_minimum_size().y,maxf(24.0,usable-overhead))
	if not is_equal_approx(description_scroll.custom_minimum_size.y,height):
		description_scroll.custom_minimum_size.y=height
		popup.reset_size()
	position_details.call_deferred()

func position_details() -> void:
	if focusing or (_menu_tween != null and _menu_tween.is_running()): return
	if store._selected.is_empty() or not store.is_visible_in_tree(): return
	# Text can shrink after wrapping settles; do not retain a preceding card's
	# larger minimum height when placing a newly focused detail panel.
	var needed:=popup.get_combined_minimum_size()
	if not popup.size.is_equal_approx(needed): popup.size=needed
	var node_rect: Rect2 = store._nodes[store._selected].get_global_rect()
	var limits := _map_rect().grow(-8)
	limits.position.y += _toolbar_height()
	limits.size.y -= _toolbar_height()
	var point := Vector2(node_rect.end.x + 12, node_rect.position.y)
	var width := popup.size.x + _parent_width()
	if point.x + width > limits.end.x and not _parents_expanded: point.x = node_rect.position.x - popup.size.x - 12
	point.x = clampf(point.x, limits.position.x, maxf(limits.position.x, limits.end.x - width))
	var height := popup.size.y
	if _parents_expanded: height = maxf(height, store._buy.global_position.y - popup.global_position.y + parent_links.size.y)
	point.y = clampf(point.y, limits.position.y, maxf(limits.position.y, limits.end.y - height))
	if guidance_scroll.visible and is_instance_valid(store._toolbar):
		var toolbar_rect: Rect2=store._toolbar.get_global_rect()
		if Rect2(point,Vector2(width,height)).intersects(toolbar_rect):
			var above := toolbar_rect.position.y-height-8.0
			if above>=limits.position.y:point.y=above
	popup.global_position = point
	_position_parent_links()

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
	if not store._nodes.has(id): return
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

## Three-parent menus reserve width for the selected card as well as all links.
## Link width uses the fixed card size so refitting zoom cannot widen them again.
func _focus_zoom_for_view(view_size: Vector2) -> float:
	var value := maxf(0.6,minf(1.25,(view_size.y-24.0)/(LABEL_OFFSET.y+LABEL_SIZE.y)))
	if _parents_expanded and _missing_targets.size()==3:
		var width := node_footprint(store._nodes[store._selected]).size.x
		value=minf(value,maxf(0.25,(view_size.x-popup.size.x-_parent_width()-36.0)/width))
	return value

func focus_selection(id: StringName) -> void:
	_stop_focus_animation()
	_view_revision += 1
	focusing = true
	popup.modulate.a = 0.0
	store._buy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	store._buy.focus_mode = Control.FOCUS_NONE
	var view_size := _map_rect().size
	view_size.y -= _toolbar_height()
	var old_zoom := zoom
	var old_center := (Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) + _camera_center() - tree.position) / zoom
	var final_zoom := _focus_zoom_for_view(view_size)
	# Leave room on the right for the detail menu, including at outermost nodes.
	_focus_padding = view_size / 2.0
	var target: Vector2 = node_footprint(store._nodes[id]).get_center() + Vector2((popup.size.x + _parent_width() + 20.0) / (2.0 * final_zoom), 0.0)
	_focus_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_method(func(weight: float): _camera_frame(lerpf(old_zoom, final_zoom, weight), old_center.lerp(target, weight)), 0.0, 1.0, 0.30)
	_focus_tween.tween_callback(_finish_focus.bind(id, final_zoom, target, _view_revision, 2, view_size))

func _finish_focus(id: StringName, final_zoom: float, target: Vector2, revision: int, frames_left: int = 2, expected_view: Vector2 = Vector2(-1,-1)) -> void:
	# Container scroll ranges lag a zoom frame. Reapply the final camera only
	# after those ranges settle; otherwise a large overview-to-card jump clamps
	# against the old bounds and leaves the inspected card offscreen.
	# Bound one-shot callbacks disconnect when the map is freed. A coroutine
	# started by Tween can otherwise resume after its script instance is gone.
	if not is_inside_tree(): return
	if frames_left > 0:
		get_tree().process_frame.connect(_finish_focus.bind(id, final_zoom, target, revision, frames_left - 1, expected_view), CONNECT_ONE_SHOT)
		return
	if revision != _view_revision or store._selected != id: return
	var settled_view:=_map_rect().size-Vector2(0,_toolbar_height())
	if expected_view.x>=0 and not settled_view.is_equal_approx(expected_view):
		# Selecting a costly node can reveal the budget-warning row. Containers
		# settle after focus starts; refit against that real viewport and allow
		# the changed scroll ranges to settle before revealing details.
		final_zoom=_focus_zoom_for_view(settled_view)
		_focus_padding=settled_view/2.0
		target=node_footprint(store._nodes[id]).get_center()+Vector2((popup.size.x+_parent_width()+20.0)/(2.0*final_zoom),0)
		_camera_frame(final_zoom,target)
		_finish_focus(id,final_zoom,target,revision,2,settled_view)
		return
	_camera_frame(final_zoom, target)
	get_tree().process_frame.connect(_finish_focus_menu.bind(id, revision), CONNECT_ONE_SHOT)

func _finish_focus_menu(id: StringName, revision: int) -> void:
	if is_inside_tree() and revision == _view_revision and store._selected == id: _slide_menu(id)

func _camera_frame(value: float, world_center: Vector2) -> void:
	zoom = value
	tree.scale = Vector2.ONE * zoom
	tree.queue_redraw()
	canvas.custom_minimum_size = bounds * zoom + _focus_padding * 2.0 + Vector2(0, _toolbar_height())
	canvas.size = canvas.custom_minimum_size.max(_map_rect().size)
	_center_canvas()
	var offset := world_center * zoom + tree.position - _camera_center()
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
		store._buy.focus_mode = Control.FOCUS_ALL
		_reveal_parent_links()
		if guidance_scroll.visible:position_details.call_deferred())

func _reveal_node(id: StringName) -> void:
	_view_revision += 1
	var offset := Vector2(scroll.scroll_horizontal, scroll.scroll_vertical)
	var button: Button = store._nodes[id]
	# Work in scaled canvas coordinates. ScrollContainer can defer child layout
	# until the next frame, so global rectangles lag rapid key-repeat events.
	var footprint := node_footprint(button)
	var rect := Rect2(tree.position + footprint.position * zoom, footprint.size * zoom)
	var viewport_rect := Rect2(offset, _map_rect().size).grow(-12)
	# The transparent toolbar still owns its interactive controls. Keyboard
	# reveal must leave a card below them so the revealed node can be clicked.
	viewport_rect.position.y += _toolbar_height()
	viewport_rect.size.y -= _toolbar_height()
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
	# Compare logical map positions, so zoom/tween rounding cannot reorder ties.
	var navigation_center := (Vector2(scroll.scroll_horizontal, scroll.scroll_vertical) + _map_rect().size / 2.0 - tree.position) / zoom
	if not anchor.is_empty(): navigation_center = store._nodes[anchor].position + store.NODE_SIZE / 2.0
	var target: StringName = &""
	var best := INF
	for id: StringName in store._nodes:
		if id == anchor: continue
		var delta: Vector2 = store._nodes[id].position + store.NODE_SIZE / 2.0 - navigation_center
		var score := delta.length_squared()
		if not anchor.is_empty():
			var forward := delta.dot(direction)
			if forward <= 1.0: continue
			var sideways := absf(delta.cross(direction))
			# Prefer the requested row/column before distant diagonal branches.
			score = forward + sideways * 2.0 + (100000.0 if sideways > forward else 0.0)
		if score < best or (is_equal_approx(score, best) and store._edges.has([id, anchor])):
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
	if MenuTransitions.navigation_input_blocked(self):get_viewport().set_input_as_handled();return
	if store._debug_popup.visible:
		_cancel_drag()
		return
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
		# _input runs before GUI dispatch. A tip's close button can be hovered
		# while the map still owns keyboard focus; its higher layer must win.
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and _input_layer(hovered) > _input_layer(self): return
		# _input precedes GUI dispatch: never steal a toolbar button's gesture.
		if _over_toolbar_control(event.position): return
		var over_menu := (popup.visible and popup.modulate.a > 0.05 and popup.get_global_rect().has_point(event.position)) or (parent_links.is_visible_in_tree() and parent_links.get_global_rect().grow(MenuTransitions.ENTRANCE_DISTANCE).has_point(event.position))
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
		if popup.visible and focused != null and (popup.is_ancestor_of(focused) or parent_links.is_ancestor_of(focused)) and not MenuTransitions.cancel_pressed(event): return
		if directions.has(event.keycode):
			_cancel_drag()
			navigate_direction(directions[event.keycode])
			get_viewport().set_input_as_handled()
		elif MenuTransitions.cancel_pressed(event):
			_cancel_drag()
			if popup.visible: get_viewport().set_input_as_handled()
			dismiss()
	elif MenuTransitions.cancel_pressed(event):
		_cancel_drag()
		if popup.visible: get_viewport().set_input_as_handled()
		dismiss()
