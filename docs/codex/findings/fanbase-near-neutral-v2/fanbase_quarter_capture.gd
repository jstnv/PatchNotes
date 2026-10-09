extends "res://analysis/task32_routes_v1.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project, run)
	state["fans"] = run.get_fans()
	state["fan_history"] = run.get_fanbase_history()
	state["fan_snapshot"] = run.get_fanbase_snapshot()
	return state
