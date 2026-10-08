extends "res://scripts/debug/verify_studio_finance_integration.gd"
func _run() -> void:
	snapshots.load_ledgers()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution
		root.content_scale_size=resolution
		var run:=named()
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		game.run_state=run
		root.add_child(game)
		await create_timer(0.3).timeout
		var studio: StudioPhase=game.get("_active_phase")
		studio.get_node("%Employees").pressed.emit()
		var panel: EmployeePanel=studio._employees_panel
		check(panel.visible and panel.get_ok_button().disabled,"Pre-release hiring unavailable with reason")
		panel.get_cancel_button().pressed.emit()
		await process_frame
		check(not panel.visible,"Back closes employee panel")
		studio.get_node("%Employees").pressed.emit()
		panel.get_cancel_button().grab_focus()
		check(panel.gui_get_focus_owner()==panel.get_cancel_button(),"Keyboard focus belongs to employee dialog")
		var escape := InputEventKey.new()
		escape.keycode=KEY_ESCAPE
		escape.pressed=true
		panel.push_input(escape,true)
		await process_frame
		check(not panel.visible,"Escape cancels employee dialog")
		check(run.register_release(_released_project(751)),"UI post-release fixture")
		var before:=snapshot(run)
		studio.get_node("%Employees").pressed.emit()
		check(not panel.get_ok_button().disabled and panel.dialog_text.contains("$100.00") and panel.dialog_text.contains("$10.00") and panel.dialog_text.contains("cycle 2"),"Fee wage and first payday shown before confirmation")
		await process_frame
		check(panel.size.x<=resolution.x and panel.size.y<=resolution.y,"Employee dialog fits viewport")
		if "--capture" in OS.get_cmdline_user_args():
			await process_frame
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/codex/findings/employee-implementation-v1/hire-%d.png" % resolution.x))
		panel.get_cancel_button().pressed.emit()
		check(snapshot(run)==before and run.get_employees().employees.is_empty(),"Cancel hire preserves all state")
		studio.get_node("%Employees").pressed.emit()
		panel.get_ok_button().pressed.emit()
		await process_frame
		check(run.get_employees().employees.size()==1 and run.get_cash_cents()==before[0]-10000,"Confirmed UI hires once")
		studio.get_node("%Employees").pressed.emit()
		check(panel.get_ok_button().disabled and panel.dialog_text.contains("training incomplete"),"Owned training status and no second hire")
		panel.get_cancel_button().pressed.emit()
		game.queue_free()
		await process_frame
	print("Employee UI: %d failures" % failures)
	quit(failures)
