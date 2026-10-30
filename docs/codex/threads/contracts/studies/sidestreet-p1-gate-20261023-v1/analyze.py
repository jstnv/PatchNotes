from pathlib import Path
import json,statistics,collections,hashlib
H=Path(__file__).resolve().parent;T=H.parents[1]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
checks=[]
def ck(ok,name): checks.append({'pass':bool(ok),'check':name})
rows=[];records={};events={}
for arm in ['balanced','skip']:
    for batch in [1,2]:
        b=T/f'sims/sidestreet-p1-{arm}-{batch}-20261023-v1'
        ck(read(b/'run-report.json').get('ok'),f'{arm}{batch} runner successful')
        ev=collections.defaultdict(lambda:collections.defaultdict(list))
        for line in (b/'experiment.log').read_text(encoding='utf-8-sig').splitlines():
            if line.startswith('PN_ACCESS_'):
                tag,v=line.split(' ',1);v=json.loads(v);ev[v['case']][tag.removeprefix('PN_ACCESS_')].append(v)
        for p in sorted((b/'cases').glob('*/result.json')):
            r=read(p);case=r['case_id'];key=case.rsplit('-',1)[0];s=read(p.parent/'studio_checkpoint.json')['studio_payload']['run'];t=read(p.parent/'telemetry.json');e=ev[case]
            ck(r['ok'] and r['status']=='completed' and r['final_release_count']==4,case+' four releases complete')
            ck(not e['FAIL'],case+' no policy assertion failed')
            awards=[int(x['credited_reputation_bp']) for x in s['publisher_relationships']['events']]
            ck(len(awards)==len(e['RESULT']) and sum(awards)==sum(x['award'] for x in e['RESULT']),case+' committed P1 credits equal independent grades')
            ck(all(int(x['credited_investment_bp'])==0 for x in s['publisher_relationships']['events']),case+' no Investment award')
            ck(len({x['source_id'] for x in s['publisher_relationships']['events']})==len(awards),case+' exactly once sources')
            ck(all(b['cycle']==a['cycle']+2 for a,b in zip(e['ACCEPT'],e['RESULT'])),case+' two cycles per brief')
            ck(len(awards)==0 if arm=='skip' else (sum(awards)>=2000 and sum(awards[:-1])<2000 and len(awards)<=3),case+' stop at gate policy')
            ck(len(s['sidestreet_briefs'])==len(awards)+1,case+' one future pending offer no backlog')
            releases=[]
            gate=e['R20'][0]['cycle'] if e['R20'] else None
            for i,release in enumerate(r['outcome']['releases'],1):
                m=release['metadata'];v=m['review']
                releases.append({'ordinal':i,'scope':v['scope'],'required_scope':v['required_scope'],'review':v['final_review'],'cycle':m['release_cycle'],'after_gate':gate is not None and m['release_cycle']>gate,'readiness':v['required_scope']>0 and v['scope']>=v['required_scope'] and v['final_review']>=6.0,'literal30_readiness':v['scope']>=30 and v['final_review']>=6.0})
            row={'case':case,'key':key,'arm':arm,'bundle':str(b),'commands':r['accepted_commands'],'cycle':r['final_run_cycle'],'cash':int(r['outcome']['cash_cents']),'cash_low':min(int(x['cash_cents']) for x in t['samples']),'overdue':int(t['samples'][-1]['overdue_cents']),'briefs':len(awards),'awards':awards,'reputation':sum(awards),'gate_cycle':gate,'gate_cash':e['RESULT'][-1]['cash'] if gate else None,'releases':releases}
            rows.append(row);records[(key,arm)]=(r,t,row);events[case]=dict(e)
for (key,arm),(r,t,row) in records.items():
    if arm!='balanced':continue
    r0,t0,row0=records[(key,'skip')]
    ck(r['source_identity']==r0['source_identity'],key+' same candidate mechanics')
    ck(r['initial_state']==r0['initial_state'] and r['initial_rng']==r0['initial_rng'],key+' exact initial state and RNG equality')
    accepts=[i for i,s in enumerate(t['samples']) if s['command_type']=='accept_contract']
    idx=accepts[1]
    ck(t['samples'][:idx]==t0['samples'][:idx],key+' shared prefix equality through Ironclad')
    row['cash_delta_vs_skip']=row['cash']-row0['cash'];row['extra_cycles_vs_skip']=row['cycle']-row0['cycle']
for key in ['action-1104','racing-1104']:
    r0=read(T/f'sims/sidestreet-p1-baseline-20261023-v1/cases/{key}-skip/result.json');r=records[(key,'skip')][0]
    ck(r0['initial_rng']==r['initial_rng'] and r0['final_rng']==r['final_rng'],key+' cross-version skip initial/final RNG unchanged')
    ck(r0['outcome']==r['outcome'],key+' cross-version skip all ordinary outcome fields unchanged')
balanced=[r for r in rows if r['arm']=='balanced'];post=[x for r in balanced for x in r['releases'] if x['after_gate']]
summary={'candidate_cases':len(rows),'commands':sum(x['commands'] for x in rows),'two_briefs':sum(x['briefs']==2 for x in balanced),'three_briefs':sum(x['briefs']==3 for x in balanced),'cash_delta_range':[min(x['cash_delta_vs_skip'] for x in balanced),max(x['cash_delta_vs_skip'] for x in balanced)],'cash_delta_median':statistics.median(x['cash_delta_vs_skip'] for x in balanced),'gate_cash_range':[min(x['gate_cash'] for x in balanced),max(x['gate_cash'] for x in balanced)],'post_gate_releases':len(post),'post_gate_ready':sum(x['readiness'] for x in post),'post_gate_review_range':[min(x['review'] for x in post),max(x['review'] for x in post)],'post_gate_scope_range':[min(x['scope'] for x in post),max(x['scope'] for x in post)],'partial_awards':sum(0<a<1000 for x in balanced for a in x['awards']),'full_awards':sum(a==1000 for x in balanced for a in x['awards']),'zero_awards':sum(a==0 for x in balanced for a in x['awards'])}
result={'summary':summary,'checks':checks,'failures':[x for x in checks if not x['pass']],'rows':rows,'events':events}
(H/'analysis.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'summary':summary,'checks':len(checks),'failures':result['failures']},indent=2))
selected=[]
selected.append(sorted(balanced,key=lambda r:(r['reputation'],r['case']))[0])
selected.append(sorted(balanced,key=lambda r:(r['extra_cycles_vs_skip'],r['case']))[0])
(H/'replay-selection.json').write_text(json.dumps(selected,indent=2),encoding='utf-8')
