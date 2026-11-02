from pathlib import Path
import json,subprocess,sys
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
base=Path(__file__).resolve().parent;root=base.parents[3]
late=root/'docs/codex/findings/awards-presentation-20261101-v2/current-world/fixture.json'
names=['verify_finance_plan_proof','verify_finance_observation','verify_bank_loan','verify_bank_finance','verify_bank_integration','verify_studio_fanbase','verify_fanbase_incremental','verify_fanbase_checkpoint','verify_award_receipts','verify_annual_awards_legacy_cutoff','verify_annual_awards_world','verify_checkpoint_codec','verify_checkpoint_store','verify_checkpoint_runtime','verify_background_checkpoint','verify_campaign_latency','verify_campaign_session','verify_engine_feature_workflow','verify_engine_skill_world_continue']
cases=[(n,'res://scripts/debug/'+n+'.gd',late) for n in names]
cases += [(n,str(base/(n+'.gd')),base/'preceding-pair.json') for n in ['fanbase_replay','finance_order','cache_boundaries']]
cases += [('old_pair',str(root/'docs/codex/findings/contract-latency-20261101-v1/compatibility.gd'),base/'preceding-pair.json'),('coalescing',str(root/'docs/codex/findings/contract-latency-20261101-v1/coalescing.gd'),late)]
rows=[]
for name,script,fixture in cases:
    out=base/('suite-'+name)
    command=[sys.executable,str(base/'run.py'),'--script',script,'--output',str(out),'--fixture',str(fixture),'--fence','--timeout','180']
    with (base/(name+'-runner.log')).open('wb') as log:subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT)
    result=json.loads((out/'result.json').read_text(encoding='utf-8'));rows.append({'name':name,**result})
    print(json.dumps({k:rows[-1][k] for k in ['name','ok','exit','errors','seconds']}),flush=True)
    (base/'suite-results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8',newline='\n')
sys.exit(0 if all(r['ok'] for r in rows) else 1)
