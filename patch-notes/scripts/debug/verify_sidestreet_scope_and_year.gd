## Task 21: committed Scope gate, preserved legacy offers and one calendar.
extends "res://scripts/debug/verify_sidestreet_contract.gd"

func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	for required in [30, 40, 60]: # State-level sizes; no new size UI or balance rule.
		for scope in [0, required - 1, required, required + 1]:
			var scope_run := new_run()
			var scope_project := release(10, scope, required)
			check(scope_run.register_release(scope_project), "Under/at/above Scope launches retain normal sales")
			var count := 1 if scope >= required else 0
			check(scope_run.get_sidestreet_offer_ids().size() == count, "Scope %d / %d produces %d entitlement" % [scope, required, count])
			var scope_before := snapshot(scope_run, [scope_project])
			check(scope_run.register_release(scope_project) and snapshot(scope_run, [scope_project]) == scope_before, "Duplicate launch cannot mint or remove an entitlement")
			check(not scope_run.is_sidestreet_offer_available(), "Qualified offer waits for Ironclad")
			var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
			root.add_child(studio)
			check(studio.setup(scope_project, scope_run, snapshots) and snapshot(scope_run, [scope_project]) == scope_before, "Reconstructed Studio preserves qualification, cash, calendar, redraws and sales")
			studio.queue_free()
	for scope in [20, 21, 22, 23]:
		var starter_run := new_run()
		var starter_project := release(0, scope)
		check(starter_run.register_release(starter_project) and starter_run.get_sidestreet_offer_ids().is_empty() and starter_run.is_primitive_contract_offer_available(), "Starter Scope %d retains Ironclad but not SideStreet" % scope)
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
	# A constructed calendar/UI fixture, not a rival solvency or legal campaign
	# study. Use the supported player-only entry path; ordinary rival campaigns
	# have separate bounded record/replay and distress coverage.
	var run := RunState.new()
	run.initialize_cash_cents(0)
	check(run.create_studio_with_traits("Calendar Studio",&"action",[]),"Named player-only calendar fixture initializes")
	var game := load("res://scenes/gameplay.tscn").instantiate() as Control
	game.run_state = run
	root.add_child(game)
	await process_frame
	await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
	# Synthetic year-label fixture: explicitly funded, not a played route.
	check(run.add_cash_cents(3000000, &"financing_in"), "Calendar fixture funds its actual rent obligations")
	var studio: StudioPhase = game.get("_active_phase")
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	var actions:=preload("res://scripts/debug/ui_test_actions.gd")
	var engine_id: StringName=actions.create_feature_engine(run,"Calendar Engine")
	for cycle in [0, 47, 48, 191, 192]:
		while run.get_completed_run_cycles() < cycle:
			var advanced := run.complete_productive_action()
			check(advanced, "Shared productive boundary advances")
			if not advanced: break # Never hang if a future obligation rejects.
		await process_frame
		await process_frame
		var year: int = 1980 + cycle / 48
		check(run.get_current_year() == year and hud.footer.text.contains(str(year)) and hud.header_title.text.contains(str(year)), "Cycle %d shows year %d in Studio and shared HUD" % [cycle, year])
		var browse_before := snapshot(run, [])
		var store: FeatureStore=await actions.open_feature_implementation(studio,engine_id)
		store.hide()
		await create_timer(0.45).timeout
		check(snapshot(run, []) == browse_before and hud.footer.text.contains(str(year)), "Passive browsing does not advance year")
	for resolution in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = resolution
		root.content_scale_size = resolution
		await process_frame
		await process_frame
		var title := hud.header_title
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
		check(run.add_cash_cents(3000000, &"financing_in"), "Synthetic purchase/year fixture funds rent")
		run.finalize_starter_selection()
		if action!="campaign":
			# Constructed owned-engine control; creation economics are not exercised.
			check(run._register_proprietary_engine(&"calendar_control","Calendar control") and run.select_engine(&"calendar_control"),"Research fixture selects an editable owned engine")
			check(run.register_release(release(0,30,30,run)),"Research fixture satisfies the existing first-release gate")
			var parents: Array=[&"keyboard_and_mouse",&"menu_system"] if action=="store" else [&"4_color_palette"]
			for parent: StringName in parents:check(ResearchTestActions.acquire(run,parent),"Research fixture pays for prerequisite "+str(parent))
		# Reach the calendar through checked transactions before the release.
		var release_cycle := 187 if action == "campaign" else 191
		while run.get_completed_run_cycles() < release_cycle:
			var advanced := run.complete_productive_action()
			check(advanced, "Synthetic boundary fixture advances all ledgers together")
			if not advanced: break
		var project := release(10,30,30,run)
		run.register_release(project)
		if action == "campaign":
			for cycle in range(4):run.complete_productive_action()
		var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
		root.add_child(studio)
		studio.setup(project, run, snapshots)
		var hud := GameplayHUD.new()
		root.add_child(hud)
		hud.setup(project, run)
		hud.set_phase(studio)
		var ok := false
		if action == "store": ok = ResearchTestActions.acquire(run,&"save_files")
		elif action == "reserve": ok = ResearchTestActions.acquire(run,&"sprites")
		else: ok = run.purchase_post_launch_campaign(project.get_release_id(), 191)
		await process_frame
		await process_frame
		check(ok and run.get_completed_run_cycles() == 192 and hud.footer.text.contains("1984") and hud.header_title.text.contains("1984"), action + " updates both year labels at its successful boundary")
		var before := snapshot(run, [project])
		studio.setup(project, run, snapshots)
		check(snapshot(run, [project]) == before and hud.footer.text.contains("1984"), "Reconstructed Studio reads the same year without a cycle")
		studio.queue_free()
		hud.queue_free()
		await process_frame
