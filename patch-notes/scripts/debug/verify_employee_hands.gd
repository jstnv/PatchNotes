extends "res://scripts/debug/verify_studio_finance_integration.gd"
func match_views(phase: Control) -> Array:
	var views := phase.get_node("%HandContainer").get_children()
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var group := [views[a],views[b],views[c],views[d]]
					if EmployeeRoster.matches(EmployeeRoster.card_facts(group.map(func(v):return v.card_data))):return group
	return []
func state(phase: Control, run: RunState, project: ProjectState) -> Array:
	return [snapshot(run),run.get_employees(),phase.get("_deal_rng").state,phase.get_priority_distribution(),phase.get("_candidate_cards").duplicate(),project.get_current_cycle(),project.get_current_scope(),[project.get_core_score(0),project.get_core_score(1),project.get_core_score(2),project.get_core_score(3)]]
func _run() -> void:
	snapshots.load_ledgers()
	var run := named()
	check(run.get_production_hire_quote().is_empty(),"No hire before Game1")
	check(run.register_release(_released_project(751)),"Hire prerequisite fixture release")
	var quote := run.get_production_hire_quote()
	var before := snapshot(run)
	check(not quote.is_empty() and snapshot(run)==before,"Hire browsing is passive")
	check(run.hire_production_specialist(quote) and run.get_cash_cents()==before[0]-10000 and run.get_completed_run_cycles()==0,"Real hire atomic fee and no cycle")
	check(not run.hire_production_specialist(quote),"Duplicate hire rejected")
	var trained := false
	for label in ["design","alpha"]:
		var project := ProjectState.new(30)
		project.initialize_snapshots(&"fast_follower",&"stable_market")
		if label=="alpha":project.finalize_design_bugs(false,20,[],[])
		var phase: Control = load("res://scenes/phases/%s_phase.tscn" % label).instantiate()
		root.add_child(phase)
		phase.setup(project,run)
		phase.get("_deal_rng").seed=61001
		check(phase.call("begin_"+label),"Begin native "+label)
		for attempt in range(6):
			var selected := match_views(phase)
			if selected.is_empty():
				selected=phase.get_node("%HandContainer").get_children().slice(0,4)
			for view: CardView in selected:view.input_button.pressed.emit()
			var matching: bool = phase.get_employee_hand_status().qualifying
			var full_before := state(phase,run,project)
			check(not phase.play_hand_with_employee_plan({0:100}) and state(phase,run,project)==full_before,"Invalid plan preserves complete state")
			var changed := {0:40,1:20,2:20,3:20}
			if matching and trained:
				var old_priority: Dictionary = phase.get_priority_distribution()
				check(not phase.play_hand_with_employee_plan(old_priority) and state(phase,run,project)==full_before,"Unchanged plan preserves use")
				var dialog := EmployeePlanningDialog.new()
				phase.add_child(dialog)
				dialog.open_for(phase)
				check(dialog.visible,"Optional hand preview opens")
				if "--capture" in OS.get_cmdline_user_args():
					await process_frame
					root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/codex/findings/employee-implementation-v1/planning-%s.png" % label))
				dialog.hide()
				check(state(phase,run,project)==full_before,"Cancel preview is passive")
				var retained := phase.get_node("%HandContainer").get_children().filter(func(v):return v not in selected)
				var prior_rng: int = phase.get("_deal_rng").state
				var expected: Dictionary
				if label=="design":expected=phase._build_weighted_candidate_definitions(changed,[] as Array[float],4)
				else:
					var excluded: Array[StringName]=[]
					for card: CardData in phase.get("_candidate_cards"):
						if not card.renewable:excluded.append(card.id)
					expected=phase._build_weighted_candidate_definitions(changed,[] as Array[float],4,excluded)
				phase.get("_deal_rng").state=prior_rng
				var cycle := run.get_completed_run_cycles()
				var redraw := run.get_available_redraws()
				check(phase.play_hand_with_employee_plan(changed),"Commit bundled "+label+" plan")
				check(run.get_completed_run_cycles()==cycle+1 and run.get_available_redraws()==mini(4,redraw+1),"One ordinary cycle/refill")
				check(phase.get_priority_distribution()==changed and not EmployeeRoster.available(run.get_employees(),project.get_release_id()),"Priority and per-project use committed together")
				var after := phase.get_node("%HandContainer").get_children()
				check(retained.all(func(v):return v in after),"Three retained instances preserved")
				check(after.filter(func(v):return v not in retained).map(func(v):return v.card_data)==expected.cards,"Normal replacements use proposed priorities with no extra roll")
				var complete := state(phase,run,project)
				check(not phase.play_hand_with_employee_plan(changed) and state(phase,run,project)==complete,"Duplicate bundled callback is inert")
				reconcile(run)
				break
			else:
				if label=="design":phase._on_play_card_pressed()
				else:phase._on_play_alpha_hand_pressed()
				if matching and label=="design":
					trained=true
					check(run.get_employees().employees.values()[0].trained and EmployeeRoster.available(run.get_employees(),project.get_release_id()),"Training hand grants permanent benefit but retains use")
			await process_frame
		check(not EmployeeRoster.available(run.get_employees(),project.get_release_id()),"Fixture used benefit in "+label)
		phase.queue_free()
		await process_frame
	print("Employee hand integration: %d failures" % failures)
	quit(failures)
