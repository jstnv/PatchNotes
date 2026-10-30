from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;T=H.parents[1]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
checks=[];outcomes=[];raw_session_boundaries=[]
def check(ok,label):checks.append({'pass':bool(ok),'check':label})
def bundle(stage):return T/f'sims/publisher-renewal-{stage}-20261023-v1'
def case(stage,cid):return read(bundle(stage)/'cases'/cid/'result.json')
stages=['prefix2','commission2','support','repeat','cold','recovery','third']
identity=None;candidate=None;cases={}
for stage in stages:
    b=bundle(stage)
    if not (b/'run-report.json').exists():check(False,stage+' required report exists');continue
    report=read(b/'run-report.json');check(report.get('ok'),stage+' runner complete')
    if not report.get('ok'):continue
    vp=read(b/'variant-provenance.json')
    if candidate is None:candidate=vp['candidate_identity']
    check(vp['candidate_identity']==candidate,stage+' frozen candidate identity')
    for p in (b/'cases').glob('*/result.json'):
        r=read(p);cases[(stage,p.parent.name)]=r
        if identity is None:identity=r['source_identity']
        check(r['source_identity']==identity,stage+' mechanics identity')
        check(r['ok'] and r['status']=='completed',stage+' '+p.parent.name+' completed')
        check(r['accepted_commands']==r['commands']<=r['max_commands'],stage+' legal commands within original bound')
        check(r['final_release_count']==r['target_release_count'],stage+' exact release horizon')
        cp=p.parent/'studio_checkpoint.json'
        check(bool(r['artifacts']['studio_checkpoint']) and cp.exists(),stage+' nonempty Studio checkpoint')
        o=r['outcome'];check(o['in_studio'],stage+' ends in Studio')
        outcomes.append({'stage':stage,'case':p.parent.name,'commands':r['commands'],'cycle':r['final_run_cycle'],'releases':r['final_release_count'],'cash_cents':o['cash_cents'],'arrears':o['finance']['total_overdue_cents'],'last_review':o['releases'][-1]['metadata']['review']['final_review']})
links=[('prefix2','sports-1112-two-full-briefs-r20','commission2','sports-1112-maps-commission'),('commission2','sports-1112-maps-commission','support','sports-1112-support'),('support','sports-1112-support','repeat','second-support'),('repeat','second-support','cold','second-assessment'),('cold','second-assessment','recovery','recovery-commission'),('recovery','recovery-commission','third','third-support')]
for a,ac,b,bc in links:
    if (a,ac) not in cases or (b,bc) not in cases:continue
    left=cases[(a,ac)];right=cases[(b,bc)]
    raw_session_boundaries.append({'stage':b,'raw_session_hash_equal':left['final_state']==right['initial_state']})
    old_envelope=read(bundle(a)/'cases'/ac/'studio_checkpoint.json')
    new_input=read(bundle(b)/'cases'/bc/'initial.json')
    check(old_envelope==new_input['checkpoint'],b+' cold exact saved envelope input')
    check(left['final_rng']==right['initial_rng'],b+' cold exact RNG')
if ('support','sports-1112-support') in cases:
    a=cases[('support','sports-1112-support')];b=cases[('support','sports-1112-self-published')]
    check(a['initial_state']==b['initial_state'] and a['initial_rng']==b['initial_rng'],'support/self identical start state and RNG')
if ('repeat','second-support') in cases:
    old=case('baseline','second-support-minimal');new=cases[('repeat','second-support')]
    check(not old['artifacts']['studio_checkpoint'],'original failed save retained')
    check(old['outcome']==new['outcome'],'regenerated second-support gameplay outcome parity across declared rule revisions')
    check(old['final_rng']==new['final_rng'],'regenerated second-support gameplay RNG parity')
for stage in ['baseline-replay2','repeat-replay','third-replay']:
    p=bundle(stage)/'run-report.json'
    check(p.exists() and read(p).get('ok'),stage+' exact fresh replay')
audits={}
for p in H.glob('*-audit/checks.json'):
    data=read(p);audits[p.parent.name]=data['summary'];check(data['failures']==0,p.parent.name+' focused checks')
summary=audits.get('third-audit',{})
if summary:
    diagnostics=summary.get('cold_session_diagnostics',[])
    check(len(diagnostics)==6,'all six raw session boundaries diagnosed')
    check(all(d['differences']==['/run/_market_committed_candidate'] for d in diagnostics),'raw session differences confined to historical unsaved transaction scratch')
    check(len(summary['deals'])==3 and len(summary['assessments'])==3,'three support deals and assessments retained')
    check(summary['investment'].get('sidestreet')==4000,'legal recovery results in I40')
    check(not summary['next_quote'],'third missed support does not mint renewal')
    for old in ['support-audit','repeat-audit']:
        if old not in audits:continue
        for k,v in audits[old]['deals'].items():check(summary['deals'].get(k)==v,'frozen prior terms '+k)
        for k,v in audits[old]['assessments'].items():check(summary['assessments'].get(k)==v,'frozen prior assessment '+k)
result={'checks':checks,'failures':sum(not c['pass'] for c in checks),'raw_session_boundaries':raw_session_boundaries,'outcomes':outcomes,'candidate_identity':candidate,'mechanics_identity':identity,'audits':audits}
with (H/'analysis.json').open('x',encoding='utf-8') as f:json.dump(result,f,indent=2)
print(json.dumps({k:v for k,v in result.items() if k not in ['checks','audits']},indent=2))
raise SystemExit(bool(result['failures']))
