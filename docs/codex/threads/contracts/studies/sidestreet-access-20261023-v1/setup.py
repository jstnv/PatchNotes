from pathlib import Path
import json, hashlib, subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
GENRES=['action','adventure','role_playing','strategy','simulation','puzzle','sports','racing']
SEEDS=[1104,1108,1112]
def write(name,value):
    with (HERE/name).open('x',encoding='utf-8') as f: json.dump(value,f,indent=2)
def configuration(arm,seeds):
    cases=[]
    for genre in GENRES:
        for seed in seeds:
            identity=f'sidestreet-access-{genre}-{seed}'
            dev={'genre':genre,'theme':'fantasy','name_prefix':'Access Study','selection':'features_first','hands':{'design':3,'alpha':5,'beta':4}}
            later={**dev,'hands':{'design':2,'alpha':2,'beta':2}}
            cases.append({'schema_version':'1','case_id':f'{genre}-{seed}-{arm}','initial':{'recipe':{'schema_version':1,'studio_id':identity,'studio_name':identity,'specialty':genre,'traits':[],'seed':str(seed)}},'max_commands':160,'target_release_count':4,'telemetry':True,'policy':{'config':{'arm':arm,'label':f'{genre}-{seed}-{arm}','development_first':dev,'development_later':later}}})
    return {'schema_version':'1','policy':{'script':'policy.gd','id':'sidestreet-access-observation-only','version':'1'},'cases':cases}
for arm in ['balanced','completion','skip']: write(f'{arm}.json',configuration(arm,SEEDS))
write('canonical.json',configuration('skip',[1104]))
write('git-before.json',{key:subprocess.check_output(['git',*args],cwd=ROOT,text=True) for key,args in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--porcelain'],'diff':['diff','--stat']}.items()})
write('canonical-before.json',{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'patch-notes').rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in ('.gd','.json','.tscn','.godot')})
print('Prepared 72 candidate cases plus eight canonical controls; root',ROOT)
