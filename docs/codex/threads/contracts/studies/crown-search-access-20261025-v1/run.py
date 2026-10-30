from pathlib import Path
import json,subprocess,sys,time,hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
VAR=THREAD/'simulators/crown-search-access-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-search-access-20261025-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,o):p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists(),name
    write(HERE/(name+'-command.json'),args)
    start=time.time()
    with (HERE/(name+'-driver.log')).open('w',encoding='utf-8') as log:
        r=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start))
    print(name,r.returncode,flush=True)
    return r.returncode
def setup():
    assert not (HERE/'policy.gd').exists()
    for n,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current'])]:
        r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/(n+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
    prior=ROOT/'docs/codex/findings/qa-employees-20261025-v1/quality_wage_policy.gd'
    policy=prior.read_text(encoding='utf-8')
    policy=policy.replace('"genre":"action"','"genre":config.specialty').replace('"priorities":{0:30,1:20,2:30,3:20}','"priorities":{0:config.ratios[0],1:config.ratios[1],2:config.ratios[2],3:config.ratios[3]}')
    policy=policy.replace('_best_four(cards,current)','_best_four(cards,current,config.ratios)').replace('current: Dictionary) -> Array[int]:','current: Dictionary, ratios: Array) -> Array[int]:').replace('\tvar ratios: Array[float] = [30.0,20.0,30.0,20.0]\n','')
    # Printed observations already expose multi-Core contributions; account for them without hidden runtime access.
    old='''\t\t\t\t\t\t\tfor stat_index in range(4):
\t\t\t\t\t\t\t\tif str(card.primary_stat) == stats[stat_index]: printed[stat_index] += float(card.primary_value)
\t\t\t\t\t\t\t\tif str(card.secondary_stat) == stats[stat_index]: printed[stat_index] += float(card.secondary_value)'''
    new='''\t\t\t\t\t\t\tfor entry in card.get("core_contributions",[{"stat":card.primary_stat,"value":card.primary_value},{"stat":card.secondary_stat,"value":card.secondary_value}]):
\t\t\t\t\t\t\t\tvar stat_index: int = stats.find(str(entry.stat))
\t\t\t\t\t\t\t\tif stat_index >= 0: printed[stat_index] += float(entry.value)'''
    assert old in policy;policy=policy.replace(old,new)
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    write(HERE/'policy-origin.json',dict(path=str(prior),sha256=hashlib.sha256(prior.read_bytes()).hexdigest(),changes=['specialty/priority parameter','multi-Core observations'],plan_sha256=hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest()))
    for genre,ratios in [('action',[30,20,30,20]),('puzzle',[15,10,30,45]),('simulation',[15,15,45,25])]:
        for seed in ['4417','4521']:
            pair=genre+'-'+seed;cases=[]
            for searches in [6,18]:
                arm='cash'+str(searches)
                cases.append(dict(schema_version='1',case_id=pair+'-'+arm,initial=dict(recipe=dict(schema_version=1,studio_id='csa-'+pair,studio_name='CSA '+pair,specialty=genre,traits=[],seed=seed)),max_commands=420,target_release_count=4,telemetry=True,study=dict(pair_id=pair,arm=arm),policy=dict(config=dict(specialty=genre,ratios=ratios,first_hands=2,cash_searches=searches))))
            write(HERE/(pair+'.json'),dict(schema_version='1',policy=dict(script='policy.gd',id='crown-search-quality',version='1'),cases=cases))
    execute('create',[sys.executable,'tools/simulator_variant.py','create','--id','crown-search-access-20261025-v1','--owner','contracts','--output',str(VAR)])
def runpair(pair):return execute(pair,[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(pair+'.json')),'--output',str(RAW/pair),'--timeout','600','--godot',GODOT])
if __name__=='__main__':
    if sys.argv[1]=='setup':setup()
    elif sys.argv[1]=='pair':runpair(sys.argv[2])
    elif sys.argv[1]=='remaining':
        for genre in ['action','puzzle','simulation']:
            for seed in ['4417','4521']:
                pair=genre+'-'+seed
                if not (HERE/(pair+'-command.json')).exists():runpair(pair)
    elif sys.argv[1]=='corrected':
        for genre in ['action','puzzle','simulation']:
            for seed in ['4417','4521']:
                pair=genre+'-'+seed+'-v2'
                if not (HERE/(pair+'-command.json')).exists():runpair(pair)
    elif sys.argv[1]=='replay':
        case=sys.argv[2];pair=case.rsplit('-',1)[0]
        execute('replay-'+case,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/pair),'--case',case,'--output',str(RAW/('replay-'+case)),'--timeout','240','--godot',GODOT])
    elif sys.argv[1]=='reduce':
        case=sys.argv[2];pair=case.rsplit('-',1)[0]
        execute('reduce-'+case,[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/pair),'--case',case,'--kind','rejection','--max-commands','500','--output',str(RAW/('reduce-'+case)),'--timeout','240','--godot',GODOT])
