class_name FeatureStore
extends PanelContainer

var _run: RunState
var _tree: Control
var _scroll: ScrollContainer
var _nodes: Dictionary = {}
var _edges: Array = []
const NODE_SIZE := Vector2(224, 100)
const COLUMN_STEP := 248.0
const LEVEL_STEP := 160.0
const LANE_ORDER := [&"Visuals", &"Audio", &"Technology & Tools", &"Gameplay", &"Story & World"]
# Presentation only. Card definitions, prerequisites, and purchase rules remain in the ledger.
const LANE_MEMBERS := {
	&"Visuals": [&"text", &"colored_text", &"sprites", &"animated_sprites", &"4_color_palette", &"8_color_palette", &"scrolling", &"multi_directional_scrolling"],
	&"Audio": [&"8_bit_sound", &"recorded_sounds", &"8_bit_music", &"16_bit_music", &"sound_effects", &"music"],
	&"Technology & Tools": [&"keyboard_and_mouse", &"controller", &"menu_system", &"split_screen", &"save_files", &"branching_nodes"],
	&"Gameplay": [&"score_system", &"high_scores", &"local_leaderboards", &"lives_system", &"controls", &"enemies", &"scripted_ai", &"power_ups", &"general_combat", &"difficulty_levels"],
	&"Story & World": [&"simple_story", &"dialogue", &"character_backstories", &"multiple_endings", &"levels", &"maps", &"exploration", &"secrets"],
}
var _lane_by_id: Dictionary = {}
var _lane_buttons: Dictionary = {}
var _lane_scroll: Dictionary = {}
var _active_lane: StringName = &"Visuals"
var _gate: Label
var _lane_heading: Label
var _details: Label
var _cash: Label
var _owned_summary: Label
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
	_owned_summary = Label.new()
	_owned_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_owned_summary.add_theme_font_size_override("font_size", 14)
	_owned_summary.tooltip_text = "Printed Scope and Core scores for all owned Features. Play cost is once per owned Feature in a project; Passes are free. Later Store Features have no defined play price yet."
	layout.add_child(_owned_summary)
	var lanes := HBoxContainer.new()
	lanes.add_theme_constant_override("separation", 8)
	layout.add_child(lanes)
	for lane: StringName in LANE_ORDER:
		var lane_button := Button.new()
		lane_button.text = str(lane)
		lane_button.toggle_mode = true
		lane_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lane_button.focus_mode = Control.FOCUS_ALL
		lane_button.pressed.connect(_select_lane.bind(lane))
		lanes.add_child(lane_button)
		_lane_buttons[lane] = lane_button
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
	note.text = "Owned: green • Available: blue • Need cash: amber • Locked: gray • Selected: white border\nChoose a lane, then scroll sideways • Roots below, upgrades above ↑ • Browsing: $0.00 and 0 cycles"
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
	if _run.needs_starter_selection():
		var pool := _run.get_starter_pool_summary()
		_cash.text += "\nFirst-game pool: %d / 23 Scope · %s / $4,000.00 spent · Primitive purchases cost 0 cycles" % [pool.scope, CashFormatter.format_exact_cents(pool.spent_cents)]
	var owned := _summarize_owned_features()
	_owned_summary.text = "OWNED POOL  •  Scope %d  •  Core Score %d\n" % [owned.scope, owned.total_score]
	_owned_summary.text += "G %d · S %d · T %d · D %d  •  Play once: %s" % [owned.graphics, owned.sound, owned.technology, owned.design, CashFormatter.format_exact_cents(owned.known_play_cost_cents)]
	if owned.unpriced_count > 0:
		_owned_summary.text += "\n+ %d Store Feature%s with play cost TBD" % [owned.unpriced_count, "" if owned.unpriced_count == 1 else "s"]
	if _nodes.is_empty():
		_build_tree()
	for id: StringName in _nodes:
		var button: Button = _nodes[id]
		var offer := _run.get_feature_store_offer(id)
		var reserve := _run.get_primitive_reserve_offer(id) if offer.is_empty() else {}
		var status := "Owned"
		var color := Color("244b3d")
		if not reserve.is_empty() and not reserve.owned:
			status = "Starter · 0 cycles" if reserve.initial else "Reserve · 1 cycle"
			if not reserve.within_limits:
				status = "Starter limit reached"
			elif not reserve.affordable:
				status += " · Need cash"
			color = Color("244b70") if reserve.can_purchase else Color("674c24")
		if not offer.is_empty() and not offer.owned:
			status = "Available" if offer.unlocked else "Locked"
			color = Color("244b70") if offer.unlocked else Color("343943")
			if offer.unlocked and not offer.affordable:
				status = "Available • Need cash"
				color = Color("674c24")
			if _run.needs_starter_selection():
				status = "After first game"
				color = Color("343943")
		var card: CardData = get_node("/root/CardDatabase").get_card(id)
		button.text = card.card_name + "\n" + status
		if not offer.is_empty():
			button.text += "\n" + (str(offer.prerequisite) if not offer.unlocked else CashFormatter.format_exact_cents(offer.price_cents))
		elif not reserve.is_empty() and not reserve.owned:
			button.text += "\n" + CashFormatter.format_exact_cents(reserve.price_cents)
		var department := "No department" if card.department.is_empty() else str(card.department).replace("_", " ").capitalize()
		button.tooltip_text = "%s · %s · %s\nDepartment: %s · Scope %d · +%d %s" % [card.card_name, str(card.phase).capitalize(), str(_lane_by_id[id]), department, card.scope, card.primary_value, str(card.primary_stat).capitalize()]
		if card.secondary_value != 0:
			button.tooltip_text += " · +%d %s" % [card.secondary_value, str(card.secondary_stat).capitalize()]
		if not offer.is_empty():
			button.tooltip_text += "\nPrerequisite: %s\nBase: %s · Discount: %d%% · Final: %s\nPurchase: 1 productive cycle · %s" % [offer.prerequisite, CashFormatter.format_exact_cents(offer.base_price_cents), offer.discount_percent, CashFormatter.format_exact_cents(offer.price_cents), "Owned" if offer.owned else "Affordable" if offer.affordable and offer.unlocked else "Need cash" if offer.unlocked else "Locked"]
		elif not reserve.is_empty() and not reserve.owned:
			button.tooltip_text += "\nPrimitive %s · %s" % ["starter" if reserve.initial else "reserve", CashFormatter.format_exact_cents(reserve.price_cents)]
		else:
			button.tooltip_text += "\nOwned Primitive Feature"
		for style_name: String in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = color.lightened(0.12) if style_name == "hover" else color
			style.set_corner_radius_all(8)
			style.set_border_width_all(3 if id == _selected or style_name == "focus" else 1)
			style.border_color = Color.WHITE if id == _selected or style_name == "focus" else color.lightened(0.3)
			button.add_theme_stylebox_override(style_name, style)
	_tree.queue_redraw()
	_show_details()


