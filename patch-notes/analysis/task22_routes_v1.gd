## Read-only Task22 recapture: inherited native actions, current specialty rosters.
extends "res://analysis/lifespan_verify_routes_v2.gd"
func _run() -> void:
	era_policy = _arg("--policy=", "synergy")
	arm = "newer"
	experiment = "task22"
	route_case = int(_arg("--case=", "0"))
	max_games = 2
	action_limit = 0
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = 240930000 + route_case
	var result := await _current_route(route_case)
	result["ledger_checks"] = ledger_checks
	result["row_checks"] = row_checks
	result["discrepancies"] = discrepancies
	result["captures"] = final_captures
	var path := "res://design-logs/task22-v1/route_%s_%d.json" % [era_policy,route_case]
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(result))
	print("TASK22 releases=",result.releases.size()," discrepancies=",discrepancies.size())
	quit(0 if result.valid and discrepancies.is_empty() and result.releases.size()==2 else 1)
