"""Reuse the pre-existing native Task32 route with current typed capture hooks."""
from prepare import HERE, PROJECT, SOURCE
import shutil

body = (SOURCE/'analysis/task32_routes_v1.gd').read_text(encoding='utf-8')
body = body[body.index('func _matched_route()'):]
body = body.replace('func _matched_route()', 'func _cohort_route()')
start = body.index('\tmenu.get_node("CenterContainer/MenuLayout/StartGame")')
end = body.index('\tvar run: RunState = game.run_state',start)
setup=(PROJECT/'analysis/feature_store_rebaseline_v1.gd').read_text(encoding='utf-8')
setup=setup[setup.index('\tif startup_mode == "legacy":'):setup.index('\tvar run: RunState = game.run_state')]
body=body[:start]+setup+body[end:]
body=body.replace('out["initial"] = _state(game)','out["creation"] = run.get_studio_creation_snapshot()\n\tout["initial"] = _state(game)')
header='''## Analysis-only current native route, inherited typed-state checkpoints.
extends "res://analysis/task34_capture_v3.gd"
var contract_arm := "available"
var alignment := 0
var neon_policy := false

func _run() -> void:
\tstartup_mode = _arg("--startup=", "legacy")
\tdestination = _arg("--out=", "")
\tera_policy = _arg("--policy=", "ordinary")
\trelease_band = "early"
\tdeclared_seed = 1104
\tspecialty_id = &"action"
\tstore_arm = "none"
\tcontract_arm = _arg("--contracts=", "available")
\talignment = int(_arg("--alignment=", "0"))
\tneon_policy = _arg("--neon=", "0") == "1"
\troute_case = declared_seed
\tproject_number = 0
\tmax_games = 5
\taction_limit = 120
\tera_cap = 0
\tfirst_store_cycle = 0
\trandom_inputs.seed = declared_seed
\tvar out := await _cohort_route()
\tout["parity_checks"] = parity_checks
\tFileAccess.open(destination + ".json", FileAccess.WRITE).store_string(JSON.stringify(out))
\tFileAccess.open(destination + ".bin", FileAccess.WRITE).store_var(typed_checkpoints)
\tvar restored: Array = FileAccess.open(destination + ".bin", FileAccess.READ).get_var()
\tassert(restored == typed_checkpoints)
\tprint("TASK34_COHORT valid=", out.valid, " releases=", out.releases.size(), " typed_checks=", parity_checks)
\tquit(0 if out.valid else 1)

'''
(HERE/'cohort.gd').write_text(header+body,encoding='utf-8')
shutil.copy2(HERE/'capture.gd',PROJECT/'analysis/task34_capture_v3.gd')
shutil.copy2(HERE/'cohort.gd',PROJECT/'analysis/task34_cohort_v3.gd')
print('Installed cohort and typed capture harnesses; gameplay source unchanged.')
