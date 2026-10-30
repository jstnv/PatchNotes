"""Create declared inputs from intact legal Studio envelopes; no state edits."""
import copy, hashlib, json, pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[5]
THREAD = HERE.parents[1]
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
def write(name, obj):
    path = HERE / name
    if path.exists(): raise RuntimeError(f'Refusing overwrite: {path}')
    path.write_text(json.dumps(obj, indent=2) + '\n', encoding='utf-8')

prior = read(THREAD / 'publisher-support-1112-pair-20261022-v1.json')
initial = prior['cases'][0]['initial']
policy = {'script': 'policy.gd', 'id': 'publisher-overnight-visible-schedules', 'version': '1'}
def hands(n): return {'design':n,'alpha':n,'beta':n}
def case(name, start, schedules, game=-1, kind='', bound=200, target=7):
    return {'schema_version':'1','case_id':name,'initial':copy.deepcopy(start),'max_commands':bound,
            'target_release_count':target,'telemetry':True,'policy':{'config':{'schedules':schedules,'deal_game':game,'deal_kind':kind}}}

cases=[]
for n in [2,3]:
    for support in [True,False]:
        name=f'weak{n}-'+('support' if support else 'self')
        c=case(name,initial,{'5':hands(n),'6':{'design':5,'alpha':7,'beta':6},'7':hands(2)},5,'support' if support else '')
        c['study']={'pair_id':f'weak{n}-pair','arm':'support' if support else 'self'}
        cases.append(c)
write('weak-pairs.json',{'schema_version':'1','policy':policy,'cases':cases})
saved=read(THREAD / 'sims/publisher-support-1112-pair-20261022-v1/cases/sports-1112-support/studio_checkpoint.json')
write('renewal.json',{'schema_version':'1','policy':policy,'cases':[case('second-support',{'checkpoint':saved},{'7':hands(2)},7,'support',80)]})
provenance = {k:subprocess.check_output(['git',*v],cwd=ROOT,text=True) for k,v in {
    'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--short'],'diff_stat':['diff','--stat']}.items()}
provenance['policy_sha256']=hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest()
provenance['initial_sha256']=hashlib.sha256(json.dumps(initial,sort_keys=True).encode()).hexdigest()
write('provenance.json',provenance)
print(json.dumps({'prepared':len(cases)+1,'root':str(ROOT),'policy_sha256':provenance['policy_sha256']}))
