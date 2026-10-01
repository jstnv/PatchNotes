## Versioned analysis-only current-scene Feature Store trial.
## Candidate definitions, multi-parent gates, fees and platform filtering are isolated
## SHADOW inputs; all draw, hand resolution, Review and cycle/sales code is current.
extends SceneTree

const OUTPUT_PREFIX := "res://design-logs/feature-store-staged-v1/stage2_"
const POLICIES := ["cautious", "ordinary", "optimizer"]
const GENRES := [&"action", &"adventure", &"strategy"]
const ROSTERS := {
	19: [
		["8_bit_music", "enemies", "local_leaderboards", "menu_system", "power_ups", "score_system", "scrolling", "sprites"],
		["8_bit_music", "dialogue", "enemies", "music", "power_ups", "score_system", "scrolling", "secrets", "simple_story"],
		["enemies", "exploration", "local_leaderboards", "maps", "menu_system", "power_ups", "secrets", "simple_story", "sound_effects"],
	],
	20: [
		["8_bit_music", "character_backstories", "dialogue", "exploration", "levels", "lives_system", "multiple_endings", "power_ups", "secrets", "sprites"],
		["character_backstories", "enemies", "general_combat", "lives_system", "menu_system", "multiple_endings", "power_ups", "scrolling"],
		["8_bit_music", "exploration", "levels", "menu_system", "music", "power_ups", "score_system", "sound_effects", "sprites"],
	],
	21: [
		["dialogue", "enemies", "general_combat", "levels", "menu_system", "multiple_endings", "split_screen"],
		["exploration", "levels", "lives_system", "multiple_endings", "score_system", "scrolling", "secrets", "simple_story", "split_screen"],
		["8_bit_music", "character_backstories", "levels", "lives_system", "local_leaderboards", "maps", "music", "power_ups", "secrets", "simple_story", "sound_effects"],
	],
	22: [
		["character_backstories", "dialogue", "enemies", "general_combat", "levels", "maps", "menu_system", "simple_story", "sprites"],
		["8_bit_music", "character_backstories", "exploration", "levels", "lives_system", "menu_system", "music", "power_ups", "scrolling", "simple_story", "sound_effects"],
		["character_backstories", "dialogue", "enemies", "lives_system", "maps", "menu_system", "multiple_endings", "score_system", "split_screen"],
	],
	23: [
		["8_bit_music", "dialogue", "enemies", "exploration", "general_combat", "local_leaderboards", "menu_system", "music", "score_system", "split_screen"],
		["character_backstories", "general_combat", "levels", "maps", "power_ups", "secrets", "simple_story", "sound_effects", "split_screen", "sprites"],
		["character_backstories", "dialogue", "enemies", "lives_system", "maps", "menu_system", "multiple_endings", "music", "scrolling", "secrets"],
	],
}

var failures := 0
var rows: Array[Dictionary] = []
var focus_override := ""
var two_game_count := 30
var arm := "none"
var catalog: Dictionary = {}
var current_run: RunState
var injected_ids: Array[StringName] = []
var price_band := 1
var fee_multiplier := 0
var platform_fixture := "compatible"
var contract_seed := 0
var contract_rng_state := 0
var contract_initial_hooked := false
var base_run := false
const SHADOW_RUN := preload("res://analysis/feature_store_stage2_v1_run.gd")


func _initialize() -> void:
	call_deferred("_run")


func _arg(prefix: String, fallback: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix): return arg.substr(prefix.length())
	return fallback


func _run() -> void:
	var policy := _arg("--policy=", "cautious")
	base_run = _arg("--base-run=", "0") == "1"
	node_added.connect(_on_analysis_node_added)
	var count := int(_arg("--count=", "1"))
	var start := int(_arg("--start=", "0"))
	var tag := _arg("--tag=", "")
	arm = _arg("--arm=", "none")
	price_band = int(_arg("--price-band=", "1"))
	fee_multiplier = int(_arg("--fee=", "0"))
	platform_fixture = _arg("--platform=", "compatible")
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://analysis/feature_store_stage2_v1_catalog.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://design-logs/feature-store-staged-v1"))
	focus_override = _arg("--focus=", "")
	two_game_count = int(_arg("--two-game-count=", "30"))
	if policy not in POLICIES or count < 1 or count > 110 or start < 0 or start + count > 110:
		push_error("Invalid policy or case range")
		quit(2)
		return
	for index in range(start, start + count):
		var row := await _one(policy, index)
		rows.append(row)
		if not row.valid: failures += 1
	var path := OUTPUT_PREFIX + policy + "_" + arm + ("_" + tag if not tag.is_empty() else "") + ("_%d" % start if start != 0 else "") + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open trace output")
		quit(2)
		return
	file.store_string(JSON.stringify({"source_revision": "608a2c62ab0850cf607f7ff627b042a49b5d2dfb + pending scripted tutorial", "label": "current Godot scenes with isolated shadow candidate catalog/gates/fees/platform eligibility", "policy": policy, "arm": arm, "price_band": price_band, "fee_multiplier": fee_multiplier, "platform_fixture": platform_fixture, "start": start, "count": count, "failures": failures, "rows": rows}, "  "))
	file.close()
	print("FEATURE GAME3 %s/%s cases=%d failures=%d game3=%d output=%s" % [policy, arm, rows.size(), failures, rows.filter(func(r: Dictionary): return r.get("long_run", []).size() > 0).size(), path])
	quit(0 if failures == 0 else 1)


