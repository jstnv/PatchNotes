class_name FeatureStore
extends Control

var _map: FeatureStoreMap
var _run: RunState
var _engine_id: StringName=&""
var _tree: Control
var _scroll: ScrollContainer
var _nodes: Dictionary = {}
var _edges: Array = []
var _map_offers: Dictionary = {}
const NODE_SIZE := Vector2(128, 128)
const SCORE_COLORS := {
	&"graphics": Color("f08e9b"), &"sound": Color("e9c46a"),
	&"technology": Color("74c9e8"), &"design": Color("bda1ef"),
}
const LANE_ORDER := [&"Visuals", &"Audio", &"Technology & Tools", &"Gameplay", &"Story & World"]
# Presentation only. Card definitions, prerequisites, and purchase rules remain in the ledger.
const LANE_MEMBERS := {
	&"Visuals": [&"text", &"colored_text", &"sprites", &"animated_sprites", &"4_color_palette", &"8_color_palette", &"scrolling", &"multi_directional_scrolling"],
	&"Audio": [&"8_bit_sound", &"16_bit_sound", &"main_theme", &"recorded_sounds", &"multiple_soundtracks", &"instrumental_sounds", &"dynamic_sequencing"],
	&"Technology & Tools": [&"keyboard_and_mouse", &"controller", &"menu_system", &"split_screen", &"save_files", &"branching_nodes", &"player_level_editor"],
	&"Gameplay": [&"timer_system", &"inventory_system", &"categorized_scores", &"score_system", &"high_scores", &"local_leaderboards", &"lives_system", &"controls", &"enemies", &"scripted_ai", &"power_ups", &"general_combat", &"turn_based_combat", &"character_classes", &"difficulty_levels"],
	&"Story & World": [&"simple_story", &"dialogue", &"branching_dialogue", &"character_backstories", &"character_development", &"multiple_endings", &"levels", &"maps", &"exploration", &"secrets", &"ability_gated_exploration", &"switchable_protagonists", &"character_skill_checks"],
}
var _lane_by_id: Dictionary = {}
var _lane_scroll: Dictionary = {}
var _active_lane: StringName = &"Visuals"
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
var _header: HBoxContainer
var _body: PanelContainer
var _close: Button
var _debug: Button
var _debug_popup: PanelContainer
var _debug_notes: Label
var _debug_scroll: ScrollContainer
var _toolbar: VBoxContainer
var _implementation_controls: VBoxContainer
var _map_host: Control
var _refresh_queued := false

class DebugButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		return FeatureStore.notes_tooltip(for_text, get_viewport_rect().size.x)

class PoolSummaryLabel extends Label:
	func _make_custom_tooltip(for_text: String) -> Object:
		return FeatureStore.notes_tooltip(for_text, get_viewport_rect().size.x)

static func notes_tooltip(for_text: String, viewport_width: float) -> Label:
	var label := Label.new()
	label.custom_minimum_size.x = minf(480, viewport_width - 48)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = for_text
	backed_text(label)
	return label

static func score_label(stat: StringName) -> String:
	return "Tech" if stat == &"technology" else str(stat).capitalize()


static func backed_text(label: Label) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = FolderUI.color(&"secondary")
	background.set_content_margin_all(4)
	label.add_theme_stylebox_override("normal", background)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("shadow_color", Color.BLACK)

func _layout_store_chrome() -> void:
	if _toolbar == null or _map_host == null: return
	var available := maxf(0, _map_host.size.x - 32)
	_toolbar.position = Vector2(16, maxf(16, _map_host.size.y - _toolbar.get_combined_minimum_size().y - 16))
	_toolbar.size = _toolbar.get_combined_minimum_size()
	_implementation_controls.position = Vector2(16, 24 + maxf(44, _header.get_combined_minimum_size().y))
	_implementation_controls.size = Vector2(minf(760, available), _implementation_controls.get_combined_minimum_size().y)

func _over_floating_control(point: Vector2) -> bool:
	for group: Control in [_header, _implementation_controls, _toolbar]:
		for control: Control in group.find_children("*", "Control", true, false):
			if (control is BaseButton or control is Label) and control.is_visible_in_tree() and control.get_global_rect().has_point(point): return true
	return false

