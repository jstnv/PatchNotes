## Presentation-only fixtures. Synthetic phase/release setup is not a played route.
## godot --headless --path . --script res://scripts/debug/verify_priority_influence.gd
## For rendered evidence, omit --headless and append -- --capture.
extends "res://scripts/debug/verify_balanced_primitive_contract.gd"

const CORE_NAMES: Array[String] = ["Graphics", "Sound", "Tech", "Design"]
const CORE_INPUTS: Array[String] = ["GraphicsPriority", "SoundPriority", "TechnologyPriority", "DesignPriority"]
const BETA_INPUTS: Array[String] = ["QAPriority", "MarketingPriority", "InsiderPriority"]
const OUTPUT := "res://design-logs/priority-influence-v1/"
var checks := 0


func expect(ok: bool, message: String) -> void:
	checks += 1
	super.expect(ok, message)


func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	RenderingServer.set_default_clear_color(Color("#100608"))
	if "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for resolution in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = resolution
		root.content_scale_size = resolution
		await _verify_predevelopment_chart(resolution)
		for title: String in ["Design", "Alpha", "Beta"]:
			await _verify_phase_chart(title, resolution)
		await _verify_contract_chart(resolution)
	print("Priority influence verification: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _settle_chart() -> void:
	await process_frame
	await process_frame
	await process_frame


func _equal_values(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size(): return false
	for index in range(expected.size()):
		if not is_equal_approx(float(actual[index]), float(expected[index])): return false
	return true


func _assert_chart(chart: Control, values: Array, shares: Array, message: String) -> void:
	expect(chart != null, message + ": chart exists")
	if chart == null: return
	expect(_equal_values(chart.get("weights"), values), message + ": chart follows displayed draft values")
	var total := 0.0
	for value in values: total += float(value)
	expect(is_equal_approx(float(chart.get("total")), total), message + ": chart retains the true allocated total")
	var actual: Array = chart.call("get_chart_shares")
	expect(_equal_values(actual, shares), message + ": slice proportions are correct")
	var share_total := 0.0
	for share in actual: share_total += float(share)
	expect(is_equal_approx(share_total, 1.0), message + ": complete pie accounts for every slice")


func _assert_bounds(chart: Control, menu: Control, resolution: Vector2i, message: String) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(resolution))
	expect(viewport.encloses(menu.get_global_rect()), message + ": menu fits viewport")
	expect(viewport.encloses(chart.get_global_rect()) and menu.get_global_rect().encloses(chart.get_global_rect()), message + ": chart fits its visible menu")
	expect(chart.size.x >= 190 and chart.size.y >= 190, message + ": pie retains a readable size")


func _snapshot(project: ProjectState, run: RunState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(),
		project.get_current_cycle(), project.get_current_scope(), project.get_known_bugs(),
		project.get_core_score(0), project.get_core_score(1), project.get_core_score(2), project.get_core_score(3)]


func _capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var path := OUTPUT + "%s-%dx%d.png" % [label, resolution.x, resolution.y]
	expect(root.get_texture().get_image().save_png(path) == OK, "Rendered evidence saved: " + path)


func _verify_predevelopment_chart(resolution: Vector2i) -> void:
	var overlay := PredevelopmentOverlay.new()
	overlay.theme = preload("res://resources/ui/workspace_theme.tres")
	root.add_child(overlay)
	overlay.offset_left = 18
	overlay.offset_top = 18
	overlay.offset_right = -18
	overlay.offset_bottom = -60 # Reserve the same bottom HUD space in this UI fixture.
	overlay.open()
	await _settle_chart()
	var chart: Control = overlay.get("priority_chart")
	_assert_chart(chart, [25, 25, 25, 25], [.25, .25, .25, .25], "Pre-Development default")
	expect(chart.get("category_names") == CORE_NAMES, "Pre-Development labels use Graphics, Sound, Tech, Design")
	_assert_bounds(chart, overlay, resolution, "Pre-Development %s" % resolution)
	for i in range(4): overlay.priority_sliders[i].value = [50, 15, 15, 20][i]
	await _settle_chart()
	_assert_chart(chart, [50, 15, 15, 20], [.5, .15, .15, .2], "Pre-Development edited")
	expect(not overlay.begin_button.disabled, "Valid displayed allocation enables Begin Development")
	await _capture("predevelopment", resolution)
	overlay.priority_sliders[0].value = 40
	await _settle_chart()
	_assert_chart(chart, [40, 15, 15, 20], [.4, .15, .15, .2, .1], "Pre-Development under budget")
	expect(overlay.begin_button.disabled, "Unallocated draft remains invalid for Begin Development")
	for slider in overlay.priority_sliders: slider.value = 50
	await _settle_chart()
	_assert_chart(chart, [50, 50, 50, 50], [.25, .25, .25, .25], "Pre-Development over budget")
	expect(overlay.begin_button.disabled, "Over-budget draft remains invalid for Begin Development")
	overlay.queue_free()
	await _settle_chart()


func _verify_phase_chart(title: String, resolution: Vector2i) -> void:
	var project := ProjectState.new(30)
	var run := new_run(12345)
	if title == "Beta":
		project.finalize_design_bugs(false, 0, [&"text"], [])
		project.finalize_alpha(0, [], [])
	var phase: Control = load("res://scenes/phases/%s_phase.tscn" % title.to_lower()).instantiate()
	root.add_child(phase)
	phase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if title == "Beta": phase.setup(project, run, snapshots)
	else: phase.setup(project, run)
	var overlay: PriorityOverlay = phase.get_workspace().overlay
	expect(overlay.open(), title + ": initialization opens")
	await _settle_chart()
	var chart: Control = overlay.get("priority_chart")
	var defaults := [35, 35, 30] if title == "Beta" else [25, 25, 25, 25]
	var default_shares := [.35, .35, .3] if title == "Beta" else [.25, .25, .25, .25]
	var names := BETA_INPUTS if title == "Beta" else CORE_INPUTS
	_assert_chart(chart, defaults, default_shares, title + " default")
	expect(chart.get("category_names") == (["QA", "Marketing", "Insider"] if title == "Beta" else CORE_NAMES), title + ": chart names match phase categories")
	_assert_bounds(chart, overlay.dialog, resolution, title + " %s" % resolution)
	var before := _snapshot(project, run)
	var committed: Dictionary = phase.get_priority_distribution()
	var values := [50, 20, 30] if title == "Beta" else [50, 15, 15, 20]
	var shares := [.5, .2, .3] if title == "Beta" else [.5, .15, .15, .2]
	for i in range(names.size()): (phase.get_node("%" + names[i]) as Range).value = values[i]
	await _settle_chart()
	_assert_chart(chart, values, shares, title + " staged initialization")
	expect(phase.get_priority_distribution() == committed and _snapshot(project, run) == before, title + ": chart and draft edits preserve committed values, cash, time, redraws and project")
	await _capture(title.to_lower() + "-initial", resolution)
	phase.reset_priority_draft()
	await _settle_chart()
	_assert_chart(chart, defaults, default_shares, title + " reset")
	expect(overlay.commit_draft(), title + ": default allocation begins phase")
	await _settle_chart()
	var pool: Array = phase.get("_candidate_cards").duplicate()
	before = _snapshot(project, run)
	expect(phase.open_priority_overlay(), title + ": active priority editor opens")
	(phase.get_node("%" + names[0]) as Range).value += 5
	await _settle_chart()
	var over: Array = defaults.duplicate()
	over[0] += 5
	var over_shares: Array = []
	for value in over: over_shares.append(float(value) / 105.0)
	_assert_chart(chart, over, over_shares, title + " invalid active draft")
	expect(not overlay.commit_draft() and overlay.visible, title + ": chart does not bypass invalid-total rejection")
	overlay.cancel()
	await _settle_chart()
	_assert_chart(chart, defaults, default_shares, title + " cancel restores display")
	expect(_snapshot(project, run) == before and phase.get("_candidate_cards") == pool and phase.get_priority_distribution() == committed, title + ": open, draft, rejected commit and Cancel preserve gameplay")
	phase.queue_free()
	await _settle_chart()


func _verify_contract_chart(resolution: Vector2i) -> void:
	var project := release(751) # Synthetic release solely to expose the Contract UI.
	var run := new_run(12345)
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(studio)
	studio.setup(project, run, snapshots)
	studio.hide()
	var state := run.accept_primitive_contract()
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	phase.setup(state, run)
	root.add_child(phase)
	phase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle_chart()
	var before := [run_snapshot(run, project), project_snapshot(project), state.get_priority_distribution(), state.get_successful_hand_count()]
	var pool: Array = phase.get("_candidate_cards").duplicate()
	phase.open_priority_overlay()
	await _settle_chart()
	var modal: CanvasLayer = phase.get("_priority_modal")
	var chart: Control = phase.get("_priority_chart")
	var panel := modal.find_child("ContractModal", true, false) as PanelContainer
	_assert_chart(chart, [25, 25, 25, 25], [.25, .25, .25, .25], "Contract default")
	_assert_bounds(chart, panel, resolution, "Contract %s" % resolution)
	var inputs: Dictionary = phase.get("_priority_inputs")
	for i in range(4): (inputs[i] as Range).value = [50, 15, 15, 20][i]
	await _settle_chart()
	_assert_chart(chart, [50, 15, 15, 20], [.5, .15, .15, .2], "Contract edited")
	await _capture("contract", resolution)
	var cancel: Button
	for button in panel.find_children("*", "Button", true, false):
		if button.text == "Cancel": cancel = button
	expect(cancel != null, "Contract priority menu retains a Cancel button")
	if cancel != null: cancel.pressed.emit()
	await _settle_chart()
	_assert_chart(chart, [25, 25, 25, 25], [.25, .25, .25, .25], "Contract cancellation reset")
	expect(not modal.visible, "Contract Cancel closes the priority menu")
	expect([run_snapshot(run, project), project_snapshot(project), state.get_priority_distribution(), state.get_successful_hand_count()] == before and phase.get("_candidate_cards") == pool, "Contract chart editing and cancellation preserve frozen release, sales, cash, calendar, redraws, hands and candidates")
	phase.queue_free()
	studio.queue_free()
	await _settle_chart()
