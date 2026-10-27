## Frozen accounting fixture for Bank navigation; not a balance route.
extends "res://scripts/debug/verify_studio_finance_integration.gd"

var output := ""

func settle() -> void:
	await create_timer(0.3).timeout
	await process_frame

func capture(label: String) -> void:
	if output.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	snapshots.load_ledgers()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		var run := named()
		check(run.register_release(_released_project(751)), "Frozen fixture release")
		for i in 4: check(run.complete_productive_action(), "Native settlement fixture")
		var menu := StudioFinances.new()
		root.add_child(menu)
		menu.bind_run(run)
		check(menu.open(), "Finances opens")
		menu.open_bank()
		await settle()
		var details: Button = menu.dialog.find_child("PaymentBreakdownButton",true,false)
		check(details != null, "Monthly schedule has a separate Payment breakdown button")
		if details != null: check(details.disabled, "No loan or preview means no payment schedule")
		check(menu.bank_history.is_visible_in_tree() and menu.bank_history.text.contains("Credit score"), "Financial history remains on the main Bank page")
		menu.amount_input.text = "1500.00"
		menu.term_input.text = "24"
		menu._preview_quote()
		var shown := menu._quote.duplicate(true)
		check(shown.get("accepted",false), "Valid 24-month preview available")
		check(not menu.quote_details.text.contains("1. Month"), "Main Bank summary does not contain monthly installment logs")
		if details != null:
			check(not details.disabled, "Preview enables payment breakdown")
			var before := snapshot(run)
			var history := menu.bank_history.text
			details.pressed.emit()
			await settle()
			var payments: RichTextLabel = menu.dialog.find_child("BankPaymentDetails",true,false)
			var next: Button = menu.dialog.find_child("NextPaymentPage",true,false)
			var previous: Button = menu.dialog.find_child("PreviousPaymentPage",true,false)
			check(menu.page == &"bank_payments" and payments != null and payments.is_visible_in_tree(), "Breakdown opens its own readable view")
			if payments != null and next != null and previous != null:
				check(payments.text.contains("1. Month") and payments.text.contains("12. Month"), "First page retains the exact original installments")
				check(previous.disabled and not next.disabled, "First-page navigation has correct bounds")
				next.pressed.emit()
				check(payments.text.contains("13. Month") and payments.text.contains("24. Month") and next.disabled, "Next page retains later payments and stops at the end")
				previous.pressed.emit()
				check(payments.text.contains("1. Month") and previous.disabled, "Previous payments returns to the beginning")
				check(menu.dialog.get_global_rect().encloses(payments.get_global_rect()), "Breakdown remains inside the menu at %s" % resolution)
				await capture("payment-breakdown-%d" % resolution.x)
			menu.back_button.pressed.emit()
			await settle()
			check(menu.page == &"bank" and menu.bank_history.is_visible_in_tree() and details.has_focus(), "Back restores Bank, Financial history and button focus")
			check(snapshot(run) == before and menu._quote == shown and menu.bank_history.text == history, "Reading payment details changes no state or quote")
		menu._confirm_accept()
		check(menu._confirmation_payload == shown, "Acceptance still confirms the exact displayed quote")
		menu._confirm.hide()
		menu._confirm_transaction()
		await settle()
		check(run.get_studio_finance_snapshot().bank_loans.size() == 1, "Confirmed borrowing still creates one loan")
		var loan_id: StringName = run.get_studio_finance_snapshot().bank_loans[0].loan_id
		check(not menu.quote_details.text.contains(str(loan_id)), "Main summary uses a readable loan label instead of an internal ID")
		check(menu.bank_history.is_visible_in_tree(), "Financial history stays visible with an active loan")
		await capture("bank-main-%d" % resolution.x)
		menu.close()
		menu.queue_free()
		await process_frame
	print("Bank presentation: %d failures" % failures)
	quit(failures)
