class_name EmployeePlanningDialog
extends ConfirmationDialog
var phase: Control
var inputs: Array[VSlider] = []
var budget_feedback: PriorityBudgetFeedback
var total_label: Label
var chart: PriorityInfluenceChart
var explanation: Label
var previous: Dictionary = {}

func _ready() -> void:
	title = "Plan this hand with your Specialist"
	exclusive = true
	get_ok_button().text = "Play hand with plan"
	get_cancel_button().text = "Keep use for later"
	var body := VBoxContainer.new()
	add_child(body)
	explanation = Label.new()
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size.x = 550
	body.add_child(explanation)
	var row := HBoxContainer.new()
	body.add_child(row)
	for title_text in ["Graphics","Sound","Technology","Design"]:
		var column := VBoxContainer.new()
		row.add_child(column)
		var label := Label.new()
		label.text = title_text
		column.add_child(label)
		var input := VSlider.new()
		input.min_value = 10
		input.max_value = PriorityAllocation.MAX_PRIORITY
		input.step = 5
		input.custom_minimum_size = Vector2(32,120)
		input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(input)
		inputs.append(input)
		input.value_changed.connect(func(_value): _refresh())
	chart = PriorityInfluenceChart.new()
	row.add_child(chart)
	chart.bind_controls(inputs,PriorityInfluenceChart.CORE_NAMES,PriorityInfluenceChart.CORE_COLORS)
	budget_feedback = PriorityBudgetFeedback.new()
	add_child(budget_feedback)
	budget_feedback.bind_controls(inputs)
	total_label = Label.new()
	body.add_child(total_label)
	confirmed.connect(_commit)

func open_for(value: Control) -> void:
	phase = value
	var status: Dictionary = phase.get_employee_hand_status()
	if not status.get("available",false) or not status.get("qualifying",false): return
	previous = phase.get_priority_distribution()
	for i in range(4): inputs[i].value = previous[i]
	var base: Dictionary = phase._validate_and_calculate_base_action()
	var names: Array[String] = []
	for card: CardData in base.cards: names.append(card.card_name)
	explanation.text = "Selected hand: %s\n\nChange priorities (total 100) and commit this matching hand. The new weights apply to its normal replacements. Card effects, hand cost and one cycle are unchanged. This spends this project's one Specialist use." % ", ".join(names)
	_refresh()
	popup_centered(Vector2i(720,420))

func _distribution() -> Dictionary:
	var value := {}
	for i in range(4): value[i] = int(inputs[i].value)
	return value

func _refresh() -> void:
	var value := _distribution()
	if total_label != null:
		var total := 0
		for amount: int in value.values(): total += amount
		total_label.text = "%d/100" % total
	get_ok_button().disabled = value == previous or not PriorityAllocation.is_valid_new_distribution(value)

func _commit() -> void:
	if not is_instance_valid(phase): return
	var distribution := _distribution()
	hide()
	if not phase.get_workspace().present_employee_plan(distribution):
		explanation.text = "The hand was rejected or changed. Your Specialist use was not spent. Close this dialog and review the hand."
		get_ok_button().disabled = true
		popup_centered(Vector2i(600,310))


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		canceled.emit()
		set_input_as_handled()
