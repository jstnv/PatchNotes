## Read-only legal first-game trace runner. Invoked with --script; never changes gameplay files.
extends SceneTree

const DESIGN_SCENE := preload("res://scenes/phases/design_phase.tscn")
const ALPHA_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const OUTPUT := "res://design-logs/first_game_review_godot_traces_v1.json"
const OPTIONAL_BY_SCOPE := {
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
const POLICIES := ["conservative", "ordinary", "optimized"]
const GENRES := [&"action", &"adventure", &"strategy"]

var failures := 0
var trace: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var snapshot_db := PrimitiveSnapshotDatabase.new()
	snapshot_db.load_ledgers()
	for target in [19, 20, 21, 22, 23]:
		for policy: String in POLICIES:
			for repeat in range(3):
				var seed: int = 26092700 + int(target) * 100 + POLICIES.find(policy) * 10 + repeat
				var row := await _one(target, policy, seed, repeat, snapshot_db)
				trace.append(row)
				if not row.valid: failures += 1
	var output := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if output == null:
		push_error("Could not write calibration trace output")
		quit(1)
		return
	output.store_string(JSON.stringify({"seed_base": 26092700, "n": trace.size(), "failures": failures, "traces": trace}, "  "))
	output.close()
	print("Godot first-game calibration traces: %d cases, %d failures" % [trace.size(), failures])
	quit(0 if failures == 0 else 1)


func _one(target: int, policy: String, seed: int, repeat: int, snapshots: PrimitiveSnapshotDatabase) -> Dictionary:
	var out := {"target": target, "policy": policy, "seed": seed, "valid": false, "actions": [], "errors": []}
	var run := RunState.new()
	if not run.initialize_cash_cents(0) or not run.set_studio_name("Trace Studio"):
		out.errors.append("studio_name")
		return out
	for raw_id: String in OPTIONAL_BY_SCOPE[target][repeat]:
		if not run.purchase_starter_feature(StringName(raw_id)):
			out.errors.append("starter_purchase_" + raw_id)
			return out
	var starter := run.get_starter_pool_summary()
	out["starter_scope"] = starter.scope
	out["starter_spend_cents"] = starter.spent_cents
	out["owned_ids"] = run.get_owned_feature_ids().map(func(id: StringName): return str(id))
	if starter.scope != target or starter.spent_cents > RunState.STARTER_PURCHASE_CAP_CENTS:
		out.errors.append("starter_limits")
		return out
	var project := ProjectState.new(30)
	if not project.configure_predevelopment("Trace Game", GENRES[repeat], &"fantasy", run.get_owned_feature_ids()) or not project.initialize_snapshots(&"fast_follower", &"stable_market"):
		out.errors.append("project_setup")
		return out
	out["genre"] = str(project.get_genre_id())
	if not run.complete_productive_action() or not run.finalize_starter_selection():
		out.errors.append("begin_development")
		return out
	var design := DESIGN_SCENE.instantiate() as DesignPhase
	design.setup(project, run)
	root.add_child(design)
	await process_frame
	design.get("_deal_rng").seed = seed + 1
	design.get("_finalization_rng").seed = seed + 2
	if not design.begin_design():
		out.errors.append("begin_design")
		return out
	var design_hands := 2 if policy != "optimized" else 3
	for index in range(design_hands):
		if not _production_hand(design, project, run, policy, "design", out):
			out.errors.append("design_hand_%d" % index)
			break
	design.call("_on_proceed_to_alpha_pressed")
	if not project.has_design_bug_finalization():
		out.errors.append("design_finalization")
	design.queue_free()
	await process_frame
	if not out.errors.is_empty(): return out
	var alpha := ALPHA_SCENE.instantiate() as AlphaPhase
	alpha.setup(project, run)
	root.add_child(alpha)
	await process_frame
	alpha.get("_deal_rng").seed = seed + 3
	alpha.get("_finalization_rng").seed = seed + 4
	if not alpha.begin_alpha():
		out.errors.append("begin_alpha")
		return out
	var alpha_hands := 2 if policy == "conservative" else 3 if policy == "ordinary" else 4
	for index in range(alpha_hands):
		if not _production_hand(alpha, project, run, policy, "alpha", out):
			out.errors.append("alpha_hand_%d" % index)
			break
	var final_rng := RandomNumberGenerator.new()
	final_rng.seed = seed + 5
	if not alpha.call("_finalize_alpha", final_rng.randf(), final_rng.randf()):
		out.errors.append("alpha_finalization")
	alpha.queue_free()
	await process_frame
	if not out.errors.is_empty(): return out
	var beta := BETA_SCENE.instantiate() as BetaPhase
	if not beta.setup(project, run, snapshots):
		out.errors.append("beta_setup")
		return out
	root.add_child(beta)
	await process_frame
	beta.get("_deal_rng").seed = seed + 6
	beta.get("_insight_rng").seed = seed + 7
	if not beta.begin_beta():
		out.errors.append("begin_beta")
		return out
	var beta_hands := 0 if policy == "conservative" else 2 if policy == "ordinary" else 4
	for index in range(beta_hands):
		if not _beta_hand(beta, project, run, out):
			out.errors.append("beta_hand_%d" % index)
			break
	if not beta.authorize_launch():
		out.errors.append("beta_launch_authorization")
	var launched := beta.request_launch()
	if not launched:
		launched = beta.confirm_launch_for_verification()
	if not launched:
		out.errors.append("beta_finalization")
	beta.queue_free()
	await process_frame
	if not out.errors.is_empty(): return out
	var review := PrimitiveReviewCalculator.calculate(project, seed % 100)
	if review == null:
		out.errors.append("review")
		return out
	out["valid"] = true
	out["core_scores"] = [project.get_core_score(0), project.get_core_score(1), project.get_core_score(2), project.get_core_score(3)]
	out["scope"] = project.get_current_scope()
	out["hidden_bugs"] = project.get_hidden_bugs()
	out["known_bugs"] = project.get_known_bugs()
	out["fixed_bugs"] = project.get_fixed_bugs()
	out["marketing"] = project.get_marketing_output()
	out["production_rating"] = review.get_production_rating()
	out["scope_completion"] = review.get_scope_completion()
	out["bug_multiplier"] = review.get_bug_multiplier()
	out["genre_fit"] = review.get_genre_modifier()
	out["genre_deviation"] = review.get_genre_deviation()
	out["variance_roll"] = review.get_variance_roll()
	out["variance_modifier"] = review.get_variance_modifier()
	out["pre_genre_review"] = review.get_pre_genre_review()
	out["unrounded_review"] = review.get_unrounded_review()
	out["final_review"] = review.get_final_review()
	out["cash_cents"] = run.get_cash_cents()
	out["run_cycles"] = run.get_completed_run_cycles()
	return out


func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, label: String, out: Dictionary) -> bool:
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	if cards.size() != 7: return false
	var before := _state(project, run)
	var entry := {"phase": label, "draw": _ids(cards), "redraws": [], "before": before}
	var redraw_count := 0 if policy == "conservative" else 1 if policy == "ordinary" else 2
	for attempt in range(redraw_count):
		if run.get_available_redraws() <= 0: break
		var views: Array = phase.get_node("%HandContainer").get_children()
		var slot := _weakest_slot(cards)
		(views[slot] as CardView).input_button.pressed.emit()
		var changed: bool = phase.redraw_selected_cards()
		entry.redraws.append({"slot": slot, "from": str(cards[slot].id), "success": changed})
		if not changed:
			(views[slot] as CardView).input_button.pressed.emit()
			break
		cards.assign(phase.get("_candidate_cards"))
		entry.redraws[-1]["to"] = str(cards[slot].id)
	entry["final_draw"] = _ids(cards)
	var indices := _choose_production(cards, project, run, policy)
	if indices.size() != 4: return false
	var selected: Array[CardData] = []
	var current_views: Array = phase.get_node("%HandContainer").get_children()
	for slot: int in indices:
		selected.append(cards[slot])
		(current_views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	entry["printed_scope"] = selected.reduce(func(total: int, card: CardData) -> int: return total + card.scope, 0)
	entry["printed_core"] = _printed_cores(selected)
	entry["play_cost_cents"] = run.primitive_feature_hand_cost_cents(selected)
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var cycle_before := run.get_completed_run_cycles()
	if label == "design": phase.call("_on_play_card_pressed")
	else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state(project, run)
	out.actions.append(entry)
	return run.get_completed_run_cycles() == cycle_before + 1


func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, out: Dictionary) -> bool:
	var cards: Array[CardData] = phase.get("_candidate_cards")
	if cards.size() != 7: return false
	var entry := {"phase": "beta", "draw": _ids(cards), "before": _state(project, run)}
	var ranked: Array = []
	for slot in range(cards.size()):
		var card := cards[slot]
		var weight := float(card.beta_value)
		if card.id == &"search_for_bugs" and project.get_hidden_bugs() > 0: weight += 10.0
		if card.id == &"debug" and project.get_remaining_bugs() > 0: weight += 10.0
		if card.beta_category == CardData.BETA_CATEGORY_MARKETING: weight += 2.0
		ranked.append({"slot": slot, "weight": weight})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.weight > b.weight if a.weight != b.weight else a.slot < b.slot)
	var views: Array = phase.get_node("%HandContainer").get_children()
	var selected: Array[CardData] = []
	for i in range(4):
		var slot: int = ranked[i].slot
		selected.append(cards[slot])
		(views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	var categories: Array[String] = []
	for card: CardData in selected: categories.append(str(card.beta_category))
	entry["categories"] = categories
	entry["synergy"] = "QA specialization" if categories.count("qa") == 4 else "Marketing specialization" if categories.count("marketing") == 4 else "balanced operations" if categories.count("qa") > 0 and categories.count("marketing") > 0 and categories.count("insider") > 0 else "none"
	var before_cycle := run.get_completed_run_cycles()
	var ok := phase.play_selected_hand()
	entry["after"] = _state(project, run)
	out.actions.append(entry)
	return ok and run.get_completed_run_cycles() == before_cycle + 1


func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String) -> Array[int]:
	if policy == "conservative": return [0, 1, 2, 3]
	var best := -INF
	var result: Array[int] = []
	for a in range(4):
		for b in range(a + 1, 5):
			for c in range(b + 1, 6):
				for d in range(c + 1, 7):
					var hand: Array[CardData] = [cards[a], cards[b], cards[c], cards[d]]
					var cost := run.primitive_feature_hand_cost_cents(hand)
					if cost < 0 or cost > run.get_cash_cents(): continue
					var scope := 0
					var score := 0
					var primary := hand[0].primary_stat
					var same := true
					for card: CardData in hand:
						scope += card.scope
						score += card.primary_value + card.secondary_value
						if card.primary_stat != primary: same = false
					var value := 4.0 * mini(scope, maxi(0, 30 - project.get_current_scope())) + float(score)
					if policy == "optimized" and same: value += 0.5 * score
					if value > best:
						best = value
						result = [a, b, c, d]
	return result


