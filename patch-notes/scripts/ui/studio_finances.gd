class_name StudioFinances
extends CanvasLayer

## Passive finance navigation; confirmed Bank actions call atomic RunState APIs.
signal closed

var run: RunState
var dialog: PanelContainer
var back_button: Button
var bank_button: Button
var month_table: Tree
var month_detail: RichTextLabel
var totals_label: Label
var block_label: Label
var bank_history: RichTextLabel
var expense_details: RichTextLabel
var finance_tabs: TabContainer
var page := &"finances"
var report: Dictionary = {}
var _title: Label
var _finance_page: VBoxContainer
var _bank_page: VBoxContainer
var _previous_focus: Control
var _return_label := "Back to Game"
var _entrance: Tween
var _content: MarginContainer
var amount_input: LineEdit
var term_input: LineEdit
var accept_button: Button
var payoff_button: Button
var quote_details: RichTextLabel
var _quote: Dictionary = {}
var _payoff: Dictionary = {}
var _schedule_page := 0
var _confirm: ConfirmationDialog
var _confirmation_kind: StringName = &""


func _ready() -> void:
	layer = 40
	visible = false
	var shade := ColorRect.new()
	shade.name = "FinanceInputBlocker"
	shade.color = Color(0.02, 0.015, 0.025, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	dialog = PanelContainer.new()
	dialog.name = "StudioFinancesDialog"
	dialog.theme = preload("res://resources/ui/workspace_theme.tres")
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.offset_left = 28
	dialog.offset_right = -28
	dialog.offset_top = 24
	dialog.offset_bottom = -64
	shade.add_child(dialog)
	_content = MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		_content.add_theme_constant_override("margin_" + edge, 12)
	dialog.add_child(_content)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_content.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)
	_title = _label("Studio Finances", header, 26)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_button = Button.new()
	bank_button.name = "VisitBankButton"
	bank_button.text = "Visit Bank"
	bank_button.pressed.connect(open_bank)
	header.add_child(bank_button)
	back_button = Button.new()
	back_button.name = "FinanceBackButton"
	back_button.text = _return_label
	back_button.pressed.connect(back)
	header.add_child(back_button)
	totals_label = _label("", layout, 16)
	totals_label.name = "FinanceTotals"
	block_label = _label("", layout)
	block_label.name = "UnpaidObligations"
	block_label.add_theme_color_override("font_color", Color("ffc779"))
	_finance_page = VBoxContainer.new()
	_finance_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_finance_page.add_theme_constant_override("separation", 8)
	layout.add_child(_finance_page)
	finance_tabs = TabContainer.new()
	finance_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_finance_page.add_child(finance_tabs)
	var monthly := VBoxContainer.new()
	monthly.name = "Monthly report"
	finance_tabs.add_child(monthly)
	expense_details = RichTextLabel.new()
	expense_details.name = "Outstanding bills"
	expense_details.scroll_active = true
	finance_tabs.add_child(expense_details)
	_label("Actual studio months · Sales revenue uses earned net after the 70% share, applied once. Cash settled is shown separately.", monthly)
	month_table = Tree.new()
	month_table.name = "FinanceMonthlyRows"
	month_table.columns = 6
	month_table.hide_root = true
	month_table.column_titles_visible = true
	month_table.select_mode = Tree.SELECT_ROW
	month_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	month_table.custom_minimum_size.y = 105
	for i in range(6):
		month_table.set_column_title(i, ["Run month", "Revenue", "Expenses", "Net profit", "Cash change", "Closing cash"][i])
		month_table.set_column_custom_minimum_width(i, 100)
	month_table.item_selected.connect(_show_month)
	monthly.add_child(month_table)
	month_detail = RichTextLabel.new()
	month_detail.name = "FinanceMonthDetail"
	month_detail.custom_minimum_size.y = 145
	month_detail.scroll_active = true
	monthly.add_child(month_detail)
	_bank_page = VBoxContainer.new()
	_bank_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_bank_page)
	var controls := HBoxContainer.new()
	_bank_page.add_child(controls)
	_label("Loan amount $", controls).autowrap_mode = TextServer.AUTOWRAP_OFF
	amount_input = LineEdit.new()
	amount_input.name = "BankAmount"
	amount_input.text = "500.00"
	amount_input.custom_minimum_size.x = 140
	controls.add_child(amount_input)
	_label("Months", controls).autowrap_mode = TextServer.AUTOWRAP_OFF
	term_input = LineEdit.new()
	term_input.name = "BankTerm"
	term_input.text = "12"
	term_input.custom_minimum_size.x = 100
	controls.add_child(term_input)
	var preview := Button.new()
	preview.text = "Preview quote"
	preview.pressed.connect(_preview_quote)
	controls.add_child(preview)
	accept_button = Button.new()
	accept_button.text = "Accept loan…"
	accept_button.pressed.connect(_confirm_accept)
	controls.add_child(accept_button)
	payoff_button = Button.new()
	payoff_button.text = "Pay off…"
	payoff_button.pressed.connect(_confirm_payoff)
	controls.add_child(payoff_button)
	amount_input.text_changed.connect(_invalidate_quote)
	term_input.text_changed.connect(_invalidate_quote)
	quote_details = RichTextLabel.new()
	quote_details.name = "BankQuote"
	quote_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	quote_details.scroll_active = true
	quote_details.custom_minimum_size.y = 130
	_bank_page.add_child(quote_details)
	var pages := HBoxContainer.new()
	_bank_page.add_child(pages)
	for direction in [-1,1]:
		var button := Button.new()
		button.text = "Previous payments" if direction < 0 else "Next payments"
		button.pressed.connect(func():
			_schedule_page = maxi(0,_schedule_page + direction)
			_show_quote())
		pages.add_child(button)
	_label("Financial history", _bank_page, 18)
	bank_history = RichTextLabel.new()
	bank_history.name = "BankHistory"
	bank_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bank_history.scroll_active = true
	_bank_page.add_child(bank_history)
	_label("Rate: 1% of scheduled opening principal per month. Credit uses prototype defaults; score does not set eligibility or price.", _bank_page)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Confirm Bank transaction"
	_confirm.dialog_autowrap = true
	_confirm.confirmed.connect(_confirm_transaction)
	add_child(_confirm)
	_set_page(&"finances")


