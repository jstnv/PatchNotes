class_name FeatureStore
extends PanelContainer

var _map: FeatureStoreMap
var _run: RunState
var _tree: Control
var _scroll: ScrollContainer
var _nodes: Dictionary = {}
var _edges: Array = []
const NODE_SIZE := Vector2(128, 128)
const SCORE_COLORS := {
	&"graphics": Color("f08e9b"), &"sound": Color("e9c46a"),
	&"technology": Color("74c9e8"), &"design": Color("bda1ef"),
}
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
var _spending_advice: Label
var _buy: Button
var _selected: StringName
var _research_list: OptionButton
var _research_button: Button
var _research_quote: Dictionary = {}
var _admission_dialog: ConfirmationDialog

static func score_label(stat: StringName) -> String:
	return "Tech" if stat == &"technology" else str(stat).capitalize()


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
	_spending_advice = Label.new()
	_spending_advice.name = "SpendingAdvice"
	_spending_advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_spending_advice.add_theme_font_size_override("font_size", 14)
	layout.add_child(_spending_advice)
	var queue_bar := HBoxContainer.new()
	layout.add_child(queue_bar)
	_research_list = OptionButton.new()
	_research_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_research_list.item_selected.connect(func(index: int): _select_node(_research_list.get_item_metadata(index)))
	queue_bar.add_child(_research_list)
	_research_button = Button.new()
	_research_button.text = "Research"
	_research_button.pressed.connect(func():
		var quote := _research_quote.duplicate(true)
		if _run.research_feature(quote): _refresh())
	queue_bar.add_child(_research_button)
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
	_map = FeatureStoreMap.new()
	add_child(_map)
	_map.configure(self, layout)
	_run.features_changed.connect(_refresh)
	_run.cash_changed.connect(_refresh)
	_run.sales_changed.connect(_refresh)
	_run.calendar_changed.connect(_refresh, CONNECT_DEFERRED)
	_refresh()


func open_store() -> void:
	_refresh()
	show()


func _refresh() -> void:
	# Deferred run signals can arrive after Studio has been detached for departure.
	if not is_inside_tree() or _tree == null:
		return
	_cash.text = "Feature Store"
	_research_list.clear()
	_research_quote = {}
	var pending := _run.get_feature_research_queue()
	_research_list.visible = not _run.needs_starter_selection()
	_research_button.visible = not _run.needs_starter_selection()
	for entry: Dictionary in pending:
		var q := _run.get_feature_research_quote(entry.feature_id)
		_research_list.add_item("%d. %s - %d action(s) left" % [_research_list.item_count+1,_run._feature_definitions[entry.feature_id].name,q.remaining_actions])
		_research_list.set_item_metadata(_research_list.item_count-1,entry.feature_id)
	if pending.is_empty(): _research_list.add_item("Research queue empty")
	else: _research_quote = _run.get_feature_research_quote(pending[0].feature_id)
	_research_button.disabled = _research_quote.is_empty() or not _research_quote.can_research
	_research_button.text = "Research" if _research_quote.is_empty() else "Research %s - 1 cycle" % CashFormatter.format_exact_cents(_research_quote.due_cents)
	_research_button.tooltip_text = "Only the first queued Feature receives research. No automatic progress or due bills."
	if _run.needs_starter_selection():
		var pool := _run.get_starter_pool_summary()
		_cash.text += "\nFirst-game pool: %d Scope · Optional Primitive purchases cost 0 cycles" % pool.scope
	var owned := _summarize_owned_features()
	_owned_summary.text = "OWNED POOL  •  Scope %d  •  Core Score %d\n" % [owned.scope, owned.total_score]
	_owned_summary.text += "Graphics %d · Sound %d · Tech %d · Design %d  •  Play once: %s" % [owned.graphics, owned.sound, owned.technology, owned.design, CashFormatter.format_exact_cents(owned.known_play_cost_cents)]
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
			if not reserve.affordable:
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
		var research := _run.get_feature_research_quote(id)
		if not _run.needs_starter_selection() and not _run.owns_feature(id):
			status = "Research head" if research.head else "Queued" if research.queued else "Locked" if not research.unlocked else "Queue available" if research.can_admit else "Queue - Need cash / clear bills"
		var card: CardData = get_node("/root/CardDatabase").get_card(id)
		button.text = card.card_name + "\n" + status
		(button.get_node("MapStatus") as Label).text = status
		var department := "No department" if card.department.is_empty() else str(card.department).replace("_", " ").capitalize()
		button.tooltip_text = "%s · %s · %s\nDepartment: %s · Scope %d · +%d %s" % [card.card_name, str(card.phase).capitalize(), str(_lane_by_id[id]), department, card.scope, card.primary_value, score_label(card.primary_stat)]
		if card.secondary_value != 0:
			button.tooltip_text += " · +%d %s" % [card.secondary_value, score_label(card.secondary_stat)]
		if not offer.is_empty() and offer.owned:
			button.tooltip_text += "\nOwned Feature\nPrerequisite: %s" % offer.prerequisite
		elif not offer.is_empty():
			button.tooltip_text += "\nPrerequisite: %s\nBase: %s. Queue down payment: %s (0 cycles).\nNext research installment: %s (1 cycle); %d%% familiarity now." % [offer.prerequisite,CashFormatter.format_exact_cents(research.base_cents),CashFormatter.format_exact_cents(research.down_cents),CashFormatter.format_exact_cents(research.due_cents),research.discount_percent]
		elif not reserve.is_empty() and not reserve.owned:
			button.tooltip_text += "\nPrimitive %s · %s" % ["starter" if reserve.initial else "reserve", CashFormatter.format_exact_cents(reserve.price_cents)]
		else:
			button.tooltip_text += "\nOwned Primitive Feature"
		for style_name: String in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = color.lightened(0.12) if style_name == "hover" else color
			style.set_corner_radius_all(8)
			style.set_border_width_all(5 if id == _selected or style_name == "focus" else 3)
			style.border_color = SCORE_COLORS[card.primary_stat]
			if style_name == "focus": style.bg_color = Color.TRANSPARENT
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
		_map.decorate(button, get_node("/root/CardDatabase").get_card(id))
	assert(_nodes.size() == _lane_by_id.size(), "Store lane map does not match ledger")
	_gate = Label.new()
	_gate.name = "GameplayGate"
	_gate.text = "OWN ANY 3 DISTINCT\nGAMEPLAY FEATURES\nOwnership gate • no discount"
	_gate.size = Vector2(180, 100)
	_gate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gate.add_theme_font_size_override("font_size", 14)
	_tree.add_child(_gate)
	_lane_heading = Label.new()
	_lane_heading.position = Vector2(16, 8)
	_tree.add_child(_lane_heading)
	_layout_lane(children)


