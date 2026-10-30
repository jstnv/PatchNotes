"""Bounded isolated runner; exact command receipts, never overwrites outputs."""
from pathlib import Path
import sys,json,subprocess,shutil
H=Path(__file__).resolve().parent; R=H.parents[5]; T=H.parents[1]
P=sys.executable
G='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,o):
    with p.open('x',encoding='utf-8') as f:json.dump(o,f,indent=2)
stage=sys.argv[1]
variant=T/'simulators/publisher-support-renewal-v2'
def bundle(s):return T/f'sims/publisher-renewal-{s}-20261023-v1'
def initial(s,c):return {'checkpoint':read(bundle(s)/'cases'/c/'studio_checkpoint.json')}
def h(n):return dict(design=n,alpha=n,beta=n)
def case(cid,init,target,bound,config):return dict(schema_version='1',case_id=cid,initial=init,max_commands=bound,target_release_count=target,telemetry=True,policy={'config':config})
if stage.endswith('-replay') or stage=='baseline-replay2':
    parent='baseline' if stage=='baseline-replay2' else stage.removesuffix('-replay');cid=sys.argv[2]
    argv=[P,str(R/'tools/simulate.py'),'replay','--bundle',str(bundle(parent)),'--case',cid,'--output',str(bundle(stage)),'--godot',G,'--timeout','360']
else:
    if stage=='prefix2':
        c=read(T/'publisher-commission-r20-prefix-20261022-v2.json');c['policy']['script']=str(T/'publisher_r20_progression_policy_v1.gd')
    elif stage=='commission2':
        c=read(T/'publisher-commission-1112-continuation-20261022-v2.json');c['cases']=[x for x in c['cases'] if x['policy']['config']['commission']]
        c['cases'][0]['initial']=initial('prefix2','sports-1112-two-full-briefs-r20')
        c['policy'].pop('source_identity',None);c['policy']['script']=str(T/'publisher_commission_continuation_policy_v1.gd')
    elif stage=='support':
        c=read(T/'publisher-support-1112-pair-20261022-v1.json')
        commission_case=read(H/'commission2.json')['cases'][0]['case_id']
        for x in c['cases']:x['initial']=initial('commission2',commission_case)
        c['policy'].pop('source_identity',None);c['policy']['script']=str(T/'publisher_support_continuation_policy_v1.gd')
    else:
        policy={'script':str(T/'studies/publisher-overnight-20261022-v1/policy.gd'),'id':'publisher-renewal-visible-schedules','version':'1'}
        if stage=='repeat':
            cases=[case('second-support',initial('support','sports-1112-support'),7,40,dict(schedules={'7':h(1)},deal_game=7,deal_kind='support'))]
        elif stage=='cold':
            cases=[case('second-assessment',initial('repeat','second-support'),8,80,dict(schedules={'8':h(2)}))]
        elif stage=='recovery':
            cases=[case('recovery-commission',initial('cold','second-assessment'),9,100,dict(schedules={'9':dict(design=5,alpha=7,beta=6)},deal_game=9,deal_kind='commission'))]
        elif stage=='third':
            cases=[case('third-support',initial('recovery','recovery-commission'),11,120,dict(schedules={'10':h(2),'11':h(2)},deal_game=10,deal_kind='support'))]
        else:raise ValueError(stage)
        c=dict(schema_version='1',policy=policy,cases=cases)
    write(H/f'{stage}.json',c)
    argv=[P,str(R/'tools/simulate.py'),'run','--variant',str(variant),'--config',str(H/f'{stage}.json'),'--output',str(bundle(stage)),'--godot',G,'--timeout','360']
assert shutil.disk_usage(R).free>20*1024**3
write(H/f'{stage}-command.json',{'argv':argv})
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
write(H/f'{stage}-process.json',{'exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr})
report=read(bundle(stage)/'run-report.json')
print(json.dumps({'stage':stage,'exit':p.returncode,'ok':report.get('ok'),'error':report.get('error')}),flush=True)
if not stage.endswith('-replay') and stage!='baseline-replay2':
    for path in (bundle(stage)/'cases').glob('*/result.json'):
        result=read(path)
        print(json.dumps({'case':path.parent.name,'ok':result.get('ok'),'commands':result.get('commands_executed'),'artifacts':result.get('artifacts')}),flush=True)
raise SystemExit(p.returncode)