func _label(text: String, parent: Node, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func bind_run(value: RunState) -> void:
	if run == value: return
	if run != null and run.finance_changed.is_connected(_on_finance_changed):
		run.finance_changed.disconnect(_on_finance_changed)
	close()
	run = value
	if run != null: run.finance_changed.connect(_on_finance_changed)
	if is_node_ready(): refresh()


func open(return_label: String = "Back to Game") -> bool:
	if run == null or not is_node_ready(): return false
	_return_label = return_label
	_previous_focus = get_viewport().gui_get_focus_owner()
	_set_page(&"finances")
	refresh()
	visible = true
	back_button.grab_focus()
	_animate_entrance.call_deferred()
	return true


func close() -> void:
	if not visible: return
	visible = false
	_confirm.hide()
	if _entrance != null: _entrance.kill()
	if is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	closed.emit()


func open_bank() -> void:
	if not visible or run == null: return
	_set_page(&"bank")
	refresh()
	back_button.grab_focus()
	_animate_entrance.call_deferred()


func back() -> void:
	if page == &"bank":
		_set_page(&"finances")
		bank_button.grab_focus()
	else:
		close()


func _set_page(value: StringName) -> void:
	page = value
	_title.text = "Visit Bank" if page == &"bank" else "Studio Finances"
	_finance_page.visible = page == &"finances"
	_bank_page.visible = page == &"bank"
	bank_button.visible = page == &"finances"
	back_button.text = "Back to Finances" if page == &"bank" else _return_label


func _on_finance_changed() -> void:
	if visible: refresh()


func refresh() -> void:
	if not is_node_ready(): return
	report = run.get_studio_finance_report() if run != null else {}
	var available := bool(report.get("available", false))
	_quote = {}
	_payoff = {}
	_confirm.hide()
	accept_button.disabled = true
	payoff_button.disabled = true
	quote_details.text = "Enter an amount and term, then preview the exact quote."
	if available:
		for loan: Dictionary in report.get("bank_loans", []):
			if not loan.closed:
				_payoff = run.get_bank_payoff_quote(loan.loan_id)
				_quote = {"schedule": loan.schedule, "reason": "Active loan: " + String(loan.loan_id)}
				payoff_button.disabled = _payoff.is_empty()
				_show_quote()
	var cash: int = report.get("cash_cents", run.get_cash_cents() if run != null else -1)
	var due: int = report.get("next_due_cycle", 0)
	var arrears: int = report.get("unpaid_rent_cents", 0)
	totals_label.text = "Available cash: %s" % (_money(cash) if cash >= 0 else "Unavailable")
	if available:
		var due_text := "end of run Month %d (cycle %d)" % [due / 2, due] if due > 0 else "unavailable"
		totals_label.text += "   ·   Total overdue: %s" % _money(report.get("total_overdue_cents", 0))
		totals_label.text += "   ·   Monthly rent: %s   ·   Unpaid rent: %s\nNext rent due: %s. Forecasts and unpaid sales are not spendable cash." % [_money(report.get("monthly_rent_cents", 0)), _money(arrears), due_text]
	var blocked := bool(report.get("financially_blocked", false))
	block_label.visible = blocked
	block_label.text = run.get_financial_block_reason() if blocked and run != null else ""
	var previous := month_table.get_selected()
	var prior_month: int = previous.get_metadata(0) if previous != null else -1
	month_table.clear()
	month_detail.text = ""
	var root_item := month_table.create_item()
	var selected: TreeItem
	var rows: Array = report.get("rows", []) if available else []
	for row: Dictionary in rows:
		var item := month_table.create_item(root_item)
		var month: int = row.get("month", 0)
		item.set_metadata(0, month)
		item.set_text(0, "%d%s" % [month, " (partial)" if row.get("partial", false) else " (complete)"])
		for column in range(5):
			item.set_text(column + 1, _money(row.get(["operating_revenue_cents", "operating_expenses_cents", "net_profit_cents", "cash_change_cents", "closing_cash_cents"][column], 0)))
		if selected == null or prior_month == month or prior_month < 0: selected = item
	if selected != null:
		selected.select(0)
		month_table.ensure_cursor_is_visible()
		_show_month()
	else:
		month_detail.text = "No monthly transactions recorded yet." if available else "Monthly history unavailable for this run. Prior income and expenses have not been reconstructed."
	_update_expenses(available)
	_update_bank(available, rows)


func _show_month() -> void:
	var item := month_table.get_selected()
	if item == null: return
	var month: int = item.get_metadata(0)
	for row: Dictionary in report.get("rows", []):
		if int(row.get("month", -1)) != month: continue
		var lines: Array[String] = ["Run Month %d · %s" % [month, "Partial actual activity" if row.get("partial", false) else "Completed month"],
			"Sales net earned: %s · Sales cash settled: %s · Non-sales income total: %s" % [_money(row.get("sales_net_earned_cents", 0)), _money(row.get("sales_settled_cents", 0)), _money(row.get("other_income_cents", 0))],
			"Publisher receipts: %s · Beta income: %s · Miscellaneous income: %s" % [_money(row.get("publisher_income_cents", 0)), _money(row.get("beta_income_cents", 0)), _money(row.get("miscellaneous_income_cents", 0))],
			"Feature play: %s · Store: %s · Campaigns: %s · Playtests: %s · Other expenses: %s" % [_money(row.get("feature_play_cents", 0)), _money(row.get("store_cents", 0)), _money(row.get("campaign_cents", 0)), _money(row.get("playtest_cents", 0)), _money(row.get("other_expense_cents", 0))],
			"Rent due: %s · Paid this month: %s · Still unpaid from this month: %s" % [_money(row.get("rent_due_cents", 0)), _money(row.get("rent_paid_cents", 0)), _money(row.get("rent_unpaid_cents", 0))],
			"Payroll due: %s · Paid this month: %s · Still unpaid: %s" % [_money(row.get("payroll_due_cents",0)),_money(row.get("payroll_paid_cents",0)),_money(row.get("payroll_unpaid_cents",0))],
			"Financing received: %s · Principal repaid: %s · Interest expense: %s" % [_money(row.get("financing_in_cents", 0)), _money(row.get("principal_paid_cents", 0)), _money(row.get("interest_cents", 0))],
			"Cash: %s opening → %s closing · Change: %s" % [_money(row.get("opening_cash_cents", 0)), _money(row.get("closing_cash_cents", 0)), _money(row.get("cash_change_cents", 0))],
			"Rent payments belong to the payment month; unpaid rent belongs to its original due month.",
			"Earned revenue and settled cash use different timing. Financing is not revenue; principal is not an expense."]
		month_detail.text = "\n".join(lines)
		return


func _update_expenses(available: bool) -> void:
	if not available:
		expense_details.text = "Outstanding history unavailable. No historical bills have been invented."
		return
	var lines: Array[String] = ["Outstanding bills · two productive cycles = one month"]
	var bills: Array = report.get("outstanding_expenses", []).duplicate(true)
	for bill: Dictionary in run.get_studio_finance_snapshot().get("obligations", []):
		if bill.expense_type in [&"bank_installment",&"payroll"] and bill.unpaid_cents == 0:
			bills.append(OutstandingExpenses.describe(bill, run.get_completed_run_cycles()))
	if bills.is_empty(): lines.append("No outstanding bills.")
	for bill: Dictionary in bills:
		lines.append("\n%s · %s" % [OutstandingExpenses.LABELS[bill.expense_type], bill.bill_id])
		lines.append("Original due: Month %d, cycle %d · Original %s · Paid %s · Remaining %s" % [bill.month, bill.due_cycle, _money(bill.due_cents), _money(bill.paid_cents), _money(bill.unpaid_cents)])
		lines.append("%s · Overdue %d cycles (%.1f months). Credit tier: -%d; next age tier: -%d." % ["Paid on time" if bill.paid_on_time else "Late payment history", bill.overdue_cycles, bill.overdue_cycles / 2.0, bill.penalty, bill.next_penalty])
		if bill.expense_type == &"bank_installment":
			lines.append("Principal %s / %s paid · Interest %s / %s paid" % [_money(bill.principal_paid_cents),_money(bill.principal_cents),_money(bill.interest_paid_cents),_money(bill.interest_cents)])
		for payment: Dictionary in bill.payments:
			lines.append("  Cycle %d: %s" % [payment.cycle,_money(payment.cents)])
	lines.append("\nCredit applies once per completed month, using the oldest qualifying bill in each category. Partial payment preserves the original due date. Paying stops future penalties; past late history remains.")
	expense_details.text = "\n".join(lines)


func _update_bank(available: bool, rows: Array) -> void:
	if not available:
		bank_history.text = "Financial history unavailable for this run. No credit history has been invented."
		return
	var inputs: Dictionary = report.get("credit_inputs", {})
	var completed: int = inputs.get("completed_months", 0)
	var credit: Dictionary = report.get("credit", {})
	var lines: Array[String] = ["Credit score: %d · Working range %d–%d" % [credit.get("score", 600), OutstandingExpenses.MIN_SCORE, OutstandingExpenses.MAX_SCORE]]
	if completed == 0:
		lines.append("Neutral starting history. No completed months yet.")
	else:
		lines.append("Completed months: %d" % completed)
	lines.append("Paid-on-time months: %d · Late-payment months: %d" % [inputs.get("paid_on_time_months", 0), inputs.get("late_months", 0)])
	lines.append("Unpaid rent: %s" % _money(report.get("unpaid_rent_cents", 0)))
	lines.append("")
	for row: Dictionary in rows:
		if row.get("partial", false): continue
		lines.append("Month %d · Revenue %s · Expenses %s · Net profit %s · Rent unpaid %s" % [row.get("month", 0), _money(row.get("operating_revenue_cents", 0)), _money(row.get("operating_expenses_cents", 0)), _money(row.get("net_profit_cents", 0)), _money(row.get("rent_unpaid_cents", 0))])
	lines.append("")
	lines.append("Monthly credit changes · %s" % credit.get("policy_version", "unavailable"))
	for entry: Dictionary in credit.get("history", []):
		lines.append("Month %d: %d → %d (%+d)" % [entry.month, entry.before, entry.after, entry.change])
		for reason: Dictionary in entry.reasons:
			if reason.type == &"clean_profit": lines.append("  +%d · Profitable month, bills paid cleanly" % reason.points)
			elif reason.type == &"paid_no_profit": lines.append("  +0 · Paid loss or break-even month")
			else: lines.append("  %d · %s · %s · overdue %d cycles%s" % [reason.points, OutstandingExpenses.LABELS[reason.type], reason.bill_id, reason.overdue_cycles, " at recovery" if reason.recovered else ""])
	lines.append("Partial months do not add credit. Repayment gives no instant bonus. Loan eligibility uses settled sales and live obligations, without score-based pricing.")
	bank_history.text = "\n".join(lines)


func _animate_entrance() -> void:
	if not is_inside_tree() or not visible: return
	if _entrance != null: _entrance.kill()
	var rest_x := dialog.get_theme_stylebox("panel").get_content_margin(SIDE_LEFT)
	_content.position.x = rest_x + 32.0
	_entrance = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(_content, "position:x", rest_x, 0.22)


func _input(event: InputEvent) -> void:
	if not visible: return
	if _confirm.visible: return
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
		var controls: Array[Control] = []
		for control: Control in dialog.find_children("*", "Control", true, false):
			if control.focus_mode == Control.FOCUS_ALL and control.is_visible_in_tree(): controls.append(control)
		if not controls.is_empty():
			var index := controls.find(get_viewport().gui_get_focus_owner())
			controls[posmod(index + (-1 if event.is_action_pressed("ui_focus_prev") else 1), controls.size())].grab_focus()
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if visible: get_viewport().set_input_as_handled()


static func _money(cents: int) -> String:
	if cents < 0: return "-$%d.%02d" % [-(cents / 100), -(cents % 100)]
	return CashFormatter.format_exact_cents(cents)


func _invalidate_quote(_text: String) -> void:
	_quote = {}
	accept_button.disabled = true
	_confirm.hide()


func _preview_quote() -> void:
	if run == null or not visible: return
	_quote = run.get_bank_quote(BankLoan.parse_dollars(amount_input.text), BankLoan.parse_integer(term_input.text.strip_edges()))
	_schedule_page = 0
	accept_button.disabled = not _quote.get("accepted", false)
	_show_quote()


func _show_quote() -> void:
	var lines: Array[String] = [_quote.get("reason", "Quote unavailable.")]
	if _quote.has("capacity_cents"):
		lines.append("Settled sales: older %s · latest %s · conservative basis %s" % [_money(_quote.older_sales_cents),_money(_quote.latest_sales_cents),_money(_quote.basis_cents)])
		lines.append("Monthly rent %s · Other required obligations %s · Payment capacity %s" % [_money(_quote.rent_cents),_money(_quote.obligations_cents),_money(_quote.capacity_cents)])
		lines.append("Maximum principal for this term: %s" % _money(_quote.maximum_principal_cents))
	if _quote.has("schedule"):
		var terms: Dictionary = _quote.schedule
		lines.append("%s over %d months · 1%% monthly · Total interest %s · Total repayment %s" % [_money(terms.principal_cents),terms.term_months,_money(terms.total_interest_cents),_money(terms.total_payment_cents)])
		_schedule_page = mini(_schedule_page, (int(terms.term_months)-1)/12)
		for number in range(_schedule_page*12+1,mini((_schedule_page+1)*12+1,int(terms.term_months)+1)):
			var due := BankLoan.installment(terms,number)
			lines.append("%d. Month %d / cycle %d: %s = %s principal + %s interest" % [number,due.due_cycle/2,due.due_cycle,_money(due.payment_cents),_money(due.principal_cents),_money(due.interest_cents)])
	if not _payoff.is_empty():
		lines.append("Outstanding principal %s · Due unpaid interest %s · Payoff now %s. Future interest is waived; no fee." % [_money(_payoff.principal_cents),_money(_payoff.interest_cents),_money(_payoff.total_cents)])
	quote_details.text = "\n".join(lines)


func _confirm_accept() -> void:
	if not visible or page != &"bank" or not _quote.get("accepted", false): return
	_confirmation_kind = &"accept"
	_confirm.dialog_text = "Borrow %s over %d months? Total scheduled interest: %s. First payment is due at cycle %d. No time passes on acceptance." % [_money(_quote.schedule.principal_cents),_quote.schedule.term_months,_money(_quote.schedule.total_interest_cents),_quote.schedule.first_due_cycle]
	_confirm.popup_centered(Vector2i(520,180))


func _confirm_payoff() -> void:
	if not visible or page != &"bank" or _payoff.is_empty(): return
	_confirmation_kind = &"payoff"
	_confirm.dialog_text = "Pay %s to close this loan? This includes outstanding principal and due unpaid interest. Other overdue bills are paid first. Future interest is waived." % _money(_payoff.total_cents)
	_confirm.popup_centered(Vector2i(520,180))


func _confirm_transaction() -> void:
	if not visible or page != &"bank" or run == null: return
	var ok := run.accept_bank_loan(_quote) if _confirmation_kind == &"accept" else run.pay_off_bank_loan(_payoff)
	refresh()
	if not ok: quote_details.text = "Transaction rejected. Cash or finance state changed, funds are insufficient, or another action is in progress. Preview again."
