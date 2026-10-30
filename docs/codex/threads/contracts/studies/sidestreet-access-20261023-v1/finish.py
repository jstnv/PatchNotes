"""Bounded completion of the unchanged predeclared screen; retains all attempts."""
from pathlib import Path
import json, sys, subprocess, time, datetime
HERE=Path(__file__).resolve().parent
THREAD=HERE.parents[1]
ROOT=HERE.parents[5]
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
VARIANT=THREAD/'simulators/sidestreet-access-v1'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,value): p.write_text(json.dumps(value,indent=2),encoding='utf-8')
# Explicit paths keep the first failed setup bundles separate from gameplay.
coverage={a:[str(THREAD/'sims'/f"sidestreet-access-{a}-20261023-{'v1' if a=='skip' else 'v2'}")] for a in ['balanced','completion','skip']}
deadline=time.monotonic()+1500
while True:
    status={a:read(Path(paths[0])/'run-report.json') for a,paths in coverage.items()}
    if all(r.get('ok') or r.get('error') for r in status.values()): break
    if time.monotonic()>deadline: raise RuntimeError('Original batches did not close within1500s observer allowance')
    time.sleep(10)
print('Original batches closed', {a:r.get('error','PASS') for a,r in status.items()},flush=True)
jobs=[]
def run(argv,label):
    command={'argv':argv,'cwd':str(ROOT),'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    print('Starting',label,flush=True)
    completed=subprocess.run(argv,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=1200)
    command['exit']=completed.returncode
    (HERE/(label+'.log')).write_bytes(completed.stdout)
    write(HERE/(label+'.command.json'),command)
    print('Finished',label,'exit',completed.returncode,flush=True)
    return completed.returncode
for arm,paths in coverage.items():
    original=read(HERE/(arm+'.json'))
    complete={p.parent.name for folder in paths for p in (Path(folder)/'cases').glob('*/result.json')}
    missing=[case for case in original['cases'] if case['case_id'] not in complete]
    for start in range(0,len(missing),8):
        if len(jobs)>=4: raise RuntimeError('Recovery invocation limit reached; keep remaining coverage incomplete')
        chunk=missing[start:start+8]; number=len(jobs)+1
        config={**original,'cases':chunk}; path=HERE/f'recovery-{number}.json'
        if path.exists(): raise RuntimeError('Recovery config already exists')
        write(path,config)
        output=THREAD/'sims'/f'sidestreet-access-recovery-{number}-20261023-v1'
        argv=[sys.executable,str(ROOT/'tools/simulate.py'),'run','--variant',str(VARIANT),'--config',str(path),'--output',str(output),'--godot',GODOT,'--timeout','600']
        jobs.append({'arm':arm,'cases':[c['case_id'] for c in chunk],'output':str(output)})
        write(HERE/'recovery-jobs.json',jobs)
        code=run(argv,f'recovery-{number}')
        paths.append(str(output)); write(HERE/'coverage.json',coverage)
        if code and len(list((output/'cases').glob('*/result.json')))!=len(chunk): raise RuntimeError('Recovery incomplete; bounded stop')
write(HERE/'coverage.json',coverage)
code=run([sys.executable,str(HERE/'analyze.py')],'analysis')
if code: raise RuntimeError('Analysis failed')
analysis=read(HERE/'analysis.json')
print(json.dumps(analysis['summaries']),flush=True)
if analysis['failures']: raise RuntimeError('Analysis checks need inspection before replay')
replay_results=[]
for index,item in enumerate(analysis['replays'],1):
    output=THREAD/'sims'/f'sidestreet-access-replay-{index}-20261023-v1'
    argv=[sys.executable,str(ROOT/'tools/simulate.py'),'replay','--bundle',item['bundle'],'--case',item['case'],'--output',str(output),'--godot',GODOT,'--timeout','600']
    code=run(argv,f'replay-{index}'); replay_results.append({**item,'output':str(output),'exit':code})
    write(HERE/'replay-results.json',replay_results)
    if code: raise RuntimeError('Replay failure retained; no replacement case')
print('Fixed screen and representative replays complete',flush=True)
