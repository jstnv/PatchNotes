## Seeded SideStreet acceptance batch using the live gameplay scenes and cash boundaries.
## Usage: godot --headless --path patch-notes --script res://analysis/sidestreet_acceptance_stress_v1.gd -- --policy=cautious --count=110
extends SceneTree

const OUTPUT_PREFIX := "res://design-logs/contract_synergy_first_capture_v1_"
const POLICIES := ["synergy"]
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


func _initialize() -> void:
	call_deferred("_run")


func _arg(prefix: String, fallback: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix): return arg.substr(prefix.length())
	return fallback


func _run() -> void:
	var policy := _arg("--policy=", "cautious")
	var count := int(_arg("--count=", "1"))
	var start := int(_arg("--start=", "0"))
	var tag := _arg("--tag=", "")
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
	var path := OUTPUT_PREFIX + policy + ("_" + tag if not tag.is_empty() else "") + ("_%d" % start if start != 0 else "") + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open trace output")
		quit(2)
		return
	file.store_string(JSON.stringify({"policy": policy, "start": start, "count": count, "failures": failures, "rows": rows}, "  "))
	file.close()
	print("SIDESTREET STRESS %s cases=%d failures=%d full_two_game=%d output=%s" % [policy, rows.size(), failures, rows.filter(func(r: Dictionary): return r.get("game_2", {}).get("released", false)).size(), path])
	quit(0 if failures == 0 else 1)


func _one(policy: String, index: int) -> Dictionary:
	var pair := index / 2
	var seed := 270927000 + pair * 97
	var beta_mode := "qa" if index % 2 == 0 else "marketing"
	var focus := focus_override if focus_override in ["sound", "mixed"] else "sound" if (pair / 12) % 2 == 0 else "mixed"
	var target := 19 if index >= 100 else 20 + pair % 4
	var roster: Array = ROSTERS[target][pair % 3]
	var genre: StringName = GENRES[(pair / 3) % 3]
	var out := {"policy": policy, "case": index, "pair": pair, "seed": seed, "beta_mode": beta_mode,
		"production_focus": focus, "starter_target": target, "starter_roster": roster.duplicate(),
		"genre_1": str(genre), "valid": false, "errors": [], "blockers": [], "actions": []}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
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
	var deferred_contracts := index < two_game_count and index % 2 == 1
	if not deferred_contracts:
		if not await _contract(game, policy, seed, out, "ironclad"):
			out.errors.append("ironclad")
			return await _cleanup(game, out)
		if not await _contract(game, policy, seed + 100, out, "sidestreet_1"):
			out.errors.append("sidestreet_1")
			return await _cleanup(game, out)
		out["publishers_after_contract"] = _publishers(run)
	studio = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	store = studio.get("_feature_store")
	var store_id := &"recorded_sounds" if focus == "sound" else &"colored_text"
	var store_offer := run.get_feature_store_offer(store_id)
	var store_before := _state(game)
	(store.get("_nodes")[store_id] as Button).pressed.emit()
	(store.get("_buy") as Button).pressed.emit()
	out["store_purchase"] = {"id": str(store_id), "offer": store_offer, "before": store_before, "after": _state(game), "success": not store_offer.owned and run.owns_feature(store_id)}
	if not run.owns_feature(store_id):
		out.blockers.append("Store upgrade unaffordable or locked: " + str(store_id))
	var reserve_id := &"8_bit_music" if focus == "sound" else &"sprites"
	if run.owns_feature(reserve_id): reserve_id = &"sound_effects" if not run.owns_feature(&"sound_effects") else &"menu_system"
	if run.owns_feature(reserve_id):
		var eligible_reserves: Array[StringName] = []
		for candidate: StringName in store.get("_nodes").keys():
			var candidate_offer := run.get_primitive_reserve_offer(candidate)
			if not candidate_offer.is_empty() and candidate_offer.can_purchase:
				eligible_reserves.append(candidate)
		eligible_reserves.sort()
		if not eligible_reserves.is_empty(): reserve_id = eligible_reserves[0]
	var reserve_offer := run.get_primitive_reserve_offer(reserve_id)
	var reserve_before := _state(game)
	(store.get("_nodes")[reserve_id] as Button).pressed.emit()
	(store.get("_buy") as Button).pressed.emit()
	out["reserve_purchase"] = {"id": str(reserve_id), "offer": reserve_offer, "before": reserve_before, "after": _state(game), "success": not reserve_offer.owned and run.owns_feature(reserve_id)}
	if not out.reserve_purchase.success:
		out.blockers.append("Primitive reserve unaffordable or locked: " + str(reserve_id))
	store.hide()
	out["cash_before_game_2_cents"] = run.get_cash_cents()
	out["sales_before_game_2"] = _sales(run)
	if index < two_game_count:
		# The public initial-snapshot verifier hook is pre-tree only. Reapply its
		# deterministic rolls directly for Game 2 before the real preparation path.
		game.set("_controlled_snapshot_rolls", [(pair * 17 + 31) % 100, (pair * 19 + 47) % 100])
		var next_genre: StringName = GENRES[(pair / 3 + 1) % 3]
		if not _begin_game(game, "Game Two", next_genre, out):
			out.errors.append("begin_game_2")
			return await _cleanup(game, out)
		await process_frame
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
			for number in range(3, 7):
				var before_next := _state(game)
				game.set("_controlled_snapshot_rolls", [(pair * 23 + number * 7) % 100, (pair * 29 + number * 11) % 100])
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
	out["valid"] = out.errors.is_empty()
	return await _cleanup(game, out)


func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	game.queue_free()
	await process_frame
	return out


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
	overlay.begin_button.pressed.emit()
	out.actions.append({"phase": "predevelopment", "game": title, "genre": str(genre), "before": before, "after": _state(game)})
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
	var attempts := 0 if policy == "cautious" else 1 if policy == "ordinary" else 2
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
	var indices := _choose_production(cards, project, run, policy, focus)
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
					if policy == "synergy":
						# Public current Genre targets and visible printed cards only.
						var ratios: Array = project.get_genre_ratios()
						var stats: Array[StringName] = [&"graphics", &"sound", &"technology", &"design"]
						var weighted := 0.0
						for stat_index in range(4):
							var printed := 0
							for card: CardData in hand:
								if card.primary_stat == stats[stat_index]: printed += card.primary_value
								if card.secondary_stat == stats[stat_index]: printed += card.secondary_value
							weighted += float(printed) * float(ratios[stat_index]) / 25.0
						var synergy_value := weighted * (1.5 if same else 1.0)
						var synergy_score := float(mini(scope, maxi(0, 30 - project.get_current_scope()))) * 4.0 + synergy_value + (10.0 if same else 0.0)
						if synergy_score > best:
							best = synergy_score
							choice = [a, b, c, d]
						continue
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
	(detail.find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	var phase: ContractPhase = game.get("_active_phase")
	if phase == null: return false
	var state := run.get_active_contract()
	if state == null: return false
	var log := {"label": label, "contract_id": str(state.get_contract_id()), "offer_id": str(state.get_offer_id()),
		"release_id": str(state.get_source_release_id()), "before": before, "after_accept": _state(game), "hands": []}
	if label == "ironclad" and log.after_accept.cash_cents != before.cash_cents + 40000: return false
	if label != "ironclad" and log.after_accept != before: return false
	phase.get("_rng").seed = seed + 40
	var deterministic: Array[CardData] = phase.call("_build_candidate_pool")
	phase.call("_publish_candidate_pool", deterministic)
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
			"entitlement_cents": record.get("entitlement_cents", 0), "settled_cents": record.get("settled_cents", 0)})
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
