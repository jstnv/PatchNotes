"""Predeclared rent-era native Contract controls; no gameplay edits."""
import concurrent.futures, hashlib, json, sys, time
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task32-v1';v.OUT.mkdir(exist_ok=True);(v.OUT/'.gdignore').touch()
jobs=[(b,p,s,c,a,0) for b in ['early','slow'] for p in ['ordinary','synergy']
      for s in [1104,4417] for c in ['none','available'] for a in [0,1]]
jobs += [('early','synergy',s,'available',a,1) for s in [1104,4417] for a in [0,1]]
if '--pilot' in sys.argv:jobs=[('early','synergy',1104,'available',1,1)]
source={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for d in ['scripts','scenes','data'] for p in (v.ROOT/d).rglob('*') if p.is_file()}
(v.OUT/'source-before.json').write_text(json.dumps({'head':v.git('rev-parse','HEAD').decode().strip(),'files':source},indent=2))
plan={'jobs':jobs,'native_horizon':'5 releases or first legal block; <=120 productive actions',
      'first_budget':'12 or18, plus1 actual changed Design priority for alternate calendar alignment',
      'later_budget':'18; no new Store purchases; Action automatic roster',
      'policy':'Reuse current visible ordinary/synergy choices and Task29 seeds. Available arm takes Ironclad afterG1 and eligible SideStreet afterG1–4; none takes no Contract.',
      'neon_sensitivity':'Four separate routes: on G2 after2 QA hands commit QA25/Marketing50/Insider25, use visible Marketing policy for remaining4 hands; adds1 actual cycle.',
      'modeled_contracts':'At true Crown/Neon unlock and afterG4 if reachable;20 draw seeds200929000..019; ordinary/synergy; retained3 and4replacement;2 or3 cycles; targetsCrown9/10,Neon10/11;caps192000/12 and156000/20; no runtime offer.',
      'time_limit_seconds':1200,'per_route_limit_seconds':180,'workers':2,'human_evidence':False}
(v.OUT/'predeclaration.json').write_text(json.dumps(plan,indent=2))
start=time.monotonic()
def run(j):
    if time.monotonic()-start>1200:return {'job':j,'skipped':'wall limit'}
    b,p,s,c,a,n=j
    return v.run('route_'+'_'.join(map(str,j)),v.ROOT,['--script','res://analysis/task32_routes_v1.gd','--',f'--band={b}',f'--policy={p}',f'--seed={s}',f'--contracts={c}',f'--alignment={a}',f'--neon={n}'],180)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool: results=list(pool.map(run,jobs))
changed=[p for p,h in source.items() if hashlib.sha256((v.ROOT/p).read_bytes()).hexdigest()!=h]
(v.OUT/('pilot-commands.json' if '--pilot' in sys.argv else 'commands.json')).write_text(json.dumps({'results':results,'changed':changed,'seconds':time.monotonic()-start},indent=2))
print('Task32 native',len(results),'changed',changed)
raise SystemExit(0 if not changed and all(r.get('exit')==0 and not r.get('errors') for r in results) else 1)
