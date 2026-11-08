class_name PredevelopmentOverlay
extends PanelContainer

signal begin_requested(base_name: String, genre: StringName, theme: StringName)
signal cancelled

var name_input: LineEdit
var genre_input: OptionButton
var theme_input: OptionButton
var error_label: Label
var begin_button: Button
var back_button: Button
var priority_sliders: Array[HSlider] = []
var priority_labels: Array[Label] = []
var priority_total: Label
var priority_chart: PriorityInfluenceChart
var budget_feedback: PriorityBudgetFeedback
var genre_targets_label: Label
var engine_label: Label
var engine_picker: VBoxContainer
var market_run: RunState
var commission_mode := false
var support_mode := false
var _support_quote: Dictionary = {}
var _support_confirmation: ConfirmationDialog
var _support_terms: RichTextLabel
var _commission_quote: Dictionary = {}
var _commission_confirmation: ConfirmationDialog
var _commission_terms: RichTextLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var shell := VBoxContainer.new()
	margin.add_child(shell)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	scroll.add_child(layout)
	var heading:=HBoxContainer.new();layout.add_child(heading)
	var title:=_add_label(heading,"Pre-Development",26)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_add_label(layout, "Set up your game. These choices are locked when development begins.", 16)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	layout.add_child(columns)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 8)
	columns.add_child(identity)
	var priorities := VBoxContainer.new()
	priorities.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priorities.size_flags_stretch_ratio = 1.5
	priorities.add_theme_constant_override("separation", 8)
	columns.add_child(priorities)
	_add_label(identity, "Game name", 16)
	name_input = LineEdit.new()
	name_input.name = "GameName"
	name_input.placeholder_text = "Enter a game name"
	name_input.tooltip_text = "Give this game a name. You can edit it until development begins."
	identity.add_child(name_input)
	_add_label(identity, "Genre", 16)
	genre_input = _add_options(identity, "genres")
	genre_input.tooltip_text = "Genre sets the Core targets used in this game's production rating."
	_add_label(identity, "Theme", 16)
	theme_input = _add_options(identity, "themes")
	theme_input.tooltip_text = "Genre and Theme determine which other releases crowd this game's future sales."
	engine_picker=preload("res://scripts/ui/engine_picker.gd").new()
	identity.add_child(engine_picker)
	engine_picker.selection_changed.connect(func(_id: StringName):
		_commission_quote={};_support_quote={}
		if is_instance_valid(_commission_confirmation):_commission_confirmation.hide()
		if is_instance_valid(_support_confirmation):_support_confirmation.hide()
		error_label.text="";_refresh_engine())
	engine_label = _add_label(identity,"",15)
	engine_label.name = "SelectedEngine"
	genre_targets_label = _add_label(identity, "", 15)
	genre_targets_label.name = "GenreTargets"
	genre_input.item_selected.connect(func(_index: int): _refresh_genre_targets())
	_refresh_genre_targets()
	_add_label(priorities, "Initial Design priorities", 20)
	_add_label(priorities, "Priorities weight future draws, not scores.\nAllocate 100 total in steps of 5, within the ranges shown.", 14)
	priorities.tooltip_text = "Graphics: visuals. Sound: audio. Tech: systems. Design: gameplay. Core scores measure quality; Scope measures how much game you build."
	var priority_body := HBoxContainer.new()
	priority_body.add_theme_constant_override("separation", 16)
	priorities.add_child(priority_body)
	var priority_controls := VBoxContainer.new()
	priority_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priority_controls.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	priority_controls.add_theme_constant_override("separation", 14)
	priority_body.add_child(priority_controls)
	for i in range(4):
		var row := HBoxContainer.new()
		priority_controls.add_child(row)
		var value := _add_label(row, "", 16)
		value.custom_minimum_size.x = 102
		value.add_theme_color_override("font_color", PriorityInfluenceChart.CORE_COLORS[i])
		priority_labels.append(value)
		var slider := HSlider.new()
		slider.min_value = 10
		slider.max_value = PriorityAllocation.MAX_PRIORITY
		slider.step = 5
		slider.value = 25
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 100
		row.add_child(slider)
		priority_sliders.append(slider)
		slider.value_changed.connect(func(_value: float): _refresh_priorities())
	priority_chart = PriorityInfluenceChart.new()
	priority_body.add_child(priority_chart)
	priority_chart.bind_controls(priority_sliders, PriorityInfluenceChart.CORE_NAMES, PriorityInfluenceChart.CORE_COLORS)
	budget_feedback = PriorityBudgetFeedback.new()
	add_child(budget_feedback)
	budget_feedback.bind_controls(priority_sliders)
	priority_total = _add_label(priorities, "", 16)
	_add_label(layout, "Begin Development: 1 calendar cycle • New project starts at cycle 0 • No cash required\nEditing or cancelling: 0 cycles • Genre/Theme crowding affects future sales", 16)
	error_label = _add_label(layout, "", 16)
	error_label.add_theme_color_override("font_color", Color("ffc779"))
	var actions := HBoxContainer.new()
	shell.add_child(actions)
	begin_button = Button.new()
	begin_button.name = "BeginDevelopment"
	begin_button.text = "Begin Development"
	begin_button.tooltip_text = "Locks this game's name, Genre and Theme and advances one calendar cycle."
	begin_button.custom_minimum_size = Vector2(240, 44)
	begin_button.pressed.connect(_confirm)
	actions.add_child(begin_button)
	var back := Button.new()
	back_button = back
	back.name = "CancelPredevelopment"
	back.text = "Back to Studio"
	back.tooltip_text = "Return to Studio without spending cash or advancing time."
	back.custom_minimum_size = Vector2(180, 44)
	back.pressed.connect(func(): cancelled.emit())
	heading.add_child(back)
	FolderUI.standard_back(back)
	_refresh_priorities()
	name_input.text_changed.connect(func(_text: String): error_label.text = "")

