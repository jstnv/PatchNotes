from pathlib import Path
import json, hashlib, subprocess, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
OLD=HERE.parent/'sidestreet-access-20261023-v1'
def write(p,v):
    with p.open('x',encoding='utf-8') as f: json.dump(v,f,indent=2)
policy=(OLD/'policy.gd').read_text(encoding='utf-8')
(HERE/'baseline-policy.gd').write_text(policy,encoding='utf-8')
baseline=json.loads((OLD/'canonical.json').read_text())
baseline['cases']=[x for x in baseline['cases'] if x['case_id'] in ['action-1104-skip','racing-1104-skip']]
baseline['policy']['script']='baseline-policy.gd'
write(HERE/'baseline.json',baseline)
write(HERE/'git-before.json',{k:subprocess.check_output(['git',*v],cwd=ROOT,text=True) for k,v in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--porcelain'],'diff':['diff','--stat']}.items()})
write(HERE/'canonical-before.json',{p.relative_to(ROOT/'patch-notes').as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'patch-notes').rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in ['.gd','.json','.godot','.tscn']})
print('Baseline prepared; canonical source recorded')
