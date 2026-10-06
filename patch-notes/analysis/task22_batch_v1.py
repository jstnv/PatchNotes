"""Bounded read-only trait recapture. No runtime mutations, isolated Godot profiles."""
import json, hashlib, subprocess
import tutorial_task17_verify_v1 as v
OUT=v.ROOT/'design-logs/task22-v1'; OUT.mkdir(exist_ok=True); (OUT/'.gdignore').touch();v.OUT=OUT
def manifest():
 return {str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for d in ['scripts','scenes','data'] for p in (v.ROOT/d).rglob('*') if p.is_file()}
if __name__=='__main__':
 before=manifest()
 (OUT/'source-before.json').write_text(json.dumps({'head':v.git('rev-parse','HEAD').decode().strip(),'files':before},indent=2),encoding='utf-8')
 (OUT/'initial-status.txt').write_bytes(v.git('status','--short','--branch'));(OUT/'initial-diff.patch').write_bytes(v.git('diff'))
 cases=[('synergy',i) for i in [0,1,3,5,8,15]]+[('ordinary',i) for i in [5,6]]
 (OUT/'predeclared.json').write_text(json.dumps({'cases':cases,'releases':2,'timeout_seconds_per_route':180,'production_seed':'240930100+case*97; +500000 second game','environment_seed':'240930000+case','policy':'Inherited lifespan_verify_routes_v2 visible-choice policy; same actions for each shadow. No extra gameplay arms.','horizon':'Observed two releases; conditional fixed-portfolio 24 calendar months, not free Wait','trials':'Buzz3/5/7 vs old10; matching specialty3/5/7 vs10; small additive packages; Cult25/50/75/100 vs200 with saturated curve and bounded retention; Family300 reference; loan +2points/$10x96 interest-free arrears'},indent=2),encoding='utf-8')
 results=[v.run('import',v.ROOT,['--editor','--import'],180)]
 for test in ['verify_zero_work_release','verify_studio_specialties','verify_predevelopment','verify_game_lifespan_sales','verify_monthly_sales_report','verify_sidestreet_scope_and_year']:
  path=v.ROOT/'scripts/debug'/f'{test}.gd'
  if path.exists(): results.append(v.run(test,v.ROOT,['--script','res://scripts/debug/'+path.name],120))
 for policy,case in cases:
  results.append(v.run(f'route_{policy}_{case}',v.ROOT,['--script','res://analysis/task22_routes_v1.gd','--',f'--policy={policy}',f'--case={case}'],180))
 assert before==manifest(),'Runtime source changed during analysis'
 (OUT/'gate.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
 assert all(r['exit']==0 and not r['errors'] for r in results)