func _one(policy: String, index: int) -> Dictionary:
	var pair := index / 2
	var seed := 280929000 + pair * 97
	var beta_mode := "qa" if index % 2 == 0 else "marketing"
	var focus := focus_override if focus_override in ["sound", "mixed"] else "sound" if pair % 2 == 0 else "mixed"
	var target := 19 if index >= 100 else 20 + pair % 4
	var roster: Array = ROSTERS[target][pair % 3]
	var genre: StringName = GENRES[(pair / 3) % 3]
	var out := {"policy": policy, "case": index, "pair": pair, "seed": seed, "beta_mode": beta_mode,
		"production_focus": focus, "starter_target": target, "starter_roster": roster.duplicate(),
		"genre_1": str(genre), "valid": false, "errors": [], "blockers": [], "actions": []}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var shadow: RunState = RunState.new() if base_run else SHADOW_RUN.new()
	if not base_run:
		shadow.set("fee_multiplier", fee_multiplier)
		shadow.set("compatible", platform_fixture != "none" and platform_fixture != "none_then_compatible")
	game.run_state = shadow
	current_run = shadow
	game.set_snapshot_initialization_rolls((pair * 7 + 11) % 100, (pair * 13 + 23) % 100)
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	if menu == null:
		out.errors.append("main_menu")
		return await _cleanup(game, out)
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Overnight Studio"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var studio: StudioPhase = game.get("_active_phase")
	if studio == null or run.get_cash_cents() != 550000:
		out.errors.append("studio_creation")
		return await _cleanup(game, out)
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	var purchases: Array[Dictionary] = []
	for raw_id: String in roster:
		var id := StringName(raw_id)
		var offer := run.get_primitive_reserve_offer(id)
		var before := _state(game)
		(store.get("_nodes")[id] as Button).pressed.emit()
		(store.get("_buy") as Button).pressed.emit()
		var success := run.owns_feature(id)
		purchases.append({"id": raw_id, "price_cents": offer.get("price_cents", -1), "success": success, "before": before, "after": _state(game)})
		if not success:
			out.errors.append("starter_purchase_" + raw_id)
			break
	store.hide()
	out["starter_purchases"] = purchases
	out["starter_summary"] = run.get_starter_pool_summary()
	if not out.errors.is_empty() or int(out.starter_summary.scope) != target or int(out.starter_summary.spent_cents) > 400000:
		out.errors.append("starter_scope_or_cap")
		return await _cleanup(game, out)
	if not _begin_game(game, "Game One", genre, out):
		out.errors.append("begin_game_1")
		return await _cleanup(game, out)
	await process_frame
	if not await _develop_game(game, policy, focus, beta_mode, seed, 1, out):
		out.errors.append("game_1_development")
		return await _cleanup(game, out)
	var first: ProjectState = game.project_state
	var release_one := _release(first, run)
	release_one["released"] = run.get_released_game_ids().has(first.get_release_id())
	out["game_1"] = release_one
	out["after_release_1"] = _state(game)
	out["publishers_after_1"] = _publishers(run)
	if not release_one.released or not game.get("_active_phase") is StudioPhase:
		out.errors.append("game_1_release")
		return await _cleanup(game, out)
	studio = game.get("_active_phase")
	studio.get_node("%PostGameSummaries").pressed.emit()
	studio.get_node("%CloseSummaryButton").pressed.emit()
	out["after_passive_summary"] = _state(game)
	var deferred_contracts := false
	if not deferred_contracts:
		if not await _contract(game, policy, seed, out, "ironclad"):
			out.errors.append("ironclad")
			return await _cleanup(game, out)
		if not await _contract(game, policy, seed + 100, out, "sidestreet_1"):
			out.errors.append("sidestreet_1")
			return await _cleanup(game, out)
		out["publishers_after_contract"] = _publishers(run)
	out["trial_purchases"] = []
	out["shopping_before"] = _state(game)
	if not base_run and arm != "none": _register_candidates(run)
	_shop(game, out, false)
	out["shopping_after"] = _state(game)
	if _arg("--campaign=", "0") == "1":
		var campaign_id: StringName = run.get_released_game_ids()[0]
		var campaign_before := _state(game)
		var campaign_quote := run.get_post_launch_campaign_offer(campaign_id)
		var campaign_bought := run.purchase_post_launch_campaign(campaign_id, run.get_completed_run_cycles())
		out["campaign_sensitivity"] = {"quote": campaign_quote, "bought": campaign_bought, "before": campaign_before, "after": _state(game)}
	out["cash_before_game_2_cents"] = run.get_cash_cents()
	out["sales_before_game_2"] = _sales(run)
	if index < two_game_count:
		# The public initial-snapshot verifier hook is pre-tree only. Reapply its
		# deterministic rolls directly for Game 2 before the real preparation path.
		var game_two_rolls: Array[int] = [(pair * 17 + 31) % 100, (pair * 19 + 47) % 100]
		game.set("_controlled_snapshot_rolls", game_two_rolls)
		if game.get("_controlled_snapshot_rolls") != game_two_rolls:
			out.errors.append("game_2_snapshot_roll_assignment")
			return await _cleanup(game, out)
		out["game_2_controlled_rolls"] = (game.get("_controlled_snapshot_rolls") as Array).duplicate()
		var next_genre: StringName = GENRES[(pair / 3 + 1) % 3]
		if not _begin_game(game, "Game Two", next_genre, out):
			out.errors.append("begin_game_2")
			return await _cleanup(game, out)
		await process_frame
		out["game_2_forecast_id"] = str(game.project_state.get_assigned_market_forecast_snapshot_id_for_authority())
		if not await _develop_game(game, policy, focus, beta_mode, seed + 500000, 2, out):
			out.errors.append("game_2_development")
			return await _cleanup(game, out)
		var second: ProjectState = game.project_state
		var release_two := _release(second, run)
		release_two["released"] = run.get_released_game_ids().has(second.get_release_id())
		out["game_2"] = release_two
		out["publishers_after_2"] = _publishers(run)
		out["after_release_2"] = _state(game)
		if not release_two.released: out.errors.append("game_2_release")
		if out.errors.is_empty() and deferred_contracts:
			if not await _contract(game, policy, seed, out, "ironclad"):
				out.errors.append("deferred_ironclad")
			if out.errors.is_empty() and not await _contract(game, policy, seed + 100, out, "sidestreet_1"):
				out.errors.append("deferred_sidestreet_1")
		if out.errors.is_empty() and not await _contract(game, policy, seed + 200, out, "sidestreet_2"):
			out.errors.append("sidestreet_2")
		out["publishers_after_three_contracts"] = _publishers(run)
		out["completed_contract_count"] = run.get_completed_contract_count()
		out["sidestreet_history"] = run.get_sidestreet_completion_history()
		if out.errors.is_empty() and (run.get_completed_contract_count() != 3 or not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE)):
			out.errors.append("starwave_gate")
		if out.errors.is_empty() and _arg("--long-run=", "0") == "1":
			out["long_run"] = []
			if arm == "staged_pair": _shop(game, out, true)
			if _arg("--retry-game3=", "0") == "1" and catalog.has(arm): _buy_chain(game, StringName(arm), out, true)
			if platform_fixture == "none_then_compatible": run.set("compatible", true)
			var max_game := mini(6, maxi(3, int(_arg("--max-game=", "3"))))
			for number in range(3, max_game + 1):
				var before_next := _state(game)
				var later_rolls: Array[int] = [(pair * 23 + number * 7) % 100, (pair * 29 + number * 11) % 100]
				game.set("_controlled_snapshot_rolls", later_rolls)
				if game.get("_controlled_snapshot_rolls") != later_rolls:
					out.blockers.append("game_%d_snapshot_roll_assignment" % number)
					break
				var later_genre: StringName = GENRES[(pair / 3 + number - 1) % 3]
				if not _begin_game(game, "Game %d" % number, later_genre, out):
					out.blockers.append("begin_game_%d" % number)
					break
				await process_frame
				if not await _develop_game(game, policy, focus, beta_mode, seed + number * 500000, number, out):
					out.blockers.append("game_%d_development" % number)
					break
				var later: ProjectState = game.project_state
				var later_release := _release(later, run)
				later_release["released"] = run.get_released_game_ids().has(later.get_release_id())
				if not later_release.released:
					out.blockers.append("game_%d_release" % number)
					break
				var offer_label := "sidestreet_%d" % number
				if not await _contract(game, policy, seed + number * 100, out, offer_label):
					out.blockers.append("game_%d_contract" % number)
					break
				out.long_run.append({"number": number, "before": before_next, "release": later_release,
					"after": _state(game), "marginal_cash_cents": run.get_cash_cents() - int(before_next.cash_cents),
					"marginal_cycles": run.get_completed_run_cycles() - int(before_next.cycle)})
	out["final_state"] = _state(game)
	out["owned_final"] = run.get_owned_feature_ids()
	out["familiarity_final"] = run.get("_familiarity").duplicate()
	out["valid"] = out.errors.is_empty()
	return await _cleanup(game, out)