func _add_label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation=&"HeadingLabel" if font_size>=20 else &"Label"
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _add_options(parent: Node, kind: String) -> OptionButton:
	var options := OptionButton.new()
	options.name = kind.capitalize()
	for entry: Dictionary in PrimitivePredevelopment.catalog()[kind]:
		options.add_item(entry.name)
		options.set_item_metadata(options.item_count - 1, StringName(entry.id))
	parent.add_child(options)
	return options

func open() -> void:
	var values: Dictionary=PriorityAllocation.editable_distribution(get_initial_priorities(),market_run)
	var limits:=PriorityAllocation.bounds(market_run)
	for index in priority_sliders.size():
		priority_sliders[index].min_value=limits.x;priority_sliders[index].max_value=limits.y
		priority_sliders[index].set_value_no_signal(values[index])
	_refresh_priorities()
	_commission_quote = {}
	_support_quote = {}
	begin_button.text = "Review commission quote" if commission_mode else "Begin Development"
	if support_mode: begin_button.text = "Review support quote"
	error_label.text = ""
	_refresh_genre_targets()
	_refresh_engine()
	show()
	name_input.grab_focus()

func _refresh_genre_targets() -> void:
	var profile := PrimitiveReviewCalculator.get_genre_profile(genre_input.get_selected_metadata())
	if profile == null: genre_targets_label.text = ""; return
	genre_targets_label.text = "Core targets\nGraphics %d · Sound %d\nTechnology %d · Design %d\n\nAll targets: 8/10 production.\n125%% of each: 10/10.\nScope and Bugs affect the final Review." % [profile.get_standard(0), profile.get_standard(1), profile.get_standard(2), profile.get_standard(3)]
	if market_run != null and market_run._market_provider.is_valid():
		var market: Dictionary=market_run._market_provider.call(market_run._bank_run_id,market_run.get_completed_run_cycles()+1)
		var details: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").targets(market,str(market_run._bank_run_id),genre_input.get_selected_metadata())
		genre_targets_label.text=preload("res://scripts/market/market_transaction_trial.gd").describe(details).replace("frozen at project start","preview for next project")+"\nOrder: Graphics / Sound / Tech / Design.\nAll final targets: 8/10 production; 125%: 10/10."

func _refresh_engine() -> void:
	engine_picker.bind(market_run)
	engine_label.text="The engine and configured pool freeze when development begins. Change the selection here before Begin." if market_run!=null else ""

