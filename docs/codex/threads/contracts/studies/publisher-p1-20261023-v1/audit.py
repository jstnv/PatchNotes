from pathlib import Path
import json,hashlib,sys
ROOT=Path(__file__).resolve().parents[6];HERE=Path(__file__).resolve().parent
S=ROOT/'docs/codex/threads/contracts/sims'
label=sys.argv[1]
B=S/'publisher-p1-baseline-20261023-v1';C=S/f'publisher-p1-candidate-20261023-{label}'
checks=[]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def check(ok,name):
    checks.append({'check':name,'pass':bool(ok)})
def project(value):
    if isinstance(value,dict):
        return {k:project(v) for k,v in value.items() if k not in ('_publisher_relationships','_relationship_commit_in_progress')}
    if isinstance(value,list): return [project(x) for x in value]
    return value
identities={}
for case in ('action-4417','sports-1112'):
    b=B/'cases'/case;c=C/'cases'/case
    br=read(b/'result.json');cr=read(c/'result.json')
    identities[case]={'baseline':br['source_identity'],'candidate':cr['source_identity']}
    check(br['ok'] and cr['ok'] and br['status']==cr['status']=='completed',case+' completed both')
    check(br['commands']==cr['commands']==36,case+' unchanged 36 commands')
    check(br['initial_rng']==cr['initial_rng'] and br['final_rng']==cr['final_rng'],case+' initial and final RNG equal')
    check(br['outcome']==cr['outcome'],case+' complete measured outcome equal')
    check(read(b/'case.json')['initial']==read(c/'case.json')['initial'],case+' exact legal starting recipe')
    check(bool(cr['artifacts']['studio_checkpoint']),case+' nonempty Studio checkpoint')
    bp=read(b/'studio_checkpoint.json')['studio_payload'];cp=read(c/'studio_checkpoint.json')['studio_payload']
    ledger=cp['run'].pop('publisher_relationships')
    check(ledger=={'version':'1','owner':cp['run']['bank_run_id'],'events':[]},case+' no new relationship awards')
    cp['content_revision']=bp['content_revision']
    check(cp==bp,case+' all preexisting native state and RNG equal')
    check(project(read(b/'final_state.variant.json'))==project(read(c/'final_state.variant.json')),case+' full runtime final state equal excluding two declared additive fields')
    bt=read(b/'replay.tape.json');ct=read(c/'replay.tape.json')
    check(len(bt['steps'])==len(ct['steps']),case+' tape length equal')
    # Every request and result has identical mechanical fields; state digests
    # legitimately include the new dormant ledger and are not substituted.
    for i,(bs,cs) in enumerate(zip(bt['steps'],ct['steps'])):
        check({k:v for k,v in bs.items() if k!='state'}=={k:v for k,v in cs.items() if k!='state'},case+f' command/result/RNG {i} equal')
report={'cross_revision':True,'ordinary_pair_comparator_used':False,'identities':identities,'checks':checks,'failed':[x for x in checks if not x['pass']]}
out=HERE/f'audit-{label}.json'
with out.open('x',encoding='utf-8') as f: json.dump(report,f,indent=2)
print(json.dumps({'checks':len(checks),'failed':report['failed'],'identities':identities},indent=2))
sys.exit(bool(report['failed']))
