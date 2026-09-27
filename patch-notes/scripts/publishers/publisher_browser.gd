class_name PublisherBrowser
extends PanelContainer

signal closed

var _run: RunState
var _list: ItemList
var _details: RichTextLabel
var _selected_id: StringName


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var heading := HBoxContainer.new()
	layout.add_child(heading)
	var title := Label.new()
	title.text = "Publisher List"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 26)
	heading.add_child(title)
	var back := Button.new()
	back.name = "ClosePublisherBrowser"
	back.text = "Back to Studio"
	back.custom_minimum_size = Vector2(165, 44)
	back.pressed.connect(func(): closed.emit())
	heading.add_child(back)
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
	_details.text = "%s\n\n%s\n\nPrerequisite: %s\n\n%s\n\n%s" % [
		status.name, "Unlocked" if status.unlocked else "Locked", status.requirement,
		status.personality, availability]