func get_initial_priorities() -> Dictionary:
	var result := {}
	for i in range(priority_sliders.size()): result[i] = int(priority_sliders[i].value)
	return result

func _refresh_priorities() -> void:
	var total := 0
	for i in range(priority_sliders.size()):
		var value := int(priority_sliders[i].value)
		total += value
		priority_labels[i].text = "%s: %d" % [["Graphics", "Sound", "Tech", "Design"][i], value]
	priority_total.text = "%d/100" % total
	if begin_button != null: begin_button.disabled = total != 100
	if total == 100 and error_label != null and error_label.text == "Allocate exactly 100 priority points before beginning.": error_label.text = ""

func _confirm() -> void:
	if not PriorityAllocation.is_valid_new_distribution(get_initial_priorities(), market_run):
		error_label.text = "Allocate exactly 100 priority points before beginning."
		return
	var genre: StringName = genre_input.get_selected_metadata()
	var selected_theme: StringName = theme_input.get_selected_metadata()
	error_label.text = PrimitivePredevelopment.validation_error(name_input.text, genre, selected_theme)
	if not error_label.text.is_empty():
		name_input.grab_focus()
		return
	if commission_mode:
		_review_commission()
		return
	elif support_mode:
		_review_support()
		return
	begin_requested.emit(name_input.text.strip_edges(), genre, selected_theme)

func get_confirmed_commission_quote() -> Dictionary:
	return _commission_quote.duplicate(true) if commission_mode else {}

func get_confirmed_support_quote() -> Dictionary:
	return _support_quote.duplicate(true) if support_mode else {}

func _review_support() -> void:
	_support_quote = {} if market_run == null else market_run.get_support_quote(name_input.text,genre_input.get_selected_metadata(),theme_input.get_selected_metadata())
	if _support_quote.is_empty():
		error_label.text = "Support unavailable. Need Investment 15, a released game and a resolved prior support assessment with a new qualifying success."
		return
	if _support_confirmation == null:
		_support_confirmation = preload("res://scripts/ui/quit_confirmation.gd").new()
		_support_confirmation.name = "SupportConfirmation"
		_support_confirmation.title = "Confirm SideStreet support"
		_support_confirmation.ok_button_text = "Accept and begin (1 cycle)"
		_support_confirmation.cancel_button_text = "Keep editing"
		_support_confirmation.theme = preload("res://resources/ui/onyx_theme.tres")
		add_child(_support_confirmation)
		_support_terms = RichTextLabel.new()
		_support_terms.name = "SupportTerms"
		_support_terms.custom_minimum_size = Vector2(0,350)
		_support_terms.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_support_terms.add_theme_font_size_override("normal_font_size",16)
		_support_confirmation.add_content(_support_terms)
		_support_confirmation.canceled.connect(func(): _support_quote = {})
		_support_confirmation.confirmed.connect(func():
			if market_run == null or _support_quote.is_empty() or _support_quote != market_run.get_support_quote(name_input.text,genre_input.get_selected_metadata(),theme_input.get_selected_metadata()):
				_support_quote = {}
				error_label.text = "The quote changed. Review a fresh support quote."
				return
			begin_requested.emit(name_input.text.strip_edges(),genre_input.get_selected_metadata(),theme_input.get_selected_metadata()))
	var q := _support_quote
	_support_terms.text = "%s · %s / %s\n\nFunding at Begin: %s · Launch marketing: %d Awareness\nTotal package/recoup cap: %s\n\nYou own the game. SideStreet receives 20%% of this title's cumulative net sales after the platform share, rounded down to cents, up to the package cap through earning cycle 24. The remainder is yours. Unrecouped support expires; it never becomes debt or a claim on other games.\n\nAt earning cycle 6, frozen Review must be at least 7.0 AND actual cumulative units at least 1,000. Success requests +10 Investment, capped at100. A miss grants zero; there is no standing loss or clawback.\n\nFor another offer, this assessment must finish, Investment must remain at least15, and a new support success or full SideStreet commission must have been earned since the last acceptance. Cap100 successes still qualify; unused older successes do not bank offers.\n\nFunding commits once with Begin and is nonoperating cash, excluded from profit and Bank income. Begin costs one productive cycle; bills continue. Back is free; no cancellation after Begin." % [q.base_name,String(q.genre).capitalize(),String(q.theme).capitalize(),CashFormatter.format_exact_cents(q.funding_cents),q.marketing_points,CashFormatter.format_exact_cents(q.budget_cents)]
	_support_confirmation.max_size = Vector2i(get_viewport_rect().size)-Vector2i(40,40)
	_support_confirmation.popup_centered(Vector2i(mini(840,int(get_viewport_rect().size.x)-60),460))

