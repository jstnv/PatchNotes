class_name EmployeePanel
extends ConfirmationDialog
var run: RunState
var quote: Dictionary = {}

func _ready() -> void:
	title = "Production Specialist"
	exclusive = true
	get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_label().custom_minimum_size.x = 600
	get_cancel_button().text = "Back"
	confirmed.connect(_hire)

func open_for(value: RunState) -> void:
	run = value
	quote = run.get_production_hire_quote()
	var roster := run.get_employees()
	var lines: Array[String] = []
	if roster.employees.is_empty():
		lines.append("Hire one Production Specialist for $100.00, with no cycle cost.")
		lines.append("Trial wage: $10.00 per month. Final wage is still being tested.")
		if not quote.is_empty(): lines.append("First payday: Month %d end, cycle %d; then every two cycles." % [quote.first_due_cycle/2,quote.first_due_cycle])
		else: lines.append("Requires a released game, current bills and $100.00 available cash.")
	else:
		var employee: Dictionary = roster.employees.values()[0]
		lines.append("Hired Production Specialist - %s" % ("trained" if employee.trained else "training incomplete"))
		for payroll: Dictionary in run.get_studio_finance_snapshot().employees:
			lines.append("Trial wage $10.00/month. Next payday: cycle %d." % [payroll.first_due_cycle+payroll.issued*2])
	lines.append("\nTraining: commit a Design hand with a Core Pass and a Feature matching its printed primary or secondary Core stat.")
	lines.append("Once trained: optionally change priorities with one later matching Design/Alpha hand per project. The training hand cannot use the new benefit. Each new project gets one use; training is permanent.")
	lines.append("The hand still costs its ordinary money and one cycle. Planning changes its replacement draws, with no extra cards or redraws.")
	dialog_text = "\n\n".join(lines)
	get_ok_button().text = "Hire for $100.00"
	get_ok_button().disabled = quote.is_empty()
	popup_centered(Vector2i(670,430))

func _hire() -> void:
	if run == null: return
	if not run.hire_production_specialist(quote):
		open_for(run)
		dialog_text = "Hiring could not be completed. Cash or bills changed; review the current offer.\n\n" + dialog_text


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		canceled.emit()
		set_input_as_handled()