func _weakest_slot(cards: Array[CardData]) -> int:
	var lowest := INF
	var slot := 0
	for index in range(cards.size()):
		var card := cards[index]
		var utility := float(card.primary_value + card.secondary_value + card.scope * 2)
		if utility < lowest:
			lowest = utility
			slot = index
	return slot


func _ids(cards: Array[CardData]) -> Array[String]:
	var result: Array[String] = []
	for card: CardData in cards: result.append(str(card.id))
	return result


func _printed_cores(cards: Array[CardData]) -> Dictionary:
	var scores := {"graphics": 0, "sound": 0, "technology": 0, "design": 0}
	for card: CardData in cards:
		scores[str(card.primary_stat)] += card.primary_value
		if not card.secondary_stat.is_empty(): scores[str(card.secondary_stat)] += card.secondary_value
	return scores


func _state(project: ProjectState, run: RunState) -> Dictionary:
	return {"scope": project.get_current_scope(), "cores": [project.get_core_score(0), project.get_core_score(1), project.get_core_score(2), project.get_core_score(3)],
		"hidden": project.get_hidden_bugs(), "known": project.get_known_bugs(), "fixed": project.get_fixed_bugs(), "marketing": project.get_marketing_output(),
		"cash_cents": run.get_cash_cents(), "cycle": run.get_completed_run_cycles(), "redraws": run.get_available_redraws()}
