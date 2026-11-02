from pathlib import Path
import json,subprocess,sys
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
base=Path(__file__).resolve().parent
root=base.parents[3]
first=root/'docs/codex/findings/awards-presentation-20261101-v2/current-world/fixture.json.first-year.json'
late=first.with_name('fixture.json')
preceding=base/'preceding-pair.json'
checks=[(n,'res://scripts/debug/'+n+'.gd',late) for n in ['verify_checkpoint_codec','verify_checkpoint_store','verify_checkpoint_runtime','verify_studio_checkpoint','verify_background_checkpoint']]
checks += [(n,str(base/(n+'.gd')),f) for n,f in [('search_guard',first),('codec_short_circuit',first),('decode_reuse',preceding),('compatibility',preceding),('coalescing',first)]]
rows=[]
for name,script,fixture in checks:
    out=base/('final-'+name)
    command=[sys.executable,str(base/'run.py'),'--script',script,'--output',str(out),'--fixture',str(fixture),'--fence','--timeout','180']
    with (base/(name+'-final-runner.log')).open('wb') as log:
        subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT)
    result=json.loads((out/'result.json').read_text(encoding='utf-8'))
    rows.append({'name':name,**result})
    print(json.dumps({k:rows[-1][k] for k in ['name','ok','exit','errors','seconds']}),flush=True)
(base/'final-acceptance-results.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
sys.exit(0 if all(r['ok'] for r in rows) else 1)
