from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import os, subprocess, json, itertools, hashlib

HERE = Path(__file__).resolve().parent
ROOT = Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006')
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
(ROOT/'results').mkdir(exist_ok=True)
jobs = set()
for funding, band, policy, seed in itertools.product(['base','trait'], ['early','middle','slow','stress'], ['ordinary','synergy'], [1104,4417]):
    jobs.add((funding,band,policy,seed,'none',0))
for band, policy, seed, reward in itertools.product(['early','slow'], ['ordinary','synergy'], [1104,4417], ['paid','standalone','bundle','curated']):
    jobs.add(('base',band,policy,seed,reward,1))
for band, reward in itertools.product(['early','slow'], ['paid','standalone','bundle','curated']):
    jobs.add(('base',band,'synergy',1104,reward,2))
for band, seed in itertools.product(['early','slow'], [1104,4417]):
    jobs.add(('trait',band,'synergy',seed,'bundle',1))
# Pin input grid and hashes before launching.
manifest = {'source_commit':'553d1a46f33d59641efa4c2e4ff141f958c1230d','jobs':sorted(jobs),
            'archive_sha256':hashlib.sha256((ROOT/'source.zip').read_bytes()).hexdigest(),
            'driver_sha256':hashlib.sha256((HERE/'driver.gd').read_bytes()).hexdigest()}
(HERE/'manifest.json').write_text(json.dumps(manifest,indent=2))

def run(job):
    funding,band,policy,seed,reward,staff = job
    tag = f'route_{funding}_{band}_{policy}_{seed}_{reward}_{staff}'
    env = dict(os.environ,APPDATA=str(ROOT/'profile'),LOCALAPPDATA=str(ROOT/'profile'))
    args = [str(GODOT),'--headless','--path',str(ROOT/'patch-notes'),'--script','res://analysis/employee_comparison_v1.gd','--',
            f'--funding={funding}',f'--band={band}',f'--policy={policy}',f'--seed={seed}',f'--reward={reward}',f'--staff={staff}',f'--out={ROOT / "results"}']
    with (ROOT/'results'/f'{tag}.log').open('w') as log:
        process = subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,env=env,timeout=120)
    path = ROOT/'results'/f'{tag}.json'
    data = json.loads(path.read_text()) if path.exists() else {}
    result = {'tag':tag,'exit':process.returncode,'valid':data.get('valid'), 'releases':len(data.get('releases',[])),
              'stop':data.get('stop'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None}
    print(json.dumps(result),flush=True)
    return result

with ThreadPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(run,sorted(jobs)))
(HERE/'run-index.json').write_text(json.dumps(results,indent=2))
raise SystemExit(0 if all(r['exit']==0 and r['valid'] for r in results) else 1)
