from pathlib import Path
import json,subprocess,sys,time,hashlib,copy
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
OLD=THREAD/'studies/crown-access-policy-20261025-v1'
VAR=THREAD/'simulators/puzzle-research-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/puzzle-research-20261025-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
PAIRS={'baseline':['8_bit_sound','general_combat'],'music_combat':['music','general_combat'],'sound_sprites':['8_bit_sound','sprites'],'music_sprites':['music','sprites']}
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,o):p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists(),name
    write(HERE/(name+'-command.json'),args);start=time.time()
    with (HERE/(name+'-driver.log')).open('w',encoding='utf-8') as log:r=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start));print(name,r.returncode,flush=True)
    return r.returncode
def case(seed,arm):
    c=copy.deepcopy(load(OLD/'puzzle.json')['cases'][2]);c['case_id']='puzzle-'+seed+'-'+arm
    recipe=c['initial']['recipe'];recipe.update(seed=seed,studio_id='csa-puzzle-'+seed,studio_name='CSA puzzle-'+seed)
    c['study']=dict(pair_id='puzzle-'+seed,arm=arm)
    c['policy']['config'].update(label=c['case_id'],purchases=PAIRS[arm])
    return c
def config(cases):return dict(schema_version='1',policy=dict(script='policy.gd',id='puzzle-research',version='1'),cases=cases)
def setup():
    assert not (HERE/'policy.gd').exists()
    for n,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current']),('worktrees',['git','worktree','list','--porcelain'])]:
        r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/(n+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
    policy=(OLD/'policy.gd').read_text(encoding='utf-8')
    policy=policy.replace('"research":[]','"research":[],"research_cost":0')
    start=policy.index('\t\t\tif state.research.size()<');end=policy.index('\n\t\treturn {"type":&"begin_development"',start)
    policy=policy[:start]+'''\t\t\tif state.research.size()<2:
\t\t\t\tvar desired: String=config.purchases[state.research.size()]
\t\t\t\tfor quote: Dictionary in view.research_quotes:
\t\t\t\t\tif str(quote.feature_id)!=desired:continue
\t\t\t\t\tvar cost: int=int(quote.down_cents)+int(quote.remaining_cents)
\t\t\t\t\tif quote.can_admit and cost==45000 and int(state.research_cost)+cost<=90000 and int(view.cash_cents)-cost>=600000:
\t\t\t\t\t\tstate.research.append(desired);state.research_cost+=cost
\t\t\t\t\t\treturn {"type":&"admit_research","payload":{"quote":quote}}
\t\t\t\tprint("PN_PR_BLOCK "+JSON.stringify({"case":config.label,"desired":desired,"cash":view.cash_cents,"cycle":view.run_cycle}))
\t\t\t\treturn {"type":&"puzzle_research_pair_unavailable"}'''+policy[end:]
    policy=policy.replace('"proxy":proxy,"scope":current.scope','"proxy":proxy,"core":current.core,"scope":current.scope')
    (HERE/'policy.gd').write_text(policy,encoding='utf-8')
    write(HERE/'pin.json',dict(parent_policy_sha256=hashlib.sha256((OLD/'policy.gd').read_bytes()).hexdigest(),policy_sha256=hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest(),plan_sha256=hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest()))
    for seed in ['4417','4521']:write(HERE/('discovery-'+seed+'.json'),config([case(seed,arm) for arm in PAIRS]))
    return execute('create',[sys.executable,'tools/simulator_variant.py','create','--id','puzzle-research-20261025-v1','--owner','contracts','--from-variant',str(THREAD/'simulators/crown-access-policy-20261025-v1'),'--output',str(VAR)])
def run(name,timeout='600'):return execute(name,[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(name+'.json')),'--output',str(RAW/name),'--timeout',timeout,'--godot',GODOT])
def source(name):
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as v
    c=v.sim.source_hashes(ROOT/'patch-notes');p=v.sim.source_hashes(VAR/'project');old=v.sim.source_hashes(THREAD/'simulators/crown-access-policy-20261025-v1/project')
    out=dict(canonical_identity=v.identity(c),candidate_identity=v.identity(p),parent_identity=v.identity(old),canonical_delta=v.delta(old,c),candidate_delta=v.delta(old,p),canonical=c,candidate=p)
    write(HERE/(name+'.json'),out);assert not out['candidate_delta'] and not out['canonical_delta']
    print('Identical canonical/parent/candidate '+out['canonical_identity'],flush=True)
if __name__=='__main__':
    if sys.argv[1]=='setup':setup();source('source-before')
    elif sys.argv[1]=='discover':
        for seed in ['4417','4521']:run('discovery-'+seed)
    elif sys.argv[1]=='source':source('source-after')
