from run import *
from collections import Counter
bundle=RAW/'baseline'
config=load(HERE/'baseline.json')
fixture=load(VAR/'project/scripts/debug/fixtures/studio_specialties_v3.json')
rows=[]; pairs={}; receipts={}; manifest={}
for case in config['cases']:
    cid=case['case_id']; folder=bundle/'cases'/cid
    result=load(folder/'result.json'); tel=load(folder/'telemetry.json'); samples=tel['samples']
    genre=case['initial']['recipe']['specialty']
    assert sorted(samples[0]['owned_features'])==fixture[genre]['ids'], cid
    assert result['initial_state']==tel['initial_state'] and result['final_state']==tel['final_state']
    assert len(samples)==result['commands']+1
    p=case['study']['pair_id']
    identity=(result['source_identity'],result['initial_state'],result['initial_rng'])
    if p in pairs: assert pairs[p]==identity, 'Unmatched state/RNG: '+p
    else: pairs[p]=identity
    first=None
    for s in samples:
        for release in s['releases']:
            if release['review'] is not None and float(release['review'])>=7:
                if first is None: first=dict(release=release['id'],cycle=release['release_cycle'],cash_cents=int(s['cash_cents']))
    reviews=[float(r['review']) for r in samples[-1]['releases'] if r['review'] is not None]
    lows=[int(s['cash_cents']) for s in samples]+[int(s['transaction_cash_low_cents']) for s in samples if s.get('transaction_cash_low_cents') is not None]
    overdue=[int(s['overdue_cents']) for s in samples if s['overdue_cents'] is not None]
    rejected=[s for s in samples if s['accepted'] is False]
    row=dict(case=cid,genre=genre,arm=case['study']['arm'],seed=case['initial']['recipe']['seed'],status=result['status'],error=result['error'],
        accepted=result['accepted_commands'],commands=result['commands'],releases=result['final_release_count'],cycles=result['final_run_cycle'],
        initial_cash_cents=int(samples[0]['cash_cents']),final_cash_cents=int(samples[-1]['cash_cents']),minimum_cash_cents=min(lows),
        maximum_overdue_cents=max(overdue) if overdue else None,final_overdue_cents=int(samples[-1]['overdue_cents']) if samples[-1]['overdue_cents'] is not None else None,
        final_bank_loans=result['outcome']['finance'].get('bank_loans'),reviews=reviews,first_qualifying_release=first,
        first_rejection=rejected[0] if rejected else None,in_studio=result['outcome']['in_studio'])
    rows.append(row);receipts[cid]=result
    for name in ['result.json','telemetry.json','replay.tape.json','case.variant.json','initial.json','final_state.variant.json']:
        q=folder/name;manifest[str(q)]=hashlib.sha256(q.read_bytes()).hexdigest()
complete=sorted(r['case'] for r in rows if r['status']=='completed')
failed=sorted(r['case'] for r in rows if r['first_rejection'])
selected=([complete[0]] if complete else [])
if failed: selected.append(failed[0])
elif complete:
    first_pair=receipts[complete[0]]['study']['pair_id']
    selected += [c for c in complete[1:] if receipts[c]['study']['pair_id'] != first_pair][:1]
result=dict(cases=rows,status_counts=dict(Counter(r['status'] for r in rows)),matched_pairs=len(pairs),roster_checks=len(rows),
    qualifying_cases=sum(r['first_qualifying_release'] is not None for r in rows),accepted_commands=sum(r['accepted'] for r in rows),
    representative_replays=selected,reduction_case=failed[0] if failed else None,continuation_case=complete[0] if complete else None)
write(HERE/'analysis.json',result);write(HERE/'evidence-manifest.json',manifest)
print(json.dumps({k:v for k,v in result.items() if k!='cases'},indent=2))
for genre in sorted(fixture):
    rs=[r for r in rows if r['genre']==genre]
    print(genre,[(r['seed'],r['arm'],r['status'],r['releases'],r['reviews'],r['final_cash_cents'],r['error']) for r in rs])
