## Bounded, native Task29 rent routes. Policies see only displayed information.
## No injected money/cards, free waits, loan, or forced launch results.
extends "res://analysis/lifespan_verify_routes_v2.gd"

var declared_seed := 1104
var release_band := "early"
var funding_mode := "base"
var next_contract_seed := 0
var finance_observations: Array = []

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	release_band = _arg("--band=", "early")
	funding_mode = _arg("--funding=", "base")
	declared_seed = int(_arg("--seed=", "1104"))
	route_case = declared_seed
	project_number = 0
	max_games = 3
	action_limit = 100
	era_cap = 0
	first_store_cycle = 0
	arm = "next"
	experiment = "task29"
	random_inputs.seed = declared_seed
	mode = _arg("--reward=", "none")
	staff = int(_arg("--staff=", "1"))
	extra_rng.seed = declared_seed + 180000000
	var out := await _finance_route()
	out["reward"] = mode
	out["staff"] = staff
	out["trial_events"] = trial_events
	var destination := _arg("--out=", "res://design-logs/task33-v1") + "/route_%s_%s_%s_%d_%s_%d.json" % [funding_mode, release_band, era_policy, declared_seed, mode, staff]
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("EMPLOYEE TRIAL ", destination, " releases=", out.releases.size(), " stop=", out.stop, " discrepancies=", discrepancies.size())
	quit(0 if out.valid else 1)

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var value := super._state_for(project, run)
	value["finance"] = run.call("get_studio_finance_snapshot") if run.has_method("get_studio_finance_snapshot") else {}
	value["finance_report"] = run.call("get_studio_finance_report") if run.has_method("get_studio_finance_report") else {}
	value["financial_block"] = run.call("get_financial_block_reason") if run.has_method("get_financial_block_reason") else "finance API unavailable"
	return value

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	finance_observations.append({"cycle": game.run_state.get_completed_run_cycles(), "report": game.run_state.call("get_studio_finance_report"), "snapshot": game.run_state.call("get_studio_finance_snapshot")})

func _capture_final(game: Control, out: Dictionary) -> void:
	super._capture_final(game, out)
	if final_captures.is_empty(): return
	var capture: Dictionary = final_captures[-1]
	for key: String in ["studio_finance", "studio_finance_report"]:
		var live: Dictionary = game.run_state.call("get_studio_finance_snapshot" if key == "studio_finance" else "get_studio_finance_report")
		if capture.get(key, {}) != JSON.parse_string(JSON.stringify(live)):
			discrepancies.append({"kind": "finance capture mismatch", "field": key})

func _finance_blocked(run: RunState) -> bool:
	return not str(run.call("get_financial_block_reason")).is_empty()

func _stop(game: Control, out: Dictionary, phase: String, reason: String) -> void:
	out.stop = "financial_block" if _finance_blocked(game.run_state) else "policy_action_blocked"
	out.blockers.append({"game": project_number, "phase": phase, "reason": reason, "state": _state(game)})

func _curtail(game: Control, out: Dictionary, phase: String, hand: int) -> void:
	out.blockers.append({"game": project_number, "phase": phase, "hand": hand + 1, "reason": "Rejected production; take remaining free phase transitions and attempt legal release", "state": _state(game)})

