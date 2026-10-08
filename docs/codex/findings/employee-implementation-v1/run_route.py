from pathlib import Path
import gzip,json,shutil
import run_checks as v
v.PROJECT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\employee-route-20261007\patch-notes')
v.run('route-import',['--editor','--import','--quit'])
v.run('route',['--script','res://analysis/employee_native_route.gd','--','--policy=ordinary','--band=early','--seed=1104','--specialty=action','--contracts=available','--alignment=0','--neon=0'],600)
raw=v.PROJECT/'design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json'
with raw.open('rb') as source,gzip.open(v.HERE/'route.json.gz','wb',compresslevel=9) as target:shutil.copyfileobj(source,target)
d=json.loads(raw.read_text(encoding='utf-8'))
print('valid',d['valid'],'releases',[(r['cycle'],r['final_review']) for r in d['releases']],'employees',d['final']['employees'],'cash',d['final']['cash_cents'])
