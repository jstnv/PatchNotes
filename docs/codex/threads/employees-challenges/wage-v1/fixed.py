from pathlib import Path
import json,gzip,os,subprocess,tempfile
from run import HERE,ROOT,PROJECT,GODOT
inputs=[]
for p in sorted(HERE.glob('*_ordinary_*_base_1000.json.gz')):
 d=json.loads(gzip.decompress(p.read_bytes()));inputs.append(dict(name=p.name[:-8],finance=d['final']['finance']))
ip=ROOT/'fixed-input.json';ip.write_text(json.dumps(inputs));(PROJECT/'analysis/wage_fixed.gd').write_bytes((HERE/'fixed.gd').read_bytes())
results=[]
for wage in [1000,2500,5000,7500]:
 env=os.environ.copy();profile=Path(tempfile.mkdtemp(prefix='fixed-',dir=ROOT))
 for key in ['APPDATA','LOCALAPPDATA']:
  q=profile/key;q.mkdir();env[key]=str(q)
 op=ROOT/f'fixed-{wage}.json';env.update(WAGE_CENTS=str(wage),FIXED_INPUT=str(ip),FIXED_OUTPUT=str(op))
 cmd=[GODOT,'--headless','--path',str(PROJECT),'--script','res://analysis/wage_fixed.gd']
 r=subprocess.run(cmd,env=env,capture_output=True,timeout=120);(HERE/f'fixed-{wage}.log').write_bytes(r.stdout+r.stderr)
 assert r.returncode==0,(r.stdout+r.stderr).decode(errors='replace')
 data=json.loads(op.read_text());assert all(x['valid'] for x in data)
 if wage==1000:
  for x,s in zip(data,inputs):assert x['finance']==s['finance'] and not x['stop'],x['case']
 results.extend(data)
(HERE/'fixed.json.gz').write_bytes(gzip.compress(json.dumps(results).encode()))
print('PASS',len(results),'native fixed-journal sensitivities; baseline exact reconstruction',len(inputs))