func _finance_route() -> Dictionary:
	var target_cycle := 12 if release_band == "early" else (13 if release_band == "odd" else (14 if release_band == "middle" else (22 if release_band == "stress" else 18)))
	var out := {"seed": declared_seed, "policy": era_policy, "band": release_band, "funding": funding_mode, "first_release_target_cycle": target_cycle, "specialty": "action", "actions": [], "purchases": [], "releases": [], "studio_visits": [], "errors": [], "blockers": [], "stop": "requested three-release horizon", "valid": false}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var created_run := RunState.new()
	created_run.initialize_cash_cents(0)
	var created := false
	if funding_mode == "trait":
		created = created_run.create_studio("Rent Route %d" % declared_seed, &"action", &"family_funding", [])
	elif funding_mode == "base":
		created = created_run.set_studio_name("Rent Route %d" % declared_seed, &"action")
	if not created:
		out.errors.append("Studio creation rejected: " + funding_mode)
		return out
	game.run_state = created_run
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	out["creation"] = run.get_studio_creation_snapshot()
	var expected_cash := 570000 if funding_mode == "trait" else 550000
	if run.get_cash_cents() != expected_cash or not game.get("_active_phase") is StudioPhase:
		out.errors.append("Studio creation cash/phase mismatch")
	if not run.has_method("get_studio_finance_report"):
		out.errors.append("Task29 finance API unavailable")
	else:
		run.calendar_changed.connect(_capture_cycle.bind(game))
		out["initial"] = _state(game)
		out["starter_summary"] = run.get_starter_pool_summary()
		out["owned_ids"] = run.get_owned_feature_ids()
		_visit(game, out, "initial Studio")
		for number in range(1, 4):
			if not _begin_game(game, "Rent Route Game %d" % number, &"action", out): _stop(game, out, "predevelopment", "departure rejected"); break
			if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, out): break
			var release := _release(game.project_state, run)
			release["required_scope"] = game.project_state.get_required_scope()
			release["qualifies"] = game.project_state.get_current_scope() >= game.project_state.get_required_scope()
			out.releases.append(release)
			_visit(game, out, "committed release")
			if number == 1:
				if not await _contract(game, era_policy, declared_seed + 30000, out, "ironclad"): _stop(game, out, "ironclad", "Contract did not complete"); break
				if run.is_sidestreet_offer_available():
					if not await _contract(game, era_policy, declared_seed + 40000, out, "sidestreet_1"): _stop(game, out, "sidestreet", "Contract did not complete"); break
				_trial_shop(game, out)
				out["game2_available_cash"] = _state(game)
				_visit(game, out, "before Game 2")
		if out.releases.size() == 3:
			out["second_release_checkpoint"] = _state(game)
			if _begin_game(game, "Employee Trial Follow-up", &"action", out):
				await process_frame
				var phase: DesignPhase = game.get("_active_phase")
				active_project = game.project_state
				phase_for_choice = phase
				if not _production_hand(phase, game.project_state, run, era_policy, "mixed", "design", 4, out):
					_stop(game, out, "post-release follow-up", "first Game3 hand rejected before Game2 full settlement")
				else: out.stop = "three releases and two legal earning follow-up actions"
			else: _stop(game, out, "post-release follow-up", "Game3 departure rejected before Game2 first settlement")
		_capture_final(game, out)
	out["final"] = _state(game)
	out["final_finance_report"] = run.call("get_studio_finance_report") if run.has_method("get_studio_finance_report") else {}
	out["live_cycles"] = live_cycles
	out["finance_observations"] = finance_observations
	out["ledger_checks"] = ledger_checks
	out["row_checks"] = row_checks
	out["discrepancies"] = discrepancies
	out["captures"] = []
	out.valid = out.errors.is_empty() and discrepancies.is_empty()
	game.queue_free()
	await process_frame
	return out

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	project_number += 1
	uses_in_project = 0
	triggered_project = false
	perk_used = false
	var seed_value := declared_seed + (project_number - 1) * 500000
	var seed_ready := func(child: Node):
		if child is DesignPhase:
			child.ready.connect(func():
				child.get("_deal_rng").seed = seed_value + 1
				child.get("_finalization_rng").seed = seed_value + 2, CONNECT_ONE_SHOT)
	game.get_node("%PhaseRoot").child_entered_tree.connect(seed_ready)
	var rolls: Array[int] = [random_inputs.randi_range(0, 99), random_inputs.randi_range(0, 99)]
	game.set("_controlled_snapshot_rolls", rolls)
	var studio: StudioPhase = game.get("_active_phase")
	studio.close_summary()
	studio.get_node("%StartNextGame").pressed.emit()
	if studio.get_node("%LowScopeWarning").visible: studio.get_node("%LowScopeWarning").confirmed.emit()
	var setup: PredevelopmentOverlay = studio.get("_predevelopment")
	if setup == null:
		game.get_node("%PhaseRoot").child_entered_tree.disconnect(seed_ready)
		return false
	setup.name_input.text = title
	for i in range(setup.genre_input.item_count):
		if setup.genre_input.get_item_metadata(i) == genre: setup.genre_input.select(i)
	var priorities := {0: 25, 1: 25, 2: 25, 3: 25}
	# Rank the actual visible Genre ratios; equal ratios keep Core display order.
	if era_policy == "synergy":
		var ratios: Array = PrimitivePredevelopment.find_entry("genres", genre).ratios
		var ranked: Array[int] = [0, 1, 2, 3]
		ranked.sort_custom(func(a: int, b: int): return ratios[a] > ratios[b] if ratios[a] != ratios[b] else a < b)
		priorities = {ranked[0]: 50, ranked[1]: 30, ranked[2]: 15, ranked[3]: 5}
	for i in range(4): setup.priority_sliders[i].value = priorities[i]
	var before := _state(game)
	setup.begin_button.pressed.emit()
	game.get_node("%PhaseRoot").child_entered_tree.disconnect(seed_ready)
	var success: bool = game.get("_active_phase") is DesignPhase and not game.get("_active_phase").is_initial_priority_planning()
	out.actions.append({"phase": "predevelopment", "game": project_number, "title": title, "genre": genre, "rolls": rolls, "priorities": priorities, "before": before, "after": _state(game), "success": success})
	return success