func setup(run: RunState) -> void:
	_run = run
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body = PanelContainer.new()
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	_body.add_child(margin)
	_map_host = Control.new()
	_map_host.name = "StoreMapHost"
	_map_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_host.custom_minimum_size.y = 150
	margin.add_child(_map_host)
	_header = HBoxContainer.new()
	_header.name = "StoreHeader"
	_header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_header.offset_left = 16
	_header.offset_right = -16
	_header.offset_top = 16
	_header.add_theme_constant_override("separation", 24)
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_host.add_child(_header)
	_close = Button.new()
	_close.name = "CloseStore"
	_close.text = "Back to Engine"
	_close.pressed.connect(hide)
	_header.add_child(_close)
	FolderUI.standard_back(_close)
	_cash = Label.new()
	_cash.name = "EngineTitle"
	_cash.theme_type_variation = &"HeadingLabel"
	_cash.add_theme_font_size_override("font_size",16)
	_cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cash.clip_text = true
	_cash.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cash.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_cash.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_header.add_child(_cash)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(gap)
	_owned_summary = PoolSummaryLabel.new()
	_owned_summary.size_flags_horizontal = Control.SIZE_SHRINK_END
	_owned_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_owned_summary.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_owned_summary.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_owned_summary.add_theme_font_size_override("font_size", 14)
	_header.add_child(_owned_summary)
	_implementation_controls = VBoxContainer.new()
	_implementation_controls.name = "ImplementationControls"
	_implementation_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_implementation_controls.add_theme_constant_override("separation", 6)
	_map_host.add_child(_implementation_controls)
	# Queue and completion use the former Research row, with engine-scoped
	# implementation terms. Selected Feature details keep their actions too.
	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation", 8)
	_implementation_controls.add_child(actions)
	_research_list = OptionButton.new()
	_research_list.name = "ImplementationQueue"
	_research_list.fit_to_longest_item = false
	_research_list.clip_text = true
	_research_list.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_research_list.custom_minimum_size.x = 220
	_research_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_research_list.show()
	_research_list.item_selected.connect(func(index: int):
		var id: Variant = _research_list.get_item_metadata(index)
		if id is StringName: _select_node(id))
	actions.add_child(_research_list)
	_research_button = Button.new()
	_research_button.name = "ImplementFeature"
	_research_button.text = "Implement"
	_research_button.pressed.connect(func():
		if not _research_quote.is_empty(): _implement(_research_quote.feature_id))
	actions.add_child(_research_button)
	_toolbar = VBoxContainer.new()
	_toolbar.name = "StoreToolbar"
	_toolbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar.add_theme_constant_override("separation", 6)
	_map_host.add_child(_toolbar)
	_debug = DebugButton.new()
	_debug.name = "StoreDebug"
	_debug.text = "Debug"
	_debug.pressed.connect(_toggle_debug)
	_toolbar.add_child(_debug)
	_build_debug_popup()
	resized.connect(_position_debug)
	visibility_changed.connect(func():
		if not visible: _debug_popup.hide())
	_spending_advice = Label.new()
	_spending_advice.name = "SpendingAdvice"
	_spending_advice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spending_advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toolbar.add_child(_spending_advice)
	_spending_advice.hide()
	_map = FeatureStoreMap.new()
	add_child(_map)
	_map.configure(self, _toolbar, _map_host)
	for group: Control in [_header, _implementation_controls, _toolbar]:
		for label: Label in group.find_children("*", "Label", true, false):
			backed_text(label)
			label.mouse_filter = Control.MOUSE_FILTER_STOP
		group.minimum_size_changed.connect(_layout_store_chrome)
	_map_host.resized.connect(_layout_store_chrome)
	_layout_store_chrome.call_deferred()
	_run.features_changed.connect(_request_refresh)
	_run.cash_changed.connect(_request_refresh)
	_run.sales_changed.connect(_request_refresh)
	_run.calendar_changed.connect(_request_refresh)
	_run.engines_changed.connect(_request_refresh)
	_refresh()


