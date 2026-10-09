extends "res://scripts/debug/starwave_timing_v10.gd"

func _run() -> void:
	era_policy = "synergy"
	declared_seed = int(_arg("--seed=","1104"))
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = false
	max_games = 5
	action_limit = 160
	era_cap = 0
	first_store_cycle = 0
	var out := {"seed":declared_seed,"foundation":{},"starwave_chain":{},"starwave_checkpoint":{},"errors":[]}
	var prepared: Dictionary = await _prepare_starwave(out)
	out["valid"] = not prepared.is_empty()
	if out.valid:
		var run := StudioCheckpoint.new().hydrate(prepared.checkpoint)
		out["frozen_eligible"] = run._primitive_contract_eligible_ids()
		out["contract_rng"] = str(run.random_streams.stream(&"contract_deal").state)
		out["has_active"] = run.get_active_contract() != null
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("SW1 FOUNDATION ",declared_seed," valid=",out.valid)
	quit(0)
