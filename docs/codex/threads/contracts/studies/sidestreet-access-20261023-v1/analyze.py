from pathlib import Path
import collections, hashlib, json, statistics
HERE=Path(__file__).resolve().parent
THREAD=HERE.parents[1]
ARMS=['balanced','completion','skip']
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
coverage=read(HERE/'coverage.json') if (HERE/'coverage.json').exists() else None
def bundle(arm):
    suffix='v1' if arm=='skip' else 'v2'
    return THREAD/'sims'/f'sidestreet-access-{arm}-20261023-{suffix}'
def events(path):
    found=collections.defaultdict(lambda:collections.defaultdict(list))
    for line in (path/'experiment.log').read_text(encoding='utf-8-sig').splitlines():
        if not line.startswith('PN_ACCESS_'): continue
        tag,raw=line.split(' ',1)
        value=json.loads(raw); found[value['case']][tag.removeprefix('PN_ACCESS_')].append(value)
    return found
checks=[]
def check(ok,label): checks.append({'pass':bool(ok),'check':label})
rows=[]; records={}; event_sets={}; choice_differences=[]
for arm in ARMS:
    records[arm]={}; ev={}; paths=[]; prior_logs={}
    for run in ([Path(p) for p in coverage[arm]] if coverage else [bundle(arm)]):
        run_events=events(run)
        for case,noted in run_events.items():
            if case in prior_logs:
                for tag,values in prior_logs[case].items():
                    check(values==noted[tag][:len(values)],case+' retained timeout observation prefix '+tag)
            prior_logs[case]=noted
        for path in sorted((run/'cases').glob('*/result.json')):
            paths.append(path); ev[path.parent.name]=run_events[path.parent.name]
    event_sets[arm]=ev
    check(len(paths)==24,arm+' all24 fixed cases have final results')
    for path in paths:
        r=read(path); case=r['case_id']; key=case.removesuffix('-'+arm)
        t=read(path.parent/'telemetry.json'); e=ev[case]; results=e['RESULT']; hands=e['HAND']
        check(r['ok'],case+' complete run')
        check(len(results)==(0 if arm=='skip' else 3),case+' expected completed Brief count')
        check(not e['FAIL'],case+' no policy integrity failure')
        check(len({v['offer'] for v in results})==len(results),case+' unique result offers')
        check(len({v['source'] for v in e['ACCEPT']})==len(results),case+' unique release sources')
        for accept,result in zip(e['ACCEPT'],results): check(result['cycle']==accept['cycle']+2,case+' two productive cycles per Brief')
        check(r['initial_state']==t['initial_state'],case+' initial trace identity')
        if r['ok']:
            saved=read(path.parent/'studio_checkpoint.json')['studio_payload']['run']
            briefs=saved['sidestreet_briefs']
            check(len(briefs)==(1 if arm=='skip' else 4),case+' saved offer count without release backlog')
            check(sum(entry['value']['state'] is None for entry in briefs)==1,case+' exactly one saved pending Brief')
        final=t['samples'][-1]
        awards=[v['award'] for v in results]; shadow=[v['shadow8'] for v in results]
        row={'case':case,'bundle':str(path.parents[2]),'key':key,'specialty':key.rsplit('-',1)[0],'arm':arm,'ok':r['ok'],'status':r['status'],'accepted':r['accepted_commands'],'releases':r['final_release_count'],'cycle':r['final_run_cycle'],'cash':int(final['cash_cents']),'fans':int(final['fans']),'overdue':int(final['overdue_cents']),'reputation':sum(awards),'awards':awards,'shadow8_awards':shadow,'shadow8_reputation':sum(shadow),'full':awards.count(1000),'zero':awards.count(0),'unattainable_observed_second':sum(h['hand']==1 and h['full_options']==0 for h in hands),'r20_cycle':e['R20'][0]['cycle'] if e['R20'] else None}
        rows.append(row); records[arm][key]=(r,t,row)
