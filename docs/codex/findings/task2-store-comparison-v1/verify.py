"""Run focused unchanged native verifiers and the exact historical replay."""
from pathlib import Path
import json
import os
import subprocess

OUT=Path(__file__).resolve().parent
meta=json.loads((OUT/'source-manifest.json').read_text())
project=Path(meta['project'])
godot=Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
cases=[('historical-alpha','analysis/alpha_exit_arrears_route_v1.gd',['--stage=after']),
 ('alpha-recovery','scripts/debug/verify_alpha_exit_arrears.gd',[]),
 ('store-cycle','scripts/debug/verify_feature_store_cycle_purchase.gd',[]),
 ('atomic-redraw','scripts/debug/verify_atomic_selected_redraw.gd',[]),
 ('retention','scripts/debug/verify_candidate_retention.gd',[]),
 ('typed-expenses','scripts/debug/verify_outstanding_expenses.gd',[])]
records=[]
for name,script,args in cases:
    env=os.environ.copy()
    for key in ('APPDATA','LOCALAPPDATA'):
        profile=project.parent/'checks-profile'/name/key
        profile.mkdir(parents=True,exist_ok=True)
        env[key]=str(profile)
    # These unchanged verifiers optionally save their own constructed evidence.
    for folder in ('alpha-exit-arrears-v1','alpha-exit-arrears-v2','task33-v1'):
        (project/'design-logs'/folder).mkdir(parents=True,exist_ok=True)
    command=[str(godot),'--headless','--path',str(project),'--script','res://'+script]
    if args: command+=['--']+args
    result=subprocess.run(command,env=env,capture_output=True,timeout=180)
    output=result.stdout+result.stderr
    (OUT/(name+'.log')).write_bytes(output)
    lines=output.decode(errors='replace').splitlines()
    errors=[s for s in lines if 'SCRIPT ERROR' in s or 'FAIL:' in s or ('ERROR:' in s and 'Failed to read the root certificate store.' not in s)]
    record=dict(name=name,command=command,exit=result.returncode,errors=errors,pass_markers=sum(s.startswith('PASS:') for s in lines))
    records.append(record)
    print(record,flush=True)
    if result.returncode or errors: raise RuntimeError('Focused verifier failed')
historical=json.loads((project/'design-logs/alpha-exit-arrears-v1/route-after.json').read_text())
(OUT/'historical-alpha.json.gz').write_bytes(__import__('gzip').compress(json.dumps(historical).encode(),mtime=0))
(OUT/'verification-index.json').write_text(json.dumps(records,indent=2))
