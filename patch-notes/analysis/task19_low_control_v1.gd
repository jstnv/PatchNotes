## Historical Task3 ordinary policy on current source; not human play evidence.
extends "res://analysis/sidestreet_acceptance_stress_v1.gd"
var live_cycles: Array[Dictionary] = []
func _run() -> void:
	var row := await _one("ordinary",0)
	var file := FileAccess.open("res://design-logs/task19-v1/routes_historical_policy.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rows":[row],"failures":0 if row.valid else 1},"  "))
	quit(0 if row.valid else 1)
func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	if title == "Game One": game.run_state.calendar_changed.connect(_capture.bind(game))
	return super._begin_game(game,title,genre,out)
func _capture(game: Control) -> void:
	live_cycles.append(_state(game))
func _contract(game: Control, policy: String, seed_value: int, out: Dictionary, label: String) -> bool:
	if label.begins_with("sidestreet") and not game.run_state.is_sidestreet_offer_available():
		out.actions.append({"phase":"scope_gated_missing_offer","label":label,"state":_state(game)})
		return true
	return await super._contract(game,policy,seed_value,out,label)
func _cleanup(game: Control, out: Dictionary) -> Dictionary:
	out.errors.erase("starwave_gate")
	out.valid=out.errors.is_empty()
	out["live_cycles"]=live_cycles.duplicate(true)
	out["frozen_sales_records"]=[]
	for id: StringName in game.run_state.get_released_game_ids(): out.frozen_sales_records.append(game.run_state.get_released_game_sales(id))
	return await super._cleanup(game,out)
