## Paired read-only capture. Native scenes and actions; five production hands.
extends "res://analysis/task24_normal_v1.gd"

var arm := "specialty"

func _run() -> void:
	arm = _arg("--arm=", "specialty")
	era_policy = _arg("--policy=", "ordinary")
	for index in range(int(_arg("--start=", "0")), int(_arg("--start=", "0")) + int(_arg("--count=", "24"))):
		live_cycles = []
		random_inputs.seed = 250930000 + index
		var result := await _roster_route(index)
		rows.append(result)
		if not result.valid: failures += 1
		print("TASK25 ", arm, " ", era_policy, " case=", index, " releases=", result.releases.size(), " errors=", result.errors)
	var file := FileAccess.open("res://design-logs/task25-v1/routes_%s_%s_%s.json" % [arm, era_policy, _arg("--start=", "0")], FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows": rows, "failures": failures, "command": OS.get_cmdline_args()}, "  "))
	quit(0 if failures == 0 else 1)

func _roster_route(index: int) -> Dictionary:
	var genre_list: Array = PrimitivePredevelopment.catalog().genres
	var specialty := StringName(genre_list[index % 8].id)
	var seed_value := 250930100 + index * 97
	var focus := "sound" if index % 2 == 0 else "mixed"
	if _arg("--scope-trial=", "0") == "1": focus = "mixed"
	var mode := "qa" if index % 2 == 0 else "marketing"
	var out := {"arm": arm, "policy": era_policy, "case": index, "seed": seed_value, "environment_seed": 250930000 + index, "specialty": str(specialty), "actions": [], "purchases": [], "releases": [], "errors": [], "blockers": [], "valid": false}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Roster Trial"
	if arm == "specialty":
		var choice: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty")
		choice.select(index % 8 + 1)
		choice.item_selected.emit(index % 8 + 1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	run.calendar_changed.connect(_capture_cycle.bind(game))
	out["initial_owned"] = run.get_owned_feature_ids()
	if arm == "historical":
		for id: String in ROSTERS[20 + index % 4][(index / 8) % 3]:
			_purchase_initial(game, StringName(id), out)
	else:
		var target := int(run.get_starter_pool_summary().scope) if era_policy == "cautious" else 31 if era_policy == "ordinary" else 35
		if _arg("--scope-trial=", "0") == "1": target = 39
		var offers: Array[Dictionary] = []
		for entry: Dictionary in FeatureStoreCatalog.starting_features():
			var quote := run.get_primitive_reserve_offer(entry.id)
			if not quote.owned: offers.append(quote)
		offers.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.scope) > int(b.scope) if a.scope != b.scope else str(a.id) < str(b.id))
		for offer: Dictionary in offers:
			if int(run.get_starter_pool_summary().scope) >= target: break
			if run.get_cash_cents() - int(offer.price_cents) >= 180000: _purchase_initial(game, offer.id, out)
	out["starter_summary"] = run.get_starter_pool_summary()
	out["owned_before_game_1"] = run.get_owned_feature_ids()
	out["before_game_1"] = _state(game)
	for number in range(1, 3):
		if not out.errors.is_empty(): break
		var chosen := specialty if index < 8 else StringName(genre_list[(index + 3) % 8].id)
		if number == 2: chosen = StringName(genre_list[(index + 1) % 8].id)
		if not _begin_game(game, "Roster Game %d" % number, chosen, out): out.errors.append("begin_game"); break
		if not await _develop_game(game, era_policy, focus, mode, seed_value + (number - 1) * 500000, number, out): out.errors.append("development"); break
		var release := _release(game.project_state, run)
		release["required_scope"] = game.project_state.get_required_scope()
		release["sidestreet_entitlement"] = run.get("_sidestreet_entitlements").has(game.project_state.get_release_id())
		out.releases.append(release)
		if release.sidestreet_entitlement != (int(release.scope) >= int(release.required_scope)): out.errors.append("scope_gate")
		if number == 1:
			if not await _contract(game, era_policy, seed_value, out, "ironclad"): out.errors.append("ironclad"); break
			if run.is_sidestreet_offer_available() and not await _contract(game, era_policy, seed_value + 17, out, "sidestreet"): out.errors.append("sidestreet"); break
			out["before_game_2_shopping"] = _state(game)
			# Same visible, affordable reserve policy in both arms; no free money.
			for entry: Dictionary in FeatureStoreCatalog.starting_features():
				if int(run.get_starter_pool_summary().scope) >= 33: break
				var offer := run.get_primitive_reserve_offer(entry.id)
				if offer.owned or run.get_cash_cents() - int(offer.price_cents) < 180000: continue
				var before := _state(game)
				var success := run.purchase_primitive_reserve_feature(offer.id)
				out.purchases.append({"id": offer.id, "kind": "reserve", "success": success, "quote": offer, "before": before, "after": _state(game)})
				if not success: out.errors.append("reserve_purchase")
			out["before_game_2"] = _state(game)
			out["owned_before_game_2"] = run.get_owned_feature_ids()
	out["final"] = _state(game)
	out["live_cycles"] = live_cycles.duplicate(true)
	out.valid = out.errors.is_empty()
	game.queue_free()
	await process_frame
	return out