func _summarize_owned_features() -> Dictionary:
	var scores := {&"graphics": 0, &"sound": 0, &"technology": 0, &"design": 0}
	var scope := 0
	var unpriced_count := 0
	var priced_cards: Array[CardData] = []
	var database := get_node("/root/CardDatabase")
	for id: StringName in _run.get_owned_feature_ids():
		var card: CardData = database.get_card(id)
		if card == null or card.card_type != &"feature":
			continue
		scope += card.scope
		scores[card.primary_stat] += card.primary_value
		if not card.secondary_stat.is_empty():
			scores[card.secondary_stat] += card.secondary_value
		if _run.get_feature_store_offer(id).is_empty():
			priced_cards.append(card)
		else:
			unpriced_count += 1
	var cost := _run.primitive_feature_hand_cost_cents(priced_cards)
	return {"scope": scope, "total_score": scores[&"graphics"] + scores[&"sound"] + scores[&"technology"] + scores[&"design"],
		"graphics": scores[&"graphics"], "sound": scores[&"sound"], "technology": scores[&"technology"], "design": scores[&"design"],
		"known_play_cost_cents": cost, "unpriced_count": unpriced_count}


func _build_tree() -> void:
	var entries := FeatureStoreCatalog.starting_features() + FeatureStoreCatalog.entries()
	var children: Dictionary = {}
	for lane: StringName in LANE_ORDER:
		for id: StringName in LANE_MEMBERS[lane]:
			assert(not _lane_by_id.has(id), "Feature appears in two Store lanes: " + str(id))
			_lane_by_id[id] = lane
	for entry: Dictionary in entries:
		var id := StringName(entry.id)
		assert(_lane_by_id.has(id), "Feature missing Store lane: " + str(id))
		var parent := StringName(entry.get("purchase_parent", ""))
		if int(entry.get("gameplay_features_required", 0)) > 0:
			parent = &"gameplay_gate"
		if not parent.is_empty():
			if not children.has(parent): children[parent] = []
			children[parent].append(id)
			_edges.append([parent, id])
		var button := Button.new()
		button.size = NODE_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.pressed.connect(_select_node.bind(id))
		_tree.add_child(button)
		_nodes[id] = button
	assert(_nodes.size() == _lane_by_id.size(), "Store lane map does not match ledger")
	_gate = Label.new()
	_gate.name = "GameplayGate"
	_gate.text = "OWN ANY 3 DISTINCT\nGAMEPLAY FEATURES\nOwnership gate • no discount"
	_gate.size = NODE_SIZE
	_gate.add_theme_font_size_override("font_size", 14)
	_tree.add_child(_gate)
	_lane_heading = Label.new()
	_lane_heading.position = Vector2(16, 8)
	_tree.add_child(_lane_heading)
	_layout_lane(children)


