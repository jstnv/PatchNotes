"""Fresh processes consume original, unmodified checkpoint files."""
from pathlib import Path
import json, os, socket, subprocess, hashlib
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[3]
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
PROJECT=BASE/'integrated-v6/project'
OUT=BASE/'fresh-world-v2';OUT.mkdir(exist_ok=False)
records=[]
def execute(label,script,args):
    env=os.environ.copy()
    for key in ('APPDATA','LOCALAPPDATA'):
        p=ROOT/'.codex-godot-temp'/('qv2-fresh-'+label)/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
    command=[GODOT,'--headless','--audio-driver','Dummy','--path',str(PROJECT),'--script',script,'--',*map(str,args)]
    with (OUT/(label+'.log')).open('wb') as log:
        result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    text=(OUT/(label+'.log')).read_text(errors='replace')
    records.append(dict(label=label,command=command,exit=result.returncode,errors=[s for s in text.splitlines() if s.startswith(('ERROR:','SCRIPT ERROR:'))],passes=text.count('PASS:')))
    (OUT/'results.json').write_text(json.dumps(records,indent=2))
    print(label,result.returncode,flush=True)
    return result.returncode==0
for label,source in [('legacy',BASE/'integrated-v6/verify_legacy_world-result.json'),('old-ai7',BASE/'milestones/long-ai-studio7.json'),('old-ai9',BASE/'milestones/long-ai-studio9.json')]:
    output=OUT/(label+'.json')
    if execute(label,'res://scripts/debug/verify_world_restore_file.gd',[source,output]):
        execute(label+'-again','res://scripts/debug/verify_world_restore_file.gd',[output,OUT/(label+'-again.json')])
snapshot=OUT/'traits-snapshot.json'
execute('traits-snapshot',str(ROOT/'patch-notes/design-logs/threads/studio-traits/2026-10-17-foundation-snapshot-v1.gd'),[snapshot])
if snapshot.exists():
    print('snapshot sha256',hashlib.sha256(snapshot.read_bytes()).hexdigest(),flush=True)
raise SystemExit(any(r['exit'] or r['errors'] for r in records))
