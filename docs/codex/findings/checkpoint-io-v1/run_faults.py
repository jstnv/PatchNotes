"""Fresh-profile, separate-process checkpoint publication/recovery cases."""
from pathlib import Path
import json, os, subprocess, tempfile

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
root=Path(tempfile.mkdtemp(prefix='checkpoint-acceptance-'))
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    p=root/key;p.mkdir();env[key]=str(p)
cases={name:['initial','fault-'+name,'read-100'] for name in ['permission_denied','disk_full']}
records=[]
for case,modes in cases.items():
    for index,mode in enumerate(modes):
        cmd=[GODOT,'--headless','--path',str(REPO/'patch-notes'),'--script','res://scripts/debug/checkpoint_fault_matrix_probe.gd','--',mode,str(root/case)]
        log=HERE/f'{case}-{index}.log'
        with log.open('wb') as f:
            result=subprocess.run(cmd,env=env,cwd=REPO,stdout=f,stderr=subprocess.STDOUT,timeout=45)
        lines=log.read_text(encoding='utf-8',errors='replace').splitlines()
        errors=[s for s in lines if ('SCRIPT ERROR' in s or s.startswith('ERROR:') or 'FAIL:' in s) and 'root certificate store' not in s]
        records.append(dict(case=case,mode=mode,command=cmd,exit=result.returncode,errors=errors,passes=sum(s.startswith('PASS:') for s in lines)))
        (HERE/'fault-results.json').write_text(json.dumps(dict(profile=str(root),test_lease_port=47413,runs=records),indent=2),encoding='utf-8')
        print(case,mode,result.returncode,errors,flush=True)
        if result.returncode or errors: raise SystemExit(1)
