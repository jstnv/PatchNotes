extends SceneTree

const DESIGN_SCENE := preload("res://scenes/phases/design_phase.tscn")

var _failures := 0


func _init() -> void:
	call_deferred(&"_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)


func _run() -> void:
	var run := RunState.new()
	_check(run.get_available_redraws() == 4, "A new run must start with four redraws.")
	for expected in [3, 2, 1, 0]:
		_check(run.consume_redraw(), "An available redraw must be consumable.")
		_check(run.get_available_redraws() == expected, "Redraw consumption must decrement once.")
	_check(not run.consume_redraw(), "A fifth redraw must reject at zero.")
	_check(run.get_completed_run_cycles() == 0, "Redraws must cost zero cycles.")
	_check(run.advance_calendar_cycle(), "A valid time action must advance.")
	_check(run.get_available_redraws() == 1, "A time action must restore one redraw.")
	run.refresh_redraws()
	_check(run.get_available_redraws() == 4, "Development-phase entry must refresh to four.")
	run.advance_calendar_cycle()
	_check(run.get_available_redraws() == 4, "Restoration must cap at four.")

	var project := ProjectState.new(30)
	var phase := DESIGN_SCENE.instantiate() as DesignPhase
	root.add_child(phase)
	phase.setup(project, run)
	await process_frame
	_check(phase.begin_design(), "Design must begin for redraw verification.")
	await process_frame
	var hand := phase.get_node("%HandContainer") as HBoxContainer
	_check(hand.get_child_count() == 7, "Design must expose seven candidates.")
	var target := hand.get_child(0) as CardView
	var old_id := target.card_data.id
	target.card_pressed.emit(target)
	_check(phase.get_node("%PlayCardButton").disabled, "One selected card must not enable Play Hand.")
	var before_redraws := run.get_available_redraws()
	_check(phase.redraw_selected_cards([0.5]), "An ordinary Design candidate must redraw.")
	await process_frame
	var replacement := hand.get_child(0) as CardView
	_check(replacement.card_data.id != old_id, "A redraw cannot immediately return the discarded definition.")
	_check(not replacement.is_selected(), "A replacement must start unselected.")
	_check(run.get_available_redraws() == before_redraws - 1, "A successful redraw must consume exactly one allowance.")
	_check(run.get_completed_run_cycles() == 2, "The redraw itself must not advance time.")

	var changed := {
		ProjectState.CoreScore.GRAPHICS: 30,
		ProjectState.CoreScore.SOUND: 25,
		ProjectState.CoreScore.TECHNOLOGY: 25,
		ProjectState.CoreScore.DESIGN: 20,
	}
	var cycles_before_commit := run.get_completed_run_cycles()
	var project_cycles_before_commit: int = project.get_current_cycle()
	var redraws_before_commit := run.get_available_redraws()
	_check(phase.commit_priority_distribution(changed), "A valid changed priority distribution must commit.")
	_check(run.get_completed_run_cycles() == cycles_before_commit + 1, "Priority commit must cost exactly one cycle.")
	_check(project.get_current_cycle() == project_cycles_before_commit + 1, "Priority commit must advance the project-development cycle exactly once.")
	_check(run.get_available_redraws() == mini(4, redraws_before_commit + 1), "Priority commit must restore one redraw.")
	_check(not phase.commit_priority_distribution(changed), "An unchanged priority commit must reject.")
	_check(run.get_completed_run_cycles() == cycles_before_commit + 1, "An unchanged commit must cost zero cycles.")
	_check(project.get_current_cycle() == project_cycles_before_commit + 1, "An unchanged commit must not advance the project-development cycle.")
	var invalid := changed.duplicate()
	invalid[ProjectState.CoreScore.GRAPHICS] = 35
	_check(not phase.commit_priority_distribution(invalid), "A distribution not totaling 100 must reject.")
	_check(run.get_completed_run_cycles() == cycles_before_commit + 1, "An invalid commit must cost zero cycles.")

	phase.queue_free()
	await process_frame
	if _failures == 0:
		print("Shared redraw and priority-adjustment verification passed.")
	quit(0 if _failures == 0 else 1)