func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	game.queue_free()
	await process_frame
	var db: Node = root.get_node_or_null("CardDatabase")
	if db != null:
		var cards: Dictionary = db.get("_store_cards")
		for id: StringName in injected_ids: cards.erase(id)
		db.set("_store_cards", cards)
	injected_ids.clear()
	return out


func _register_candidates(run: RunState) -> void:
	var db: Node = root.get_node("CardDatabase")
	for id: String in catalog:
		var entry: Dictionary = catalog[id].duplicate(true)
		if entry.get("unsupported_tertiary", false): continue
		entry["base_price_cents"] = entry.price_bands[price_band] * 100
		run.get("_feature_definitions")[StringName(id)] = entry
		run.get("_feature_offers")[StringName(id)] = entry
		run.get("trial_ids")[StringName(id)] = entry
		db.get("_store_cards")[StringName(id)] = db.call("_create_card", entry)
		injected_ids.append(StringName(id))


func _shop(game: Control, out: Dictionary, staged: bool) -> void:
	var ids: Array[StringName] = []
	if staged:
		ids = [&"sub_areas"]
	elif arm == "none": return
	elif arm == "reserve_only": ids = [&"music", &"levels"]
	elif arm == "control_background_music": ids = [&"music"]
	elif arm == "control_sub_areas": ids = [&"levels"]
	elif arm == "pair": ids = [&"background_music", &"sub_areas"]
	elif arm == "staged_pair": ids = [&"background_music"]
	elif arm == "existing_upgrade": ids.append(&"recorded_sounds" if out.production_focus == "sound" else &"colored_text")
	elif arm == "tools_bundle": ids = [&"inventory_system", &"procedural_maps", &"custom_key_bindings"]
	elif arm == "visual_bundle": ids = [&"tile_based_backgrounds", &"color_cycling", &"parallax_scrolling"]
	elif arm == "gameplay_bundle": ids = [&"turn_based_combat", &"local_co_op", &"sprite_collision_events"]
	else: ids = [StringName(arm)]
	for id: StringName in ids: _buy_chain(game, id, out, staged)


