"""Audit native journals, finite card access, source stability and matched prefixes."""
from collections import Counter
from pathlib import Path
import gzip
import hashlib
import json
import sys

OUT=Path(__file__).resolve().parent
REPO=OUT.parents[3]
meta=json.loads((OUT/'source-manifest.json').read_text())
plan=json.loads((OUT/'manifest.json').read_text())
project=Path(meta['project'])
raw_dir=project.parent/'raw'
partial='--partial' in sys.argv
results=[json.loads(p.read_text()) for p in raw_dir.glob('*.result.json')] if partial else json.loads((OUT/'run-index.json').read_text())
results=[r for r in results if r.get('harness_sha256')==plan['harness_sha256']]
checks=Counter()
failures=[]

def check(condition,label,key=''):
    checks[label]+=1
    if not condition: failures.append((key,label))

def sha(raw): return hashlib.sha256(raw).hexdigest()

if not partial:
    check(len(results)==len(plan['jobs'])==556,'matrix count')
    check({r['job']['key'] for r in results}=={j['key'] for j in plan['jobs']},'matrix identities')
for name,field in [('driver.gd','driver_sha256'),('trial_run_state.gd','subclass_sha256'),('task29_base.gd','base_sha256')]:
    check(sha((OUT/name).read_bytes())==plan[field]==sha((project/'analysis/task2_analysis'/name).read_bytes()),'harness identity',name)
for item in meta['files']:
    check(sha((REPO/item['path']).read_bytes())==item['checkout_sha256'],'shared source unchanged',item['path'])
    check(sha((project.parent/item['path']).read_bytes())==item['archive_sha256'],'private source unchanged',item['path'])

