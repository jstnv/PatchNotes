extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Empty Release Reproduction"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var rows: Array = []
	var one_feature := "--one-feature" in OS.get_cmdline_user_args()
	var stress_seed := 260930201
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stress-seed="): stress_seed = int(arg.trim_prefix("--stress-seed="))
	var run: RunState = game.run_state
	for number in range(32):
		var studio: StudioPhase = game.get("_active_phase")
		if not game.call("_begin_next_project", studio, "Empty %d" % number, &"action", &"fantasy"): break
		var design: DesignPhase = game.get("_active_phase")
		design.get("_deal_rng").seed = 260930000 + number
		design.get("_finalization_rng").seed = 260930100 + number
		design.get_workspace().overlay.commit_draft()
		design.call("_on_proceed_to_alpha_pressed")
		var alpha: AlphaPhase = game.get("_active_phase")
		alpha.get("_deal_rng").seed = stress_seed if one_feature else 260930200 + number
		alpha.get("_finalization_rng").seed = 260930300 + number
		if one_feature: alpha.set_priority_distribution({0:50, 1:5, 2:40, 3:5})
		alpha.get_workspace().overlay.commit_draft()
		if one_feature:
			var views := alpha.get_node("%HandContainer").get_children()
			var chosen: Array = []
			var candidates: Array = []
			var feature: CardView
			for view: CardView in views:
				candidates.append(str(view.card_data.id))
				if view.card_data.card_type == &"pass" and chosen.size() < 3: chosen.append(view)
				elif view.card_data.card_type == &"feature" and feature == null: feature = view
			if chosen.size() != 3 or feature == null:
				rows.append({"number": number, "blocked_at": "one-Feature draw unavailable", "candidates": candidates})
				break
			chosen.append(feature)
			var committed: Array = []
			for view: CardView in chosen:
				committed.append(str(view.card_data.id))
				view.card_pressed.emit(view)
			alpha.get_node("%PlayAlphaHandButton").pressed.emit()
			alpha.get_workspace().hand_motion.cancel()
			rows.append({"number": number, "seed": stress_seed, "candidates": candidates, "committed": committed, "cash":run.get_cash_cents(), "cycle":run.get_completed_run_cycles()})
		alpha.request_proceed_to_beta()
		if alpha.get_node("%UnderScopeDialog").visible: alpha.get_node("%UnderScopeDialog").confirmed.emit()
		if not game.get("_active_phase") is BetaPhase:
			rows.append({"number": number, "blocked_at": "Alpha", "cash": run.get_cash_cents(), "cycle": run.get_completed_run_cycles()})
			break
		var beta: BetaPhase = game.get("_active_phase")
		beta.get_workspace().overlay.commit_draft()
		game.get("_review_rng").seed = 260930400 + number
		var launched := beta.request_launch()
		if not launched: launched = beta.confirm_launch_for_verification()
		rows.append({"number": number, "launched": launched, "scope": game.project_state.get_current_scope(), "project_cycles": game.project_state.get_current_cycle(), "cash": run.get_cash_cents(), "cycle": run.get_completed_run_cycles(), "release_id": game.project_state.get_release_id(), "sales": run.get_released_game_sales(game.project_state.get_release_id())})
		if not launched: break
		await process_frame
	var records: Array = []
	for id in run.get_released_game_ids(): records.append(run.get_released_game_sales(id))
	var output := {"source": "e879c7b5259bf9696ea11f40f83597f3f6442060", "rows": rows, "cash": run.get_cash_cents(), "cycle": run.get_completed_run_cycles(), "sales": records, "sidestreet": run.get_sidestreet_offer_ids()}
	var path := "res://design-logs/overnight-2026-09-30-v1/one-feature-stress-%d.json" % stress_seed if one_feature else "res://design-logs/overnight-2026-09-30-v1/empty-after.json"
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(output, "  "))
	print("Empty reproduction: releases=%d cash=%d cycles=%d" % [records.size(), run.get_cash_cents(), run.get_completed_run_cycles()])
	game.queue_free()
	await process_frame
	quit()
