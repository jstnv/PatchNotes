extends SceneTree

var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1
func _initialize() -> void: go.call_deferred()
func frames() -> void:
	for i in 6: await process_frame
func go() -> void:
	await process_frame
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Skill Studio", &"action", []), "Creates a Studio")
	var created := run.create_proprietary_engine(run.get_proprietary_engine_creation_quote("Test Engine"))
	check(created.get("ok", false), "Creates an engine")
	if not created.get("ok", false): quit(1); return
	var id: StringName = created.engine_id
	var browser = load("res://scripts/ui/engine_market_browser.gd").new()
	root.add_child(browser); await frames()
	browser.open(run, null); browser._inspect(id); browser._open_skill_tree(); await frames()
	browser.skill_grid.inspect(&"graphics_1"); await frames()
	check(browser.skill_progress.visible and not browser.skill_grid.action_button.visible, "Incomplete challenge shows only progress")
	browser.skill_grid.inspect(&"graphics_2"); await frames()
	check(browser.skill_progress.visible and not browser.skill_grid.action_button.visible, "Locked challenge shows only progress")
	var project := ProjectState.new(30)
	check(project.set_engine_id(id, 25), "Binds engine to project")
	var card := CardData.new()
	card.card_type = &"feature"; card.phase = &"design"; card.primary_stat = &"graphics"; card.primary_value = 5
	run.credit_engine_skill_feature(project, card)
	browser._refresh_skill_tree(); browser.skill_grid.inspect(&"graphics_1"); await frames()
	check(not run.get_engine_skill_quote(id, &"graphics").is_empty(), "Completed challenge has an affordable quote")
	check(not browser.skill_progress.visible and browser.skill_grid.action_button.visible and not browser.skill_grid.action_button.disabled, "Ready challenge replaces progress with enabled Implement")
	check(browser.skill_grid.action_button.text.contains("125.00"), "Implement shows the actual cost")
	for dimensions: Vector2i in [Vector2i(900, 600), Vector2i(1152, 648), Vector2i(1280, 720)]:
		root.size = dimensions; root.content_scale_size = dimensions; await frames()
		check(browser.skill_grid.popup.get_global_rect().encloses(browser.skill_grid.action_button.get_global_rect()), "Implement stays inside inspector at %s" % dimensions)
	if DisplayServer.get_name() != "headless" and not OS.get_environment("PN_ENGINE_BAR_CAPTURE").is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_ENGINE_BAR_CAPTURE"))
	var funds: int = run._cash_cents
	run._cash_cents = 0
	browser._refresh_skill_tree(); browser.skill_grid.inspect(&"graphics_1"); await frames()
	check(run.get_engine_skill_quote(id, &"graphics").is_empty(), "Unaffordable fixture has no purchase quote")
	check(not browser.skill_progress.visible and browser.skill_grid.action_button.visible and browser.skill_grid.action_button.disabled, "Unaffordable ready challenge shows disabled Implement in place of progress")
	run._cash_cents = funds
	browser._refresh_skill_tree(); browser.skill_grid.inspect(&"graphics_1"); await frames()
	var before: int = run.get_cash_cents()
	var cycle: int = run.get_completed_run_cycles()
	browser.skill_grid.action_button.pressed.emit(); await frames()
	check(run.get_cash_cents() == before - 12500 and run.get_completed_run_cycles() == cycle, "Implement purchases at the quoted cost without a cycle")
	browser.skill_grid.inspect(&"graphics_1"); await frames()
	check(browser.skill_progress.visible and browser.skill_progress_label.text == "Implemented" and not browser.skill_grid.action_button.visible, "Purchased node shows Implemented status")
	browser.skill_grid.inspect(&"graphics_2"); await frames()
	check(browser.skill_progress.visible and not browser.skill_grid.action_button.visible, "Next challenge returns to progress")
	print("ENGINE_IMPLEMENT_BAR checks=%d failures=%d" % [checks, failures])
	quit(failures)