func _buy_chain(game: Control, id: StringName, out: Dictionary, staged: bool) -> bool:
	var run: RunState = game.run_state
	if run.owns_feature(id): return true
	if catalog.has(str(id)) and catalog[str(id)].get("unsupported_tertiary", false):
		out.blockers.append("BLOCKED unsupported tertiary printed effect: " + str(id))
		return false
	var definitions: Dictionary = run.get("_feature_definitions")
	if not definitions.has(id):
		out.blockers.append("Missing definition: " + str(id))
		return false
	var entry: Dictionary = definitions[id]
	var parents: Array = entry.get("parents", [])
	if parents.is_empty() and not str(entry.get("purchase_parent", "")).is_empty(): parents = [str(entry.purchase_parent)]
	for parent_id: String in parents:
		if not _buy_chain(game, StringName(parent_id), out, staged): return false
	var is_store: bool = run.get("_feature_offers").has(id)
	var quote := run.get_feature_store_offer(id) if is_store else run.get_primitive_reserve_offer(id)
	var before := _state(game)
	var bought := run.purchase_feature(id) if is_store else run.purchase_primitive_reserve_feature(id)
	var after := _state(game)
	var price := int(quote.get("price_cents", 0))
	var delta := _settlement_delta(before.sales, after.sales)
	var parity: bool = (after.cash_cents - before.cash_cents == -price + delta and after.cycle == before.cycle + 1) if bought else after == before
	out.trial_purchases.append({"id": str(id), "stage": 3 if staged else 2, "shadow": catalog.has(str(id)), "quote": quote, "bought": bought, "before": before, "after": after, "settlement_delta_cents": delta, "cash_cycle_parity": parity})
	if not parity: out.errors.append("purchase cash/cycle parity: " + str(id))
	if not bought: out.blockers.append("Unaffordable or locked purchase: " + str(id))
	return bought


func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	var studio: StudioPhase = game.get("_active_phase")
	if studio == null: return false
	studio.get_node("%StartNextGame").pressed.emit()
	if studio.get_node("%LowScopeWarning").visible:
		studio.get_node("%LowScopeWarning").confirmed.emit()
		out["low_scope_warning_accepted"] = true
	var overlay: PredevelopmentOverlay = studio.get("_predevelopment")
	if overlay == null or not overlay.visible: return false
	overlay.name_input.text = title
	for i in range(overlay.genre_input.item_count):
		if overlay.genre_input.get_item_metadata(i) == genre:
			overlay.genre_input.select(i)
			break
	overlay.theme_input.select(0)
	var before := _state(game)
	if not base_run: current_run.set("filter_project_supply", true)
	overlay.begin_button.pressed.emit()
	if not base_run: current_run.set("filter_project_supply", false)
	out.actions.append({"phase": "predevelopment", "game": title, "genre": str(genre), "before": before, "after": _state(game), "owned": current_run.get_owned_feature_ids(), "project_eligible": game.project_state.get_feature_supply_ids(), "platform_compatible": (true if base_run else current_run.get("compatible"))})
	return game.get("_active_phase") is DesignPhase


