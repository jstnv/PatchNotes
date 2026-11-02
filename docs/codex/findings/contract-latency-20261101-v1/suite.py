from pathlib import Path
import json,subprocess,sys
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
base=Path(__file__).resolve().parent
root=base.parents[3]
names=['verify_checkpoint_codec','verify_checkpoint_rng','verify_checkpoint_store','verify_checkpoint_runtime','verify_studio_checkpoint','verify_contract_extraction','verify_contract_search','verify_contract_definitions','verify_contract_challenge_runtime','verify_background_checkpoint']
rows=[]
for name in names:
    out=base/('suite-'+name)
    command=[sys.executable,str(base/'run.py'),'--script','res://scripts/debug/'+name+'.gd','--output',str(out),'--fixture',str(root/'docs/codex/findings/awards-presentation-20261101-v2/current-world/fixture.json'),'--fence','--timeout','180']
    with (base/(name+'-runner.log')).open('wb') as log:
        subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT)
    result=json.loads((out/'result.json').read_text(encoding='utf-8'))
    rows.append({'name':name,**result})
    print(json.dumps({k:rows[-1][k] for k in ['name','ok','exit','errors','seconds']}),flush=True)
(base/'suite-results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
sys.exit(0 if all(r['ok'] for r in rows) else 1)