func _purchase_initial(game: Control, id: StringName, out: Dictionary) -> void:
	var before := _state(game)
	var quote: Dictionary = game.run_state.get_primitive_reserve_offer(id)
	var success: bool = game.run_state.purchase_starter_feature(id)
	out.purchases.append({"id": id, "kind": "initial", "success": success, "quote": quote, "before": before, "after": _state(game)})
	if not success: out.errors.append("initial_purchase")

func _develop_game(game: Control,policy: String,focus: String,mode: String,seed_value: int,number: int,out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState=game.project_state
	var run: RunState=game.run_state
	active_project=project
	var design: DesignPhase=game.get("_active_phase")
	design.get("_deal_rng").seed=seed_value+1
	design.get("_finalization_rng").seed=seed_value+2
	if focus=="sound": design.set_priority_distribution(_core_priorities(true))
	if not design.get_workspace().overlay.commit_draft(): return false
	var dh:=2
	var ah:=3
	var bh:=2 if policy=="cautious" else 4 if policy=="ordinary" else 6
	for hand in range(dh):
		if not _production_hand(design,project,run,policy,focus,"design",number,out):
			out.blockers.append({"phase":"design","game":number,"hand":hand+1,"state":_state(game)}); return false
		if hand==1 and policy!="cautious":
			var before:=_state(game)
			var success:=design.commit_priority_distribution(_core_priorities(false) if focus=="sound" else _core_adjustment())
			out.actions.append({"phase":"design_priority","success":success,"before":before,"after":_state(game)})
	design.call("_on_proceed_to_alpha_pressed")
	if not game.get("_active_phase") is AlphaPhase: out.errors.append("alpha_transition");return false
	var alpha: AlphaPhase=game.get("_active_phase")
	alpha.get("_deal_rng").seed=seed_value+3
	alpha.get("_finalization_rng").seed=seed_value+4
	if focus=="sound": alpha.set_priority_distribution(_core_priorities(true))
	if not alpha.get_workspace().overlay.commit_draft(): return false
	for hand in range(ah):
		if not _production_hand(alpha,project,run,policy,focus,"alpha",number,out):
			out.blockers.append({"phase":"alpha","game":number,"hand":hand+1,"state":_state(game)});return false
	alpha.request_proceed_to_beta()
	if game.get("_active_phase") is AlphaPhase and alpha.get_node("%UnderScopeDialog").visible: alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game.get("_active_phase") is BetaPhase:out.errors.append("beta_transition");return false
	var beta: BetaPhase=game.get("_active_phase")
	beta.get("_deal_rng").seed=seed_value+5
	beta.get("_insight_rng").seed=seed_value+6
	beta.set_priority_distribution(_beta_priorities(mode))
	if not beta.get_workspace().overlay.commit_draft(): return false
	for hand in range(bh):
		if not _beta_hand(beta,project,run,policy,mode,number,out):out.errors.append("beta_hand");return false
	game.set("_controlled_review_roll",-1)
	game.get("_review_rng").seed=seed_value+7
	var before:=_state(game)
	var success:=beta.request_launch()
	if not success:success=beta.confirm_launch_for_verification()
	out.actions.append({"phase":"launch","game":number,"success":success,"before":before,"after":_state(game)})
	return success and game.get("_active_phase") is StudioPhase

