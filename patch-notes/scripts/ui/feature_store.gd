class_name FeatureStore
extends PanelContainer

var _run: RunState
var _tree: Control
var _scroll: ScrollContainer
var _nodes: Dictionary = {}
var _edges: Array = []
const NODE_SIZE := Vector2(224, 100)
const STEP := Vector2(300, 124)
var _details: Label
var _cash: Label
var _buy: Button
var _selected: StringName


func setup(run: RunState) -> void:
	_run = run
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	_cash = Label.new()
	_cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_cash)
	var close := Button.new()
	close.text = "Close Store"
	close.pressed.connect(hide)
	header.add_child(close)
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(280, 260)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.follow_focus = true
	body.add_child(_scroll)
	_tree = Control.new()
	_tree.draw.connect(_draw_connections)
	_scroll.add_child(_tree)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size.x = 320
	detail_scroll.size_flags_horizontal = Control.SIZE_FILL
	body.add_child(detail_scroll)
	var detail_layout := VBoxContainer.new()
	detail_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_theme_constant_override("separation", 16)
	detail_scroll.add_child(detail_layout)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_layout.add_child(_details)
	_buy = Button.new()
	_buy.text = "Purchase Feature"
	_buy.pressed.connect(_purchase)
	detail_layout.add_child(_buy)
	var note := Label.new()
	note.text = "Owned: green • Available: blue • Need cash: amber • Locked: gray • Selected: white border\nScroll to explore • Opening / closing: $0.00 and 0 cycles • Permanent run ownership"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)
	_run.features_changed.connect(_refresh)
	_run.cash_changed.connect(_refresh)
	_refresh()


func open_store() -> void:
	_refresh()
	show()


func _refresh() -> void:
	if _tree == null:
		return
	_cash.text = "Feature Store — Cash: " + CashFormatter.format_exact_cents(_run.get_cash_cents())
	if _nodes.is_empty():
		_build_tree()
	for id: StringName in _nodes:
		var button: Button = _nodes[id]
		var offer := _run.get_feature_store_offer(id)
		var status := "Owned"
		var color := Color("244b3d")
		if not offer.is_empty() and not offer.owned:
			status = "Available" if offer.unlocked else "Locked"
			color = Color("244b70") if offer.unlocked else Color("343943")
			if offer.unlocked and not offer.affordable:
				status = "Available • Need cash"
				color = Color("674c24")
		var card: CardData = get_node("/root/CardDatabase").get_card(id)
		button.text = card.card_name + "\n" + status
		if not offer.is_empty():
			button.text += "\n" + (str(offer.prerequisite) if not offer.unlocked else CashFormatter.format_exact_cents(offer.price_cents))
		button.tooltip_text = card.card_name + ("\n" + str(offer.prerequisite) if not offer.is_empty() else "\nStarting owned Feature")
		for style_name: String in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = color.lightened(0.12) if style_name == "hover" else color
			style.set_corner_radius_all(8)
			style.set_border_width_all(3 if id == _selected or style_name == "focus" else 1)
			style.border_color = Color.WHITE if id == _selected or style_name == "focus" else color.lightened(0.3)
			button.add_theme_stylebox_override(style_name, style)
	_tree.queue_redraw()
	_show_details()


func _build_tree() -> void:
	var entries := FeatureStoreCatalog.starting_features() + FeatureStoreCatalog.entries()
	var children: Dictionary = {}
	var roots: Array = []
	for entry: Dictionary in entries:
		var id := StringName(entry.id)
		var parent := StringName(entry.get("purchase_parent", ""))
		if int(entry.get("gameplay_features_required", 0)) > 0:
			parent = &"gameplay_gate"
		if parent.is_empty():
			roots.append(id)
		else:
			if not children.has(parent): children[parent] = []
			children[parent].append(id)
			_edges.append([parent, id])
		var button := Button.new()
		button.size = NODE_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.pressed.connect(_select_node.bind(id))
		_tree.add_child(button)
		_nodes[id] = button
	var row := 0
	for id: StringName in roots:
		if children.has(id):
			row = _place_branch(id, 0, row, children)
	var gate := Label.new()
	gate.name = "GameplayGate"
	gate.text = "OWN ANY 3 DISTINCT\nGAMEPLAY FEATURES\nOwnership gate • no discount"
	gate.position = Vector2(16, 44 + row * STEP.y)
	gate.size = NODE_SIZE
	gate.add_theme_font_size_override("font_size", 14)
	_tree.add_child(gate)
	for id: StringName in children.get(&"gameplay_gate", []):
		row = _place_branch(id, 1, row, children)
	for id: StringName in roots:
		if not children.has(id):
			row = _place_branch(id, 0, row, children)
	_tree.custom_minimum_size.y = 60 + row * STEP.y
	for depth in range(2):
		var heading := Label.new()
		heading.text = "ROOT FEATURES" if depth == 0 else "PREREQUISITE UPGRADES →"
		heading.position = Vector2(16 + depth * STEP.x, 8)
		_tree.add_child(heading)