func _layout_lane(children: Dictionary) -> void:
	_map.layout_map(children)


func _select_lane(lane: StringName) -> void:
	_active_lane = lane
	_map.navigate(lane)
	for key: StringName in _lane_buttons:
		_lane_buttons[key].button_pressed = key == lane


func _draw_connections() -> void:
	_map.draw_core()
	for edge: Array in _edges:
		var parent: Control = _gate if edge[0] == &"gameplay_gate" else _nodes[edge[0]]
		var child: Control = _nodes[edge[1]]
		var parent_rect := parent.get_rect() if parent == _gate else _map.node_footprint(parent)
		var child_rect := _map.node_footprint(child)
		var direction := (child_rect.get_center() - parent_rect.get_center()).normalized()
		var start := _map.edge_port(parent_rect, direction)
		var end := _map.edge_port(child_rect, -direction)
		var offer := _run.get_feature_store_offer(edge[1])
		var color := Color("7ed6be") if offer.unlocked else Color("8993a5")
		_tree.draw_line(start, end, color, 3, true)
		var across := direction.orthogonal() * 6.0
		_tree.draw_colored_polygon(PackedVector2Array([end, end - direction * 9.0 + across, end - direction * 9.0 - across]), color)


func _select_node(id: StringName) -> void:
	_selected = id
	_refresh()
	_map.focus_selection(id)

func _show_details() -> void:
	_map.show_details()
	_refresh_spending_advice()


func _refresh_spending_advice() -> void:
	var advice := _run.get_feature_spending_advice(_selected)
	_spending_advice.text = FeatureSpendingGuidance.message(advice)
	_spending_advice.tooltip_text = FeatureSpendingGuidance.explanation(advice)
	_spending_advice.add_theme_color_override("font_color", Color("e9c46a") if advice.get("below_reserve", false) else Color("bdd5cf"))


func _purchase() -> void:
	var reserve := _run.get_primitive_reserve_offer(_selected)
	if not reserve.is_empty() and _run.needs_starter_selection():
		_run.purchase_starter_feature(_selected)
		return
	var quote := _run.get_feature_research_quote(_selected)
	if quote.is_empty() or not quote.can_admit: return
	if is_instance_valid(_admission_dialog): _admission_dialog.queue_free()
	_admission_dialog = ConfirmationDialog.new()
	_admission_dialog.title = "Queue Feature research?"
	_admission_dialog.dialog_text = "Pay %s now (0 cycles). This down payment is irreversible.\nNo cancellation or reordering. Ownership begins only after research finishes.\nNext installment at current familiarity: %s; 1 productive cycle.\nFuture familiarity can change the remaining price." % [CashFormatter.format_exact_cents(quote.down_cents),CashFormatter.format_exact_cents(quote.due_cents)]
	_admission_dialog.confirmed.connect(func():
		_run.admit_feature_research(quote)
		_refresh())
	add_child(_admission_dialog)
	_admission_dialog.popup_centered()
	_admission_dialog.get_cancel_button().grab_focus()