definitions={x['id']:x for x in json.loads((project/'data/card_ledger.json').read_text())}
definitions.update({x['id']:x for x in json.loads((project/'data/feature_store_ledger.json').read_text())})
definitions.update({'sub_areas':dict(type='feature',phase='alpha',renewable=False),'background_music':dict(type='feature',phase='alpha',renewable=False)})
later={x['id'] for x in json.loads((project/'data/feature_store_ledger.json').read_text())}|{'sub_areas','background_music'}
traces={}
totals=Counter()
for result in results:
    j=result['job']; key=j['key']
    raw=gzip.decompress((raw_dir/f'{key}.json.gz').read_bytes())
    compact=gzip.decompress((OUT/'traces'/f'{key}.json.gz').read_bytes())
    check(sha(raw)==result['raw_sha256'] and sha(compact)==result['compact_sha256'],'trace hashes',key)
    d=json.loads(compact); traces[key]=d
    check(result['exit']==0 and result['valid'] and not result['errors'] and not d['discrepancies'] and not d['errors'],'native route valid',key)
    check(result['harness_sha256']==plan['harness_sha256'],'run harness',key)
    check(d['initial']['cash_cents']==(550000 if j['startup']=='legacy' else 570000),'genuine initial cash',key)
    f=d['final_finance_snapshot']; report=d['final_finance_report']
    check(f['cash_cents']==d['final']['cash_cents']==report['cash_cents'] and f['last_cycle']==d['final']['cycle'],'final finance header',key)
    check(d['ledger_checks']>0 and d['row_checks']>0,'native per-title row checks',key)
    totals['native_title_checks']+=d['ledger_checks']; totals['native_row_checks']+=d['row_checks']
    balance=0
    for n,t in enumerate(f['transactions'],1):
        check(t['sequence']==n and t['cash_before_cents']==balance,'journal sequence and opening',key)
        balance+=t['cash_delta_cents']
        check(balance==t['cash_after_cents'] and balance>=0,'exact journal cash',key)
    check(balance==f['cash_cents'],'journal closing cash',key)
    starting=[t for t in f['transactions'] if t['cycle']==0 and t['cash_delta_cents']>0]
    check(sum(t['cash_delta_cents'] for t in starting)==d['initial']['cash_cents'] and len(starting)==(1 if j['startup']=='legacy' else 2),'genuine funding provenance',key)
    check([a['cycle'] for a in f['actions'] if a['productive']]==list(range(1,f['last_cycle']+1)),'productive calendar identity',key)
    check(sum(b['due_cents'] for b in f['obligations'])==50000*(f['last_cycle']//2),'native rent accrual',key)
    for b in f['obligations']:
        check(b['expense_type']=='rent' and b['due_cents']==b['paid_cents']+b['unpaid_cents'] and sum(p['cents'] for p in b['payments'])==b['paid_cents'],'typed bill conservation',key)
    check(sum(b['unpaid_cents'] for b in f['obligations'])==report['unpaid_rent_cents']==d['final']['unpaid_rent_cents'],'arrears identity',key)
    for row in f['monthly_rows']:
        check(row['net_profit_cents']==row['operating_revenue_cents']-row['operating_expenses_cents'],'monthly profit identity',key)
        check(row['closing_cash_cents']-row['opening_cash_cents']==row['cash_change_cents'],'monthly cash identity',key)
    check(sum(row['sales_settled_cents'] for row in f['monthly_rows'])==sum(s['settled_cents'] for s in d['sales_records']),'settled title finance identity',key)
    actions_by_cycle={a['cycle']:a for a in f['actions'] if a['productive']}
    played=set()
    for a in d['actions']:
        phase=a['phase']
        if phase in ('design','alpha'):
            check(len(a['draw'])==7,'seven native candidates',key)
            if 'after' not in a: continue
            success=a['after']['cycle']==a['before']['cycle']+1
            if not success: continue
            expected=0
            for card_id in a.get('selected',[]):
                entry=definitions[card_id]
                if entry['type']=='feature':
                    identity=(a['game'],card_id)
                    check(identity not in played,'finite Feature commit once',key)
                    played.add(identity)
                    if card_id not in later:
                        expected+=1000*(entry['primary_value']+entry['secondary_value']+2*entry['scope'])
                    if card_id==('sub_areas' if j['store']=='sub_areas' else 'background_music'):
                        expected+=j['fee']
            check(a['cost_cents']==expected,'native hand and trial fee cost',key)
            check(actions_by_cycle[a['after']['cycle']]['direct_delta']==-expected,'native atomic hand debit',key)
            totals['committed_production_hands']+=1
            totals['candidate_plays']+=sum(x in ('sub_areas','background_music') for x in a.get('selected',[]))
            totals['candidate_fee_cents']+=j['fee']*sum(x==('sub_areas' if j['store']=='sub_areas' else 'background_music') for x in a.get('selected',[]))
        elif ' hand' in phase:
            ids=a.get('draw',[])+a.get('selected',[])+[r.get('to','') for r in a.get('redraws',[])]
            check(not {'sub_areas','background_music'}.intersection(ids),'candidate Contract exclusion',key)
        elif phase=='store':
            if a['success']:
                totals['successful_store_actions']+=1
                check(a['after']['cycle']==a['before']['cycle']+1,'Store productive cost',key)
                check(actions_by_cycle[a['after']['cycle']]['direct_delta']==-a['quote']['price_cents'],'Store exact direct quote',key)
            else:
                totals['rejected_store_actions']+=1
                check(a['rejection_unchanged'] and a['before']==a['after'],'Store rejection rollback',key)
    for purchase in d['purchases']:
        if purchase.get('stage')=='timing decision':
            if purchase['eligible'] and j['timing']=='buffer':
                check(purchase['cash_cents']>=purchase['chain_cost_cents']+purchase['reserve_cents'] and purchase['unpaid_rent_cents']==0,'reserve uses settled cash',key)
            if purchase['eligible'] and j['timing']=='stronger_settled':
                check(purchase['qualifying_release_settled_cents']>0 and purchase['stronger_review'],'deferral uses actual qualifying settlement',key)
    for a in d['actions']:
        for candidate in ('sub_areas','background_music'):
            if a['phase'] in ('design','alpha') and candidate in a.get('selected',[]) and 'after' in a and a['after']['cycle']==a['before']['cycle']+1:
                check(any(p.get('success') and p['id']==candidate and p['after']['cycle']<a['before']['cycle'] for p in d['purchases']),'played after legal purchase',key)
                check(any(p['phase']=='predevelopment' and p.get('game')==a['game'] and candidate in p.get('eligible_supply',[]) for p in d['actions']),'next-project candidate supply',key)

def signature(d,limit=None):
    return [(r['cycle'],r['final_review'],r['scope'],r['cash_cents']) for r in d['releases'][:limit]]

for result in results:
    j=result['job']; key=j['key']; d=traces[key]
    control_key=f"{j['band']}_{j['specialty']}_{j['seed']}_{j['policy']}_{j['startup']}_none_none_none_0"
    if control_key not in traces: continue
    c=traces[control_key]
    buys=[p for p in d['purchases'] if p.get('success')]
    prefix=min((p['game'] for p in buys),default=len(d['releases']))
    check(signature(d,prefix)==signature(c,prefix),'matched pre-purchase releases',key)
    if not buys:
        check(signature(d)==signature(c) and d['final']['cash_cents']==c['final']['cash_cents'] and d['stop']==c['stop'],'abstainer equals native control',key)
    if j['store']=='none' and j['band']=='early' and j['specialty']=='strategy':
        old=REPO/'docs/codex/threads/feature-store/sim-v8'/f"route_early_strategy_{j['policy']}_none_none_none_{j['seed']}_0_{j['startup']}.json.gz"
        prior=json.loads(gzip.decompress(old.read_bytes()))
        check(signature(d,len(prior['releases']))==signature(prior),'prior pilot control extension',key)

result=dict(route_count=len(results),checks=dict(checks),check_total=sum(checks.values()),failures=failures,totals=dict(totals))
(OUT/('partial-audit.json' if partial else 'audit-results.json')).write_text(json.dumps(result,indent=2))
print(json.dumps(result if failures else {k:v for k,v in result.items() if k!='checks'},indent=2))
raise SystemExit(bool(failures))
