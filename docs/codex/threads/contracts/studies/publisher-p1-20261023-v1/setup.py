from pathlib import Path
import hashlib, json, subprocess

ROOT = Path(__file__).resolve().parents[6]
HERE = Path(__file__).resolve().parent
def hashes():
    paths = [p for p in (ROOT / 'patch-notes').rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in ('.gd','.json','.tscn','.godot')]
    return {str(p.relative_to(ROOT)).replace('\\','/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
config = {'schema_version':'1','policy':{'script':'res://scripts/simulation/finite_fixture_policy.gd','id':'finite-development-fixture','version':'1'},'cases':[]}
for specialty, seed in [('action','4417'),('sports','1112')]:
    config['cases'].append({'schema_version':'1','case_id':f'{specialty}-{seed}', 'initial':{'recipe':{'schema_version':1,'studio_id':f'p1-{specialty}-{seed}','studio_name':'P1 Structural Control','specialty':specialty,'traits':[],'seed':seed}}, 'max_commands':100,'target_release_count':2,'policy':{'config':{'genre':specialty,'theme':'fantasy','name_prefix':'P1 Control','selection':'features_first','hands':{'design':2,'alpha':2,'beta':2}}}})
for name,data in [('cases.json',config),('canonical-before.json',hashes()),('git-before.json',{key:subprocess.check_output(['git',*args],cwd=ROOT,text=True) for key,args in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--porcelain'],'diff':['diff','--stat']}.items()})]:
    path=HERE/name
    with path.open('x',encoding='utf-8') as out: json.dump(data,out,indent=2)
print(ROOT)
print('Recorded two fixed cases and canonical hashes')
