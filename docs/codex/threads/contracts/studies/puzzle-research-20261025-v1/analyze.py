from run import *
from collections import Counter
rows=[];samples={};identities={};controls=[];prefix=[];hashes={};exits=[]
fixture=load(VAR/'project/scripts/debug/fixtures/studio_specialties_v3.json')['puzzle']['ids']
for bundle in ['discovery-4417','discovery-4521','confirmation']:
    if not (HERE/(bundle+'.json')).exists():continue
    log=RAW/bundle/'experiment.log'
    if log.exists():
        for line in log.read_text(encoding='utf-8').splitlines():
            if line.startswith('PN_CAP_EXIT '):exits.append(json.loads(line.split(' ',1)[1]))
    for c in load(HERE/(bundle+'.json'))['cases']:
        folder=RAW/bundle/'cases'/c['case_id']
        if not (folder/'result.json').exists():continue
        r=load(folder/'result.json');t=load(folder/'telemetry.json');ss=t['samples'];pair=c['study']['pair_id'];arm=c['study']['arm']
        ident=[r['source_identity'],r['initial_state'],r['initial_rng']]
        if pair in identities:assert ident==identities[pair]
        else:identities[pair]=ident
        assert sorted(ss[0]['owned_features'])==fixture
        assert len(ss)==r['commands']+1 and t['initial_state']==r['initial_state'] and t['final_state']==r['final_state']
        samples[(pair,arm)]=ss
        access=None
        for s in ss:
            for rel in s['releases']:
                if rel['review'] is not None and float(rel['review'])>=7 and access is None:access=dict(release=rel['id'],cycle=rel['release_cycle'],cash_cents=int(s['cash_cents']))
        admissions=[s['request']['payload']['quote'] for s in ss if s['command_type']=='admit_research' and s['accepted']]
        ids=[q['feature_id'] for q in admissions];cost=sum(int(q['down_cents'])+int(q['remaining_cents']) for q in admissions)
        research=sum(s['command_type']=='research' and s['accepted'] is True for s in ss)
        searches=sum(s['command_type']=='search_contracts' and s['accepted'] is True for s in ss)
        if r['status']=='completed':assert ids==PAIRS[arm] and cost==90000 and research==2 and searches==6
        lows=[int(s['cash_cents']) for s in ss]+[int(s['transaction_cash_low_cents']) for s in ss if s.get('transaction_cash_low_cents') is not None]
        row=dict(case=c['case_id'],bundle=bundle,pair=pair,arm=arm,status=r['status'],error=r['error'],commands=r['commands'],accepted=r['accepted_commands'],releases=r['final_release_count'],cycles=r['final_run_cycle'],reviews=[x['review'] for x in ss[-1]['releases']],access=access,cash_cents=int(ss[-1]['cash_cents']),minimum_cash_cents=min(lows),max_overdue_cents=max(int(s['overdue_cents']) for s in ss if s['overdue_cents'] is not None),research_ids=ids,quoted_cost_cents=cost,research_actions=research,searches=searches,rejection=next((s for s in ss if s['accepted'] is False),None))
        row['game2_begin']=next((dict(cycle=s['run_cycle'],cash_cents=int(s['cash_cents'])) for s in ss if s['command_type']=='begin_development' and s['accepted'] and s['release_count']==1),None)
        rows.append(row)
        if arm=='baseline' and bundle.startswith('discovery'):
            prior=load(RAW.parent/'crown-access-policy-20261025-v1/puzzle/cases'/(pair+'-reserve')/'result.json')
            keys=['initial_state','initial_rng','final_state','final_rng','status','commands','accepted_commands','final_release_count','final_run_cycle']
            check={k:r[k]==prior[k] for k in keys};assert all(check.values()),check;controls.append(dict(pair=pair,checks=check))
        for name in ['result.json','telemetry.json','case.variant.json','replay.tape.json','studio_checkpoint.json']:
            p=folder/name
            if p.exists():hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
for (pair,arm),ss in samples.items():
    if arm=='baseline' or (pair,'baseline') not in samples:continue
    baseline=samples[(pair,'baseline')];shared=0
    for x,y in zip(baseline,ss):
        if x['request']!=y['request']:break
        assert x['state_digest']==y['state_digest'];shared+=1
    assert shared>=61
    first=next(r for r in rows if r['pair']==pair and r['arm']=='baseline')['game2_begin']
    second=next(r for r in rows if r['pair']==pair and r['arm']==arm)['game2_begin']
    if first and second:assert first==second
    prefix.append(dict(pair=pair,arm=arm,exact_shared_samples=shared,game2_cash_cycle_equal=first==second if first and second else None,first_changed_baseline=baseline[shared]['command_type'] if shared<len(baseline) else None,first_changed_candidate=ss[shared]['command_type'] if shared<len(ss) else None))
out=dict(rows=rows,statuses=dict(Counter(r['status'] for r in rows)),matched_initial_groups=len(identities),historical_controls=controls,prefixes=prefix,exits=exits,accepted_commands=sum(r['accepted'] for r in rows))
write(HERE/'analysis.json',out);write(HERE/'evidence-manifest.json',hashes)
print(json.dumps({k:v for k,v in out.items() if k not in ['rows','historical_controls','prefixes','exits']}))
for r in rows:print(json.dumps({k:v for k,v in r.items() if k not in ['rejection','pair']}))
