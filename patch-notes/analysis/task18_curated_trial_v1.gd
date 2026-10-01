## READ-ONLY employee trial. Changes only analysis-controlled redraw inputs.
extends "res://analysis/task21_route_v1.gd"

var trained := false
var perk_used := false
var extra_rng := RandomNumberGenerator.new()
var mode := "normal"
var trial_policy := "ordinary"
var decision := 0

func _run() -> void:
	mode = _arg("--reward=", "normal")
	trial_policy = _arg("--policy=", "ordinary")
	for index in range(int(_arg("--count=", "12"))):
		live_cycles = []
		trained = false
		decision = 0
		random_inputs.seed = 290929000 + index
		extra_rng.seed = 180929000 + index
		var row := await _one(trial_policy, index)
		rows.append(row)
		if not row.valid: failures += 1
	var file := FileAccess.open("res://design-logs/task18-v1/" + trial_policy + "_" + mode + _arg("--tag=", "") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"rows":rows}, "  "))
	print("TASK18 routes=",rows.size()," failures=",failures)
	quit(0 if failures == 0 else 1)

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	if not out.has("trial_events"): out["trial_events"] = []
	return super._begin_game(game,title,genre,out)

func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	out.errors.erase("starwave_gate")
	out.valid = out.errors.is_empty()
	if out.valid and int(out.case) < int(_arg("--game3-count=", "2")):
		if not _begin_game(game,"Game Three",&"strategy",out) or not await _develop_game(game,trial_policy,"mixed","qa",int(out.seed)+1000000,3,out):
			out.errors.append("game_3")
		else: out["game_3"] = _release(game.project_state,game.run_state)
	return await super._cleanup(game,out)

func _alpha_screen(phase: AlphaPhase, project: ProjectState, run: RunState, number: int, out: Dictionary) -> void:
	var cards: Array[CardData] = phase.get("_candidate_cards").duplicate()
	var counts := {}
	for c: CardData in cards: counts[c.primary_stat] = int(counts.get(c.primary_stat,0))+1
	var threes: Array[StringName] = []
	for stat: StringName in counts:
		if counts[stat] == 3: threes.append(stat)
	var matching: Array[StringName] = []
	for c: CardData in phase.get("_available_features"):
		if c.primary_stat in threes and not _ids(cards).has(str(c.id)): matching.append(c.id)
	out.trial_events.append({"kind":"first_alpha", "game":number, "trained":trained,"draw":_ids(cards),"threes":threes,"offscreen_matching":matching,"bank":run.get_available_redraws(),"scope":project.get_current_scope()})

