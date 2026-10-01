## Analysis only: native legal calendar stress routes, no runtime mutations.
extends "res://analysis/task21_route_v1.gd"

var stress_arm := "priority"
var stress_cap := 1104
var stress_cycles: Array[Dictionary] = []
var efficient_selection := false

func _run() -> void:
	stress_arm = _arg("--stress=", "priority")
	stress_cap = int(_arg("--cap=", "1104"))
	if stress_arm not in ["priority", "empty", "repeat"]: quit(2); return
	random_inputs.seed = 290929000
	var row := await _stress_route()
	var tag := _arg("--tag=", "")
	var file := FileAccess.open("res://design-logs/task24-v1/stress_" + stress_arm + ("_" + tag if not tag.is_empty() else "") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"arm": stress_arm, "source_revision": "608a2c62ab0850cf607f7ff627b042a49b5d2dfb", "production_seed": 270927000, "environment_seed": 290929000, "requested_cycle": stress_cap, "command": OS.get_cmdline_args(), "rows": [row]}, "  "))
	file.close()
	print("TASK24 STRESS arm=%s valid=%s cycle=%s releases=%s" % [stress_arm, row.valid, row.final.cycle, row.releases.size()])
	quit(0 if row.valid else 1)

func _stress_route() -> Dictionary:
	var out := {"case": 0, "seed": 270927000, "arm": stress_arm, "errors": [], "blockers": [], "actions": [], "purchases": [], "releases": [], "studios": [], "valid": false}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.set_snapshot_initialization_rolls(11, 23)
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Calendar Stress " + stress_arm
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	_stress_studio(game, out, "new_run")
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	for raw_id: String in ROSTERS[20][0]:
		var id := StringName(raw_id)
		var quote := run.get_primitive_reserve_offer(id)
		var before := _state(game)
		(store.get("_nodes")[id] as Button).pressed.emit()
		(store.get("_buy") as Button).pressed.emit()
		out.purchases.append({"kind": "starter", "id": id, "quote": quote, "success": run.owns_feature(id), "before": before, "after": _state(game)})
		_stress_studio(game, out, "starter_purchase:" + raw_id)
		if not run.owns_feature(id): out.errors.append("starter_purchase:" + raw_id)
	store.hide()
	out["starter_summary"] = run.get_starter_pool_summary()
	if out.starter_summary.scope != 20 or out.starter_summary.spent_cents > 400000: out.errors.append("starter_cap")
	if not out.errors.is_empty(): return await _stress_finish(game, out)
	if not _begin_game(game, "Game One", &"action", out) or not await _develop_game(game, "synergy", "mixed", "qa", 270927000, 1, out):
		out.errors.append("first_game"); return await _stress_finish(game, out)
	_stress_release(game, out, 1)
	if run.is_sidestreet_offer_available(): out.errors.append("under_scope_first_release_has_sidestreet")
	if not await _contract(game, "synergy", 270927000, out, "ironclad"):
		out.errors.append("ironclad"); return await _stress_finish(game, out)
	_stress_studio(game, out, "ironclad_completed")
	if stress_arm != "empty":
		if not _buy_primitive_reserves(game, out): return await _stress_finish(game, out)
	var number := 2
	while out.errors.is_empty() and run.get_completed_run_cycles() < stress_cap and number <= 1200:
		var title := "Stress Game %d" % number
		if not _begin_game(game, title, &"adventure", out):
			out.errors.append("begin_game_%d" % number); break
		await process_frame
		var success := false
		if stress_arm == "empty": success = _empty_native(game, out, number)
		elif stress_arm == "priority" and number >= 3: success = _priority_native(game, out, number)
		else: success = await _efficient_native(game, out, number)
		if not success:
			out.errors.append("development_%d" % number); break
		_stress_release(game, out, number)
		if stress_arm == "empty" and run.is_sidestreet_offer_available(): out.errors.append("empty_release_has_sidestreet")
		if stress_arm == "priority" and number == 2 and game.project_state.get_current_scope() < game.project_state.get_required_scope(): out.errors.append("priority_requires_full_scope_release")
		if stress_arm == "repeat" and run.is_sidestreet_offer_available() and run.get_completed_run_cycles() < stress_cap:
			if not await _contract(game, "synergy", 270927000 + number * 17, out, "sidestreet_%d" % number): out.errors.append("sidestreet_%d" % number); break
			_stress_studio(game, out, "sidestreet_%d_completed" % number)
		number += 1
		if number % 50 == 0:
			print("STRESS progress ", stress_arm, " cycle=", run.get_completed_run_cycles(), " releases=", number - 1)
			var partial := FileAccess.open("res://design-logs/task24-v1/stress_" + stress_arm + "_progress_" + _arg("--tag=", "main") + ".json", FileAccess.WRITE)
			partial.store_string(JSON.stringify({"arm": stress_arm, "completed_checkpoint_only": true, "cycles": stress_cycles, "releases": out.releases, "studio_visits": out.studios}, "  "))
			partial.close()
	return await _stress_finish(game, out)

