## Read-only live-scene era reachability. No catalog, cash, date or score injection.
## Existing harness helpers drive ordinary scene transactions; only RNG streams are seeded.
extends "res://analysis/feature_pair_game3_trial_v1.gd"

var route_kind := "production"
var cycle_cap := 240
var studio_count := 0
var cycle_rows: Array[Dictionary] = []

func _run() -> void:
	var policy := _arg("--policy=", "ordinary")
	var count := int(_arg("--count=", "4"))
	var start := int(_arg("--start=", "0"))
	route_kind = _arg("--route=", "production")
	cycle_cap = int(_arg("--cap=", "240"))
	if policy not in POLICIES or route_kind not in ["production", "minimal", "priority"]:
		quit(2)
		return
	for index in range(start, start + count):
		var row := await _route(policy, index)
		rows.append(row)
		if not row.valid: failures += 1
		print("STAGE3 case=%d/%s/%s valid=%s cycle=%d releases=%d" % [index, policy, route_kind, row.valid, row.final.cycle, row.releases.size()])
	var tag := _arg("--tag=", "")
	var path := "res://design-logs/feature-store-staged-v1/stage3_%s_%s_%d_%d%s.json" % [policy, route_kind, start, cycle_cap, "_" + tag if not tag.is_empty() else ""]
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_revision": _arg("--revision=", "608a2c62ab0850cf607f7ff627b042a49b5d2dfb"), "policy": policy, "route": route_kind, "cycle_cap": cycle_cap, "count": count, "failures": failures, "command": OS.get_cmdline_args(), "rows": rows}, "\t"))
	file.close()
	quit(0 if failures == 0 else 1)