func open_store(engine: StringName=&"") -> void:
	var requested: StringName=engine
	if requested.is_empty():requested=_engine_id if not _engine_id.is_empty() else _run.get_selected_engine_id()
	var state:=_run.get_engine_feature_state()
	if not state.engines.has(requested) or state.engines[requested].kind!=&"proprietary":return
	if _engine_id!=requested:
		_selected=&""
		_map.dismiss()
	_engine_id=requested
	_refresh()
	show()


func _request_refresh() -> void:
	# A committed transaction publishes several signals. Rebuild once after all
	# of them, using its final state; a hidden Store refreshes when next opened.
	if _refresh_queued or not is_visible_in_tree(): return
	_refresh_queued = true
	_flush_refresh.call_deferred()


func _flush_refresh() -> void:
	if not _refresh_queued: return
	_refresh_queued = false
	if is_visible_in_tree(): _refresh()


func _refresh() -> void:
	_refresh_queued = false
	# Deferred run signals can arrive after Studio has been detached for departure.
	if not is_inside_tree() or _tree == null:
		return
	if _engine_id.is_empty():_engine_id=_run.get_selected_engine_id()
	var view := _run.get_feature_store_view(_engine_id)
	if view.has("error"):
		_map_offers={}
		_cash.text = "Feature Implementation unavailable: " + str(view.error)
		_research_button.disabled = true
		_map.popup.hide()
		return
	_map_offers=view.offers.duplicate()
	for id: StringName in view.reserves:
		if _map_offers[id].is_empty(): _map_offers[id]=view.reserves[id]
	var engine_state:=_run.get_engine_feature_state()
	var selected_record: Dictionary=engine_state.engines[_engine_id]
	var available_ids:=_run.get_future_project_feature_ids(_engine_id)
	_cash.text = selected_record.name
	_cash.tooltip_text = selected_record.name
	var starter_gate := _starter_gate_applies()
	_research_list.clear()
	_research_quote = {}
	var pending := _run.get_feature_research_queue()
	_research_list.visible = not starter_gate
	_research_button.visible = not starter_gate
	for entry: Dictionary in pending:
		if entry.engine_id!=_engine_id:continue
		var q: Dictionary = _run.get_feature_research_quote(entry.feature_id,entry.engine_id)
		_research_list.add_item("%d. %s / %s - %d action(s) left" % [_research_list.item_count+1,engine_state.engines[entry.engine_id].name,_run._feature_definitions[entry.feature_id].name,q.remaining_actions])
		_research_list.set_item_metadata(_research_list.item_count-1,entry.feature_id)
	_research_list.tooltip_text = "Implementation Queue for " + str(selected_record.name)
	_research_list.disabled = _research_list.item_count==0
	if _research_list.disabled: _research_list.add_item("Implementation queue empty")
	if not pending.is_empty() and pending[0].engine_id==_engine_id:_research_quote = _run.get_feature_research_quote(pending[0].feature_id,_engine_id)
	_research_button.disabled = _research_quote.is_empty() or not _research_quote.can_research
	_research_button.text = "Other engine first" if not pending.is_empty() and pending[0].engine_id!=_engine_id else "Implement" if _research_quote.is_empty() else "Implement %s - 1 cycle" % CashFormatter.format_exact_cents(_research_quote.due_cents)
	_research_button.tooltip_text = "Select a Feature node and queue its implementation first." if pending.is_empty() else "Only the first queued Feature can complete. Completion takes one productive cycle and makes it available to future games."
	var owned := _summarize_owned_features()
	_owned_summary.text = "AVAILABLE LIBRARY · Scope %d\nGraphics %d · Sound %d · Tech %d · Design %d" % [owned.scope, owned.graphics, owned.sound, owned.technology, owned.design]
	_owned_summary.tooltip_text = "Implemented Features available to this engine's future games. Known cost per play: %s; Passes are free. Active games retain their frozen pool." % CashFormatter.format_exact_cents(owned.known_play_cost_cents)
	if starter_gate:
		_owned_summary.tooltip_text += "\n\nFirst-game pool: optional Primitive purchases cost 0 cycles."
	if _nodes.is_empty():
		_build_tree()
	for id: StringName in _nodes:
		var button: Button = _nodes[id]
		var offer: Dictionary = view.offers[id]
		var reserve: Dictionary = view.reserves[id]
		var record: Dictionary=selected_record
		var status := "Available" if id in available_ids else "Implemented · held"
		var color := Color("244b3d")
		if not reserve.is_empty() and not reserve.owned:
			status = "Starter · 0 cycles" if reserve.initial else "Reserve · 1 cycle"
			if not reserve.unlocked: status = "Locked · parent required"
			if not reserve.affordable:
				status += " · Need cash"
			color = Color("244b70") if reserve.can_purchase else Color("674c24")
		var research: Dictionary = view.quotes[id]
		if not _run.owns_feature(id,_engine_id) and (not offer.is_empty() or not starter_gate):
			status = queue_status(research,view.financial_block_reason)
			color = Color("244b70") if research.can_admit or research.queued else Color("674c24")
		var card: CardData = get_node("/root/CardDatabase").get_card(id)
		button.text = card.card_name + "\n" + status
		(button.get_node("MapStatus") as Label).text = status
		button.tooltip_text = card.card_name + " · Scope %d" % card.scope
		for entry in card.core_contributions(): button.tooltip_text += " · +%d %s" % [entry.value,score_label(entry.stat)]
		button.tooltip_text += "\nPlay cost: " + (play_cost_text(card))
		var visual := [color,id==_selected]
		if button.get_meta("store_visual",[])==visual: continue
		button.set_meta("store_visual",visual)
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
	_layout_store_chrome.call_deferred()