func _pool_value(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> float:
	var chosen := _choose_production(cards,project,run,policy,focus)
	if chosen.size()!=4: return -INF
	var hand: Array[CardData] = []
	for i in chosen: hand.append(cards[i])
	var same := hand.all(func(c: CardData): return c.primary_stat == hand[0].primary_stat)
	var scope := 0
	var core := 0.0
	var stats: Array[StringName] = [&"graphics",&"sound",&"technology",&"design"]
	for c: CardData in hand:
		scope += c.scope
		if policy == "synergy":
			core += c.primary_value * float(project.get_genre_ratios()[stats.find(c.primary_stat)]) / 25.0
			if c.secondary_value > 0: core += c.secondary_value * float(project.get_genre_ratios()[stats.find(c.secondary_stat)]) / 25.0
		else:
			core += c.primary_value + c.secondary_value
			if focus == "sound": core += 1.4 * ((c.primary_value if c.primary_stat == &"sound" else 0) + (c.secondary_value if c.secondary_stat == &"sound" else 0))
	return mini(scope,maxi(0,project.get_required_scope()-project.get_current_scope()))*4.0 + core*(1.5 if same and policy=="synergy" else 1.0)+(10.0 if same and policy=="synergy" else 2.0 if same else 0.0)

func _entries(phase: Control, old: CardData, cards: Array[CardData], kind: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Array = phase.get("_available_features") if kind == &"feature" else phase.get("_pass_definitions")
	for c: CardData in source:
		if c.id == old.id or (kind == &"feature" and _ids(cards).has(str(c.id))): continue
		var weight: float = phase.call("_calculate_candidate_weight",c,phase.get_priority_distribution())
		if weight > 0: result.append({"card":c,"weight":weight})
	result.sort_custom(func(a: Dictionary,b: Dictionary): return str(a.card.id)<str(b.card.id))
	return result

func _roll_for(entries: Array[Dictionary], card: CardData, split: bool) -> float:
	var total := 0.0
	var before := 0.0
	var selected := 0.0
	for e: Dictionary in entries: total += float(e.weight)
	for e: Dictionary in entries:
		if e.card.id == card.id: selected = float(e.weight); break
		before += float(e.weight)
	var roll := (before + selected * 0.5) / total
	return roll * 0.5 + (0.5 if card.card_type == &"pass" else 0.0) if split else roll

func _trial_redraw(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = phase.get("_candidate_cards").duplicate()
	var views: Array[CardView] = phase.get("_selected_card_views")
	if views.size()!=1: return phase.redraw_selected_cards()
	var slot := views[0].get_index()
	var old := cards[slot]
	var rng: RandomNumberGenerator = phase.get("_deal_rng")
	var rng_before := rng.state
	if _arg("--protocol-probes=", "0") == "1":
		var before_probe := _state_for(project,run)
		var perk_before := perk_used
		var before_cards := _ids(cards)
		var rejected: bool = not phase.redraw_selected_cards([-1.0] as Array[float])
		# Canceled pre-confirmation preview: no options are returned to the policy
		# or displayed. Only the existing read-only availability plan is queried.
		phase.call("_plan_selected_redraw",[0.5] as Array[float])
		phase.call("_plan_selected_redraw",[0.5] as Array[float])
		if not rejected or _state_for(project,run)!=before_probe or rng.state!=rng_before or perk_used!=perk_before or _ids(phase.get("_candidate_cards"))!=before_cards:
			failures+=1
			push_error("FAIL: rejected/canceled trial preview mutated state")
	# Preserve the tutorial guarantee and its zero random consumption.
	var preview: Dictionary = phase.call("_plan_selected_redraw", [0.5] as Array[float])
	if preview.get("guided_redraw",false): return phase.redraw_selected_cards()
	var roll := rng.randf()
	var first_plan: Dictionary = phase.call("_plan_selected_redraw", [roll] as Array[float])
	if not first_plan.valid:
		rng.state = rng_before
		return false
	var first: CardData = first_plan.cards[0]
	var features := _entries(phase,old,cards,&"feature")
	var passes := _entries(phase,old,cards,&"pass")
	var entries := features if first.card_type == &"feature" else passes
	var alternatives: Array[Dictionary] = []
	for e: Dictionary in entries:
		if e.card.id!=first.id: alternatives.append(e)
	var counts := {}
	for c: CardData in cards: counts[c.primary_stat]=int(counts.get(c.primary_stat,0))+1
	var wants := counts.values().has(3) or label == "alpha"
	var eligible := trained and not perk_used and wants
	var chosen := first
	var second: CardData = null
	var extra_roll := extra_rng.randf()
	if not alternatives.is_empty(): second = phase.call("_select_weighted_entry",alternatives,extra_roll)
	var first_pool := cards.duplicate()
	first_pool[slot]=first
	var value := _pool_value(first_pool,project,run,policy,focus)
	var use := eligible and entries.size()>=2 and mode != "normal"
	if use and mode == "curated":
		var second_pool := cards.duplicate()
		second_pool[slot]=second
		if _pool_value(second_pool,project,run,policy,focus)>value: chosen=second
	elif use and mode == "core":
		# Explicit upper bound: best printed primary Core from visible hand, then
		# weighted legal definition in that Core on the separate trial stream.
		var best_stat: StringName = cards[0].primary_stat
		for stat: StringName in counts:
			if int(counts[stat]) > int(counts[best_stat]): best_stat=stat
		var core_entries: Array[Dictionary] = []
		for e: Dictionary in features+passes:
			if e.card.primary_stat==best_stat: core_entries.append(e)
		if not core_entries.is_empty(): chosen=phase.call("_select_weighted_entry",core_entries,extra_roll)
	var commit_entries := features if chosen.card_type==&"feature" else passes
	var commit_roll := _roll_for(commit_entries,chosen,not features.is_empty() and not passes.is_empty())
	var before := _state_for(project,run)
	var finite_before := _ids(phase.get("_available_features"))
	var planned: Dictionary = phase.call("_plan_selected_redraw",[commit_roll] as Array[float])
	if not planned.valid or planned.cards[0].id!=chosen.id:
		push_error("FAIL: curated inverse-weight lookup")
		failures+=1
		return false
	var success: bool = phase.redraw_selected_cards([commit_roll] as Array[float])
	if success and use: perk_used=true
	if not success: rng.state=rng_before
	var chosen_pool := cards.duplicate()
	chosen_pool[slot]=chosen
	out.trial_events.append({"kind":"redraw", "decision":decision,"game":number,"phase":label,"mode":mode,"trained":trained,"eligible":eligible,"used":success and use,"fewer_than_two":eligible and entries.size()<2,"draw":_ids(cards),"slot":slot,"priorities":phase.get_priority_distribution(),"finite_available":finite_before,"roll":roll,"extra_roll":extra_roll,"class":first.card_type,"legal_class":entries.map(func(e: Dictionary): return str(e.card.id)),"first":first.id,"second":second.id if second!=null else &"","choice":chosen.id,"first_value":value,"chosen_value":_pool_value(chosen_pool,project,run,policy,focus),"success":success,"before":before,"after":_state_for(project,run)})
	decision+=1
	if success and (run.get_available_redraws()!=int(before.redraws)-1 or run.get_completed_run_cycles()!=int(before.cycle)):
		failures+=1
		push_error("FAIL: trial redraw charge/cycle")
	return success

func _develop_game(game: Control, policy: String, focus: String, beta_mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	perk_used = false
	await process_frame # Complete the preceding scene's queue_free before action signals.
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	active_project = project
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = seed_value + 1
	design.get("_finalization_rng").seed = seed_value + 2
	if not design.get_workspace().overlay.commit_draft(): return false
	for hand in range(4 if policy == "ordinary" else 6):
		if not _production_hand(design, project, run, policy, focus, "design", number, out): break
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = seed_value + 3
	alpha.get("_finalization_rng").seed = seed_value + 4
	if not alpha.get_workspace().overlay.commit_draft(): return false
	_alpha_screen(alpha, project, run, number, out)
	for hand in range(6 if policy == "ordinary" else 8):
		if not _production_hand(alpha, project, run, policy, focus, "alpha", number, out): break
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible:
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase: return false
	var beta: BetaPhase = game.get("_active_phase")
	beta.get("_deal_rng").seed = seed_value + 5
	beta.get("_insight_rng").seed = seed_value + 6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft(): return false
	for hand in range(6):
		if not _beta_hand(beta,project,run,policy,"qa",number,out): return false
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch", "game":number,"success":launched,"before":before,"after":_state(game)})
	return launched and game.get("_active_phase") is StudioPhase

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	active_project = project
	guided_target = &""
	var tutorial := run.get_first_game_tutorial(project) if phase is DesignPhase else null
	if tutorial != null and tutorial.stage == FirstGameTutorial.Stage.FIRST_HAND:
		guided_target = tutorial.first_stat
		policy = "cautious"
	elif tutorial != null and tutorial.stage == FirstGameTutorial.Stage.REDRAW_HAND:
		guided_target = tutorial.second_stat
		policy = "ordinary"
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
		var changed: bool = _trial_redraw(phase, project, run, policy, focus, label, game_number, out)
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
	if run.get_completed_run_cycles() == before_cycle + 1 and label == "design" and not trained:
		for pass_card: CardData in selected:
			if trained: break
			if pass_card.card_type != &"pass": continue
			for feature: CardData in selected:
				if feature.card_type == &"feature" and pass_card.primary_stat in [feature.primary_stat, feature.secondary_stat]:
					trained = true
					out.trial_events.append({"kind":"training", "game":game_number, "cycle":run.get_completed_run_cycles(), "pass":pass_card.id, "feature":feature.id})
					break
	return run.get_completed_run_cycles() == before_cycle + 1


func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	if not guided_target.is_empty(): return super._choose_production(cards, project, run, policy, focus)
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


