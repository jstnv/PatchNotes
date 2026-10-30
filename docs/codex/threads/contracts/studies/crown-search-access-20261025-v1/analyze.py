from run import *
from collections import Counter
rows=[];pairs={};manifest={}
fixture=load(VAR/'project/scripts/debug/fixtures/studio_specialties_v3.json')
for config_path in sorted(HERE.glob('*-v2.json')):
    config=load(config_path)
    if not isinstance(config,dict) or 'cases' not in config:continue
    pair=config_path.stem
    for c in config['cases']:
        folder=RAW/pair/'cases'/c['case_id']
        if not (folder/'result.json').exists():continue
        r=load(folder/'result.json');tel=load(folder/'telemetry.json');ss=tel['samples']
        ident=[r['source_identity'],r['initial_state'],r['initial_rng']]
        if pair in pairs:assert pairs[pair]==ident
        else:pairs[pair]=ident
        genre=c['initial']['recipe']['specialty']
        assert sorted(ss[0]['owned_features'])==fixture[genre]['ids']
        assert len(ss)==r['commands']+1 and r['initial_state']==tel['initial_state'] and r['final_state']==tel['final_state']
        qualifying=None
        for sample in ss:
            for release in sample['releases']:
                if release['review'] is not None and float(release['review'])>=7 and qualifying is None:
                    qualifying=dict(release=release['id'],cycle=release['release_cycle'],cash_cents=int(sample['cash_cents']))
        lows=[int(s['cash_cents']) for s in ss]+[int(s['transaction_cash_low_cents']) for s in ss if s.get('transaction_cash_low_cents') is not None]
        overdue=[int(s['overdue_cents']) for s in ss if s['overdue_cents'] is not None]
        rejected=[s for s in ss if s['accepted'] is False]
        row=dict(case=c['case_id'],pair=pair,arm=c['study']['arm'],status=r['status'],error=r['error'],commands=r['commands'],accepted=r['accepted_commands'],releases=r['final_release_count'],cycles=r['final_run_cycle'],reviews=[x['review'] for x in ss[-1]['releases']],access=qualifying,cash_cents=int(ss[-1]['cash_cents']),minimum_cash_cents=min(lows),max_overdue_cents=max(overdue) if overdue else None,owned_features=ss[-1]['owned_features'],in_studio=r['outcome']['in_studio'],rejection=rejected[0] if rejected else None)
        rows.append(row)
        row['paid_searches']=sum(s['accepted'] is True and s['command_type']=='search_contracts' for s in ss)
        row['research_actions']=sum(s['accepted'] is True and s['command_type']=='research' for s in ss)
        row['final_phase']=r['outcome']['phase']
        row['game2_begin']=next((dict(cycle=s['run_cycle'],cash_cents=int(s['cash_cents'])) for s in ss if s['accepted'] is True and s['command_type']=='begin_development' and s['release_count']==1),None)
        for name in ['result.json','telemetry.json','replay.tape.json','case.variant.json','studio_checkpoint.json']:
            p=folder/name
            if p.exists():manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
out=dict(rows=rows,statuses=dict(Counter(x['status'] for x in rows)),matched_initial_groups=len(pairs),access_count=sum(x['access'] is not None for x in rows),accepted_commands=sum(x['accepted'] for x in rows))
write(HERE/'analysis.json',out);write(HERE/'evidence-manifest.json',manifest)
print(json.dumps({k:v for k,v in out.items() if k!='rows'}))
for row in rows:print(json.dumps({k:v for k,v in row.items() if k not in ['rejection','owned_features']}))