func _starter_gate_applies() -> bool:
	if not _run.needs_starter_selection(): return false
	var state: Dictionary = _run.get_engine_feature_state()
	return not state.engines.has(_engine_id) or state.engines[_engine_id].kind != &"proprietary"

func queue_block_reasons(quote: Dictionary, current_block: Variant = null) -> Array[String]:
	# Explain the live quote; never substitute full-card affordability for its deposit.
	var reasons: Array[String] = []
	if quote.is_empty(): return ["Implementation queue unavailable; check Finances."]
	if quote.queued or _run.owns_feature(quote.feature_id,_engine_id): return reasons
	if _starter_gate_applies(): reasons.append("Available after first game")
	if not quote.unlocked:
		var offer := _run.get_feature_store_offer(quote.feature_id,_engine_id)
		if offer.is_empty(): offer = _run.get_primitive_reserve_offer(quote.feature_id,_engine_id)
		if not offer.get("missing_parents",[]).is_empty() or not offer.has("year_reached"):
			reasons.append("Locked — " + str(offer.get("prerequisite", "Prerequisite required")))
		if not offer.get("year_reached",true): reasons.append("Locked — Available in %d"%offer.min_year)
		if not offer.get("era_qualified",true): reasons.append("Locked — %d era needs a qualifying Studio-owned release (played Scope meets required Scope)"%offer.era_year)
	if quote.cash_cents < quote.down_cents:
		reasons.append("Need %s to queue" % CashFormatter.format_exact_cents(quote.down_cents))
	var finance: String = _run.get_financial_block_reason() if current_block==null else current_block
	if finance.begins_with("Unpaid bills:"):
		reasons.append("Clear overdue bills to queue")
	elif not finance.is_empty() or not _run.is_cash_initialized():
		reasons.append("Implementation queue unavailable; check Finances.")
	return reasons


func queue_status(quote: Dictionary, current_block: Variant = null) -> String:
	if quote.is_empty(): return "Queue unavailable"
	if quote.head: return "Implementation head"
	if quote.queued: return "Queued"
	if quote.can_admit: return "Queue available"
	var reasons := queue_block_reasons(quote,current_block)
	if reasons.is_empty(): return "Queue unavailable"
	if reasons[0].begins_with("Locked —"): return "Locked"
	if reasons[0].begins_with("Implementation queue unavailable"): return "Queue unavailable"
	return reasons[0]


