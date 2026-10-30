from pathlib import Path
import json, subprocess, sys, time, hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
VAR=THREAD/'simulators/balanced-craft-access-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/balanced-craft-access-20261025-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,x): p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8')
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists()
    write(HERE/(name+'-command.json'),args)
    start=time.time()
    r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(name+'-driver.log')).write_text(r.stdout+'\n'+r.stderr,encoding='utf-8')
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start))
    print(name,r.returncode,flush=True)
    return r.returncode
def setup():
    assert not (HERE/'baseline.json').exists()
    fixture=load(VAR/'project/scripts/debug/fixtures/studio_specialties_v3.json')
    genres=sorted(fixture)
    assert len(genres)==8, genres
    cases=[]
    for genre in genres:
        for seed in ['4417','4521']:
            pair=genre+'-'+seed
            for arm in ['visible_order','features_first']:
                cases.append(dict(schema_version='1',case_id=pair+'-'+arm,
                    initial=dict(recipe=dict(schema_version=1,studio_id='bca-'+pair,studio_name='BCA '+pair,specialty=genre,traits=[],seed=seed)),
                    max_commands=160,target_release_count=4,telemetry=True,study=dict(pair_id=pair,arm=arm),
                    policy=dict(config=dict(genre=genre,theme='fantasy',name_prefix='BCA',selection=arm,hands=dict(design=2,alpha=2,beta=2)))))
    write(HERE/'baseline.json',dict(schema_version='1',policy=dict(script='res://scripts/simulation/finite_fixture_policy.gd',id='finite-development-fixture',version='1'),cases=cases))
    for name,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current'])]:
        r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        (HERE/(name+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
    write(HERE/'plan-pin.json',dict(plan_sha256=hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest(),case_count=len(cases),genres=genres))
    print('Configured',len(cases),genres)
if __name__=='__main__':
    action=sys.argv[1]
    if action=='setup': setup()
    elif action=='baseline': execute('baseline',[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/'baseline.json'),'--output',str(RAW/'baseline'),'--timeout','600','--godot',GODOT])
    elif action=='replay':
        case=sys.argv[2]
        execute('replay-'+case,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/'baseline'),'--case',case,'--output',str(RAW/('replay-'+case)),'--timeout','240','--godot',GODOT])
    elif action=='reduce':
        case=sys.argv[2]
        execute('reduce-'+case,[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/'baseline'),'--case',case,'--kind','rejection','--max-commands','1000','--output',str(RAW/('reduce-'+case)),'--timeout','240','--godot',GODOT])
    elif action=='continue':
        case=sys.argv[2]
        result=load(RAW/'baseline/cases'/case/'result.json')
        if execute('prepare-continuation',[sys.executable,'docs/codex/threads/simulation-engine/examples/prepare-continuation.py','--bundle',str(RAW/'baseline'),'--case',case,'--case-id','cold-continue','--target-release-count',str(result['final_release_count']+1),'--max-commands','40','--output',str(HERE/'continuation.json')])==0:
            execute('continuation',[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/'continuation.json'),'--output',str(RAW/'continuation'),'--timeout','240','--godot',GODOT])