func _buy_primitive_reserves(game: Control, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	var ids: Array = store.get("_nodes").keys()
	ids.sort()
	for id: StringName in ids:
		var quote := run.get_primitive_reserve_offer(id)
		if quote.is_empty() or quote.owned: continue
		if not quote.can_purchase:
			out.blockers.append({"action": "buy_primitive", "id": id, "quote": quote, "state": _state(game)})
			out.errors.append("primitive_reserve_unaffordable"); store.hide(); return false
		var before := _state(game)
		(store.get("_nodes")[id] as Button).pressed.emit()
		(store.get("_buy") as Button).pressed.emit()
		out.purchases.append({"kind": "primitive_reserve", "id": id, "quote": quote, "success": run.owns_feature(id), "before": before, "after": _state(game)})
		_stress_studio(game, out, "reserve_purchase:" + str(id))
		if not run.owns_feature(id): out.errors.append("primitive_reserve_purchase_rejected"); store.hide(); return false
	store.hide()
	_stress_studio(game, out, "all_primitive_reserves_bought")
	return true

func _efficient_native(game: Control, out: Dictionary, number: int) -> bool:
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	active_project = project
	var design: DesignPhase = game.get("_active_phase")
	var seed_value := 270927000 + number * 500000
	design.get("_deal_rng").seed = seed_value + 1
	design.get("_finalization_rng").seed = seed_value + 2
	if not design.get_workspace().overlay.commit_draft(): return false
	efficient_selection = true
	# Exhaust the owned finite Design Features to preserve sufficient Alpha Scope.
	for hand in range(20):
		if (design.get("_available_features") as Array).is_empty(): break
		if not _production_hand(design, project, run, "ordinary", "mixed", "design", number, out):
			out.blockers.append({"action": "Design hand", "game": number, "hand": hand + 1, "state": _state(game)})
			efficient_selection = false; return false
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: efficient_selection = false; return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = seed_value + 3
	alpha.get("_finalization_rng").seed = seed_value + 4
	if not alpha.get_workspace().overlay.commit_draft(): efficient_selection = false; return false
	for hand in range(25):
		if project.get_current_scope() >= project.get_required_scope(): break
		if not _production_hand(alpha, project, run, "ordinary", "mixed", "alpha", number, out):
			out.blockers.append({"action": "Alpha hand", "game": number, "hand": hand + 1, "state": _state(game)})
			efficient_selection = false; return false
	efficient_selection = false
	if project.get_current_scope() < project.get_required_scope():
		out.blockers.append({"action": "full_scope_target_not_reached", "game": number, "state": _state(game)})
		return false
	return _finish_from_alpha(game, out, number)

func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	if not efficient_selection: return super._choose_production(cards, project, run, policy, focus)
	var best := -INF
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var cost := run.primitive_feature_hand_cost_cents(hand)
					if cost < 0 or cost > run.get_cash_cents(): continue
					var value := 0.0
					for card: CardData in hand: value += card.scope * 100.0 + (card.primary_value + card.secondary_value) * 2.0
					if hand.all(func(card: CardData): return card.primary_stat == hand[0].primary_stat): value += 8.0
					value -= cost / 10000.0
					if value > best: best = value; choice = [a, b, c, d]
	return choice

func _priority_native(game: Control, out: Dictionary, number: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = 270927700
	design.get("_finalization_rng").seed = 270927701
	if not design.get_workspace().overlay.commit_draft(): return false
	var commits := 0
	var start := _state(game)
	var next_checkpoint := stress_cap
	for checkpoint: int in [96, 240, 480, 720, 960, 1104]:
		if checkpoint >= game.run_state.get_completed_run_cycles(): next_checkpoint = mini(checkpoint, stress_cap); break
	while game.run_state.get_completed_run_cycles() < next_checkpoint:
		var allocation := {0: 30, 1: 20, 2: 25, 3: 25} if commits % 2 == 0 else {0: 25, 1: 25, 2: 25, 3: 25}
		var before := _state(game)
		if not design.commit_priority_distribution(allocation):
			out.blockers.append({"action": "priority_commit", "allocation": allocation, "before": before}); return false
		out.actions.append({"phase": "alternating_priority", "game": number, "allocation": allocation, "before": before, "after": _state(game)})
		if game.run_state.get_completed_run_cycles() != int(before.cycle) + 1: return false
		commits += 1
	if not out.has("priority_stress"): out["priority_stress"] = []
	out.priority_stress.append({"commits": commits, "before": start, "after": _state(game)})
	return _finish_from_design(game, out, number)

func _empty_native(game: Control, out: Dictionary, number: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = 270927000 + number
	design.get("_finalization_rng").seed = 270927003 + number
	if not design.get_workspace().overlay.commit_draft(): return false
	return _finish_from_design(game, out, number)

func _finish_from_design(game: Control, out: Dictionary, number: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = 270927001 + number
	alpha.get("_finalization_rng").seed = 270927002 + number
	if not alpha.get_workspace().overlay.commit_draft(): return false
	return _finish_from_alpha(game, out, number)

func _finish_from_alpha(game: Control, out: Dictionary, number: int) -> bool:
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible:
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
		out.actions.append({"phase": "under_scope_warning_accepted", "game": number, "scope": game.project_state.get_current_scope(), "required_scope": game.project_state.get_required_scope()})
	if not game.get("_active_phase") is BetaPhase: return false
	var beta: BetaPhase = game.get("_active_phase")
	if not beta.get_workspace().overlay.commit_draft(): return false
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = 270927007 + number * 97
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "stress_launch_no_beta_hands", "game": number, "before": before, "after": _state(game), "success": launched})
	return launched and game.get("_active_phase") is StudioPhase

func _stress_release(game: Control, out: Dictionary, number: int) -> void:
	var record := _release(game.project_state, game.run_state)
	record["game"] = number
	record["required_scope"] = game.project_state.get_required_scope()
	record["meets_required_scope"] = int(record.scope) >= int(record.required_scope)
	record["committed"] = game.run_state.get_released_game_ids().has(game.project_state.get_release_id())
	record["sidestreet_offer_available"] = game.run_state.is_sidestreet_offer_available()
	out.releases.append(record)
	_stress_studio(game, out, "release_%d" % number)

func _stress_studio(game: Control, out: Dictionary, reason: String) -> void:
	var snap := _state(game)
	snap["reason"] = reason
	snap["owned_ids"] = game.run_state.get_owned_feature_ids()
	snap["is_studio"] = game.get("_active_phase") is StudioPhase
	snap["eligible_project_ids"] = game.run_state.get_owned_feature_ids().filter(func(id): return game.run_state.get("_feature_definitions")[id].phase in ["design", "alpha"])
	snap["full_scope_release_count"] = out.releases.filter(func(r: Dictionary): return r.meets_required_scope).size()
	snap["qualifying_count"] = snap.full_scope_release_count
	snap["familiarity"] = {}
	for id: StringName in snap.owned_ids: snap.familiarity[id] = game.run_state.get_feature_familiarity(id)
	snap["starter_pool"] = game.run_state.get_starter_pool_summary()
	out.studios.append(snap)

func _capture_cycle(game: Control) -> void:
	var snap := _state(game)
	snap["phase"] = game.get("_active_phase").get_script().resource_path
	stress_cycles.append(snap)

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var snap := super._state_for(project, run)
	snap["year"] = run.get_current_year()
	snap["month"] = run.get_current_month()
	snap["release_count"] = run.get_released_game_ids().size()
	snap["unpaid_cents"] = snap.sales[0].entitlement_cents - snap.sales[0].settled_cents
	return snap

func _sales(run: RunState) -> Array[Dictionary]:
	# Compact complete totals keep 1,000 empty-release traces bounded. Raw final
	# per-release histories are saved separately; no sales calculation is modeled.
	var total := {"release_id": "all_actual_releases", "earned_units": 0, "entitlement_cents": 0, "settled_cents": 0}
	for id: StringName in run.get_released_game_ids():
		var record := run.get_released_game_sales(id)
		for field in ["earned_units", "entitlement_cents", "settled_cents"]: total[field] += int(record.get(field, 0))
	return [total]

func _stress_finish(game: Control, out: Dictionary) -> Dictionary:
	out["final"] = _state(game)
	out["cycles"] = stress_cycles
	out["studio_visits"] = out.studios
	out["owned_ids"] = game.run_state.get_owned_feature_ids()
	out["released_sales_records"] = []
	for id: StringName in game.run_state.get_released_game_ids(): out.released_sales_records.append(game.run_state.get_released_game_sales(id))
	out["valid"] = out.errors.is_empty() and game.run_state.get_completed_run_cycles() >= stress_cap and game.get("_active_phase") is StudioPhase
	game.queue_free()
	await process_frame
	return out