func _summarize_owned_features() -> Dictionary:
	var scores := {&"graphics": 0, &"sound": 0, &"technology": 0, &"design": 0}
	var scope := 0
	var unpriced_count := 0
	var priced_cards: Array[CardData] = []
	var database := get_node("/root/CardDatabase")
	for id: StringName in _run.get_future_project_feature_ids(_engine_id):
		var card: CardData = database.get_card(id)
		if card == null or card.card_type != &"feature":
			continue
		scope += card.scope
		for entry in card.core_contributions(): scores[entry.stat] += int(entry.value)
		if not _run._feature_offers.has(id):
			priced_cards.append(card)
		elif not _run._feature_offers[id].has("play_cost_cents"):
			unpriced_count += 1
	var cost := _run.primitive_feature_hand_cost_cents(priced_cards)
	return {"scope": scope, "total_score": scores[&"graphics"] + scores[&"sound"] + scores[&"technology"] + scores[&"design"],
		"graphics": scores[&"graphics"], "sound": scores[&"sound"], "technology": scores[&"technology"], "design": scores[&"design"],
		"known_play_cost_cents": cost, "unpriced_count": unpriced_count}


func _build_tree() -> void:
	var entries: Array = _run._feature_definitions.values().filter(func(entry: Dictionary): return FeatureStoreCatalog.is_active(StringName(entry.id)))
	var graph := FeatureStoreCatalog.graph(_run._feature_definitions, _run._feature_offers)
	if graph.has("error"): return
	var children: Dictionary = {}
	for lane: StringName in LANE_ORDER:
		for id: StringName in LANE_MEMBERS[lane]:
			assert(not _lane_by_id.has(id), "Feature appears in two Store lanes: " + str(id))
			_lane_by_id[id] = lane
	for entry: Dictionary in entries:
		var id := StringName(entry.id)
		assert(_lane_by_id.has(id), "Feature missing Store lane: " + str(id))
		var parents: Array = graph.parents[id]
		var parent: StringName = parents[0] if not parents.is_empty() else &""
		if not parent.is_empty():
			if not children.has(parent): children[parent] = []
			children[parent].append(id)
		# Draw local branches only. Cross-category requirements remain in the
		# catalog/AND badge and prerequisite navigation, without long map arrows.
		for required: StringName in parents:
			if _lane_by_id[required]==_lane_by_id[id]: _edges.append([required, id])
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
		if parents.size() > 1: _map.decorate_and_gate(button, parents)
	assert(_nodes.size() == _lane_by_id.size(), "Store lane map does not match ledger")
	_lane_heading = Label.new()
	_lane_heading.position = Vector2(16, 8)
	_tree.add_child(_lane_heading)
	_layout_lane(children)


func _layout_lane(children: Dictionary) -> void:
	_map.layout_map(children)


func _select_lane(lane: StringName) -> void:
	_active_lane = lane
	_map.navigate(lane)


func _draw_connections() -> void:
	_map.draw_core()
	for edge: Array in _edges:
		var path: PackedVector2Array = _map.edge_routes.get(str(edge[0])+"->"+str(edge[1]),PackedVector2Array())
		if path.size()<2: continue
		var end := path[-1]
		var direction := (end-path[-2]).normalized()
		# Lines use the same completed synchronous view as their node labels.
		var offer: Dictionary = _map_offers.get(edge[1],{})
		var color := Color("7ed6be") if offer.get("unlocked", false) else Color("8993a5")
		_tree.draw_polyline(path, color, 3, true)
		var across := direction.orthogonal() * 6.0
		_tree.draw_colored_polygon(PackedVector2Array([end, end - direction * 9.0 + across, end - direction * 9.0 - across]), color)


func play_cost_text(card: CardData) -> String:
	if _run._feature_offers.has(card.id):
		var entry: Dictionary=_run._feature_offers[card.id]
		return CashFormatter.format_exact_cents(int(entry.play_cost_cents)) if entry.has("play_cost_cents") else "TBD"
	var single: Array[CardData] = [card]
	return CashFormatter.format_exact_cents(_run.primitive_feature_hand_cost_cents(single))


func _select_node(id: StringName) -> void:
	if not _nodes.has(id): return # Historical paid queue remains actionable from Implementation.
	_debug_popup.hide()
	_selected = id
	_refresh()
	_map.focus_selection(id)

func _show_details() -> void:
	_map.show_details()
	_refresh_spending_advice()


# The shared top HUD now contains the chart; Store content begins below it.
func get_menu_transition_content() -> Control:
	return _body.get_child(0)


