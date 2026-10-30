from pathlib import Path
import json,subprocess,sys,time,hashlib,copy
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
OLD=THREAD/'studies/crown-search-access-20261025-v1'
VAR=THREAD/'simulators/crown-access-policy-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-access-policy-20261025-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,o):p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists(),name
    write(HERE/(name+'-command.json'),args);start=time.time()
    with (HERE/(name+'-driver.log')).open('w',encoding='utf-8') as log:r=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start));print(name,r.returncode,flush=True)
    return r.returncode
def setup():
    assert not (HERE/'policy.gd').exists()
    for n,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current']),('worktrees',['git','worktree','list','--porcelain'])]:
        r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/(n+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
    policy=(OLD/'policy-v2.gd').read_text(encoding='utf-8')
    policy=policy.replace('"research":[]','"research":[],"search_bug_hands":{}')
    policy=policy.replace('state.research.size()<4','state.research.size()<(2 if config.arm=="reserve" else 4)')
    policy=policy.replace('str(quote.feature_id)==id and quote.can_admit:', 'str(quote.feature_id)==id and quote.can_admit and (config.arm!="reserve" or int(view.cash_cents)-int(quote.down_cents)-int(quote.remaining_cents)>=600000):')
    needle='\tif int(state.hands.get(key,0))>=target:return _development(view,&"request_exit")'
    repl='''\tif config.arm!="control" and not view.releases.is_empty():
\t\tvar count: int=int(state.hands.get(key,0))
\t\tvar proxy: float=quality_proxy(current,config.specialty)
\t\tvar reason: String=""
\t\tif count>=1 and int(view.cash_cents)<=200000:reason="cash_reserve"
\t\telif current.phase=="design":
\t\t\tif count>=6:reason="design_cap"
\t\t\telif count>=3 and int(current.scope)>=int(current.required_scope) and proxy>=6.0:reason="design_quality"
\t\telif current.phase=="alpha":
\t\t\tif count>=10:reason="alpha_cap"
\t\t\telif count>=2 and int(current.scope)>=int(current.required_scope) and proxy>=8.5:reason="alpha_quality"
\t\telse:
\t\t\tif count>=6:reason="beta_cap"
\t\t\telif count>=3 and int(current.known_bugs)==0 and int(state.search_bug_hands.get(key,0))>=1:reason="known_clear_after_search"
\t\tif not reason.is_empty():
\t\t\tprint("PN_CAP_EXIT "+JSON.stringify({"case":config.label,"release_count":view.releases.size(),"phase":current.phase,"hands":count,"reason":reason,"proxy":proxy,"scope":current.scope,"known_bugs":current.known_bugs,"cash":view.cash_cents,"cycle":view.run_cycle}))
\t\t\treturn _development(view,&"request_exit")
\telif int(state.hands.get(key,0))>=target:return _development(view,&"request_exit")'''
    assert needle in policy;policy=policy.replace(needle,repl)
    needle='\tvar indices:=_best_four(cards,current,config.ratios)'
    policy=policy.replace(needle,needle+'\n\tif current.phase=="beta":\n\t\tfor i in indices:\n\t\t\tif cards[i].definition=="search_for_bugs":state.search_bug_hands[key]=int(state.search_bug_hands.get(key,0))+1')
    policy+='''
static func quality_proxy(current: Dictionary,specialty: String) -> float:
\tvar standards: Array={"action":[40,26,40,26],"puzzle":[20,13,40,59],"simulation":[20,20,59,33]}[specialty]
\tvar ratios: Array[float]=[]
\tvar mean: float=0.0
\tfor i in range(4):
\t\tvar value: float=clampf(float(current.core.get(i,0))/float(standards[i]),0.0,1.25)
\t\tratios.append(value);mean+=value/4.0
\tvar variance: float=0.0
\tfor value in ratios:variance+=pow(value-mean,2)/4.0
\treturn clampf((mean-0.5*sqrt(variance))*8.0,0.0,10.0)
'''
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    write(HERE/'pin.json',dict(parent_policy_sha256=hashlib.sha256((OLD/'policy-v2.gd').read_bytes()).hexdigest(),policy_sha256=hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest(),plan_sha256=hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest()))
    for genre in ['action','puzzle','simulation']:
        cases=[]
        for seed in ['4417','4521']:
            base=load(OLD/(genre+'-'+seed+'-v2.json'))['cases'][0]
            for arm in ['control','exit','reserve']:
                c=copy.deepcopy(base);c['case_id']=genre+'-'+seed+'-'+arm;c['study']['arm']=arm;c['policy']['config'].update(arm=arm,label=c['case_id']);cases.append(c)
        write(HERE/(genre+'.json'),dict(schema_version='1',policy=dict(script='policy.gd',id='crown-access-policy',version='1'),cases=cases))
    return execute('create',[sys.executable,'tools/simulator_variant.py','create','--id','crown-access-policy-20261025-v1','--owner','contracts','--from-variant',str(THREAD/'simulators/crown-search-access-20261025-v1'),'--output',str(VAR)])
def run(name,timeout='600'):return execute(name,[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(name+'.json')),'--output',str(RAW/name),'--timeout',timeout,'--godot',GODOT])
if __name__=='__main__':
    if sys.argv[1]=='setup':setup()
    elif sys.argv[1]=='run':
        for genre in ['action','puzzle','simulation']:run(genre)
