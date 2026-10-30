from run import *
from collections import Counter
rows=[];pairs={};events={};prefixes=[];manifest={}
for sel in load(HERE/'selection.json'):
    folder=prefix_output(sel['group'])/'cases'/('prefix-'+sel['route'])
    if not (folder/'result.json').exists():continue
    r=load(folder/'result.json');t=load(folder/'telemetry.json');s=t['samples'][-1]
    assert r['status']=='completed' and s['run_cycle']==sel['access']['cycle'] and int(s['cash_cents'])==sel['access']['cash_cents']
    prefixes.append(dict(route=sel['route'],group=sel['group'],cycle=s['run_cycle'],cash_cents=int(s['cash_cents']),releases=r['final_release_count'],reviews=[x['review'] for x in s['releases']],state=r['final_state'],rng=r['final_rng']))
for group in GROUPS:
    config=HERE/('branches-'+group+'.json')
    if not config.exists():continue
    log=RAW/('branches-'+group)/'experiment.log'
    if log.exists():
        for line in log.read_text(encoding='utf-8').splitlines():
            if line.startswith('PN_CB_RESULT '):
                e=json.loads(line.split(' ',1)[1]);events.setdefault(e['case'],[]).append(e)
    for c in load(config)['cases']:
        folder=RAW/('branches-'+group)/'cases'/c['case_id']
        if not (folder/'result.json').exists():continue
        r=load(folder/'result.json');ss=load(folder/'telemetry.json')['samples'];pair=c['study']['pair_id'];arm=c['study']['arm']
        identity=[r['source_identity'],r['initial_state'],r['initial_rng']]
        if pair in pairs:assert pairs[pair]==identity
        else:pairs[pair]=identity
        pre=next(p for p in prefixes if 'prefix-'+p['route']==pair)
        assert r['initial_state']==pre['state'] and r['initial_rng']==pre['rng'] and len(ss)==r['commands']+1
        lows=[int(s['cash_cents']) for s in ss]+[int(s['transaction_cash_low_cents']) for s in ss if s.get('transaction_cash_low_cents') is not None]
        searches=[s for s in ss if s['command_type']=='search_contracts' and s['accepted']];ev=events.get(c['case_id'],[])
        if arm=='mean' and r['status']=='completed':
            assert len(ev)==3 and len(searches)==3
            assert all(ev[i]['cycle']==searches[i]['run_cycle']+2 for i in range(3))
            assert all(e['redraws']==0 for e in ev)
            for i,e in enumerate(ev):
                cores=e['cores'];n=2*min(e['scope'],9)+sum(min(h,8) for h in cores)+2*min(min(cores),8)
                completion=10000*n//66;balance=max(0,10000-1250*max(0,max(cores)-min(cores)-4));grade=min(completion,balance)
                assert (e['completion'],e['promise'],e['grade'],e['award'])==(completion,balance,grade,grade//10)
                assert e['ordinal']==i+1 and e['total']==sum(x['award'] for x in ev[:i+1])
        if arm=='skip':assert not ev and not searches
        row=dict(case=c['case_id'],group=group,pair=pair,arm=arm,status=r['status'],error=r['error'],commands=r['commands'],accepted=r['accepted_commands'],initial_cycle=ss[0]['run_cycle'],final_cycle=ss[-1]['run_cycle'],initial_cash_cents=int(ss[0]['cash_cents']),final_cash_cents=int(ss[-1]['cash_cents']),min_cash_cents=min(lows),max_overdue_cents=max(int(s['overdue_cents']) for s in ss if s['overdue_cents'] is not None),final_releases=r['final_release_count'],final_review=ss[-1]['releases'][-1]['review'],searches=len(searches),briefs=ev,reputation_bp=sum(e['award'] for e in ev),rejection=next((s for s in ss if s['accepted'] is False),None))
        rows.append(row)
        for name in ['result.json','telemetry.json','replay.tape.json','case.variant.json','studio_checkpoint.json']:
            p=folder/name
            if p.exists():manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
comparisons=[]
for pair in pairs:
    arms={r['arm']:r for r in rows if r['pair']==pair}
    if len(arms)!=2:continue
    skip=arms['skip'];mean=arms['mean']
    comparisons.append(dict(pair=pair,both_completed=skip['status']==mean['status']=='completed',cash_delta_cents=mean['final_cash_cents']-skip['final_cash_cents'],cycle_delta=mean['final_cycle']-skip['final_cycle'],skip_review=skip['final_review'],mean_review=mean['final_review'],standing_bp=mean['reputation_bp'],zero_awards=sum(e['award']==0 for e in mean['briefs'])))
out=dict(rows=rows,prefixes=prefixes,comparisons=comparisons,matched_pairs=len(comparisons),statuses=dict(Counter(r['status'] for r in rows)))
write(HERE/'analysis.json',out);write(HERE/'evidence-manifest.json',manifest)
print(json.dumps(dict(prefixes=len(prefixes),cases=len(rows),statuses=out['statuses'])))
for r in rows:print(json.dumps({k:v for k,v in r.items() if k not in ['briefs','rejection']}))
for c in comparisons:print(json.dumps(c))
