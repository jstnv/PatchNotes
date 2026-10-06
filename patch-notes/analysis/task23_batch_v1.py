import json,hashlib
import tutorial_task17_verify_v1 as v
OUT=v.ROOT/'design-logs/task23-v1';OUT.mkdir(exist_ok=True);(OUT/'.gdignore').touch();v.OUT=OUT
def manifest():
 return {str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for d in ['scripts','scenes','data'] for p in (v.ROOT/d).rglob('*') if p.is_file()}
if __name__=='__main__':
 (OUT/'source-before.json').write_text(json.dumps({'head':v.git('rev-parse','HEAD').decode().strip(),'files':manifest()},indent=2),encoding='utf-8')
 (OUT/'initial-status.txt').write_bytes(v.git('status','--short','--branch'));(OUT/'initial-diff.patch').write_bytes(v.git('diff'))
 (OUT/'predeclared.json').write_text(json.dumps({'native_cases':['crown synergy case0','neon synergy case0, marketing fromG2Beta hand7; up to8 extra visibleMarketing hands to125Awareness'],'seed':240930100,'environment_seed':240930000,'games':5,'action_limit':300,'timeout_seconds':180,'shadow_contract_seeds':[200929000+i for i in range(20)],'policies':['ordinary','synergy'],'timing':['first eligible release','after fourth release'],'formula_rescore':'all exact960 historical Task20 hands, unchanged','bound':'native final action; conditional future ledger through G5ageMonth12; no freeWait, no runtime proposed offer'}),encoding='utf-8')
 results=[]
 for neon in [0,1]:results.append(v.run('route_'+('neon' if neon else 'crown'),v.ROOT,['--script','res://analysis/task23_routes_v1.gd','--',f'--neon={neon}'],180))
 (OUT/'route-gate.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
 assert all(x['exit']==0 and not x['errors'] for x in results)
