from pathlib import Path
import sys,json,subprocess,shutil
from paths import bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
PY=sys.executable;G='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
variant=sys.argv[2] if len(sys.argv)>2 else 'sidestreet-commission-p1-v1'
tag=variant.rsplit('-',1)[-1]
mode=sys.argv[1]
def out(stage):return bundle(stage,tag)
def dev(genre,hands):return dict(genre=genre,theme='fantasy',name_prefix='Commission Study',selection='features_first',hands=dict(zip(['design','alpha','beta'],hands)))
def checkpoint(stage,case):return json.loads((out(stage)/'cases'/case/'studio_checkpoint.json').read_text())
def case(name,initial,config,target,budget):return {'schema_version':'1','case_id':name,'initial':initial,'max_commands':budget,'target_release_count':target,'telemetry':True,'policy':{'config':config}}
cases=[]
if mode=='prefix':
    shutil.copyfile(H.parent/'sidestreet-p1-gate-20261023-v1/policy.gd',H/'prefix_policy.gd')
    for genre,seed in [('sports',1112),('action',1108)]:
        label=f'{genre}-{seed}'
        recipe=dict(schema_version=1,studio_id='commission-p1-'+label,studio_name='Commission '+label,specialty=genre,traits=[],seed=str(seed))
        cfg=dict(arm='balanced',label=label,development_first=dev(genre,[3,5,4]),development_later=dev(genre,[2,2,2]))
        cases.append(case(label,dict(recipe=recipe),cfg,4,200))
    script='prefix_policy.gd'
elif mode=='delivery':
    for label,genre,hands,commission,maps in [('long-commission','sports',[5,7,6],True,True),('long-owned','sports',[5,7,6],False,True),('short-commission','action',[2,2,2],True,False),('medium-commission','action',[3,4,3],True,False)]:
        cfg=dict(label=label,development=dev(genre,hands),commission=commission,maps=maps)
        cases.append(case(label,dict(checkpoint=checkpoint('prefix','sports-1112' if genre=='sports' else 'action-1108')),cfg,5,180))
    script='delivery_policy.gd'
elif mode=='continue':
    for label in ['long-commission','long-owned']:
        cfg=dict(label=label,development=dev('sports',[2,2,2]),commission=False,maps=False)
        cases.append(case(label,dict(checkpoint=checkpoint('delivery',label)),cfg,6,100))
    script='delivery_policy.gd'
else:raise ValueError(mode)
config={'schema_version':'1','policy':dict(script=script,id='sidestreet-p1-commission-'+mode,version='1'),'cases':cases}
path=H/f'{mode}-{tag}.json'
with path.open('x',encoding='utf-8') as f:json.dump(config,f,indent=2)
if shutil.disk_usage(R).free<10*1024**3:raise RuntimeError('10GiB free-space floor')
argv=[PY,str(R/'tools/simulate.py'),'run','--variant',str(T/'simulators'/variant),'--config',str(path),'--output',str(out(mode)),'--godot',G,'--timeout','600']
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
with (H/f'{mode}-{tag}.command.json').open('x') as f:json.dump(dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);sys.exit(p.returncode)
