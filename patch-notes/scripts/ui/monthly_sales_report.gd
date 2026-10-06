class_name MonthlySalesReport
extends PanelContainer

signal closed
var _run: RunState
var _ids: Array[StringName] = []
var _selected_id: StringName
var _report: Dictionary = {}
var _titles: OptionButton
var _totals: Label
var _forecast: Label
var _table: Tree
var _detail: RichTextLabel


func _ready() -> void:
	theme = preload("res://resources/ui/workspace_theme.tres")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "Monthly Sales"
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	_titles = OptionButton.new()
	_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titles.clip_text = true
	_titles.item_selected.connect(func(index: int):
		_selected_id = _ids[index]
		refresh())
	header.add_child(_titles)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back to Summary"
	back.pressed.connect(func(): hide(); closed.emit())
	header.add_child(back)
	var explanation := Label.new()
	explanation.text = "Actual earnings by release age · Titles earn concurrently · Zero units means dormant, not expired."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(explanation)
	_totals = Label.new()
	_totals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_totals)
	_table = Tree.new()
	_table.name = "MonthlyRows"
	_table.columns = 6
	_table.hide_root = true
	_table.column_titles_visible = true
	_table.select_mode = Tree.SELECT_ROW
	_table.custom_minimum_size.y = 120
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in range(6): _table.set_column_title(i, ["Age month", "Units", "Gross earned", "Net earned", "Paid", "Unpaid"][i])
	_table.item_selected.connect(_show_month)
	layout.add_child(_table)
	_detail = RichTextLabel.new()
	_detail.name = "MonthDetail"
	_detail.custom_minimum_size.y = 155
	_detail.scroll_active = true
	layout.add_child(_detail)
	_forecast = Label.new()
	_forecast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_forecast)
	if OS.has_feature("editor") and ResourceLoader.exists("res://scripts/debug/lifespan_capture.gd"):
		var capture := Button.new()
		capture.text = "Save local playtest capture (editor only)"
		capture.tooltip_text = "Writes this run's frozen sales inputs and actual monthly history locally. No upload or future simulation."
		capture.pressed.connect(func():
			var exporter = load("res://scripts/debug/lifespan_capture.gd")
			_detail.text = exporter.save_capture(_run))
		layout.add_child(capture)


func setup(run: RunState, release_id: StringName) -> void:
	_run = run
	_selected_id = release_id
	_ids = run.get_released_game_ids()
	_titles.clear()
	for id in _ids: _titles.add_item(run.get_released_game_display_name(id))
	_titles.select(_ids.find(release_id))
	refresh()
	if not run.sales_changed.is_connected(_on_sales_changed): run.sales_changed.connect(_on_sales_changed)


func _on_sales_changed() -> void:
	if visible: refresh()


func refresh() -> void:
	var prior := _table.get_selected()
	var selected_month: int = prior.get_metadata(0) if prior != null else -1
	_report = _run.get_released_game_monthly_report(_selected_id)
	_table.clear()
	_detail.text = ""
	_forecast.text = ""
	if _report.is_empty():
		_totals.text = "Monthly history unavailable: the stored release provenance could not be reconciled."
		return
	_totals.text = "Lifetime: %d units · Gross %s · Net %s · Paid %s · Unpaid %s" % [_report.units, _money(_report.gross_cents), _money(_report.net_cents), _money(_report.settled_cents), _money(_report.unpaid_cents)]
	var root := _table.create_item()
	var selection: TreeItem
	for row: Dictionary in _report.rows:
		var item := _table.create_item(root)
		item.set_metadata(0, row.age_month)
		item.set_text(0, "%d%s%s" % [row.age_month, " (partial)" if row.earned_halves < 2 else "", " *" if row.campaign else ""])
		item.set_text(1, str(row.units))
		for i in range(4): item.set_text(i + 2, _money(row[["gross_cents", "net_cents", "settled_cents", "unpaid_cents"][i]]))
		item.set_tooltip_text(0, "* Campaign this age month. Select a row for earning slices, Awareness and exact payment boundaries.")
		if selection == null or selected_month == row.age_month or selected_month < 0: selection = item
	if selection != null:
		selection.select(0)
		_table.ensure_cursor_is_visible()
		_show_month()
	else:
		_detail.text = "No sales earned yet. Month 1 earns over the next two productive actions; launch itself pays nothing."
	var forecast: Dictionary = _report.forecast
	if not forecast.is_empty():
		_forecast.text = "Forecast only · Age month %d, next half %d · %d units for the full age month.\nForecast units are not earned cash. Paid columns exclude campaign fees and other Studio spending." % [forecast.next_age_month, forecast.next_age_cycle, forecast.projected_month_units]


func _show_month() -> void:
	var item := _table.get_selected()
	if item == null or _report.is_empty(): return
	var row: Dictionary = _report.rows[int(item.get_metadata(0)) - 1]
	var lines: Array[String] = ["Age month %d · %d / 2 earning halves · %s" % [row.age_month, row.earned_halves, "Partial actual earnings" if row.earned_halves < 2 else "Complete"],
		"Organic Awareness %.4f · Active Awareness %.4f · %s" % [row.organic_awareness_scaled / 10000.0, row.active_awareness_scaled / 10000.0, "Campaign #%d (*)" % row.campaign_number if row.campaign else "No campaign"]]
	if row.units == 0 and row.earned_halves == 2: lines.append("Dormant this month: zero units. Future campaigns may revive this title.")
	for slice: Dictionary in row.slices:
		lines.append("Half %d · %s · +%d units · net +%s" % [slice.half, _calendar(slice.run_cycle), slice.units, _money(slice.net_cents)])
	for payment: Dictionary in row.payments:
		lines.append("Paid %s at %s (calendar-month boundary)" % [_money(payment.cents), _calendar(payment.run_cycle)])
	if row.unpaid_cents > 0: lines.append("Unpaid %s: waiting for a calendar-month settlement." % _money(row.unpaid_cents))
	_detail.text = "\n".join(lines)


static func _calendar(cycle: int) -> String:
	return "%d · Month %d %s · cycle %d" % [RunState.START_YEAR + cycle / 24, cycle / 2 + 1, "First Half" if cycle % 2 == 0 else "Second Half", cycle]


static func _money(cents: int) -> String:
	return CashFormatter.format_exact_cents(cents)
