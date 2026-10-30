from pathlib import Path
import json,subprocess,sys,time,hashlib,copy,shutil
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/early-brief-affordability-20261025-v1')
VAR=THREAD/'simulators/early-brief-affordability-20261025-v1'
PARENT=THREAD/'simulators/crown-search-brief-20261025-v1'
BRIEF=THREAD/'studies/crown-search-brief-20261025-v1'
ACCESS=THREAD/'studies/crown-access-policy-20261025-v1'
PUZZLE=THREAD/'studies/puzzle-research-20261025-v1'
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
GROUPS=['puzzle-a','puzzle-b','others']
def prefix_output(group):return RAW/('prefix-puzzle-a-retry1' if group=='puzzle-a' else 'prefix-'+group)
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,o):p.write_text(json.dumps(o,indent=2)+'\n',encoding='utf-8')
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists(),name
    write(HERE/(name+'-command.json'),args);start=time.time()
    with (HERE/(name+'-driver.log')).open('w',encoding='utf-8') as log:r=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start));print(name,r.returncode,flush=True);return r.returncode
def source(name):
    sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as v
    canonical=v.sim.source_hashes(ROOT/'patch-notes');candidate=v.sim.source_hashes(VAR/'project');parent=v.sim.source_hashes(PARENT/'project');base=load(PARENT/'base-manifest.json')
    out=dict(canonical_identity=v.identity(canonical),candidate_identity=v.identity(candidate),parent_identity=v.identity(parent),canonical_delta_from_base=v.delta(base,canonical),candidate_delta_from_parent=v.delta(parent,candidate),canonical=canonical,candidate=candidate,parent=parent)
    write(HERE/(name+'.json'),out)
    print(json.dumps({k:val for k,val in out.items() if k not in ['canonical','candidate','parent']}),flush=True)
def setup():
    for n,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current']),('worktrees',['git','worktree','list','--porcelain'])]:
        r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');(HERE/(n+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8')
    assert execute('create',[sys.executable,'tools/simulator_variant.py','create','--id','early-brief-affordability-20261025-v1','--owner','contracts','--from-variant',str(PARENT),'--output',str(VAR)])==0
    debug=VAR/'project/scripts/debug'
    shutil.copyfile(ACCESS/'policy.gd',debug/'eca_access.gd');shutil.copyfile(PUZZLE/'policy.gd',debug/'eca_puzzle.gd')
    (debug/'eca_router.gd').write_text('''extends RefCounted
const Access=preload("res://scripts/debug/eca_access.gd")
const Puzzle=preload("res://scripts/debug/eca_puzzle.gd")
static func factory(config: Dictionary) -> Callable:
\tvar cfg: Dictionary=config.duplicate(true)
\tcfg.arm=cfg.production_arm
\treturn Puzzle.factory(cfg) if cfg.route_kind=="puzzle" else Access.factory(cfg)
''',encoding='utf-8')
    policy=(BRIEF/'policy.gd').read_text(encoding='utf-8').replace('res://scripts/debug/csa_access.gd','res://scripts/debug/eca_router.gd')
    (HERE/'policy.gd').write_text(policy,encoding='utf-8');shutil.copyfile(BRIEF/'cross_prefix.gd',HERE/'cross_prefix.gd')
    selections=[];configs={g:[] for g in GROUPS}
    for seed in ['4417','4418','4521','4522']:
        row=next(r for r in load(PUZZLE/'analysis.json')['rows'] if r['case']=='puzzle-'+seed+'-sound_sprites')
        c=next(c for c in load(PUZZLE/(row['bundle']+'.json'))['cases'] if c['case_id']==row['case']);c=copy.deepcopy(c)
        group='puzzle-a' if seed in ['4417','4418'] else 'puzzle-b'
        selections.append(dict(route=row['case'],group=group,original_bundle=str(RAW.parent/'puzzle-research-20261025-v1'/row['bundle']),original_case=row['case'],access=row['access']))
        c['policy']['config'].update(route_kind='puzzle',production_arm='reserve');c['case_id']='prefix-'+row['case'];c['target_release_count']=int(row['access']['release'].split(':')[-1]);c.pop('study',None);configs[group].append(c)
    for genre in ['action','simulation']:
        cid=genre+'-4417-exit';row=next(r for r in load(ACCESS/'analysis.json')['rows'] if r['case']==cid)
        c=copy.deepcopy(next(c for c in load(ACCESS/(genre+'.json'))['cases'] if c['case_id']==cid))
        selections.append(dict(route=cid,group='others',original_bundle=str(RAW.parent/'crown-access-policy-20261025-v1'/genre),original_case=cid,access=row['access']))
        c['policy']['config'].update(route_kind='access',production_arm='exit');c['case_id']='prefix-'+cid;c['target_release_count']=int(row['access']['release'].split(':')[-1]);c.pop('study',None);configs['others'].append(c)
    write(HERE/'selection.json',selections)
    for group,cases in configs.items():write(HERE/('prefix-'+group+'.json'),dict(schema_version='1',policy=dict(script='res://scripts/debug/eca_router.gd',id='earned-access-router',version='1'),cases=cases))
    write(HERE/'policy-pin.json',dict(plan_sha256=hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest(),brief_policy_sha256=hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest(),parent_brief_policy_sha256=hashlib.sha256((BRIEF/'policy.gd').read_bytes()).hexdigest(),access_policy_sha256=hashlib.sha256((ACCESS/'policy.gd').read_bytes()).hexdigest(),puzzle_policy_sha256=hashlib.sha256((PUZZLE/'policy.gd').read_bytes()).hexdigest()))
    source('source-before')
def run(name,timeout='600'):return execute(name,[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/(name+'.json')),'--output',str(RAW/name),'--timeout',timeout,'--godot',GODOT])
def branches():
    cross=load(HERE/'cross-checks.json');assert len(cross)==6 and all(r['ok'] for r in cross)
    for group in GROUPS:
        cases=[]
        for prefix in load(HERE/('prefix-'+group+'.json'))['cases']:
            folder=prefix_output(group)/'cases'/prefix['case_id'];r=load(folder/'result.json');assert r['status']=='completed'
            assert max(float(x['metadata']['review']['final_review']) for x in r['outcome']['releases'])>=7
            for arm in ['skip','mean']:
                c=copy.deepcopy(prefix);c['case_id']=prefix['case_id'].replace('prefix-',arm+'-');c['initial']={'checkpoint':load(folder/'studio_checkpoint.json')};c['max_commands']=120;c['target_release_count']=r['final_release_count']+1;c['study']=dict(pair_id=prefix['case_id'],arm=arm);c['policy']['config'].update(arm=arm,label=c['case_id'],starting_reputation=0);cases.append(c)
        write(HERE/('branches-'+group+'.json'),dict(schema_version='1',policy=dict(script='policy.gd',id='crown-public-mean256-early',version='1'),cases=cases))
if __name__=='__main__':
    if sys.argv[1]=='setup':setup()
    elif sys.argv[1]=='prefixes':
        for group in GROUPS:run('prefix-'+group)
    elif sys.argv[1]=='branches':
        branches()
        for group in GROUPS:run('branches-'+group)
    elif sys.argv[1]=='source':source('source-after')
