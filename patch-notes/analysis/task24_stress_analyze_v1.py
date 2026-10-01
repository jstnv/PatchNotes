"""Audit calendar/ownership/release chronology of native stress traces."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
out=root/'design-logs/task24-v1'
summary={}
for arm in ['priority','empty','repeat']:
    path=out/f'stress_{arm}.json'
    if arm=='empty' and not path.exists(): path=out/'stress_empty_checkpoint240.json'
    if arm=='repeat' and (out/'stress_repeat_independent.json').exists(): path=out/'stress_repeat_independent.json'
    if arm=='repeat' and not path.exists(): path=out/'stress_repeat_censored981.json'
    if not path.exists(): continue
    row=json.loads(path.read_text(encoding='utf-8'))['rows'][0]
    assert row['valid'] and not row['errors']
    prefix=bool(row.get('completed_prefix_validated'))
    assert row['final']['cycle']>= (240 if arm=='empty' else 981 if prefix else 1104)
    releases=row['releases']; visits=row['studio_visits']; cycles=row['cycles']
    assert len({r['release_id'] for r in releases})==len(releases)
    assert all(r['committed'] and r['required_scope']==30 for r in releases)
    assert releases[0]['scope']==20 and not releases[0]['sidestreet_offer_available']
    assert all(s['year']==1980+s['cycle']//24 for s in visits+cycles)
    assert all(s['cash_cents']>=0 and s['unpaid_cents']>=0 for s in visits+cycles)
    assert all(s['is_studio'] for s in visits)
    assert [s['cycle'] for s in cycles]==list(range(1,row['final']['cycle']+1))
    assert all(p['success'] for p in (row['purchases'] or []))
    # Discount familiarity must arise from successful project resolutions only;
    # no extra credit is earned by priority cycling or empty releases.
    if arm=='priority':
        assert sum(r['meets_required_scope'] for r in releases)==1
        assert len(row['owned_ids'])==27
        qualifying=next(s for s in visits if s['reason']=='release_2')
        assert all(s['familiarity']==qualifying['familiarity'] for s in visits if s['cycle']>=qualifying['cycle'])
        assert [s['cycle'] for s in visits if s['reason'].startswith('release_')][-6:]==[96,240,480,720,960,1104]
    if arm=='empty':
        assert sum(r['meets_required_scope'] for r in releases)==0
        assert all(r['scope']==0 and not r['sidestreet_offer_available'] for r in releases[1:])
        assert len(row['owned_ids'])==16
        start=row['ironclad']['after_dismiss']
        assert row['final']['cash_cents']-start['cash_cents']==row['final']['sales'][0]['settled_cents']-start['sales'][0]['settled_cents']
    if arm=='repeat':
        assert all(r['meets_required_scope'] for r in releases[1:])
    summary[arm]={
        'source_trace':str(path.relative_to(root)),
        'independent_native_seeds':1,
        'requested_cycle':1104,'completed_cycle':row['final']['cycle'],
        'censored_at_completed_horizon':row['final']['cycle']<1104,
        'full_trace_available':not prefix,
        'valid_completed_evidence':True,'full_requested_horizon_met':row['final']['cycle']>=1104, 'first_game':releases[0], 'final':row['final'],
        'release_count':len(releases), 'qualifying_release_count':sum(r['meets_required_scope'] for r in releases),
        'owned_count':len(row['owned_ids']), 'purchase_count':len(row['purchases']) if not prefix else None,
        'action_count':len(row['actions']) if not prefix else None, 'full_month_boundaries':sum(s['cycle']%2==0 for s in cycles),
        'completed_contracts':sum(1 for k,v in row.items() if isinstance(v,dict) and 'completion' in v) if not prefix else None,
        'minimum_cash_cents':min(s['cash_cents'] for s in visits+cycles),
        'first_block':row['blockers'][0] if row['blockers'] else None,
        'checkpoint_studios':{
            str(c):next(({k:s[k] for k in ['cycle','year','release_count','qualifying_count','cash_cents','unpaid_cents','reason']} for s in visits if s['cycle']>=c),None)
            for c in [96,240,480,720,960,1104]},
        'review_range':[min(r['final_review'] for r in releases[1:]),max(r['final_review'] for r in releases[1:])],
        'scope_range':[min(r['scope'] for r in releases[1:]),max(r['scope'] for r in releases[1:])],
    }
    if arm=='empty':
        summary[arm]['empty_sequence_start']=start
        summary[arm]['empty_sequence_cycles']=row['final']['cycle']-start['cycle']
        summary[arm]['empty_sequence_releases']=len(releases)-1
        summary[arm]['empty_sequence_cash_gain_cents']=row['final']['cash_cents']-start['cash_cents']
        summary[arm]['remaining_game1_settlement_cents']=row['released_sales_records'][0]['settled_cents']-start['sales'][0]['settled_cents']
        summary[arm]['empty_releases_settled_cents']=sum(r['settled_cents'] for r in row['released_sales_records'][1:])
        summary[arm]['empty_releases_entitlement_cents']=sum(r['entitlement_cents'] for r in row['released_sales_records'][1:])
(out/'stress-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
