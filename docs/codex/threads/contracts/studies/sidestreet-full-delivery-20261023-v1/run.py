from pathlib import Path
import sys,json,subprocess,shutil
H=Path(__file__).resolve().parent; R=H.parents[5]; T=H.parents[1]
mode=sys.argv[1]
V=T/'simulators/sidestreet-commission-p1-v3'
G='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def output(stage):return T/f'sims/sidestreet-full-delivery-{stage}-20261023-v1'
def checkpoint(stage,case):return json.loads((output(stage)/'cases'/case/'studio_checkpoint.json').read_text())
def case(name,initial,research,commission,target,budget):
    return dict(schema_version='1',case_id=name,initial=dict(checkpoint=initial),max_commands=budget,target_release_count=target,telemetry=True,policy=dict(config=dict(label=name,research=research,commission=commission,development=dict(genre='sports',theme='fantasy',name_prefix='Scope Gate',selection='features_first',hands=dict(design=5,alpha=7,beta=6)))))
if mode=='first':
    initial=json.loads((T/'sims/sidestreet-commission-p1-prefix-20261023-v3/cases/sports-1112/studio_checkpoint.json').read_text())
    cases=[case('maps-control',initial,['maps'],True,5,180),case('portfolio-commission',initial,['maps','sprites','general_combat'],True,5,180),case('portfolio-owned',initial,['maps','sprites','general_combat'],False,5,180)]
elif mode=='second':cases=[case('second-commission',checkpoint('first','portfolio-commission'),[],True,6,180)]
elif mode=='caps':cases=[case('repeat-to-cap',checkpoint('second','second-commission'),[],True,11,400)]
elif mode=='recovery':cases=[case('investment-cap',checkpoint('caps','repeat-to-cap'),[],True,12,180)]
elif mode=='readiness':
    cases=[case('investment-cap-readiness',checkpoint('recovery','investment-cap'),[],True,13,180)]
    cases[0]['policy']['config']['development']['hands']=dict(design=10,alpha=10,beta=10)
else:raise ValueError(mode)
config=dict(schema_version='1',policy=dict(script='policy.gd',id='sidestreet-full-delivery',version='1'),cases=cases)
path=H/f'{mode}.json'
with path.open('x',encoding='utf-8') as f:json.dump(config,f,indent=2)
assert shutil.disk_usage(R).free>10*1024**3,'10GiB floor'
argv=[sys.executable,str(R/'tools/simulate.py'),'run','--variant',str(V),'--config',str(path),'--output',str(output(mode)),'--godot',G,'--timeout','600']
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
with (H/f'{mode}.command.json').open('x',encoding='utf-8') as f:json.dump(dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr),f,indent=2)
print(p.stdout);print(p.stderr);raise SystemExit(p.returncode)
