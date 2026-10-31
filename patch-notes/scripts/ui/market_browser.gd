class_name MarketBrowser
extends PanelContainer

signal closed
const Model := preload("res://scripts/ui/market_browser_model.gd")
var run: RunState
var world: RivalWorld
var rows: Array = []
var filter: OptionButton
var games: Tree
var details: RichTextLabel
var status: Label
var back_button: Button
var _selected := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	theme = preload("res://resources/ui/workspace_theme.tres")
	var margin := MarginContainer.new()
	for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Market & History"
	title.add_theme_font_size_override("font_size",24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	filter = OptionButton.new()
	filter.name = "MarketFilter"
	for choice in ["All Studios","Your Studio","AI Studios"]: filter.add_item(choice)
	filter.item_selected.connect(func(_index): refresh())
	header.add_child(filter)
	back_button = Button.new()
	back_button.text = "Back to Studio"
	back_button.pressed.connect(close)
	header.add_child(back_button)
	FolderUI.standard_back(back_button)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	games = Tree.new()
	games.name = "MarketGames"
	games.columns = 5
	games.hide_root = true
	games.column_titles_visible = true
	games.select_mode = Tree.SELECT_ROW
	games.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in range(5):
		games.set_column_title(i,["Game","Studio","Genre","Review","Units sold"][i])
		games.set_column_custom_minimum_width(i,[220,190,110,75,95][i])
		games.set_column_expand(i,i<2)
	games.item_selected.connect(_show_selection)
	layout.add_child(games)
	details = RichTextLabel.new()
	details.name = "MarketDetails"
	details.custom_minimum_size.y = 120
	details.scroll_active = true
	layout.add_child(details)
	var note := Label.new()
	note.text = "Live releases first · Sales are actual, not forecasts. Dormant games remain on market.\nHistorical records follow by year. They earn no post-start sales or Fans and do not affect the active Market."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size",14)
	layout.add_child(note)
	hide()

func open(current_run: RunState, current_world: RivalWorld) -> void:
	run = current_run
	world = current_world
	show()
	refresh()
	back_button.grab_focus()

func close() -> void:
	hide()
	closed.emit()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and MenuTransitions.navigation_input_blocked(self):get_viewport().set_input_as_handled();return
	# Cancel belongs to this overlay before a Tree or hover tooltip consumes it.
	var controller_back: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if is_visible_in_tree() and (event.is_action_pressed("ui_cancel") or controller_back):
		close()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	var result := Model.query(run,world)
	games.clear()
	rows.clear()
	if not result.ok:
		status.text = str(result.reason)
		details.text = "Return to Studio to continue playing."
		return
	var all_rows: Array = result.rows
	var historical_rows: Array = result.historical_rows
	for row: Dictionary in all_rows+historical_rows:
		if filter.selected == 1 and not row.player_owned: continue
		if filter.selected == 2 and row.player_owned: continue
		rows.append(row)
	status.text = "%d games shown · %d live releases · %d historical records across all Studios" % [rows.size(),all_rows.size(),historical_rows.size()]
	var tree_root := games.create_item()
	var selected_item: TreeItem
	for row: Dictionary in rows:
		var item := games.create_item(tree_root)
		item.set_metadata(0,_key(row))
		var owner := str(row.studio_name) + (" (you)" if row.player_owned else " (AI)")
		var historical: bool = row.get("record_type","") == "historical"
		var title := "Historical · %d · %s" % [row.release_year,row.release_title] if historical else str(row.release_title)
		var units := "—" if historical else str(row.earned_units)
		var values := [title,owner,_name("genres",row.genre),"%.1f / 10" % (row.review_tenths/10.0),units]
		for i in range(values.size()):
			item.set_text(i,str(values[i]))
			item.set_tooltip_text(i,str(values[i]))
		if _key(row) == _selected: selected_item = item
	if selected_item == null: selected_item = tree_root.get_first_child()
	if selected_item != null:
		selected_item.select(0)
		_show_selection()
	else:
		_selected = ""
		details.text = "No live releases or historical records in this view. Launch a game or choose another Studio filter."

func _show_selection() -> void:
	var item := games.get_selected()
	if item == null: return
	_selected = str(item.get_metadata(0))
	for row: Dictionary in rows:
		if _key(row) != _selected: continue
		if row.get("record_type","") == "historical":
			details.text = "%s — %s\nHistorical record · Released %d · Final Review %.1f / 10\n%s / %s\nHistorical sales data is unavailable. This frozen pre-1980 title earns no post-start sales or Fans and does not affect active Market standards or saturation." % [row.release_title,row.studio_name,row.release_year,row.review_tenths/10.0,_name("genres",row.genre),_name("themes",row.theme)]
			return
		var cores := "Core scores unavailable for this older release."
		if row.cores_available:
			cores = "Graphics %d · Sound %d · Technology %d · Design %d" % row.cores
		details.text = "%s — %s\n%s / %s · Released %d, cycle %d · Final Review %.1f / 10\n%s\nActual sales: %d units · Earned net %s · Paid %s\nEarned net is after platform share and before Studio expenses; unpaid earnings are not spendable cash." % [row.release_title,row.studio_name,_name("genres",row.genre),_name("themes",row.theme),row.release_year,row.release_cycle,row.review_tenths/10.0,cores,row.earned_units,_money(row.entitlement_cents),_money(row.settled_cents)]
		if row.get("publisher_owned",false): details.text += "\nPublisher-owned commission: values above are RAW TITLE sales. Studio entitlement and sales paid: $0.00; the separate fee is in Finances."
		if row.has("support"):
			details.text += "\nSupported Studio-owned title: values above are RAW TITLE sales. Studio entitlement %s; paid %s; recoup %s / %s through earning cycle24." % [_money(row.support.rights.studio_earned_cents),_money(row.support.rights.studio_settled_cents),_money(row.support.rights.publisher_recoup_cents),_money(row.support.terms.budget_cents)]
		return

static func _key(row: Dictionary) -> String:
	return JSON.stringify([row.get("record_type","live"),str(row.studio_id),str(row.release_id)])

static func _name(kind: String, id: String) -> String:
	return str(PrimitivePredevelopment.find_entry(kind,StringName(id)).get("name",id))

static func _money(cents: int) -> String:
	return "$%d.%02d" % [cents/100,cents%100]
