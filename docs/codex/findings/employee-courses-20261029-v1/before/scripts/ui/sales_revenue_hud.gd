class_name SalesRevenueHUD
extends PanelContainer

const WIDTH := 216.0
const ANIMATION_SECONDS := 0.65

class RevenueBars extends Control:
	var rows: Array = []
	var displayed := {}
	var peak := 1.0
	func _draw() -> void:
		var baseline := size.y - 1.0
		draw_line(Vector2(0,baseline), Vector2(size.x,baseline), Color("6e626a"), 1.0)
		for i in range(rows.size()):
			var column := size.x / SalesRevenueModel.WINDOW_MONTHS
			var height := clampf(float(displayed.get(rows[i].month,0.0)) / peak,0.0,1.0) * (baseline - 2.0)
			var color := Color("f5bd59") if rows[i].partial else Color("79d4da")
			if height > 0.0:
				draw_rect(Rect2(Vector2(i * column,baseline-height),Vector2(maxf(2,column-2),height)),color)
	func _get_tooltip(at_position: Vector2) -> String:
		var index := floori(at_position.x / maxf(1,size.x / SalesRevenueModel.WINDOW_MONTHS))
		if index < 0 or index >= rows.size(): return "Calendar months, oldest to newest; shared vertical scale."
		var row: Dictionary = rows[index]
		return "Month %d%s\nSales revenue earned: %s" % [row.month," (in progress)" if row.partial else "",CashFormatter.format_exact_cents(row.cents)]

var run: RunState
var model: Dictionary = {}
var chart: RevenueBars
var heading: Label
var month_label: Label
var total_label: Label
var active_context := false
var _refresh_pending := false
var _from := {}
var _target := {}
var _elapsed := ANIMATION_SECONDS

func _ready() -> void:
	name = "SalesRevenueHUD"
	custom_minimum_size.x = WIDTH
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# The persistent top HUD supplies the surface and border.
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",2)
	add_child(box)
	heading = _label(box,13)
	heading.add_theme_color_override("font_color",Color("f5bd59"))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation",8)
	box.add_child(body)
	chart = RevenueBars.new()
	chart.custom_minimum_size = Vector2(84,32)
	chart.tooltip_text = "Monthly sales revenue"
	body.add_child(chart)
	var amounts := VBoxContainer.new()
	amounts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amounts.add_theme_constant_override("separation",0)
	body.add_child(amounts)
	month_label = _label(amounts,14)
	total_label = _label(amounts,14)
	set_process(false)
	hide()

func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size",font_size)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label

func bind_run(value: RunState) -> void:
	if value == run: return
	if run != null:
		for event in [&"sales_changed",&"calendar_changed"]:
			if run.is_connected(event,_queue_refresh): run.disconnect(event,_queue_refresh)
	run = value
	if run != null:
		for event in [&"sales_changed",&"calendar_changed"]: run.connect(event,_queue_refresh)
	_refresh(false)

func set_context(enabled: bool) -> void:
	active_context = enabled
	visible = enabled and not model.is_empty() and model.market_count > 0

func _queue_refresh() -> void:
	if _refresh_pending: return
	_refresh_pending = true
	_refresh.call_deferred(true)

func _refresh(animate: bool) -> void:
	_refresh_pending = false
	var next := SalesRevenueModel.read(run)
	if next == model and animate: return
	model = next
	_target.clear()
	_from.clear()
	chart.rows = model.get("rows",[])
	chart.peak = 1.0
	for row: Dictionary in chart.rows:
		_target[row.month] = float(row.cents)
		_from[row.month] = float(chart.displayed.get(row.month,0.0)) if animate else float(row.cents)
		chart.peak = maxf(chart.peak,maxf(_target[row.month],_from[row.month]))
	_elapsed = 0.0 if animate else ANIMATION_SECONDS
	_apply_animation()
	set_process(animate and _target != _from)
	set_context(active_context)
	if model.is_empty(): return
	heading.text = "GAME SALES  ·  %d on market" % model.market_count
	month_label.text = "M%d %s" % [model.current_month,_compact_money(model.current_cents)]
	total_label.text = "Total %s" % _compact_money(model.total_cents)
	tooltip_text = "Sales revenue after the store share, before Studio expenses.\nMonth %d so far: %s\nAll-time earned: %s\nPaid: %s · Awaiting settlement: %s\nLast %d calendar months; amber is the current month.\nSales advance with productive cycles. Zero-sales titles stay on market and can revive with campaigns." % [model.current_month,CashFormatter.format_exact_cents(model.current_cents),CashFormatter.format_exact_cents(model.total_cents),CashFormatter.format_exact_cents(model.settled_cents),CashFormatter.format_exact_cents(model.unpaid_cents),chart.rows.size()]
	for label in [heading,month_label,total_label]: label.tooltip_text = tooltip_text

func _process(delta: float) -> void:
	_elapsed = minf(ANIMATION_SECONDS,_elapsed+delta)
	_apply_animation()
	if _elapsed >= ANIMATION_SECONDS: set_process(false)

func _apply_animation() -> void:
	var fraction := _elapsed / ANIMATION_SECONDS
	var eased := 1.0 - pow(1.0 - fraction,3.0)
	chart.displayed.clear()
	for month in _target: chart.displayed[month] = lerpf(_from[month],_target[month],eased)
	chart.queue_redraw()

static func _compact_money(cents: int) -> String:
	for unit in [[100000000000,&"b"],[100000000,&"m"],[100000,&"k"]]:
		if cents >= unit[0]: return "$%d.%d%s" % [cents / int(unit[0]), (cents % int(unit[0])) * 10 / int(unit[0]),unit[1]]
	return CashFormatter.format_exact_cents(cents)