func _review_commission() -> void:
	_commission_quote = {} if market_run == null else market_run.get_commission_quote(name_input.text,genre_input.get_selected_metadata(),theme_input.get_selected_metadata())
	if _commission_quote.is_empty():
		error_label.text = "Commission unavailable. Need SideStreet Reputation 20, a released game, a found commission invitation and no active work or commission."
		return
	if _commission_confirmation == null:
		_commission_confirmation = preload("res://scripts/ui/quit_confirmation.gd").new()
		_commission_confirmation.name = "CommissionConfirmation"
		_commission_confirmation.title = "Confirm SideStreet commission"
		_commission_confirmation.ok_button_text = "Accept and begin (1 cycle)"
		_commission_confirmation.cancel_button_text = "Keep editing"
		_commission_confirmation.theme = preload("res://resources/ui/onyx_theme.tres")
		add_child(_commission_confirmation)
		# A scrolling body bounds the Window minimum at the supported small size.
		# A wrapped dialog_text Label can otherwise force its buttons off screen.
		_commission_terms = RichTextLabel.new()
		_commission_terms.name = "CommissionTerms"
		_commission_terms.custom_minimum_size = Vector2(0,350)
		_commission_terms.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_commission_terms.add_theme_font_size_override("normal_font_size",16)
		_commission_terms.focus_mode = Control.FOCUS_ALL
		_commission_confirmation.add_content(_commission_terms)
		_commission_confirmation.canceled.connect(func(): _commission_quote = {})
		_commission_confirmation.confirmed.connect(_begin_commission)
	var quote := _commission_quote
	_commission_terms.text = "%s · %s / %s\nRequired Scope: %d (frozen from your prepared project) · Review target: 6.0 / 10\n\nPayment to your Studio at release: up to $6,000, with no advance. The fee scales with the lower of Scope completion and Review delivery (4.0 or less = $0; 5.0 = 50%%; 6.0+ = 100%%). Rounded down to cents.\nOnly full delivery requests +15 Reputation / +15 Investment; each caps at 100. Access spends no standing.\n\nSideStreet owns this title's sales. Raw units and Fans remain; Studio/Bank sales income is $0 and post-launch campaigns are unavailable. Banked Promotion is consumed by this successful launch normally.\n\nBegin costs one productive calendar cycle; rent, payroll and Bank obligations continue. The fee can service arrears. There is no cancellation after Begin. Editing or backing out now is free." % [quote.base_name,String(quote.genre).capitalize(),String(quote.theme).capitalize(),quote.required_scope]
	_commission_confirmation.max_size = Vector2i(get_viewport_rect().size)-Vector2i(40,40)
	_commission_confirmation.popup_centered(Vector2i(mini(840,int(get_viewport_rect().size.x)-60),460))

func _begin_commission() -> void:
	if market_run == null or _commission_quote.is_empty() or _commission_quote != market_run.get_commission_quote(name_input.text,genre_input.get_selected_metadata(),theme_input.get_selected_metadata()):
		_commission_quote = {}
		error_label.text = "The quote changed. Review a fresh quote before beginning."
		return
	begin_requested.emit(name_input.text.strip_edges(),genre_input.get_selected_metadata(),theme_input.get_selected_metadata())

## Value-only Begin intent used across an asynchronous checkpoint wait.
func get_start_intent() -> Dictionary:
	return {"open":is_visible_in_tree(),"name":name_input.text,"genre":genre_input.get_selected_metadata(),"theme":theme_input.get_selected_metadata(),"priorities":get_initial_priorities(),"commission":commission_mode,"support":support_mode,"commission_quote":get_confirmed_commission_quote(),"support_quote":get_confirmed_support_quote()}
