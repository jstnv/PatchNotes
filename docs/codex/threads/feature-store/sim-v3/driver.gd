## Read-only economic experiment. This script is never loaded by gameplay.
## Proposed cards are process-local shadows; no ledger or runtime files change.
extends "res://analysis/task29_routes_v1.gd"

var specialty_id := &"action"
var store_arm := "none"
var timing_policy := "immediate"
var campaign_sensitivity := false

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	release_band = _arg("--band=", "early")
	declared_seed = int(_arg("--seed=", "1104"))
	specialty_id = StringName(_arg("--specialty=", "action"))
	store_arm = _arg("--store=", "none")
	timing_policy = _arg("--timing=", "immediate")
	campaign_sensitivity = _arg("--campaign=", "0") == "1"
	route_case = declared_seed
	project_number = 0
	max_games = 4
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	var path := "C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/threads/feature-store/sim-v3/route_%s_%s_%s_%s_%s_%d_%d.json" % [release_band, specialty_id, era_policy, store_arm, timing_policy, declared_seed, int(campaign_sensitivity)]
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("STORE_REBASELINE ", path, " releases=", out.releases.size(), " stop=", out.stop, " discrepancies=", discrepancies.size())
	quit(0 if out.valid else 1)

func _matched_route() -> Dictionary:
	var out := {"seed": declared_seed, "policy": era_policy, "band": release_band, "specialty": str(specialty_id), "store_arm": store_arm, "timing_policy": timing_policy, "campaign_sensitivity": campaign_sensitivity, "first_release_target_cycle": 12 if release_band == "early" else 18, "actions": [], "purchases": [], "releases": [], "studio_visits": [], "errors": [], "blockers": [], "stop": "four releases", "valid": false}
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
	menu.get_node("CenterContainer/MenuLayout/StudioTraits/Background" ).select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioTraits/ReviewChoices" ).pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/CreationReview/ConfirmStudio" ).pressed.emit()
	var run: RunState = game.run_state
	_install_shadows(run)
	run.calendar_changed.connect(_capture_cycle.bind(game))
	out["initial"] = _state(game)
	out["starter_summary"] = run.get_starter_pool_summary()
	out["owned_ids"] = run.get_owned_feature_ids()
	_visit(game, out, "initial Studio")
	for number in range(1, 5):
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
		release["owned_ids"] = run.get_owned_feature_ids()
		out.releases.append(release)
		_visit(game, out, "committed release")
		if number == 4: break
		if number == 1:
			if not await _contract(game, era_policy, declared_seed + 30000, out, "ironclad"):
				_stop(game, out, "ironclad", "Contract blocked"); break
		if run.is_sidestreet_offer_available():
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
	var first_band := release_band
	# Later projects all get the same eighteen-action production budget.
	if number > 1: release_band = "slow"
	var success: bool = await super._develop_game(game, policy, focus, mode, seed_value, number, out)
	release_band = first_band
	return success

func _install_shadows(run: RunState) -> void:
	if store_arm not in ["background", "sub_areas", "staged"]: return
	var db: Node = root.get_node("CardDatabase")
	for entry: Dictionary in [
		{"id": "background_music", "name": "Background Music", "type": "feature", "phase": "alpha", "department": "audio", "primary_stat": "sound", "primary_value": 3, "secondary_stat": "", "secondary_value": 0, "scope": 1, "renewable": false, "artwork": "", "purchase_parent": "music", "gameplay_features_required": 0, "base_price_cents": 95000},
		{"id": "sub_areas", "name": "Sub-Areas", "type": "feature", "phase": "alpha", "department": "world_design", "primary_stat": "graphics", "primary_value": 3, "secondary_stat": "design", "secondary_value": 2, "scope": 2, "renewable": false, "artwork": "", "purchase_parent": "levels", "gameplay_features_required": 0, "base_price_cents": 170000}]:
		var id := StringName(entry.id)
		db.get("_store_cards")[id] = db.call("_create_card", entry)
		run.get("_feature_definitions")[id] = entry
		run.get("_feature_offers")[id] = entry

func _shop_matched(game: Control, out: Dictionary, number: int) -> void:
	var ids: Array[StringName] = []
	match store_arm:
		"background": ids = [&"background_music"]
		"sub_areas": ids = [&"sub_areas"]
	var run: RunState = game.run_state
	for id: StringName in ids:
		if run.owns_feature(id): continue
		var quote := run.get_feature_store_offer(id)
		var parent_missing: bool = not quote.parent.is_empty() and not run.owns_feature(quote.parent)
		var parent_quote: Dictionary = run.get_primitive_reserve_offer(StringName(quote.parent)) if parent_missing else {}
		var chain_cost: int = int(quote.price_cents) + int(parent_quote.get("price_cents", 0))
		var cash: int = run.get_cash_cents()
		var finance: Dictionary = run.get_studio_finance_report()
		var stronger := false
		var settled := 0
		var qualifying_release_id := ""
		if number >= 2 and out.releases.size() >= 2:
			var first_review: float = float(out.releases[0].final_review)
			for release: Dictionary in out.releases.slice(1):
				if float(release.final_review) >= 6.0 and float(release.final_review) >= first_review + 1.0:
					stronger = true
					var earned_settled: int = int(run.get_released_game_sales(StringName(release.release_id)).get("settled_cents", 0))
					if earned_settled > settled:
						settled = earned_settled
						qualifying_release_id = str(release.release_id)
		var eligible := false
		match timing_policy:
			"immediate": eligible = number == 1
			"buffer": eligible = cash >= chain_cost + 500000 and int(finance.get("unpaid_rent_cents", 0)) == 0
			"stronger_settled": eligible = stronger and settled > 0
		out.purchases.append({"id": id, "stage": "timing decision", "game": number, "timing_policy": timing_policy, "quote": quote, "parent_quote": parent_quote, "parent_missing": parent_missing, "chain_cost_cents": chain_cost, "reserve_cents": 500000 if timing_policy == "buffer" else 0, "cash_cents": cash, "next_due_cycle": finance.get("next_due_cycle"), "unpaid_rent_cents": finance.get("unpaid_rent_cents"), "stronger_review": stronger, "qualifying_release_id": qualifying_release_id, "qualifying_release_settled_cents": settled, "eligible": eligible})
		if not eligible: continue
		if not quote.parent.is_empty() and not run.owns_feature(quote.parent):
			var parent := StringName(quote.parent)
			var before := _state(game)
			var success := run.purchase_primitive_reserve_feature(parent)
			var action := {"phase": "store", "id": parent, "game": number, "kind": "required Primitive parent", "quote": parent_quote, "success": success, "before": before, "after": _state(game)}
			out.actions.append(action); out.purchases.append(action)
			if not success: continue
		quote = run.get_feature_store_offer(id)
		var before := _state(game)
		var success := run.purchase_feature(id)
		var action := {"phase": "store", "id": id, "game": number, "kind": "current upgrade" if store_arm.begins_with("existing") else "analysis-only candidate", "quote": quote, "success": success, "before": before, "after": _state(game)}
		out.actions.append(action); out.purchases.append(action)