func _route(policy: String, index: int) -> Dictionary:
	var seed_value := 270927000 + index * 97
	var focus := "sound" if index % 2 == 0 else "mixed"
	var beta_mode := "qa" if index % 2 == 0 else "marketing"
	var target := 20 + index % 4
	var roster: Array = ROSTERS[target][index % 3]
	var out := {"policy": policy, "case": index, "seed": seed_value, "route": route_kind, "focus": focus, "beta_mode": beta_mode, "starter_scope": target, "roster": roster, "valid": false, "errors": [], "blockers": [], "actions": [], "releases": [], "studio_visits": [], "purchases": [], "cycle_rows": []}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.set_snapshot_initialization_rolls((index * 7 + 11) % 100, (index * 13 + 23) % 100)
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	(menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName") as LineEdit).text = "Era Reachability %d" % index
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	studio_count = 1
	cycle_rows = []
	run.calendar_changed.connect(func():
		var snapshot := _state(game)
		snapshot["release_count"] = run.get_released_game_ids().size()
		snapshot["studio_visits"] = studio_count
		snapshot["owned_ids"] = run.get_owned_feature_ids()
		snapshot["calendar_year"] = run.get_current_year()
		cycle_rows.append(snapshot))
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	for raw_id: String in roster:
		var id := StringName(raw_id)
		var quote := run.get_primitive_reserve_offer(id)
		var before := _state(game)
		(store.get("_nodes")[id] as Button).pressed.emit()
		(store.get("_buy") as Button).pressed.emit()
		out.purchases.append({"id": raw_id, "quote": quote, "success": run.owns_feature(id), "before": before, "after": _state(game)})
		if not run.owns_feature(id): out.errors.append("starter:" + raw_id)
	store.hide()
	out["starter_summary"] = run.get_starter_pool_summary()
	if int(out.starter_summary.scope) != target or int(out.starter_summary.spent_cents) > 400000: out.errors.append("starter_roster_invalid")
	var number := 1
	while out.errors.is_empty() and run.get_completed_run_cycles() < cycle_cap and number <= 120:
		var later_rolls: Array[int] = [(index * 7 + number * 11) % 100, (index * 13 + number * 23) % 100]
		game.set("_controlled_snapshot_rolls", later_rolls)
		if not _begin_game(game, "Era Game %d" % number, GENRES[(index + number - 1) % 3], out):
			out.errors.append("predevelopment_failed_%d" % number)
			break
		await process_frame
		var success := false
		if route_kind == "priority" and number == 2:
			success = _priority_time(game, out, seed_value)
		elif route_kind == "minimal" and number > 1:
			success = _empty_release(game, out, seed_value, number)
		else:
			success = await _develop_game(game, policy, focus, beta_mode, seed_value + number * 500000, number, out)
		if not success:
			out.errors.append("development_failed_%d" % number)
			break
		var release_record := _release(game.project_state, run)
		release_record["owned_ids"] = run.get_owned_feature_ids()
		release_record["state"] = _state(game)
		out.releases.append(release_record)
		studio_count += 1
		_studio_snapshot(game, out, number)
		if route_kind == "priority" and number == 2: break
		if number == 1:
			if not await _contract(game, policy, seed_value, out, "ironclad"):
				out.errors.append("ironclad_failed")
				break
		if run.is_sidestreet_offer_available():
			if not await _contract(game, policy, seed_value + number * 17, out, "sidestreet_%d" % number):
				out.errors.append("sidestreet_failed_%d" % number)
				break
		# One discretionary live node, preserving a disclosed $1,500 production reserve.
		if route_kind == "production" and number >= 2:
			_buy_one_live(game, out)
		number += 1
	out["final"] = _state(game)
	out["owned_ids"] = run.get_owned_feature_ids()
	out["cycle_rows"] = cycle_rows.duplicate(true)
	out["stop"] = "bounded_cycle_cap" if run.get_completed_run_cycles() >= cycle_cap else "bounded_release_cap" if number > 120 else "failed_action"
	out["valid"] = out.errors.is_empty()
	game.queue_free()
	await process_frame
	return out

func _studio_snapshot(game: Control, out: Dictionary, number: int) -> void:
	var run: RunState = game.run_state
	var before := _state(game)
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	(studio.get("_feature_store") as FeatureStore).hide()
	if before != _state(game): out.errors.append("passive_store_mutation")
	var current := before.duplicate(true)
	current["game"] = number
	current["owned_ids"] = run.get_owned_feature_ids()
	current["eligible_design_ids"] = run.get_owned_feature_ids().filter(func(id): return run.get("_feature_definitions")[id].phase == "design")
	current["eligible_alpha_ids"] = run.get_owned_feature_ids().filter(func(id): return run.get("_feature_definitions")[id].phase == "alpha")
	current["due_expenses_cents"] = 0
	current["production_reserve_cents"] = 150000
	current["spendable_after_reserve_cents"] = maxi(0, run.get_cash_cents() - 150000)
	out.studio_visits.append(current)

func _buy_one_live(game: Control, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var offers: Array[Dictionary] = []
	for id: StringName in run.get("_feature_offers"):
		var quote := run.get_feature_store_offer(id)
		if not quote.owned and quote.unlocked and int(quote.price_cents) + 150000 <= run.get_cash_cents(): offers.append(quote)
	offers.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.price_cents) < int(b.price_cents) or (int(a.price_cents) == int(b.price_cents) and str(a.id) < str(b.id)))
	if offers.is_empty(): return
	var quote := offers[0]
	var before := _state(game)
	var bought := run.purchase_feature(quote.id)
	out.purchases.append({"id": quote.id, "quote": quote, "success": bought, "before": before, "after": _state(game)})
	if not bought: out.errors.append("eligible_store_buy_failed")