func _develop_game(game: Control, policy: String, focus: String, _mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	active_project = project
	var budgets := [3, 4, 4] if release_band == "early" else ([4, 4, 4] if release_band == "odd" else ([4, 5, 4] if release_band == "middle" else ([7, 8, 6] if release_band == "stress" else [5, 6, 6])))
	var curtailed := false
	for phase_index in range(2):
		var label := "design" if phase_index == 0 else "alpha"
		var phase: Control = game.get("_active_phase")
		if phase.is_initial_priority_planning():
			phase.get("_deal_rng").seed = seed_value + 3
			phase.get("_finalization_rng").seed = seed_value + 4
			if policy == "synergy": phase.set_priority_distribution(_priorities(project))
			if not phase.get_workspace().overlay.commit_draft(): _stop(game, out, label, "initial priorities rejected"); return false
		for hand in range(budgets[phase_index]):
			if curtailed: break
			phase_for_choice = phase
			if not _production_hand(phase, project, run, policy, focus, label, number, out):
				_curtail(game, out, label, hand)
				curtailed = true
				break
		if phase_index == 0: phase.call("_on_proceed_to_alpha_pressed")
		else:
			phase.request_proceed_to_beta()
			if phase.get_node("%UnderScopeDialog").visible: phase.get_node("%UnderScopeDialog").confirmed.emit()
		if (phase_index == 0 and not game.get("_active_phase") is AlphaPhase) or (phase_index == 1 and not game.get("_active_phase") is BetaPhase): _stop(game, out, label, "phase transition rejected"); return false
	var beta: BetaPhase = game.get("_active_phase")
	beta.get("_deal_rng").seed = seed_value + 5
	beta.get("_insight_rng").seed = seed_value + 6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft(): _stop(game, out, "beta", "initial priorities rejected"); return false
	for hand in range(budgets[2]):
		if curtailed: break
		if not _beta_hand(beta, project, run, policy, "qa", number, out):
			_curtail(game, out, "beta", hand)
			curtailed = true
			break
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": number, "success": launched, "budget_curtailed": curtailed, "before": before, "after": _state(game)})
	if not launched: _stop(game, out, "launch", "launch rejected")
	return launched and game.get("_active_phase") is StudioPhase

func _seed_contract_before_ready(node: Node) -> void:
	if not node is ContractPhase: return
	var generator := RandomNumberGenerator.new()
	generator.seed = next_contract_seed
	var cats: Array[float] = []
	var defs: Array[float] = []
	for i in range(7):
		cats.append(generator.randf())
		defs.append(generator.randf())
	var run: RunState = node.get("_run")
	if not node.setup(node.get("_state"), run, cats, defs): discrepancies.append({"kind": "Contract setup"})
	contract_initial_rolls = {"seed": next_contract_seed, "category": cats, "definition": defs}
	node.ready.connect(func():
		node.get("_rng").seed = generator.seed
		node.get("_rng").state = generator.state, CONNECT_ONE_SHOT)

func _contract(game: Control, policy: String, seed_value: int, out: Dictionary, label: String) -> bool:
	var run: RunState = game.run_state
	var before := _state(game)
	next_contract_seed = seed_value
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%Contracts").pressed.emit()
	var detail := studio.get_node_or_null("ContractDetail")
	if detail == null: return false
	(detail.find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	if not game.get("_active_phase") is ContractPhase: return false
	var phase: ContractPhase = game.get("_active_phase")
	var state := run.get_active_contract()
	var log := {"label": label, "initial_uniform_rolls": contract_initial_rolls.duplicate(true), "before": before, "after_accept": _state(game), "hands": []}
	out.actions.append({"phase": label + " accept", "before": before, "after": _state(game), "success": true})
	await process_frame
	for hand in range(2):
		var cards := phase.get_candidate_cards()
		if cards.size() != 7: return false
		var action := {"phase": label + " hand", "hand": hand + 1, "draw": _ids(cards), "before": _state(game), "redraws": []}
		if run.get_available_redraws() > 0:
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
		action["plan"] = state.plan_hand(selected)
		action["success"] = phase.call("_play_selected_hand")
		action["after"] = _state(game)
		log.hands.append(action)
		out.actions.append(action)
		if not action.success: out[label] = log; return false
	if not state.is_completed(): return false
	var result := state.get_result()
	log["completion"] = {"numerator": result.get_completion_numerator(), "scope": result.get_scope(), "payout_cents": result.get_payout_cents(), "upfront_cents": result.get_upfront_cents(), "remainder_cents": result.get_completion_payment_cents()}
	var before_dismiss := _state(game)
	(phase.get("_completion_panel").find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
	log["after_dismiss"] = _state(game)
	log["dismiss_passive"] = before_dismiss == log.after_dismiss
	out[label] = log
	if not log.dismiss_passive: discrepancies.append({"kind": "Contract dismissal changed state"})
	return game.get("_active_phase") is StudioPhase and log.dismiss_passive


var mode := "none"
var staff := 1
var trained := false
var triggered_project := false
var perk_used := false
var uses_in_project := 0
var decision := 0
var extra_rng := RandomNumberGenerator.new()
var trial_events: Array = []

func _shadow_priority(phase: Control, distribution: Dictionary) -> bool:
	# Analysis-only counterfactual: public setter intentionally rejects active play.
	if not PriorityAllocation.is_valid_distribution(distribution): return false
	if not phase.get("_priority_allocation").set_distribution(distribution): return false
	phase.set("_priority_draft", phase.get_priority_distribution())
	phase.call("_sync_priority_controls")
	return true

func _printed_match(cards: Array[CardData]) -> bool:
	for p: CardData in cards:
		if p.card_type != &"pass": continue
		for f: CardData in cards:
			if f.card_type == &"feature" and p.primary_stat in [f.primary_stat, f.secondary_stat]: return true
	return false

func _release(project: ProjectState, run: RunState) -> Dictionary:
	var value := super._release(project,run)
	value["sales_record"] = run.get_released_game_sales(project.get_release_id())
	return value

func _trial_shop(game: Control, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var offers: Array[Dictionary] = []
	for item: Dictionary in FeatureStoreCatalog.entries():
		var offer := run.get_feature_store_offer(item.id)
		if offer.unlocked and not offer.owned and int(offer.price_cents) + 180000 <= run.get_cash_cents(): offers.append(offer)
	offers.sort_custom(func(a: Dictionary,b: Dictionary): return int(a.price_cents) < int(b.price_cents) if a.price_cents != b.price_cents else str(a.id) < str(b.id))
	var before := _state(game)
	var offer: Dictionary = offers[0] if not offers.is_empty() else {}
	var success := run.purchase_feature(offer.id) if not offer.is_empty() else false
	out.actions.append({"phase":"store","quote":offer,"success":success,"before":before,"after":_state(game)})
	out.purchases.append(out.actions[-1])

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
	var eligible := staff > 0 and trained and uses_in_project < staff and wants
	var chosen := first
	var second: CardData = null
	var extra_roll := extra_rng.randf()
	if not alternatives.is_empty(): second = phase.call("_select_weighted_entry",alternatives,extra_roll)
	var first_pool := cards.duplicate()
	first_pool[slot]=first
	var value := _pool_value(first_pool,project,run,policy,focus)
	var use := eligible and entries.size()>=2 and mode == "curated"
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
	if success and use:
		perk_used=true
		uses_in_project += 1
	if not success: rng.state=rng_before
	var chosen_pool := cards.duplicate()
	chosen_pool[slot]=chosen
	trial_events.append({"kind":"redraw", "decision":decision,"game":number,"phase":label,"mode":mode,"trained":trained,"eligible":eligible,"used":success and use,"fewer_than_two":eligible and entries.size()<2,"draw":_ids(cards),"slot":slot,"priorities":phase.get_priority_distribution(),"finite_available":finite_before,"roll":roll,"extra_roll":extra_roll,"class":first.card_type,"legal_class":entries.map(func(e: Dictionary): return str(e.card.id)),"first":first.id,"second":second.id if second!=null else &"","choice":chosen.id,"first_value":value,"chosen_value":_pool_value(chosen_pool,project,run,policy,focus),"success":success,"before":before,"after":_state_for(project,run)})
	decision+=1
	if success and (run.get_available_redraws()!=int(before.redraws)-1 or run.get_completed_run_cycles()!=int(before.cycle)):
		failures+=1
		push_error("FAIL: trial redraw charge/cycle")
	return success


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
	var matching := _printed_match(selected)
	var saved_priorities: Dictionary = phase.get_priority_distribution().duplicate()
	var desired := _priorities(project)
	var eligible := staff > 0 and trained and uses_in_project < staff and matching and desired != saved_priorities
	var used := false
	if mode in ["paid", "standalone", "bundle"] and eligible:
		var before_priority := _state_for(project, run)
		used = phase.commit_priority_distribution(desired) if mode == "paid" else _shadow_priority(phase, desired)
		trial_events.append({"kind":"priority", "mode":mode,"game":game_number,"matching":matching,"selected":_ids(selected),"old":saved_priorities,"new":desired,"before":before_priority,"after":_state_for(project,run),"success":used})
		if used and mode != "bundle": uses_in_project += 1
	entry["priority_opportunity"] = eligible
	entry["priority_use"] = used
	entry["priority_before"] = saved_priorities
	entry["priority_after"] = phase.get_priority_distribution()
	entry["matching"] = matching
	entry["trained_before"] = trained
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var before_cycle := run.get_completed_run_cycles()
	if label == "design": phase.call("_on_play_card_pressed")
	else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	var committed := run.get_completed_run_cycles() == before_cycle + 1
	if used and mode == "bundle":
		if committed: uses_in_project += 1
		else: _shadow_priority(phase, saved_priorities)
	if committed and label == "design" and matching and not triggered_project and staff > 0:
		triggered_project = true
		trained = true
		trial_events.append({"kind":"training","game":game_number,"cycle":run.get_completed_run_cycles(),"staff":staff,"selected":_ids(selected)})
	entry["committed"] = committed
	entry["uses_in_project"] = uses_in_project
	_check_year(phase.get_parent().get_parent())
	return committed