func _layout_lane(children: Dictionary) -> void:
	var lane_ids: Array = LANE_MEMBERS[_active_lane]
	var roots: Array[StringName] = []
	for id: StringName in lane_ids:
		var is_child := false
		for edge: Array in _edges:
			if edge[1] == id:
				is_child = true
				break
		if not is_child:
			roots.append(id)
	if _active_lane == &"Gameplay":
		roots.append(&"gameplay_gate")
	var max_depth := 0
	for root_id: StringName in roots:
		max_depth = maxi(max_depth, _branch_depth(root_id, children))
	var baseline := 64.0 + max_depth * LEVEL_STEP
	for i in range(roots.size()):
		var x := 16.0 + i * COLUMN_STEP
		_place_upward_branch(roots[i], x, baseline, 0, children)
	_tree.custom_minimum_size = Vector2(32 + roots.size() * COLUMN_STEP, baseline + NODE_SIZE.y + 24)
	_lane_heading.text = str(_active_lane).to_upper() + "  •  UPGRADES ↑  •  ROOT FEATURES BELOW"
	_gate.visible = _active_lane == &"Gameplay"
	for id: StringName in _nodes:
		_nodes[id].visible = _lane_by_id[id] == _active_lane
	for lane: StringName in LANE_ORDER:
		_lane_buttons[lane].button_pressed = lane == _active_lane
	_tree.queue_redraw()


func _branch_depth(id: StringName, children: Dictionary) -> int:
	var depth := 0
	for child: StringName in children.get(id, []):
		depth = maxi(depth, 1 + _branch_depth(child, children))
	return depth


func _place_upward_branch(id: StringName, x: float, baseline: float, depth: int, children: Dictionary) -> void:
	var node: Control = _gate if id == &"gameplay_gate" else _nodes[id]
	var y := baseline - depth * LEVEL_STEP
	node.position = Vector2(x, y)
	for child: StringName in children.get(id, []):
		_place_upward_branch(child, x, baseline, depth + 1, children)


func _select_lane(lane: StringName) -> void:
	if lane == _active_lane:
		_lane_buttons[lane].button_pressed = true
		return
	_lane_scroll[_active_lane] = Vector2i(_scroll.scroll_horizontal, _scroll.scroll_vertical)
	_active_lane = lane
	_selected = &""
	var children: Dictionary = {}
	for edge: Array in _edges:
		if not children.has(edge[0]): children[edge[0]] = []
		children[edge[0]].append(edge[1])
	_layout_lane(children)
	var offset: Vector2i = _lane_scroll.get(lane, Vector2i.ZERO)
	_scroll.scroll_horizontal = offset.x
	_scroll.scroll_vertical = offset.y
	_show_details()


