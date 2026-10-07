## Read-only economic experiment. This script is never loaded by gameplay.
## Proposed cards are process-local shadows; no ledger or runtime files change.
extends "res://analysis/feature_store_rebaseline_v1.gd"

var contract_arm := "available"
var alignment := 0
var neon_policy := false

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	release_band = _arg("--band=", "early")
	declared_seed = int(_arg("--seed=", "1104"))
	specialty_id = StringName(_arg("--specialty=", "action"))
	store_arm = "none"
	contract_arm = _arg("--contracts=", "available")
	alignment = int(_arg("--alignment=", "0"))
	neon_policy = _arg("--neon=", "0") == "1"
	campaign_sensitivity = _arg("--campaign=", "0") == "1"
	route_case = declared_seed
	project_number = 0
	max_games = 5
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	var path := "res://design-logs/task32-v1/route_%s_%s_%d_%s_%d_%d.json" % [release_band, era_policy, declared_seed, contract_arm, alignment, int(neon_policy)]
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("STORE_REBASELINE ", path, " releases=", out.releases.size(), " stop=", out.stop, " discrepancies=", discrepancies.size())
	quit(0 if out.valid else 1)

func _matched_route() -> Dictionary:
	var out := {"seed": declared_seed, "policy": era_policy, "band": release_band, "specialty": str(specialty_id), "store_arm": store_arm, "campaign_sensitivity": campaign_sensitivity, "first_release_target_cycle": 12 if release_band == "early" else 18, "actions": [], "purchases": [], "releases": [], "studio_visits": [], "errors": [], "blockers": [], "stop": "five releases", "contract_arm": contract_arm, "alignment": alignment, "neon_policy": neon_policy, "valid": false}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Matched Store %d" % declared_seed
	var selector: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty")
	for i in range(selector.item_count):
		if selector.get_item_metadata(i) == specialty_id: selector.select(i)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	_install_shadows(run)
	run.calendar_changed.connect(_capture_cycle.bind(game))
	out["initial"] = _state(game)
	out["starter_summary"] = run.get_starter_pool_summary()
	out["owned_ids"] = run.get_owned_feature_ids()
	_visit(game, out, "initial Studio")
	for number in range(1, 6):
		var departure := run.get_completed_run_cycles()
		if not _begin_game(game, "Matched Store Game %d" % number, specialty_id, out):
			_stop(game, out, "predevelopment", "departure rejected"); break
		out.actions[-1]["eligible_supply"] = game.project_state.get_feature_supply_ids()
		if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, out): break
		var release := _release(game.project_state, run)
		release["required_scope"] = game.project_state.get_required_scope()
		release["qualifies"] = game.project_state.get_current_scope() >= game.project_state.get_required_scope()
		release["departure_cycle"] = departure
		release["development_cycles"] = run.get_completed_run_cycles() - departure
		release["publishers"] = _publishers(run)
		release["finance_action_index"] = run.get_studio_finance_snapshot().actions.size()
		release["owned_ids"] = run.get_owned_feature_ids()
		out.releases.append(release)
		_visit(game, out, "committed release")
		if number == 5: break
		if number == 1 and contract_arm == "available":
			if not await _contract(game, era_policy, declared_seed + 30000, out, "ironclad"):
				_stop(game, out, "ironclad", "Contract blocked"); break
		if contract_arm == "available" and run.is_sidestreet_offer_available():
			if not await _contract(game, era_policy, declared_seed + 40000 + number * 100, out, "sidestreet_%d" % number):
				_stop(game, out, "sidestreet", "Contract blocked"); break
		_shop_matched(game, out, number)
		if campaign_sensitivity:
			var id: StringName = run.get_released_game_ids()[0]
			var offer := run.get_post_launch_campaign_offer(id)
			var before := _state(game)
			var success := run.purchase_post_launch_campaign(id, run.get_completed_run_cycles())
			out.actions.append({"phase": "campaign", "game": number, "id": id, "offer": offer, "success": success, "before": before, "after": _state(game)})
		_visit(game, out, "before next game")
	_capture_final(game, out)
	out["final"] = _state(game)
	out["final_finance_report"] = run.get_studio_finance_report()
	out["sales_records"] = []
	for id: StringName in run.get_released_game_ids(): out.sales_records.append(run.get_released_game_sales(id))
	out["live_cycles"] = live_cycles
	out["finance_observations"] = finance_observations
	out["ledger_checks"] = ledger_checks
	out["row_checks"] = row_checks
	out["discrepancies"] = discrepancies
	out["captures"] = final_captures
	out.valid = out.errors.is_empty() and discrepancies.is_empty()
	game.queue_free()
	await process_frame
	return out


func _develop_game(game: Control, policy: String, focus: String, mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame
	if number == 1 and alignment == 1:
		var phase: DesignPhase = game.get("_active_phase")
		var before := _state(game)
		var success := phase.commit_priority_distribution({0: 40, 1: 20, 2: 20, 3: 20})
		out.actions.append({"phase": "alignment priorities", "success": success, "before": before, "after": _state(game)})
		if not success: return false
	return await super._develop_game(game, policy, focus, mode, seed_value, number, out)

func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, policy: String, mode: String, number: int, out: Dictionary) -> bool:
	if neon_policy and number == 2:
		var count := 0
		for action: Dictionary in out.actions:
			if action.get("phase") == "beta" and action.get("game") == number: count += 1
		if count == 2:
			var before := _state_for(project, run)
			var changed := phase.commit_priority_distribution({&"qa": 25, &"marketing": 50, &"insider": 25})
			out.actions.append({"phase": "neon priorities", "success": changed, "before": before, "after": _state_for(project, run)})
		if count >= 2: mode = "marketing"
	return await super._beta_hand(phase, project, run, policy, mode, number, out)