func _develop_game(game: Control, policy: String, focus: String, beta_mode: String, seed: int, number: int, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = seed + 1
	design.get("_finalization_rng").seed = seed + 2
	if focus == "sound": design.set_priority_distribution(_core_priorities(true))
	if not design.get_workspace().overlay.commit_draft(): return false
	var design_hands := 2 if policy == "cautious" else 4 if policy == "ordinary" else 6
	var requested_design_hands := int(_arg("--design-hands=", "-1"))
	if requested_design_hands >= 0: design_hands = requested_design_hands
	for hand in range(design_hands):
		if not _production_hand(design, project, run, policy, focus, "design", number, out):
			out.blockers.append("Game %d Design hand %d: no affordable/valid four-card action" % [number, hand + 1])
			break
		if hand == 0 and policy != "cautious":
			var before := _state(game)
			var changed := design.commit_priority_distribution(_core_priorities(false) if focus == "sound" else _core_adjustment())
			out.actions.append({"phase": "design_priority", "game": number, "success": changed, "before": before, "after": _state(game)})
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = seed + 3
	alpha.get("_finalization_rng").seed = seed + 4
	if focus == "sound": alpha.set_priority_distribution(_core_priorities(true))
	if not alpha.get_workspace().overlay.commit_draft(): return false
	var alpha_hands := 2 if policy == "cautious" else 4 if policy == "ordinary" else 6
	var requested_alpha_hands := int(_arg("--alpha-hands=", "-1"))
	if requested_alpha_hands >= 0: alpha_hands = requested_alpha_hands
	for hand in range(alpha_hands):
		if not _production_hand(alpha, project, run, policy, focus, "alpha", number, out):
			out.blockers.append("Game %d Alpha hand %d: no affordable/valid four-card action" % [number, hand + 1])
			break
		if hand == 0 and policy == "optimizer":
			var before := _state(game)
			var changed := alpha.commit_priority_distribution(_core_priorities(false) if focus == "sound" else _core_adjustment())
			out.actions.append({"phase": "alpha_priority", "game": number, "success": changed, "before": before, "after": _state(game)})
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible:
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase: return false
	var beta: BetaPhase = game.get("_active_phase")
	beta.get("_deal_rng").seed = seed + 5
	beta.get("_insight_rng").seed = seed + 6
	beta.set_priority_distribution(_beta_priorities(beta_mode))
	if not beta.get_workspace().overlay.commit_draft(): return false
	var beta_hands := 1 if policy == "cautious" else 3 if policy == "ordinary" else 5
	var requested_beta_hands := int(_arg("--beta-hands=", "-1"))
	if requested_beta_hands >= 0: beta_hands = requested_beta_hands
	for hand in range(beta_hands):
		if not _beta_hand(beta, project, run, policy, beta_mode, number, out):
			out.blockers.append("Game %d Beta hand %d: no valid four-card action" % [number, hand + 1])
			break
		if hand == 0 and policy != "cautious":
			var before := _state(game)
			var changed := beta.commit_priority_distribution(_beta_adjustment(beta_mode))
			out.actions.append({"phase": "beta_priority", "game": number, "success": changed, "before": before, "after": _state(game)})
	game.set_review_variance_roll_for_verification((seed / 97) % 100)
	var before_launch := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": number, "success": launched, "before": before_launch, "after": _state(game)})
	return launched and game.get("_active_phase") is StudioPhase and project.has_review_result()


func _core_priorities(sound: bool) -> Dictionary:
	return {0: 15, 1: 50, 2: 20, 3: 15} if sound else {0: 25, 1: 25, 2: 25, 3: 25}


func _core_adjustment() -> Dictionary:
	return {0: 30, 1: 20, 2: 25, 3: 25}


func _beta_priorities(mode: String) -> Dictionary:
	return {&"qa": 50, &"marketing": 25, &"insider": 25} if mode == "qa" else {&"qa": 25, &"marketing": 50, &"insider": 25}


func _beta_adjustment(mode: String) -> Dictionary:
	return {&"qa": 45, &"marketing": 30, &"insider": 25} if mode == "qa" else {&"qa": 30, &"marketing": 45, &"insider": 25}


func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	if cards.size() != 7: return false
	var entry := {"phase": label, "game": game_number, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	var guide: FirstGameTutorial = run.get_first_game_tutorial(project) if label == "design" else null
	var guided_stat := &""
	if guide != null and guide.stage == FirstGameTutorial.Stage.FIRST_HAND: guided_stat = guide.first_stat
	if guide != null and guide.stage == FirstGameTutorial.Stage.REDRAW_HAND:
		for slot in range(cards.size()):
			if cards[slot].primary_stat != guide.second_stat:
				var views: Array = phase.get_node("%HandContainer").get_children()
				(views[slot] as CardView).input_button.pressed.emit()
				var old := str(cards[slot].id)
				var changed: bool = phase.redraw_selected_cards()
				entry.redraws.append({"slot": slot, "from": old, "success": changed, "scripted_tutorial": true})
				if changed:
					cards.assign(phase.get("_candidate_cards"))
					entry.redraws[-1]["to"] = str(cards[slot].id)
					guided_stat = guide.second_stat
				break
	var attempts := 0 if not guided_stat.is_empty() or policy == "cautious" else 1 if policy == "ordinary" else 2
	for unused in range(attempts):
		if run.get_available_redraws() == 0: break
		var slot := _weakest(cards, focus)
		var views: Array = phase.get_node("%HandContainer").get_children()
		(views[slot] as CardView).input_button.pressed.emit()
		var old := str(cards[slot].id)
		var changed: bool = phase.redraw_selected_cards()
		entry.redraws.append({"slot": slot, "from": old, "success": changed})
		if not changed:
			(views[slot] as CardView).input_button.pressed.emit()
			break
		cards.assign(phase.get("_candidate_cards"))
		entry.redraws[-1]["to"] = str(cards[slot].id)
	entry["final_draw"] = _ids(cards)
	var indices: Array[int] = []
	if not guided_stat.is_empty():
		for i in range(cards.size()):
			if cards[i].primary_stat == guided_stat and indices.size() < 4: indices.append(i)
	else: indices = _choose_production(cards, project, run, policy, focus)
	if indices.size() != 4:
		entry["blocked"] = "no affordable four-card selection"
		out.actions.append(entry)
		return false
	var selected: Array[CardData] = []
	var views: Array = phase.get_node("%HandContainer").get_children()
	for slot: int in indices:
		selected.append(cards[slot])
		(views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	entry["printed_scope"] = selected.reduce(func(total: int, card: CardData) -> int: return total + card.scope, 0)
	entry["printed_core"] = _printed(selected)
	entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected)
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var before_cycle := run.get_completed_run_cycles()
	if label == "design": phase.call("_on_play_card_pressed")
	else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state_for(project, run)
	entry["resolved_core"] = []
	for i in range(4): entry.resolved_core.append(entry.after.cores[i] - entry.before.cores[i])
	entry["resolved_scope"] = entry.after.scope - entry.before.scope
	entry["familiarity"] = run.get("_familiarity").duplicate()
	entry["eligible_count"] = project.get_feature_supply_ids().size()
	out.actions.append(entry)
	return run.get_completed_run_cycles() == before_cycle + 1


func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	var best := -INF
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var cost := run.primitive_feature_hand_cost_cents(hand)
					if cost < 0 or cost > run.get_cash_cents(): continue
					if policy == "cautious" and a == 0 and b == 1 and c == 2 and d == 3: return [a, b, c, d]
					var scope := 0
					var core := 0
					var sound := 0
					var same := true
					for card: CardData in hand:
						scope += card.scope
						core += card.primary_value + card.secondary_value
						if card.primary_stat == &"sound": sound += card.primary_value
						if card.secondary_stat == &"sound": sound += card.secondary_value
						if card.primary_stat != hand[0].primary_stat: same = false
					var value := float(mini(scope, maxi(0, 30 - project.get_current_scope()))) * (4.0 if policy == "ordinary" else 5.0) + core
					if focus == "sound": value += 1.4 * sound
					if same: value += 0.5 * core if policy == "optimizer" else 2.0
					if value > best:
						best = value
						choice = [a, b, c, d]
	return choice


func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, policy: String, mode: String, game_number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = phase.get("_candidate_cards")
	if cards.size() != 7: return false
	var entry := {"phase": "beta", "game": game_number, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	if policy != "cautious" and run.get_available_redraws() > 0:
		var slot := _weakest_beta(cards, mode)
		var views: Array = phase.get_node("%HandContainer").get_children()
		(views[slot] as CardView).input_button.pressed.emit()
		var old := str(cards[slot].id)
		var changed := phase.redraw_selected_cards()
		entry.redraws.append({"slot": slot, "from": old, "success": changed})
		if not changed: (views[slot] as CardView).input_button.pressed.emit()
		else:
			cards = phase.get("_candidate_cards")
			entry.redraws[-1]["to"] = str(cards[slot].id)
	entry["final_draw"] = _ids(cards)
	var indices := _choose_beta(cards, project, mode, policy)
	var selected: Array[CardData] = []
	var views: Array = phase.get_node("%HandContainer").get_children()
	for slot: int in indices:
		selected.append(cards[slot])
		(views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	var cats: Array[String] = []
	for card: CardData in selected: cats.append(str(card.beta_category))
	entry["categories"] = cats
	entry["synergy"] = "QA specialization" if cats.count("qa") == 4 else "Marketing specialization" if cats.count("marketing") == 4 else "balanced operations" if cats.count("qa") > 0 and cats.count("marketing") > 0 and cats.count("insider") > 0 else "none"
	var before_cycle := run.get_completed_run_cycles()
	var success := phase.play_selected_hand()
	entry["success"] = success
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	return success and run.get_completed_run_cycles() == before_cycle + 1


func _choose_beta(cards: Array[CardData], project: ProjectState, mode: String, policy: String) -> Array[int]:
	if policy == "cautious": return [0, 1, 2, 3]
	var best := -INF
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var value := 0.0
					var qa := 0
					var marketing := 0
					var insider := 0
					for card: CardData in hand:
						if card.beta_category == &"qa":
							qa += 1
							if card.id == &"search_for_bugs": value += 11.0 if project.get_hidden_bugs() > 0 else 1.0
							elif card.id == &"debug": value += 12.0 if project.get_known_bugs() > 0 else 4.0
							else: value += float(card.beta_value)
						elif card.beta_category == &"marketing":
							marketing += 1
							value += float(card.beta_value) * (3.0 if mode == "marketing" else 0.7)
						else:
							insider += 1
							value += float(card.beta_value) * 0.4
					if mode == "qa": value += qa * 3.0
					if marketing == 4: value += 8.0 if mode == "marketing" else 0.0
					if qa == 4: value += 5.0 if mode == "qa" else 0.0
					if qa > 0 and marketing > 0 and insider > 0: value += 2.0
					if value > best:
						best = value
						choice = [a, b, c, d]
	return choice


func _contract(game: Control, policy: String, seed: int, out: Dictionary, label: String) -> bool:
	var studio: StudioPhase = game.get("_active_phase")
	var run: RunState = game.run_state
	var before := _state(game)
	studio.get_node("%Contracts").pressed.emit()
	var detail: PanelContainer = studio.get_node("ContractDetail")
	if detail == null: return false
	contract_seed = seed + 40
	contract_initial_hooked = false
	(detail.find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	await process_frame
	var phase: ContractPhase = game.get("_active_phase")
	if phase == null: return false
	var state := run.get_active_contract()
	if state == null: return false
	var log := {"label": label, "contract_id": str(state.get_contract_id()), "offer_id": str(state.get_offer_id()),
		"release_id": str(state.get_source_release_id()), "before": before, "after_accept": _state(game), "hands": []}
	if label == "ironclad" and log.after_accept.cash_cents != before.cash_cents + 40000: return false
	if label != "ironclad" and log.after_accept != before: return false
	if not contract_initial_hooked: return false
	phase.get("_rng").state = contract_rng_state
	log["initial_draw_seeded_before_ready"] = true
	for hand in range(2):
		var cards := phase.get_candidate_cards()
		if cards.size() != 7: return false
		var action := {"draw": _ids(cards), "before": _state(game), "redraws": []}
		if policy != "cautious" and run.get_available_redraws() > 0:
			var slot := _weakest(cards, "mixed")
			var views: Array = phase.get("_candidate_row").get_children()
			(views[slot] as CardView).input_button.pressed.emit()
			var old := str(cards[slot].id)
			var changed := phase.redraw_selected_cards()
			action.redraws.append({"slot": slot, "from": old, "success": changed})
			if not changed: (views[slot] as CardView).input_button.pressed.emit()
			else:
				cards = phase.get_candidate_cards()
				action.redraws[-1]["to"] = str(cards[slot].id)
		var indices := _choose_contract(cards, state, policy)
		var selected: Array[CardData] = []
		var views: Array = phase.get("_candidate_row").get_children()
		for slot: int in indices:
			selected.append(cards[slot])
			(views[slot] as CardView).input_button.pressed.emit()
		action["selected"] = _ids(selected)
		action["printed_scope"] = selected.reduce(func(total: int, card: CardData) -> int: return total + card.scope, 0)
		action["printed_core"] = _printed(selected)
		var plan := state.plan_hand(selected)
		action["synergy"] = str(plan.get("specialization_stat", &""))
		action["planned_remainder_cents"] = plan.get("remainder_cents", 0)
		var success: bool = phase.call("_play_selected_hand")
		action["success"] = success
		action["after"] = _state(game)
		action["settlement_delta_cents"] = _settlement_delta(action.before.sales, action.after.sales)
		action["cash_parity"] = action.after.cash_cents - action.before.cash_cents == int(plan.get("remainder_cents", 0)) + int(action.settlement_delta_cents)
		log.hands.append(action)
		out.actions.append({"phase": label + "_hand", "hand": hand + 1, "draw": action.draw, "redraws": action.redraws, "selected": action.selected, "before": action.before, "after": action.after})
		if not success or not action.cash_parity: return false
		if hand == 0 and policy != "cautious":
			var priority_before := _state(game)
			var changed := phase.commit_priority_distribution({0: 40, 1: 20, 2: 20, 3: 20})
			log["priority_commit"] = {"success": changed, "before": priority_before, "after": _state(game)}
	if not state.is_completed(): return false
	var result := state.get_result()
	log["completion"] = {"numerator": result.get_completion_numerator(), "scope": result.get_scope(), "payout_cents": result.get_payout_cents(), "upfront_cents": result.get_upfront_cents(), "remainder_cents": result.get_completion_payment_cents()}
	var independent_payout := (40000 + (200000 * result.get_completion_numerator()) / 96) if label == "ironclad" else (120000 * result.get_completion_numerator()) / 96
	log["independent_payout_cents"] = independent_payout
	if result.get_payout_cents() != independent_payout: return false
	var before_dismiss := _state(game)
	(phase.get("_completion_panel").find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
	await process_frame
	log["after_dismiss"] = _state(game)
	log["dismiss_passive"] = before_dismiss == log.after_dismiss
	out[label] = log
	return game.get("_active_phase") is StudioPhase and log.dismiss_passive


func _settlement_delta(before: Array, after: Array) -> int:
	var earlier: Dictionary = {}
	for record: Dictionary in before:
		earlier[record.release_id] = int(record.settled_cents)
	var total := 0
	for record: Dictionary in after:
		total += int(record.settled_cents) - int(earlier.get(record.release_id, 0))
	return total


func _choose_contract(cards: Array[CardData], state: ContractState, policy: String) -> Array[int]:
	if policy == "cautious": return [0, 1, 2, 3]
	var best := -INF
	var choice: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var plan := state.plan_hand(hand)
					if plan.is_empty(): continue
					var value := float(plan.scope_addition) * 4.0
					for addition: int in plan.score_additions.values(): value += addition * 0.5
					if policy == "optimizer" and not StringName(plan.specialization_stat).is_empty(): value += 5.0
					if value > best:
						best = value
						choice = [a, b, c, d]
	return choice


func _release(project: ProjectState, run: RunState) -> Dictionary:
	var review := project.get_review_result()
	if review == null: return {}
	return {"release_id": str(project.get_release_id()), "genre": str(project.get_genre_id()),
		"scope": project.get_current_scope(), "cores": _cores(project), "hidden_bugs": project.get_hidden_bugs(),
		"known_bugs": project.get_known_bugs(), "fixed_bugs": project.get_fixed_bugs(), "marketing": project.get_marketing_output(),
		"production_rating": review.get_production_rating(), "scope_completion": review.get_scope_completion(),
		"bug_multiplier": review.get_bug_multiplier(), "variance_roll": review.get_variance_roll(),
		"variance_modifier": review.get_variance_modifier(), "genre_deviation": review.get_genre_deviation(),
		"genre_fit": review.get_genre_modifier(), "pre_genre_review": review.get_pre_genre_review(),
		"final_review": review.get_final_review(), "awareness": project.get_awareness_result().get_total_awareness(),
		"month_1_units": project.get_units_sold_result().get_final_units_sold(),
		"projected_gross_cents": project.get_month_one_sales_revenue_result().get_projected_month_one_gross_cents(),
		"projected_net_cents": project.get_month_one_sales_revenue_result().get_projected_month_one_net_cents(),
		"cash_cents": run.get_cash_cents(), "cycle": run.get_completed_run_cycles()}


func _publishers(run: RunState) -> Dictionary:
	var result := {}
	for entry: Dictionary in PublisherCatalog.entries():
		var status := run.get_publisher_status(StringName(entry.id))
		result[str(entry.id)] = {"unlocked": status.get("unlocked", false), "availability": str(status.get("availability", ""))}
	return result


func _state(game: Control) -> Dictionary:
	return _state_for(game.project_state, game.run_state)


func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	return {"cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(), "redraws": run.get_available_redraws(),
		"project_cycle": project.get_current_cycle() if project != null else -1, "scope": project.get_current_scope() if project != null else 0,
		"cores": _cores(project), "hidden_bugs": project.get_hidden_bugs() if project != null else 0,
		"known_bugs": project.get_known_bugs() if project != null else 0, "fixed_bugs": project.get_fixed_bugs() if project != null else 0,
		"marketing": project.get_marketing_output() if project != null else 0, "sales": _sales(run)}


func _sales(run: RunState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: StringName in run.get_released_game_ids():
		var record := run.get_released_game_sales(id)
		result.append({"release_id": str(id), "earned_cycles": record.get("earned_cycles", 0), "earned_units": record.get("earned_units", 0),
			"total_earned_cycles": record.get("total_earned_cycles", 0), "entitlement_cents": record.get("entitlement_cents", 0), "settled_cents": record.get("settled_cents", 0), "monthly_units": record.get("monthly_units", 0), "later_enabled": record.get("later_enabled", false), "campaign_count": record.get("campaign_count", 0)})
	return result


func _cores(project: ProjectState) -> Array[int]:
	if project == null: return [0, 0, 0, 0]
	return [project.get_core_score(0), project.get_core_score(1), project.get_core_score(2), project.get_core_score(3)]


func _ids(cards: Array[CardData]) -> Array[String]:
	var result: Array[String] = []
	for card: CardData in cards: result.append(str(card.id))
	return result


func _printed(cards: Array[CardData]) -> Dictionary:
	var scores := {"graphics": 0, "sound": 0, "technology": 0, "design": 0}
	for card: CardData in cards:
		scores[str(card.primary_stat)] += card.primary_value
		if not card.secondary_stat.is_empty(): scores[str(card.secondary_stat)] += card.secondary_value
	return scores


func _weakest(cards: Array[CardData], focus: String) -> int:
	var lowest := INF
	var slot := 0
	for i in range(cards.size()):
		var card := cards[i]
		var value := float(card.primary_value + card.secondary_value + card.scope * 2)
		if focus == "sound" and card.primary_stat == &"sound": value += 3.0
		if value < lowest:
			lowest = value
			slot = i
	return slot


func _weakest_beta(cards: Array[CardData], mode: String) -> int:
	var lowest := INF
	var slot := 0
	for i in range(cards.size()):
		var card := cards[i]
		var value := float(card.beta_value)
		if card.beta_category == (&"qa" if mode == "qa" else &"marketing"): value += 5.0
		if value < lowest:
			lowest = value
			slot = i
	return slot



func _on_analysis_node_added(node: Node) -> void:
	if not node is ContractPhase: return
	var rng := RandomNumberGenerator.new()
	rng.seed = contract_seed
	var category_rolls: Array[float] = []
	var definition_rolls: Array[float] = []
	for i in range(7):
		category_rolls.append(rng.randf())
		definition_rolls.append(rng.randf())
	node.set("_initial_category_rolls", category_rolls)
	node.set("_initial_definition_rolls", definition_rolls)
	contract_rng_state = rng.state
	contract_initial_hooked = true
