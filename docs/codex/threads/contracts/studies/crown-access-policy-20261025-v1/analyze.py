from run import *
from collections import Counter
rows=[];pairs={};manifest={};controls=[];exits=[];samples={};prefix_checks=[]
fixture=load(VAR/'project/scripts/debug/fixtures/studio_specialties_v3.json')
for genre in ['action','puzzle','simulation']:
    log=RAW/genre/'experiment.log'
    if log.exists():
        for line in log.read_text(encoding='utf-8').splitlines():
            if line.startswith('PN_CAP_EXIT '):exits.append(json.loads(line.split(' ',1)[1]))
    for c in load(HERE/(genre+'.json'))['cases']:
        folder=RAW/genre/'cases'/c['case_id']
        if not (folder/'result.json').exists():continue
        r=load(folder/'result.json');tel=load(folder/'telemetry.json');ss=tel['samples'];pair=c['study']['pair_id']
        ident=[r['source_identity'],r['initial_state'],r['initial_rng']]
        if pair in pairs:assert pairs[pair]==ident
        else:pairs[pair]=ident
        assert sorted(ss[0]['owned_features'])==fixture[genre]['ids']
        assert len(ss)==r['commands']+1 and r['initial_state']==tel['initial_state'] and r['final_state']==tel['final_state']
        access=None
        for s in ss:
            for release in s['releases']:
                if release['review'] is not None and float(release['review'])>=7 and access is None:access=dict(release=release['id'],cycle=release['release_cycle'],cash_cents=int(s['cash_cents']))
        lows=[int(s['cash_cents']) for s in ss]+[int(s['transaction_cash_low_cents']) for s in ss if s.get('transaction_cash_low_cents') is not None]
        rejects=[s for s in ss if s['accepted'] is False]
        row=dict(case=c['case_id'],bundle=genre,pair=pair,arm=c['study']['arm'],status=r['status'],error=r['error'],commands=r['commands'],accepted=r['accepted_commands'],releases=r['final_release_count'],cycles=r['final_run_cycle'],reviews=[x['review'] for x in ss[-1]['releases']],access=access,cash_cents=int(ss[-1]['cash_cents']),minimum_cash_cents=min(lows),max_overdue_cents=max(int(s['overdue_cents']) for s in ss if s['overdue_cents'] is not None),rejection=rejects[0] if rejects else None,paid_searches=sum(s['accepted'] is True and s['command_type']=='search_contracts' for s in ss),research_actions=sum(s['accepted'] is True and s['command_type']=='research' for s in ss),research_admissions=sum(s['accepted'] is True and s['command_type']=='admit_research' for s in ss),game2_begin=next((dict(cycle=s['run_cycle'],cash_cents=int(s['cash_cents'])) for s in ss if s['accepted'] is True and s['command_type']=='begin_development' and s['release_count']==1),None))
        row['research_ids']=[s['request']['payload']['quote']['feature_id'] for s in ss if s['accepted'] and s['command_type']=='admit_research']
        rows.append(row);samples[(pair,row['arm'])]=ss
        if row['arm']=='control':
            old=RAW.parent/'crown-search-access-20261025-v1'/(pair+'-v2')/'cases'/(pair+'-cash6')
            prior=load(old/'result.json')
            keys=['initial_state','initial_rng','final_state','final_rng','status','commands','accepted_commands','final_release_count','final_run_cycle']
            check={k:r[k]==prior[k] for k in keys};assert all(check.values()),(pair,check)
            controls.append(dict(pair=pair,checks=check,prior=str(old)))
        for name in ['result.json','telemetry.json','replay.tape.json','case.variant.json','studio_checkpoint.json']:
            p=folder/name
            if p.exists():manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
for pair in pairs:
    if (pair,'exit') not in samples or (pair,'reserve') not in samples:continue
    control=samples[(pair,'control')];exit_samples=samples[(pair,'exit')];reserve=samples[(pair,'reserve')]
    begin=lambda ss:next(s for s in ss if s['command_type']=='begin_development' and s['release_count']==1)
    assert begin(control)['state_digest']==begin(exit_samples)['state_digest']
    shared=0
    for a,b in zip(control,reserve):
        if a['request']!=b['request']:break
        assert a['state_digest']==b['state_digest'];shared+=1
    assert shared>1
    prefix_checks.append(dict(pair=pair,control_exit_game2_exact=True,reserve_identical_prefix_samples=shared,first_changed_control=control[shared]['command_type'] if shared<len(control) else None,first_changed_reserve=reserve[shared]['command_type'] if shared<len(reserve) else None))
out=dict(rows=rows,statuses=dict(Counter(x['status'] for x in rows)),matched_initial_groups=len(pairs),controls=controls,prefix_checks=prefix_checks,exits=exits,access_count=sum(x['access'] is not None for x in rows),accepted_commands=sum(x['accepted'] for x in rows))
write(HERE/'analysis.json',out);write(HERE/'evidence-manifest.json',manifest)
print(json.dumps({k:v for k,v in out.items() if k not in ['rows','controls','exits','prefix_checks']}))
for r in rows:print(json.dumps({k:v for k,v in r.items() if k!='rejection'}))
