class_name PublisherBrowser
extends PanelContainer

signal closed
signal commission_requested
signal support_requested

var _run: RunState
var _list: ItemList
var _details: RichTextLabel
var _selected_id: StringName
var _commission_button: Button
var _support_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var title := Label.new()
	title.text = "Publisher List"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.theme_type_variation=&"HeadingLabel"
	title.add_theme_font_size_override("font_size", 26)
	heading.add_child(title)
	var back := Button.new()
	back.name = "ClosePublisherBrowser"
	back.text = "Back to Studio"
	back.custom_minimum_size = Vector2(165, 44)
	back.pressed.connect(func(): closed.emit())
	heading.add_child(back)
	FolderUI.standard_back(back)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	layout.add_child(columns)
	_list = ItemList.new()
	_list.name = "PublisherEntries"
	_list.custom_minimum_size = Vector2(290, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_selected)
	columns.add_child(_list)
	_details = RichTextLabel.new()
	_details.name = "PublisherDetails"
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(_details)
	_commission_button = Button.new()
	_commission_button.name = "PrepareSideStreetCommission"
	_commission_button.text = "Prepare SideStreet commission"
	_commission_button.custom_minimum_size.y = 44
	_commission_button.pressed.connect(func(): commission_requested.emit())
	layout.add_child(_commission_button)
	_support_button = Button.new()
	_support_button.name = "PrepareSideStreetSupport"
	_support_button.text = "Prepare SideStreet support"
	_support_button.custom_minimum_size.y = 44
	_support_button.pressed.connect(func(): support_requested.emit())
	layout.add_child(_support_button)
	if _run != null:
		_refresh()


func setup(run: RunState) -> bool:
	if run == null:
		return false
	_run = run
	if is_node_ready():
		_refresh()
	return true


func open_browser() -> void:
	if _run == null:
		return
	_refresh()
	show()
	_list.grab_focus()


func _refresh() -> void:
	_list.clear()
	var entries := PublisherCatalog.entries()
	for entry: Dictionary in entries:
		var status := _run.get_publisher_status(entry.id)
		_list.add_item("%s  [%s]" % [entry.name, "Unlocked" if status.unlocked else "Locked"])
	if entries.is_empty():
		return
	var index := 0
	for candidate in range(entries.size()):
		if entries[candidate].id == _selected_id:
			index = candidate
			break
	_list.select(index)
	_on_selected(index)


func _on_selected(index: int) -> void:
	var entries := PublisherCatalog.entries()
	if index < 0 or index >= entries.size():
		return
	_selected_id = entries[index].id
	var status := _run.get_publisher_status(_selected_id)
	var availability: String = status.availability
	if _selected_id == PublisherCatalog.IRONCLAD and status.unlocked:
		var contract := _run.get_primitive_contract()
		if contract != null:
			availability = "Balanced Primitive Contract completed." if contract.is_completed() else "Balanced Primitive Contract in progress. Resume it from Contracts."
		else:
			availability = "Balanced Primitive Contract available from Contracts."
	elif _selected_id == PublisherCatalog.SIDESTREET and status.unlocked:
		var active := _run.get_active_contract()
		if active != null and active.get_contract_id() == ContractState.SIDESTREET_CONTRACT_ID:
			availability = "SideStreet Contract in progress. Resume it from Contracts."
		elif _run.is_sidestreet_offer_available():
			availability = "%d release-linked offer(s) exist. The next offer is available from Contracts." % (_run.get_sidestreet_offer_ids().size() - _run.get_sidestreet_completion_history().size())
		else:
			availability = "No pending SideStreet offer. Each new release creates one."
	_details.text = "%s\n\n%s\n\nPrerequisite: %s\n\n%s\n\n%s" % [
		status.name, "Unlocked" if status.unlocked else "Locked", status.requirement,
		status.personality, availability]
	var relationships := _run.get_publisher_relationships()
	var standing: Dictionary = relationships.get(_selected_id,{"reputation_bp":0,"investment_bp":0})
	_details.text += "\n\nReputation %.2f / 100 · Investment %.2f / 100" % [standing.reputation_bp/100.0,standing.investment_bp/100.0]
	_commission_button.visible = _selected_id == PublisherCatalog.SIDESTREET
	_support_button.visible = _selected_id == PublisherCatalog.SIDESTREET
	_support_button.disabled = _run.get_support_quote("Support preview",&"sports",&"fantasy").is_empty()
	if _selected_id == PublisherCatalog.SIDESTREET:
		_details.text += "\n\nSupport: Investment15+. Studio-owned title, upfront funding and launch marketing, title-only capped20% recoup through earning cycle24. Assessment at earning cycle6: Review7.0 AND1,000 units. Renew after a new qualifying support success or full commission; a miss alone does not renew."
	_commission_button.disabled = standing.reputation_bp < 2000 or _run.has_pending_commission() or _run.get_active_contract() != null or _run.get_released_game_ids().is_empty() or _run.ContractSearch.invitation(_run).is_empty()
	if _selected_id == PublisherCatalog.SIDESTREET:
		_details.text += "\nReputation Briefs are separate from cash Contracts: two hands, up to 10 Reputation, no cash or Promotion. Find repeatable work through Contracts → Search. Each successful search costs one productive cycle.\nAt Reputation 20 with a released game, search for a commission invitation, then prepare it. Access does not spend standing. Choose its name, Genre and Theme to see exact Scope and terms.\nFull delivery pays $6,000 and requests +15 Reputation / +15 Investment, capped independently. Publisher owns sales; raw units and Fans remain.\nInvestment15 unlocks the optional support package above, subject to earned renewal and legal funded-start checks."
