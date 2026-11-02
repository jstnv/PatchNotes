extends VBoxContainer
const Clock := preload("res://scripts/calendar/calendar_clock.gd")

var run: RunState
var values: Dictionary={}
var captions: Dictionary={}
var notice_host: Control

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation",16)
	var heading:=FolderUI.label(self,"Your next game starts here.",&"ArcadeHeading")
	heading.theme_type_variation=&"HeadingLabel"
	heading.add_theme_font_size_override("font_size",38)
	var cards:=HBoxContainer.new();cards.add_theme_constant_override("separation",14);add_child(cards)
	for title in ["Cash","Fans","Next Bill"]:
		var card:=FolderUI.surface(cards);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var box:=VBoxContainer.new();card.add_child(box)
		var label:=FolderUI.label(box,title,&"HeadingLabel");label.add_theme_font_size_override("font_size",26);label.add_theme_color_override("font_color",Color("5EF2C2"))
		values[title]=FolderUI.label(box,"—",&"ArcadeValue")
		values[title].add_theme_font_size_override("font_size",36)
		values[title].autowrap_mode=TextServer.AUTOWRAP_OFF
		values[title].clip_text=true
		values[title].text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		values[title].resized.connect(_fit_values)
		captions[title]=FolderUI.label(box,"",&"MetadataLabel");captions[title].add_theme_font_size_override("font_size",12)
	var surface:=FolderUI.surface(self);surface.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var desk:=TextureRect.new();desk.texture=preload("res://assets/ui/arcade/studio_desk.svg")
	desk.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;desk.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	desk.custom_minimum_size.y=170;desk.mouse_filter=Control.MOUSE_FILTER_IGNORE;surface.add_child(desk)
	notice_host=Control.new();notice_host.name="OverviewNoticeHost";notice_host.mouse_filter=Control.MOUSE_FILTER_IGNORE;surface.add_child(notice_host)
	refresh()

func bind_run(value: RunState) -> void:
	if run==value:return
	if run!=null:
		for event in [run.cash_changed,run.fans_changed,run.finance_changed,run.calendar_changed]:
			if event.is_connected(refresh):event.disconnect(refresh)
	run=value
	if run!=null:
		for event in [run.cash_changed,run.fans_changed,run.finance_changed,run.calendar_changed]:event.connect(refresh)
	refresh()

func refresh() -> void:
	if run==null or values.is_empty():return
	var report:=run.get_studio_finance_report()
	var bankroll:=run.get_cash_cents()-maxi(0,int(report.get("total_overdue_cents",0)))
	values.Cash.text="∞" if run.get_meta(&"debug_unlimited_cash",false) else preload("res://scripts/ui/cash_feedback.gd").amount(bankroll)
	values.Fans.text=str(run.get_fans())
	values["Next Bill"].text=CashFormatter.format_exact_cents(report.get("monthly_rent_cents",0)) if report.get("available",false) else "—"
	captions["Next Bill"].text="Rent · month %d end" % (Clock.month(int(report.get("next_due_cycle",0))-1,run.get_calendar_profile())) if report.get("available",false) else "Unavailable"
	captions.Cash.text="Available cash";captions.Fans.text="Studio fans"
	values["Next Bill"].tooltip_text="Next rent installment. Cash → Finances lists payroll, loans and all outstanding bills."
	_fit_values()

func _fit_values() -> void:
	for label:Label in values.values():
		var font:=label.get_theme_font("font")
		var width:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,36).x
		label.add_theme_font_size_override("font_size",clampi(int(36.0*label.size.x/maxf(1,width)),18,36))
		if label!=values.get("Next Bill"):label.tooltip_text=label.text