func _refresh_spending_advice() -> void:
	_spending_advice.visible=false
	var owned := _summarize_owned_features()
	var notes := "Known engine-library play cost: %s\n%d Feature%s with play cost TBD. Unknown fees are not zero-cost promises." % [CashFormatter.format_exact_cents(owned.known_play_cost_cents), owned.unpriced_count, "" if owned.unpriced_count == 1 else "s"]
	_debug.tooltip_text = notes + "\n\nClick Debug to keep these notes open."
	_debug_notes.text = notes


func _build_debug_popup() -> void:
	_debug_popup = PanelContainer.new()
	_debug_popup.name = "StoreDebugNotes"
	_debug_popup.add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	add_child(_debug_popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_debug_popup.add_child(box)
	_debug_scroll = ScrollContainer.new()
	_debug_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_debug_scroll)
	_debug_notes = Label.new()
	_debug_notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_debug_notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_debug_notes.add_theme_font_size_override("font_size", 14)
	_debug_scroll.add_child(_debug_notes)
	var dismiss := Button.new()
	dismiss.text = "Close Debug"
	dismiss.pressed.connect(_close_debug)
	box.add_child(dismiss)
	_debug_popup.hide()


func _position_debug() -> void:
	if not is_instance_valid(_debug_popup): return
	_debug_scroll.custom_minimum_size = Vector2(minf(520, size.x - 64), minf(320, size.y - 220))
	_debug_popup.reset_size()
	_debug_popup.position = Vector2(16, maxf(16, _toolbar.get_global_rect().position.y - global_position.y - _debug_popup.size.y - 8))


func _toggle_debug() -> void:
	if _debug_popup.visible:
		_close_debug()
		return
	_map.dismiss()
	_debug_popup.show()
	_debug_popup.move_to_front()
	_position_debug()
	_debug_popup.get_child(0).get_child(1).grab_focus()


func _close_debug() -> void:
	_debug_popup.hide()
	_debug.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and _debug_popup.visible and event.is_action_pressed("ui_cancel"):
		_close_debug()
		get_viewport().set_input_as_handled()


func _purchase() -> void:
	if _run.owns_feature(_selected,_engine_id):return
	var reserve := _run.get_primitive_reserve_offer(_selected,_engine_id)
	if not reserve.is_empty() and reserve.initial:
		_run.purchase_starter_feature(_selected)
		return
	var quote := _run.get_feature_research_quote(_selected,_engine_id)
	if not quote.is_empty() and quote.queued:
		_implement(_selected)
		return
	if quote.is_empty() or not quote.can_admit: return
	if is_instance_valid(_admission_dialog): _admission_dialog.queue_free()
	_admission_dialog = preload("res://scripts/ui/quit_confirmation.gd").new()
	_admission_dialog.ok_button_text = "OK"
	# Match the fixed confirmation surface without retaining an initial autowrap minimum.
	_admission_dialog.wrap_controls = false
	_admission_dialog.min_size = Vector2i(680, 480)
	_admission_dialog.title = "Implement Feature in this engine?"
	_admission_dialog.dialog_text = "Pay %s now (0 cycles). This down payment is irreversible.\nNo cancellation or reordering.\nComplete implementation: %s; 1 productive cycle. Familiarity may reduce the unpaid balance." % [CashFormatter.format_exact_cents(quote.down_cents),CashFormatter.format_exact_cents(quote.due_cents)]
	if _run._feature_offers.get(_selected,{}).has("replaces_id"):
		_admission_dialog.dialog_text += "\n\nUpgrade: completing this Feature replaces 8-Bit Sound in future draws."
	_admission_dialog.dialog_text += "\n\nCompletion makes this Feature available to this engine's future games. A Feature is not guaranteed to be drawn or played."
	_admission_dialog.confirmed.connect(func():
		_run.admit_feature_research(quote)
		_refresh())
	add_child(_admission_dialog)
	_admission_dialog.popup_centered(Vector2i(680, 480))
	_admission_dialog.get_cancel_button().grab_focus()

func _implement(feature: StringName) -> void:
	# Both the selected Feature and top action use a fresh, engine-scoped quote.
	# RunState retains FIFO, affordability and atomic exactly-once settlement.
	var quote := _run.get_feature_research_quote(feature, _engine_id)
	if not quote.is_empty() and quote.can_research and _run.research_feature(quote):
		_refresh()