func _place_branch(id: StringName, depth: int, row: int, children: Dictionary) -> int:
	_nodes[id].position = Vector2(16 + depth * STEP.x, 44 + row * STEP.y)
	_tree.custom_minimum_size.x = maxf(_tree.custom_minimum_size.x, 32 + depth * STEP.x + NODE_SIZE.x)
	var next_row := row
	for child: StringName in children.get(id, []):
		next_row = _place_branch(child, depth + 1, next_row, children)
	return maxi(row + 1, next_row)


func _draw_connections() -> void:
	for edge: Array in _edges:
		var parent: Control = _tree.get_node("GameplayGate") if edge[0] == &"gameplay_gate" else _nodes[edge[0]]
		var child: Control = _nodes[edge[1]]
		var start := parent.position + Vector2(NODE_SIZE.x, NODE_SIZE.y / 2)
		var end := child.position + Vector2(0, NODE_SIZE.y / 2)
		var middle := (start.x + end.x) / 2
		var offer := _run.get_feature_store_offer(edge[1])
		var color := Color("7ed6be") if offer.unlocked else Color("8993a5")
		_tree.draw_polyline(PackedVector2Array([start, Vector2(middle, start.y), Vector2(middle, end.y), end]), color, 3, true)
		_tree.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-8, -5), end + Vector2(-8, 5)]), color)


func _select_node(id: StringName) -> void:
	_selected = id
	_refresh()

func _show_details() -> void:
	_buy.disabled = true
	_buy.text = "Purchase Feature"
	if _selected.is_empty():
		_details.text = "Feature technology tree\n\nOwned Features remain available for future projects. Each project has its own finite Feature exhaustion."
		return
	var card: CardData = get_node("/root/CardDatabase").get_card(_selected)
	var offer := _run.get_feature_store_offer(_selected)
	if offer.is_empty():
		_details.text = "%s\nOwned • Starting Primitive Feature\n\nFamiliarity: %d project credits\nDirect children receive 10%% per credit, up to 50%%.\n\nCore: +%d %s • Scope %d\nPrerequisite: Starting root\nBase price / discount / final price: N/A\nAffordability: Already owned" % [card.card_name, _run.get_feature_familiarity(_selected), card.primary_value, str(card.primary_stat).capitalize(), card.scope]
		if card.secondary_value != 0:
			_details.text += "\nCore: +%d %s" % [card.secondary_value, str(card.secondary_stat).capitalize()]
		_buy.text = "Already owned"
		return
	var status := "Owned" if offer.owned else ("Purchasable" if offer.unlocked else "Locked")
	_details.text = "%s\n%s\n\nPrerequisite: %s\nBase price: %s\nFamiliarity discount: %d%%\nFinal price: %s\n%s\n\nPrinted effect: +%d %s • Scope %d\nFinite once per project." % [offer.name, status, offer.prerequisite, CashFormatter.format_exact_cents(offer.base_price_cents), offer.discount_percent, CashFormatter.format_exact_cents(offer.price_cents), "Affordable" if offer.affordable else "Insufficient cash", card.primary_value, str(card.primary_stat).capitalize(), card.scope]
	if _selected == &"difficulty_levels":
		_details.text += "\nNo familiarity discount for this prerequisite."
	if card.secondary_value != 0:
		_details.text += "\nCore: +%d %s" % [card.secondary_value, str(card.secondary_stat).capitalize()]
	_buy.text = "Already owned" if offer.owned else ("Requires prerequisite" if not offer.unlocked else ("Insufficient cash" if not offer.affordable else "Purchase Feature"))
	_buy.disabled = offer.owned or not offer.unlocked or not offer.affordable


func _purchase() -> void:
	# Failed/stale requests leave the view and selection untouched.
	_run.purchase_feature(_selected)