func _draw_connections() -> void:
	for edge: Array in _edges:
		if _lane_by_id[edge[1]] != _active_lane:
			continue
		var parent: Control = _gate if edge[0] == &"gameplay_gate" else _nodes[edge[0]]
		var child: Control = _nodes[edge[1]]
		var start := parent.position + Vector2(NODE_SIZE.x / 2, 0)
		var end := child.position + Vector2(NODE_SIZE.x / 2, NODE_SIZE.y)
		var offer := _run.get_feature_store_offer(edge[1])
		var color := Color("7ed6be") if offer.unlocked else Color("8993a5")
		_tree.draw_line(start, end, color, 3, true)
		_tree.draw_colored_polygon(PackedVector2Array([end, end + Vector2(-6, 9), end + Vector2(6, 9)]), color)


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
		var reserve := _run.get_primitive_reserve_offer(_selected)
		if not reserve.is_empty() and not reserve.owned:
			var timing := "First-game starter · 0 cycles" if reserve.initial else "Studio reserve · 1 calendar cycle"
			var availability := "Starter purchase or Scope cap reached" if not reserve.within_limits else "Affordable" if reserve.affordable else "Insufficient cash"
			_details.text = "%s\nPrimitive Feature · %s\nDepartment: %s\n\nPrinted Scope: %d\nPrice: %s\n%s\n%s\n\nPermanent ownership for future projects; each project still exhausts this Feature independently." % [reserve.name, str(reserve.phase).capitalize(), "None" if card.department.is_empty() else str(card.department).replace("_", " ").capitalize(), reserve.scope, CashFormatter.format_exact_cents(reserve.price_cents), timing, availability]
			_buy.text = "Purchase Starter Feature" if reserve.initial else "Purchase Reserve Feature"
			_buy.disabled = not reserve.can_purchase
			return
		_details.text = "%s\nOwned • Primitive Feature · %s\nDepartment: %s\n\nFamiliarity: %d project credits\nDirect children receive 10%% per credit, up to 50%%.\n\nCore: +%d %s • Scope %d\nPrerequisite: Starting root\nBase price / discount / final price: N/A\nAffordability: Already owned" % [card.card_name, str(card.phase).capitalize(), "None" if card.department.is_empty() else str(card.department).replace("_", " ").capitalize(), _run.get_feature_familiarity(_selected), card.primary_value, str(card.primary_stat).capitalize(), card.scope]
		if card.secondary_value != 0:
			_details.text += "\nCore: +%d %s" % [card.secondary_value, str(card.secondary_stat).capitalize()]
		_buy.text = "Already owned"
		return
	var status := "Owned" if offer.owned else ("Purchasable" if offer.unlocked else "Locked")
	_details.text = "%s\n%s · %s\nDepartment: %s\n\nPrerequisite: %s\nBase price: %s\nFamiliarity discount: %d%%\nFinal price: %s\nPurchase time: 1 productive cycle\n%s\n\nPrinted effect: +%d %s • Scope %d\nFinite once per project." % [offer.name, status, str(card.phase).capitalize(), "None" if card.department.is_empty() else str(card.department).replace("_", " ").capitalize(), offer.prerequisite, CashFormatter.format_exact_cents(offer.base_price_cents), offer.discount_percent, CashFormatter.format_exact_cents(offer.price_cents), "Affordable" if offer.affordable else "Insufficient cash", card.primary_value, str(card.primary_stat).capitalize(), card.scope]
	if _selected == &"difficulty_levels":
		_details.text += "\nNo familiarity discount for this prerequisite."
	if card.secondary_value != 0:
		_details.text += "\nCore: +%d %s" % [card.secondary_value, str(card.secondary_stat).capitalize()]
	_buy.text = "Already owned" if offer.owned else ("Requires prerequisite" if not offer.unlocked else ("Insufficient cash" if not offer.affordable else "Purchase Feature · 1 cycle"))
	if _run.needs_starter_selection() and not offer.owned:
		_buy.text = "Available after first game"
	_buy.disabled = offer.owned or not offer.unlocked or not offer.affordable or _run.needs_starter_selection()


func _purchase() -> void:
	# Failed/stale requests leave the view and selection untouched.
	if not _run.get_primitive_reserve_offer(_selected).is_empty():
		if _run.needs_starter_selection():
			_run.purchase_starter_feature(_selected)
		else:
			_run.purchase_primitive_reserve_feature(_selected)
	else:
		_run.purchase_feature(_selected)