func _priority_time(game: Control, out: Dictionary, seed_value: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = seed_value + 700
	design.get("_finalization_rng").seed = seed_value + 701
	if not design.get_workspace().overlay.commit_draft(): return false
	var run: RunState = game.run_state
	var start_cycle := run.get_completed_run_cycles()
	var commits := 0
	while run.get_completed_run_cycles() < cycle_cap:
		var allocation := {0: 30, 1: 20, 2: 25, 3: 25} if commits % 2 == 0 else {0: 25, 1: 25, 2: 25, 3: 25}
		var before_cycle := run.get_completed_run_cycles()
		if not design.commit_priority_distribution(allocation): return false
		if run.get_completed_run_cycles() != before_cycle + 1: return false
		commits += 1
	out.actions.append({"phase": "priority_time_stress", "game": 2, "commits": commits, "from_cycle": start_cycle, "to_cycle": run.get_completed_run_cycles(), "allocation_a": {0: 30, 1: 20, 2: 25, 3: 25}, "allocation_b": {0: 25, 1: 25, 2: 25, 3: 25}})
	return _finish_empty(game, out, seed_value, 2)

func _empty_release(game: Control, out: Dictionary, seed_value: int, number: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = seed_value + number
	design.get("_finalization_rng").seed = seed_value + number + 3
	if not design.get_workspace().overlay.commit_draft(): return false
	return _finish_empty(game, out, seed_value, number)

func _finish_empty(game: Control, out: Dictionary, seed_value: int, number: int) -> bool:
	var design: DesignPhase = game.get("_active_phase")
	var before := _state(game)
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = seed_value + number + 1
	alpha.get("_finalization_rng").seed = seed_value + number + 2
	if not alpha.get_workspace().overlay.commit_draft(): return false
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible:
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase: return false
	var beta: BetaPhase = game.get("_active_phase")
	if not beta.get_workspace().overlay.commit_draft(): return false
	game.set_review_variance_roll_for_verification((seed_value / 97 + number) % 100)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "zero_hand_transitions_launch", "game": number, "before": before, "after": _state(game), "success": launched})
	return launched and game.get("_active_phase") is StudioPhase

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var tutorial := run.get_first_game_tutorial(project)
	if label != "design" or tutorial == null or tutorial.stage == FirstGameTutorial.Stage.COMPLETE:
		return super._production_hand(phase, project, run, policy, focus, label, game_number, out)
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	var target: StringName = tutorial.first_stat if tutorial.stage == FirstGameTutorial.Stage.FIRST_HAND else tutorial.second_stat
	var entry := {"phase": label, "game": game_number, "tutorial_stage": tutorial.stage, "target": target, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	if tutorial.stage == FirstGameTutorial.Stage.REDRAW_HAND:
		var views: Array = phase.get_node("%HandContainer").get_children()
		for slot in range(cards.size()):
			if cards[slot].primary_stat == target: continue
			(views[slot] as CardView).input_button.pressed.emit()
			var from_id := cards[slot].id
			var changed: bool = phase.redraw_selected_cards()
			cards.assign(phase.get("_candidate_cards"))
			entry.redraws.append({"slot": slot, "from": from_id, "to": cards[slot].id, "success": changed})
			if not changed: return false
			break
	var selected: Array[CardData] = []
	var views: Array = phase.get_node("%HandContainer").get_children()
	for slot in range(cards.size()):
		if cards[slot].primary_stat == target and selected.size() < 4:
			selected.append(cards[slot])
			(views[slot] as CardView).input_button.pressed.emit()
	if selected.size() != 4: return false
	entry["final_draw"] = _ids(cards)
	entry["selected"] = _ids(selected)
	entry["printed_core"] = _printed(selected)
	entry["printed_scope"] = selected.reduce(func(total: int, card: CardData): return total + card.scope, 0)
	entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected)
	entry["synergy"] = str(target) + " specialization"
	var before_cycle := run.get_completed_run_cycles()
	phase.call("_on_play_card_pressed")
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	return run.get_completed_run_cycles() == before_cycle + 1

func _sales(run: RunState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: StringName in run.get_released_game_ids():
		var record := run.get_released_game_sales(id)
		result.append({"release_id": str(id), "earned_cycles": record.get("total_earned_cycles", 0), "earned_units": record.get("earned_units", 0), "entitlement_cents": record.get("entitlement_cents", 0), "settled_cents": record.get("settled_cents", 0), "monthly_units": record.get("monthly_units", 0), "organic_awareness_scaled": record.get("organic_awareness_scaled", 0), "review_tenths": record.get("review_tenths", -1), "launch_awareness": record.get("launch_awareness", -1), "market_bp": record.get("market_bp", -1)})
	return result
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
	await process_frame
	var state := run.get_active_contract()
	if state == null: return false
	var log := {"label": label, "contract_id": str(state.get_contract_id()), "offer_id": str(state.get_offer_id()),
		"release_id": str(state.get_source_release_id()), "before": before, "after_accept": _state(game), "hands": []}
	if label == "ironclad" and log.after_accept.cash_cents != before.cash_cents + 40000: return false
	if label != "ironclad" and log.after_accept != before: return false
	phase.get("_rng").seed = seed + 40
	var before_seeded_deal := _state(game)
	var exhausted_before_seeded_deal := state.get_exhausted_feature_ids()
	var deterministic: Array[CardData] = phase.call("_build_candidate_pool")
	phase.call("_publish_candidate_pool", deterministic)
	log["seeded_initial_deal_passive"] = before_seeded_deal == _state(game) and exhausted_before_seeded_deal == state.get_exhausted_feature_ids()
	if not log.seeded_initial_deal_passive: return false
	for card: CardData in deterministic:
		if card.card_type == &"feature" and not state.get_eligible_feature_ids().has(card.id): return false
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
	await process_frame
	return game.get("_active_phase") is StudioPhase and log.dismiss_passive



