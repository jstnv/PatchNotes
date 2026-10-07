from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import subprocess,os,json,itertools,sys

ROOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006')
GODOT=Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
after_hire='--after-hire' in sys.argv
OUT=ROOT/('results-after-hire' if after_hire else 'results-optional'); OUT.mkdir(exist_ok=True)
env=dict(os.environ,APPDATA=str(ROOT/'profile'),LOCALAPPDATA=str(ROOT/'profile'))

def run(job):
    band,seed=job; tag=f'route_base_{band}_synergy_{seed}_bundle_1'
    script='employee_after_hire_v1' if after_hire else 'employee_optional_v1'
    args=[str(GODOT),'--headless','--path',str(ROOT/'patch-notes'),'--script',f'res://analysis/{script}.gd','--',f'--band={band}',f'--seed={seed}','--policy=synergy','--reward=bundle','--funding=base','--staff=1',f'--out={OUT}']
    with (OUT/f'{tag}.log').open('w') as log: p=subprocess.run(args,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    d=json.loads((OUT/f'{tag}.json').read_text())
    result=dict(tag=tag,exit=p.returncode,valid=d['valid'],releases=len(d['releases']))
    print(result,flush=True); return result

with ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(run,itertools.product(['early','slow'],[1104,4417])))
(Path(__file__).parent/('after-hire-run-index.json' if after_hire else 'optional-run-index.json')).write_text(json.dumps(results,indent=2))
assert all(r['exit']==0 and r['valid'] for r in results)
