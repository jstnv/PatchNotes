## Task 21: committed Scope gate, preserved legacy offers and one calendar.
extends "res://scripts/debug/verify_sidestreet_contract.gd"

func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	for required in [30, 40, 60]: # State-level sizes; no new size UI or balance rule.
		for scope in [0, required - 1, required, required + 1]:
			var run := new_run()
			var project := release(10, scope, required)
			check(run.register_release(project), "Under/at/above Scope launches retain normal sales")
			var count := 1 if scope >= required else 0
			check(run.get_sidestreet_offer_ids().size() == count, "Scope %d / %d produces %d entitlement" % [scope, required, count])
			var before := snapshot(run, [project])
			check(run.register_release(project) and snapshot(run, [project]) == before, "Duplicate launch cannot mint or remove an entitlement")
			check(not run.is_sidestreet_offer_available(), "Qualified offer waits for Ironclad")
			var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
			root.add_child(studio)
			check(studio.setup(project, run, snapshots) and snapshot(run, [project]) == before, "Reconstructed Studio preserves qualification, cash, calendar, redraws and sales")
			studio.queue_free()
	for scope in [20, 21, 22, 23]:
		var run := new_run()
		var project := release(0, scope)
		check(run.register_release(project) and run.get_sidestreet_offer_ids().is_empty() and run.is_primitive_contract_offer_available(), "Starter Scope %d retains Ironclad but not SideStreet" % scope)
	var run := new_run()
	var project := release(0, 29)
	run.register_release(project)
	var before := snapshot(run, [project])
	check(not run.register_release(ProjectState.new(30)) and snapshot(run, [project]) == before, "Failed launch preserves offer/history/cash/calendar/redraw/sales")
	var iron := await complete_contract(run, run.accept_primitive_contract())
	(iron.phase as ContractPhase).queue_free()
	check(not run.is_sidestreet_offer_available(), "Ironclad cannot turn an under-Scope release into an entitlement")
	var qualified := release(0, 40, 40)
	check(run.register_release(qualified) and run.is_sidestreet_offer_available(), "Qualifying launch after Ironclad is immediately available")
	# Pre-rule persisted entitlement fixture: the old ID and accepted state survive.
	var legacy := new_run()
	legacy.register_release(project)
	var id := project.get_release_id()
	var offer_id := StringName("%s:%s" % [ContractState.SIDESTREET_CONTRACT_ID, id])
	legacy.get("_sidestreet_entitlements")[id] = {"offer_id": offer_id, "state": null}
	var old := await complete_contract(legacy, legacy.accept_primitive_contract())
	(old.phase as ContractPhase).queue_free()
	var accepted := legacy.accept_sidestreet_offer(offer_id)
	check(accepted != null and legacy.register_release(project) and legacy.get_active_contract() == accepted, "Legacy under-Scope accepted offer remains authoritative on reconstruction")
	var done := await complete_contract(legacy, accepted)
	(done.phase as ContractPhase).queue_free()
	var frozen := snapshot(legacy, [project])
	check(legacy.register_release(project) and snapshot(legacy, [project]) == frozen and legacy.get_sidestreet_completion_history().has(offer_id), "Legacy completed offer and exact payout remain immutable")
	await _verify_year_labels()
	await _verify_studio_purchase_years()
	print("Task 21 Scope/year verification failures: ", failures)
	quit(0 if failures == 0 else 1)

func _verify_year_labels() -> void:
	var game := load("res://scenes/gameplay.tscn").instantiate() as Control
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Calendar Studio"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	var studio: StudioPhase = game.get("_active_phase")
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	for cycle in [0, 23, 24, 95, 96]:
		while run.get_completed_run_cycles() < cycle:
			check(run.complete_productive_action(), "Shared productive boundary advances")
		var year: int = 1980 + cycle / 24
		check(run.get_current_year() == year and hud.footer.text.contains(str(year)) and studio.get_node("Dashboard/Layout/Heading/Title").text.contains(str(year)), "Cycle %d shows year %d in Studio and shared HUD" % [cycle, year])
		var before := snapshot(run, [])
		studio.get_node("%FeatureStoreButton").pressed.emit()
		(studio.get("_feature_store") as FeatureStore).hide()
		check(snapshot(run, []) == before and hud.footer.text.contains(str(year)), "Passive browsing does not advance year")
	for resolution in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = resolution
		root.content_scale_size = resolution
		await process_frame
		await process_frame
		var title := studio.get_node("Dashboard/Layout/Heading/Title") as Label
		check(title.is_visible_in_tree() and title.get_global_rect().end.x <= resolution.x, "Studio year heading fits %s" % resolution)
		var font := hud.footer.get_theme_font("font")
		var year_prefix := hud.footer.text.substr(0, hud.footer.text.find("1984") + 4)
		check(font.get_string_size(year_prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, hud.footer.get_theme_font_size("font_size")).x <= hud.footer.size.x, "Shared HUD year remains readable before ellipsis at %s" % resolution)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://design-logs/task21-v1/year-%dx%d.png" % [resolution.x, resolution.y])
	var before := snapshot(run, [])
	check(not run.complete_productive_action(Callable(), -run.get_cash_cents()-1) and snapshot(run, []) == before, "Failed cash preflight preserves year and state")
	run.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	before = snapshot(run, [])
	check(not run.complete_productive_action() and snapshot(run, []) == before, "Calendar overflow rolls back without year change")
	game.queue_free()
	await process_frame

func _verify_studio_purchase_years() -> void:
	for action in ["store", "reserve", "campaign"]:
		var run := new_run()
		run.set_studio_name("Boundary Studio", &"adventure")
		run.finalize_starter_selection()
		var project := release(10)
		run.register_release(project)
		if action == "campaign":
			run.complete_productive_action()
			run.complete_productive_action()
		run.set("_completed_run_cycles", 95) # Boundary fixture, not a playable time skip.
		var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
		root.add_child(studio)
		studio.setup(project, run, snapshots)
		var hud := GameplayHUD.new()
		root.add_child(hud)
		hud.setup(project, run)
		var ok := false
		if action == "store": ok = run.purchase_feature(&"save_files")
		elif action == "reserve": ok = run.purchase_primitive_reserve_feature(&"sprites")
		else: ok = run.purchase_post_launch_campaign(project.get_release_id(), 95)
		check(ok and run.get_completed_run_cycles() == 96 and hud.footer.text.contains("1984") and studio.get_node("Dashboard/Layout/Heading/Title").text.contains("1984"), action + " updates both year labels at its successful boundary")
		var before := snapshot(run, [project])
		studio.setup(project, run, snapshots)
		check(snapshot(run, [project]) == before and hud.footer.text.contains("1984"), "Reconstructed Studio reads the same year without a cycle")
		studio.queue_free()
		hud.queue_free()
		await process_frame
