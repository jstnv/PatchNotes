## Read-only legal scene route. Seeded ordinary RNG; no forced outcomes.
extends "res://analysis/contract_synergy_first_capture_v1.gd"

var active_project: ProjectState
var random_inputs := RandomNumberGenerator.new()
var guided_target: StringName = &""
var contract_initial_rolls: Dictionary = {}
var live_cycles: Array[Dictionary] = []

func _initialize() -> void:
	node_added.connect(_seed_contract_before_ready)
	super._initialize()

func _seed_contract_before_ready(node: Node) -> void:
	if not node is ContractPhase: return
	var cats: Array[float] = []
	var defs: Array[float] = []
	for i in range(7):
		cats.append(random_inputs.randf())
		defs.append(random_inputs.randf())
	node.set("_initial_category_rolls",cats)
	node.set("_initial_definition_rolls",defs)
	contract_initial_rolls={"category":cats,"definition":defs}

func _run() -> void:
	var count := int(_arg("--count=", "6"))
	for index in range(count):
		live_cycles=[]
		random_inputs.seed = 290929000 + index
		var row := await _one("synergy", index)
		rows.append(row)
		if not row.valid: failures += 1
	var file := FileAccess.open("res://design-logs/tutorial-task17-v1/strong_" + _arg("--tag=", "search") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "rows": rows}, "  "))
	print("TASK17 routes=", rows.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	if title=="Game One": game.run_state.calendar_changed.connect(_capture_cycle.bind(game))
	# Replace historical fixed market controls with uniform seeded ordinary rolls.
	var rolls: Array[int] = [random_inputs.randi_range(0,99), random_inputs.randi_range(0,99)]
	if title in ["Game Three","Game Four"]:
		var market_rng := RandomNumberGenerator.new()
		market_rng.seed=290929000+int(out.case)+int(title.hash())
		rolls=[market_rng.randi_range(0,99),market_rng.randi_range(0,99)]
	game.set("_controlled_snapshot_rolls", rolls)
	out.actions.append({"phase":"seeded_snapshot_inputs", "title":title, "rolls":rolls})
	if title == "Game Two":
		var studio: StudioPhase = game.get("_active_phase")
		studio.get_node("%FeatureStoreButton").pressed.emit()
		var store: FeatureStore = studio.get("_feature_store")
		var ids: Array = store.get("_nodes").keys()
		ids.sort()
		for id: StringName in ids:
			var offer: Dictionary = game.run_state.get_primitive_reserve_offer(id)
			if offer.get("can_purchase",false) and game.run_state.get_cash_cents() - int(offer.price_cents) >= 180000:
				var before := _state(game)
				(store.get("_nodes")[id] as Button).pressed.emit()
				(store.get("_buy") as Button).pressed.emit()
				out.actions.append({"phase":"additional_reserve", "id":str(id), "before":before, "after":_state(game)})
		store.hide()
	return super._begin_game(game,title,genre,out)

func _develop_game(game: Control, policy: String, focus: String, beta_mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame # Complete the preceding scene's queue_free before action signals.
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	active_project = project
	var design: DesignPhase = game.get("_active_phase")
	design.get("_deal_rng").seed = seed_value + 1
	design.get("_finalization_rng").seed = seed_value + 2
	if not design.get_workspace().overlay.commit_draft(): return false
	for hand in range(8 if number == 1 else 22):
		if not _production_hand(design, project, run, policy, focus, "design", number, out): break
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: return false
	var alpha: AlphaPhase = game.get("_active_phase")
	alpha.get("_deal_rng").seed = seed_value + 3
	alpha.get("_finalization_rng").seed = seed_value + 4
	if not alpha.get_workspace().overlay.commit_draft(): return false
	for hand in range(10 if number == 1 else 24):
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
	for hand in range(12):
		if not _beta_hand(beta,project,run,policy,"qa",number,out): return false
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch", "game":number,"success":launched,"before":before,"after":_state(game)})
	return launched and game.get("_active_phase") is StudioPhase

func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	var best := -INF
	var choice: Array[int] = []
	var stats: Array[StringName] = [&"graphics",&"sound",&"technology",&"design"]
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand: Array[CardData] = [cards[a],cards[b],cards[c],cards[d]]
					if run.primitive_feature_hand_cost_cents(hand)>run.get_cash_cents(): continue
					var same := hand.all(func(card: CardData): return card.primary_stat==hand[0].primary_stat)
					var value := 0.0
					if same and hand[0].primary_stat==guided_target: value+=100000.0
					var scope := 0
					for card: CardData in hand: scope += card.scope
					value += mini(scope,maxi(0,30-project.get_current_scope()))*20.0
					for i in range(4):
						var gain := 0.0
						for card: CardData in hand:
							if card.primary_stat == stats[i]: gain += card.primary_value
							if card.secondary_stat == stats[i]: gain += card.secondary_value
						if same: gain *= 1.5
						value += minf(gain,maxf(0,44-project.get_core_score(i)))*4.0
						value += gain*0.1
					if value>best: best=value; choice=[a,b,c,d]
	return choice

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	guided_target=&""
	var tutorial := run.get_first_game_tutorial(project) if phase is DesignPhase else null
	if tutorial != null and tutorial.stage==FirstGameTutorial.Stage.FIRST_HAND:
		guided_target=tutorial.first_stat
		policy="cautious"
	elif tutorial != null and tutorial.stage==FirstGameTutorial.Stage.REDRAW_HAND:
		guided_target=tutorial.second_stat
		policy="ordinary"
	var result := super._production_hand(phase,project,run,policy,focus,label,game_number,out)
	guided_target=&""
	return result

func _weakest(cards: Array[CardData], _focus: String) -> int:
	var counts := {}
	for card: CardData in cards: counts[card.primary_stat]=int(counts.get(card.primary_stat,0))+1
	var target: StringName = &""
	for stat: StringName in counts:
		if counts[stat]==3: target=stat; break
	if not target.is_empty():
		for i in range(cards.size()):
			if cards[i].primary_stat != target: return i
	var slot := 0
	var lowest := INF
	for i in range(cards.size()):
		var value := float(cards[i].scope)*20.0 if active_project.get_current_scope()<30 else 0.0
		value += cards[i].primary_value+cards[i].secondary_value
		if value<lowest: lowest=value; slot=i
	return slot

func _choose_beta(cards: Array[CardData], project: ProjectState, _mode: String, _policy: String) -> Array[int]:
	# Uses known Bugs only; no access to hidden Bug totals for policy decisions.
	var ranked: Array[int] = [0,1,2,3,4,5,6]
	var scores: Array[float] = []
	for card: CardData in cards:
		scores.append(12.0 if card.id==&"debug" and project.get_known_bugs()>0 else 10.0 if card.id==&"search_for_bugs" else 6.0 if card.id==&"debug" else float(card.beta_value))
	ranked.sort_custom(func(a:int,b:int): return scores[a]>scores[b] if scores[a]!=scores[b] else a<b)
	return [ranked[0],ranked[1],ranked[2],ranked[3]]

func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	if game != null and out.get("valid",false) and not _arg("--arm=", "").is_empty():
		await _continue_route(game,out)
	if game != null:
		out["live_cycles"]=live_cycles.duplicate(true)
		out["frozen_sales_records"] = []
		for id: StringName in game.run_state.get_released_game_ids(): out.frozen_sales_records.append(game.run_state.get_released_game_sales(id))
	return await super._cleanup(game,out)

func _store_one(game: Control, out: Dictionary) -> bool:
	var studio: StudioPhase=game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore=studio.get("_feature_store")
	var ids: Array=store.get("_nodes").keys()
	ids.sort()
	for id: StringName in ids:
		var offer: Dictionary=game.run_state.get_feature_store_offer(id)
		if not offer.is_empty() and not offer.owned and offer.unlocked and offer.affordable:
			var before:=_state(game)
			(store.get("_nodes")[id] as Button).pressed.emit()
			(store.get("_buy") as Button).pressed.emit()
			out.actions.append({"phase":"later_store", "id":str(id),"offer":offer,"before":before,"after":_state(game)})
			store.hide()
			return game.run_state.owns_feature(id)
	store.hide()
	return false

func _campaign(game: Control, index: int, out: Dictionary) -> bool:
	var studio: StudioPhase=game.get("_active_phase")
	var ids: Array[StringName]=game.run_state.get_released_game_ids()
	var before:=_state(game)
	studio.get_node("%PostGameSummaries").pressed.emit()
	studio.call("_on_game_selected",index)
	var offer: Dictionary=game.run_state.get_post_launch_campaign_offer(ids[index])
	studio.get_node("%CampaignButton").pressed.emit()
	studio.get_node("%CloseSummaryButton").pressed.emit()
	out.actions.append({"phase":"campaign", "release_index":index,"offer":offer,"before":before,"after":_state(game)})
	return game.run_state.get_completed_run_cycles()==int(before.cycle)+1

func _continue_route(game: Control, out: Dictionary) -> void:
	var arm:=_arg("--arm=", "next_game")
	out["arm"]=arm
	if _arg("--repeat-prelude=","0")=="1":
		# Shared legal prelude: age-three first-half campaign on Game 2.
		if not _store_one(game,out) or not _campaign(game,1,out):
			out.errors.append("repeat_prelude"); out.valid=false; return
	if not _begin_game(game,"Game Three",&"adventure",out) or not await _develop_game(game,"synergy","mixed","qa",int(out.seed)+1000000,3,out):
		out.errors.append("third_release"); out.valid=false; return
	out["game_3"]=_release(game.project_state,game.run_state)
	await process_frame
	for i in range(2):
		if not _store_one(game,out): out.errors.append("two_cycle_store_setup"); out.valid=false; return
	out["shared_opportunity"]=_state(game)
	out["opportunity_quotes"]={"old":game.run_state.get_post_launch_campaign_offer(StringName(out.game_2.release_id)), "new":game.run_state.get_post_launch_campaign_offer(StringName(out.game_3.release_id))}
	if arm=="campaign_new" or arm=="campaign_old":
		if not _campaign(game,2 if arm=="campaign_new" else 1,out): out.errors.append("campaign_ineligible")
	elif arm=="store":
		if not _store_one(game,out): out.errors.append("store_ineligible")
	elif arm=="contract":
		if not await _contract(game,"synergy",int(out.seed)+300,out,"sidestreet_3"): out.errors.append("contract_ineligible")
	out["opportunity_after"]=_state(game)
	if not _begin_game(game,"Game Four",&"adventure",out) or not await _develop_game(game,"synergy","mixed","qa",int(out.seed)+1500000,4,out): out.errors.append("fourth_release")
	out["game_4"]=_release(game.project_state,game.run_state)
	out["continuation_final"]=_state(game)
	# Legal next-game progress exposes the next common calendar settlement.
	if _begin_game(game,"Game Five",&"adventure",out):
		await process_frame
		var phase: DesignPhase=game.get("_active_phase")
		active_project=game.project_state
		phase.get("_deal_rng").seed=int(out.seed)+2000001
		phase.get_workspace().overlay.commit_draft()
		for i in range(2):
			if not _production_hand(phase,game.project_state,game.run_state,"synergy","mixed","design",5,out): out.errors.append("game5_followup")
	out.valid=out.errors.is_empty()

func _capture_cycle(game: Control) -> void:
	var snapshot := _state(game)
	snapshot["records"]=[]
	for id: StringName in game.run_state.get_released_game_ids(): snapshot.records.append(game.run_state.get_released_game_sales(id))
	live_cycles.append(snapshot)


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
	log["initial_uniform_rolls"] = contract_initial_rolls.duplicate(true)
	await process_frame
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
	var deferred_contracts := false
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
	if true:
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


