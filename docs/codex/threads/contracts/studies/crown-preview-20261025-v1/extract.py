"""Read existing frozen evidence; no campaign execution or gameplay mutation."""
from pathlib import Path
import hashlib,json,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
PRIOR=HERE.parent/'crown-twohand-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-twohand-20261025-v1')
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value):(HERE/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def score(scope,h,standing=0):
    completion=(2*min(scope,9)+sum(min(x,8) for x in h)+2*min(min(h),8))*10000//66
    balance=max(0,10000-1250*max(0,max(h)-min(h)-4))
    grade=min(completion,balance);requested=grade//10;credit=min(requested,10000-standing)
    return dict(scope=scope,cores=[x/2 for x in h],spread=(max(h)-min(h))/2,completion_bp=completion,balance_bp=balance,grade_bp=grade,requested_bp=requested,credited_bp=credit,standing_before_bp=standing,standing_after_bp=standing+credit)
checks=0;records=[];files={};canonical=[ROOT/'patch-notes/scripts/phases/contract_phase.gd',ROOT/'patch-notes/scripts/contracts/contract_state.gd',ROOT/'patch-notes/scripts/contracts/publisher_relationship_brief.gd',ROOT/'patch-notes/scripts/simulation/contract_session.gd']
for seed in ['4521','4522']:
    bundle=RAW/('planning-'+seed);log=bundle/'experiment.log';files[str(log)]=sha(log)
    expected=load(PRIOR/'evidence-manifest.json')['files'][f'planning-{seed}/experiment.log'];assert sha(log)==expected;checks+=1
    parsed={tag:[] for tag in ['HAND','RESULT','ACCEPT']}
    for line in log.read_text(encoding='utf-8').splitlines():
        if line.startswith('PN_CB_'):
            tag,payload=line.split(' ',1);n=json.loads(payload)
            if n['case']=='mean-'+seed and tag[6:] in parsed:parsed[tag[6:]].append(n)
    byoffer={x['offer']:x for x in parsed['RESULT']}
    standing={x['offer']:x['prior_reputation'] for x in parsed['ACCEPT']}
    for n in parsed['HAND']:
        projected=n['projected'];p=score(projected['scope'],projected['cores'],standing[n['offer']])
        result=byoffer[n['offer']]
        if n['hand']==1:
            assert (p['grade_bp'],p['requested_bp'],p['standing_after_bp'])==(result['grade'],result['award'],result['total']);checks+=1
        records.append(dict(case=n['case'],offer=n['offer'],hand=int(n['hand'])+1,kind='provisional after first selected hand' if n['hand']==0 else 'final selected hand',chosen_tokens=n['chosen'],selected_definitions=[x['definition'] for x in n['visible'] if x['token'] in n['chosen']],preview=p,recorded_final_award_bp=result['award']))
fixtures=[]
for name,s,h,r,expected in [
    ('all targets',9,[8,8,8,8],0,(10000,10000,1000,1000)),
    ('dominance half-point beyond tolerance',9,[8,8,8,13],0,(10000,8750,875,875)),
    ('dominance despite complete work',9,[8,8,8,20],0,(10000,0,0,0)),
    ('insufficient work despite balance',9,[6,6,6,6],0,(8181,10000,818,818)),
    ('same partial scores at R99',9,[6,6,6,6],9900,(8181,10000,818,100)),
    ('full grade at cap',9,[8,8,8,8],10000,(10000,10000,1000,0)),
    ('excess Scope does not hurt',12,[8,8,8,8],0,(10000,10000,1000,1000)),
    ('empty scores are not full quality',0,[0,0,0,0],0,(0,10000,0,0))]:
    p=score(s,h,r);assert tuple(p[k] for k in ['completion_bp','balance_bp','requested_bp','credited_bp'])==expected;checks+=1
    fixtures.append(dict(label=name,kind='constructed display arithmetic, not legal route witness',preview=p))
for label,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('status',['status','--short']),('diff',['diff','--stat'])]:
    value=subprocess.check_output(['git',*args],cwd=ROOT,text=True,encoding='utf-8',errors='replace')
    (HERE/(label+'.txt')).write_text(value,encoding='utf-8')
source=load(PRIOR/'closeout.json')
write('evidence.json',dict(status='PASS',checks=checks,campaign_runs=0,scope='Read-only derivation from prior frozen mean-policy logs plus constructed display examples; no UI or human acceptance.',source_identity=source['source_identity'],candidate_identity=source['candidate_identity'],base_identity=source['base_identity'],head=(HERE/'head.txt').read_text().strip(),canonical_read_hashes={str(p.relative_to(ROOT)):sha(p) for p in canonical},source_files=files,records=records,constructed=fixtures))
print(json.dumps(dict(status='PASS',checks=checks,recorded_previews=len(records),constructed=len(fixtures),campaign_runs=0)))
