## Reproduce the already observed legal 9.0 route on the current credit source.
extends "res://analysis/feature_store_rebaseline_v1.gd"
func _run() -> void:
	era_policy = "synergy"
	release_band = "early"
	declared_seed = 4417
	specialty_id = &"action"
	store_arm = "existing_sound"
	campaign_sensitivity = false
	route_case = declared_seed
	project_number = 0
	max_games = 4
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	random_inputs.seed = declared_seed
	var out := await _matched_route()
	FileAccess.open("res://design-logs/task32-v1/strong_probe.json", FileAccess.WRITE).store_string(JSON.stringify(out))
	print("Strong native probe ", out.releases.size(), " releases; ", out.stop)
	quit(0 if out.valid else 1)