for key in records['skip']:
    r0,t0,row0=records['skip'][key]
    for arm in ['balanced','completion']:
        r,t,row=records[arm][key]
        check(r['source_identity']==r0['source_identity'],key+' same mechanics '+arm)
        check(r['initial_state']==r0['initial_state'] and r['initial_rng']==r0['initial_rng'],key+' same initial state/RNG '+arm)
        # First offer acceptance is the intentional divergence. All prior samples
        # contain command/request, state digest and finance at the actual boundary.
        i=next((i for i,s in enumerate(t['samples']) if s['command_type']=='accept_contract' and s.get('request',{}).get('kind')=='sidestreet_brief'),None)
        if i is None:
            # Telemetry request nesting is preserved by the runner; locate via first contract
            # acceptance after the completed Ironclad/dismiss boundary if needed.
            accepts=[i for i,s in enumerate(t['samples']) if s['command_type']=='accept_contract']
            i=accepts[1] if len(accepts)>1 else None
        check(i is not None,key+' first Brief trace located '+arm)
        check(i is not None and t['samples'][:i]==t0['samples'][:i],key+' identical complete pre-Brief trace '+arm)
        row['prefix_samples']=i
        row['matched_horizon']=row['ok'] and row0['ok'] and row['releases']==row0['releases']==4
        if row['matched_horizon']:
            row['cycle_delta_skip']=row['cycle']-row0['cycle']; row['cash_delta_skip']=row['cash']-row0['cash']; row['fan_delta_skip']=row['fans']-row0['fans']
        # All prior first-hand source/draw states match between the two take policies.
    rb,tb,_=records['balanced'][key];rc,tc,_=records['completion'][key]
    firstplays=[i for i,s in enumerate(tb['samples']) if s['command_type']=='contract' and s.get('request',{}).get('type')=='play']
    # Actual command structure is checked separately by exact replay; comparison
    # at least through first Brief acceptance and begin is carried by state digest.
    ib=records['balanced'][key][2]['prefix_samples']
    check(ib is not None and tb['samples'][:ib+2]==tc['samples'][:ib+2],key+' matching first Brief offer and opening deal')
    choices=lambda trace:[s['request'] for s in trace['samples'] if s['command_type']=='contract']
    left,right=choices(tb),choices(tc)
    choice_differences.append({'case':key,'different_contract_commands':sum(a!=b for a,b in zip(left,right)),'same_command_count':len(left)==len(right)})
summaries={}
for arm in ARMS:
    items=[r for r in rows if r['arm']==arm]
    deltas=[r['cash_delta_skip'] for r in items if 'cash_delta_skip' in r]
    summaries[arm]={'cases':len(items),'complete':sum(r['ok'] for r in items),'accepted':sum(r['accepted'] for r in items),'briefs':sum(len(r['awards']) for r in items),'full':sum(r['full'] for r in items),'zero':sum(r['zero'] for r in items),'unattainable_observed_second':sum(r['unattainable_observed_second'] for r in items),'R20_by_three':sum(r['reputation']>=2000 for r in items),'R20_by_two':sum(sum(r['awards'][:2])>=2000 for r in items),'reputation_range':[min(r['reputation'] for r in items),max(r['reputation'] for r in items)],'reputation_median':statistics.median(r['reputation'] for r in items),'shadow8_full':sum(v==1000 for r in items for v in r['shadow8_awards']),'shadow8_R20_by_two':sum(sum(r['shadow8_awards'][:2])>=2000 for r in items),'shadow8_R20_by_three':sum(r['shadow8_reputation']>=2000 for r in items),'cash_delta_skip_range':[min(r.get('cash_delta_skip',0) for r in items),max(r.get('cash_delta_skip',0) for r in items)],'cash_delta_skip_median':statistics.median(r.get('cash_delta_skip',0) for r in items),'overdue_cases':sum(r['overdue']>0 for r in items)}
    summaries[arm]['matched_horizon_count']=len(deltas)
    summaries[arm]['cash_delta_skip_range']=[min(deltas),max(deltas)] if deltas else None
    summaries[arm]['cash_delta_skip_median']=statistics.median(deltas) if deltas else None
take=sorted([r for r in rows if r['arm']!='skip'],key=lambda r:(r['reputation'],r['case']))
skip=next(r for r in rows if r['case']=='sports-1104-skip')
highest=min(take,key=lambda r:(-r['reputation'],r['case']))
replays=[{k:r[k] for k in ['arm','case','bundle']} for r in [take[0],highest,skip]]
out={'summaries':summaries,'rows':rows,'checks':checks,'failures':sum(not c['pass'] for c in checks),'replays':replays,'choice_differences':choice_differences}
(HERE/'analysis.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'summaries':summaries,'checks':len(checks),'failures':out['failures'],'replays':replays},indent=2))
