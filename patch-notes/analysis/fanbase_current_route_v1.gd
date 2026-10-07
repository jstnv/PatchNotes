## Legal two-release production route with the playable fan ledger included
## in each captured state. No forced Review, cards, money or free wait.
extends "res://analysis/task30_debt_routes_v1.gd"


func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project, run)
	state["fans"] = run.get_fans()
	state["fan_history"] = run.get_fanbase_history()
	return state
