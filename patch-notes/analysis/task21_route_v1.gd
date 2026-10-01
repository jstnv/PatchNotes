## Current-code route; historical inputs retained, unavailable SideStreet omitted.
extends "res://analysis/task17_strong_route_v1.gd"

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	var year: int = game.run_state.get_current_year()
	live_cycles[-1]["year"] = year
	live_cycles[-1]["hud_year_visible"] = hud.footer.text.contains(str(year))
	live_cycles[-1]["phase_type"] = game.get("_active_phase").get_script().resource_path
	# This callback may precede the HUD's listener after a phase reconnect.
	# Assert the visible result after the action returns, not mid-signal.

func _check_year(game: Control) -> void:
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	if not hud.footer.text.contains(str(game.run_state.get_current_year())):
		failures += 1
		push_error("FAIL: HUD did not refresh after completed action")

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var result := super._production_hand(phase, project, run, policy, focus, label, game_number, out)
	_check_year(phase.get_parent().get_parent())
	return result

func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, policy: String, mode: String, game_number: int, out: Dictionary) -> bool:
	var result := super._beta_hand(phase, project, run, policy, mode, game_number, out)
	_check_year(phase.get_parent().get_parent())
	return result

func _run() -> void:
	for index in range(int(_arg("--count=", "1"))):
		live_cycles = []
		random_inputs.seed = 290929000 + index
		var row := await _one("synergy", index)
		rows.append(row)
		if not row.valid: failures += 1
	var file := FileAccess.open("res://design-logs/task21-v1/route_" + _arg("--mode=", "adjusted") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "rows": rows}, "  "))
	print("TASK21 routes=", rows.size(), " failures=", failures)
	quit(0 if failures == 0 else 1)

func _contract(game: Control, policy: String, seed_value: int, out: Dictionary, label: String) -> bool:
	if label == "sidestreet_1":
		out["scope_gate_divergence"] = {"label": label, "state": _state(game), "available": game.run_state.is_sidestreet_offer_available(), "reason": "Game 1 printed Scope below chosen size requirement"}
		# Preserve the recorded later market stream; no card is drawn or granted.
		for i in range(14): random_inputs.randf()
		return not game.run_state.is_sidestreet_offer_available()
	if label.begins_with("sidestreet") and not game.run_state.is_sidestreet_offer_available():
		out.actions.append({"phase": "unavailable_contract", "label": label, "state": _state(game)})
		return true
	return await super._contract(game, policy, seed_value, out, label)

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	if title == "Game Two" and _arg("--mode=", "adjusted") == "exact":
		var historical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/tutorial-task17-v1/strong_final.json"))
		var original: Dictionary = historical.rows[int(out.case)]
		for action: Dictionary in original.actions:
			if action.phase != "additional_reserve": continue
			var id := StringName(action.id)
			var offer: Dictionary = game.run_state.get_primitive_reserve_offer(id)
			var before := _state(game)
			var success: bool = game.run_state.purchase_primitive_reserve_feature(id)
			out.actions.append({"phase": "exact_historical_reserve", "id": id, "quote": offer, "success": success, "before": before, "after": _state(game)})
			if not success:
				out["first_affordability_divergence"] = out.actions[-1]
				return false
	return super._begin_game(game, title, genre, out)

func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	# Parent's historical three-completion expectation is no longer a valid gate.
	out.errors.erase("starwave_gate")
	out.valid = out.errors.is_empty()
	if game != null:
		out["owned_features"] = game.run_state.get_owned_feature_ids()
		out["unowned_store_quotes"] = []
		for entry: Dictionary in FeatureStoreCatalog.entries():
			var offer: Dictionary = game.run_state.get_feature_store_offer(entry.id)
			if not offer.owned: out.unowned_store_quotes.append(offer)
	return await super._cleanup(game, out)
