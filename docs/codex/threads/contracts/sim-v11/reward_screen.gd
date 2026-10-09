extends "res://scripts/debug/starwave_timing_v10.gd"
func _run() -> void:
	era_policy="synergy"
	declared_seed=1104
	project_number=3
	random_inputs.seed=declared_seed
	release_band="early"
	store_arm="none"
	neon_policy=false
	max_games=5
	action_limit=160
	era_cap=0
	first_store_cycle=0
	var args:=OS.get_cmdline_user_args()
	var foundation: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var spec: Dictionary=JSON.parse_string(args[1])
	var run:=StudioCheckpoint.new().hydrate(foundation.starwave_checkpoint)
	var side:=run.get_sidestreet_offer_ids()
	var out: Dictionary=await _run_shadow_arm(foundation.starwave_checkpoint,spec,int(args[2]))
	out["sidestreet_eligible_at_foundation"]=run.is_sidestreet_offer_available()
	out["sidestreet_ids"]=side
	FileAccess.open(args[3],FileAccess.WRITE).store_string(JSON.stringify(out))
	print("SW2 ",spec.mode," success=",out.success," errors=",out.errors)
	quit(0 if out.success else 1)
