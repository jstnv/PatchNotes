"""Summarize native controls and candidate-only finance overlays in exact cents."""
from pathlib import Path
import collections,csv,hashlib,json,statistics
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task32-v1'
traces=json.loads((OUT/'contract_traces.json').read_text());ev=json.loads((OUT/'evaluations.json').read_text())
outputs=json.loads((OUT/'overlay-results.json').read_text());assert not outputs['failures'],outputs['failures'][:3]
results={r['id']:r for r in outputs['results']};inputs={r['id']:r for r in json.loads((OUT/'overlay-inputs.json').read_text())}
native=[];native_months=[];receipts=[];audit=[]
native_routes={}
for p in sorted(OUT.glob('route_*.json')):
    if '.command.' in p.name:continue
    r=json.loads(p.read_text());l=r['final']['finance'];cash=0
    native_routes[p.stem]=r
    for tx in l['transactions']:
        assert tx['cash_before_cents']==cash
        cash+=tx['cash_delta_cents'];assert cash==tx['cash_after_cents'] and cash>=0
    assert cash==r['final']['cash_cents']
    direct=0
    for a in r['actions']:
        if a['phase'].endswith(' hand') or a['phase'].endswith(' accept'):
            b,z=a['before']['finance'],a['after']['finance'];transactions=z['transactions'][len(b['transactions']):]
            reward=sum(t['cash_delta_cents'] for t in transactions if t['kind']=='publisher_receipt')
            settled=sum(t['cash_delta_cents'] for t in transactions if t['kind']=='sales_settlement')
            rent=-sum(t['cash_delta_cents'] for t in transactions if t['kind']=='rent_payment')
            assert z['cash_cents']-b['cash_cents']==reward+settled-rent
            receipts.append(dict(route=p.stem,phase=a['phase'],cycle=z['last_cycle'],reward=reward,settled=settled,rent_paid=rent,cash=z['cash_cents']))
            direct+=reward
    for row in l['monthly_rows']:native_months.append(dict(route=p.stem,**row))
    native.append(dict(route=p.stem,band=r['band'],policy=r['policy'],seed=r['seed'],contracts=r['contract_arm'],alignment=r['alignment'],neon=r['neon_policy'],releases=len(r['releases']),reviews=' / '.join(str(x['final_review']) for x in r['releases']),scopes=' / '.join(str(x['scope']) for x in r['releases']),awareness=' / '.join(str(x['awareness']) for x in r['releases']),release_cycles=' / '.join(str(x['cycle']) for x in r['releases']),end_cycle=r['final']['cycle'],cash=cash,low_cash=min([s['cash_cents'] for s in r['live_cycles']]+[cash]),publisher_reward=direct,arrears=sum(b['unpaid_cents'] for b in l['obligations']),stop=r['stop'],blockers=json.dumps(r['blockers'][-1:]) if r['blockers'] else ''))

def native_at(r,cycle):
    snapshots=[r['initial']]+[a['after'] for a in r['actions'] if 'after' in a]
    return next(s for s in reversed(snapshots) if s['cycle']<=cycle)
native_pairs=[]
for key,a in native_routes.items():
    if a['contract_arm']!='available' or a['neon_policy']:continue
    n=native_routes[key.replace('_available_','_none_')]
    for cycle in range(0,min(a['final']['cycle'],n['final']['cycle'])+1,2):
        x,y=native_at(a,cycle),native_at(n,cycle)
        native_pairs.append(dict(route=key,cycle=cycle,available_cash=x['cash_cents'],none_cash=y['cash_cents'],difference=x['cash_cents']-y['cash_cents'],available_settled=sum(t['settled_cents'] for t in x['sales']),none_settled=sum(t['settled_cents'] for t in y['sales']),available_releases=sum(z['cycle']<=cycle for z in a['releases']),none_releases=sum(z['cycle']<=cycle for z in n['releases'])))

def latest_title_totals(rows,cycle):
    latest={}
    for row in rows:
        if row['cycle']<=cycle:latest[row['release_id']]=row
    return {k:sum(x[k] for x in latest.values()) for k in ['units','earned','settled']}
def cash_at(r,c):
    return next((x['cash'] for x in reversed(r['checkpoints']) if x['cycle']<=c),550000)
tables=[];paired=[];groups=collections.defaultdict(list)
for e in ev:
    t=traces[e['trace']];full=results[e['variants']['full']];cash=results[e['variants']['cash_only']];delay=results[e['variants']['delay_only']]
    common=min(full['cycle'],cash['cycle']);p=latest_title_totals(full['titles'],common);n=latest_title_totals(cash['titles'],common)
    pc=min(full['cycle'],cash['cycle'])+24
    future=latest_title_totals(full['conditional_24_cycle_sales_projection'],pc);future0=latest_title_totals(cash['conditional_24_cycle_sales_projection'],pc)
    row=dict(trace=e['trace'],route=t['route'],publisher=t['name'],timing=t['timing'],policy=t['policy'],seed=t['seed'],target=e['target'],cycles=t['cycles'],scope=t['scope'],focus=t['focus'],payout=e['payout'],promotion=e['promotion'],cash=full['cash'],low_cash=full['low_cash'],end_cycle=full['cycle'],blocked=bool(full['block']),block=json.dumps(full['block']),next_launch_cycle=next((v['cycle'] for v in full['launches'] if v['game']==t['trigger_game']+1),None),incremental_promotion_units=p['units']-n['units'],incremental_promotion_earned=p['earned']-n['earned'],incremental_promotion_settled=p['settled']-n['settled'],cash_only_blocked=bool(cash['block']),delay_only_blocked=bool(delay['block']),conditional_promotion_net=(future['settled']-future0['settled'] if not full['block'] and not cash['block'] else None),contract_rent_paid=sum(v['rent_paid'] for v in full['receipts']),contract_settled=sum(v['sales_settled'] for v in full['receipts']),full_target=e['full'])
    tables.append(row);groups[(t['name'],t['timing'],t['policy'],t['cycles'],e['target'])].append(row)
    if t['timing']=='early':
        match=next((z for z in ev if z['target']==e['target'] and all(traces[z['trace']][k]==t[k] for k in ['route','name','policy','seed','cycles']) and traces[z['trace']]['timing']=='after_game4'),None)
        if match:
            late=results[match['variants']['full']];c=min(full['cycle'],late['cycle'])
            paired.append(dict(route=t['route'],publisher=t['name'],policy=t['policy'],seed=t['seed'],target=e['target'],cycles=t['cycles'],common_cycle=c,early_cash=cash_at(full,c),late_cash=cash_at(late,c),early_minus_late=cash_at(full,c)-cash_at(late,c),both_complete=not full['block'] and not late['block']))
summary={str(k):dict(n=len(v),blocked=sum(x['blocked'] for x in v),full=sum(x['full_target'] for x in v),median_payout=statistics.median(x['payout'] for x in v),median_promotion=statistics.median(x['promotion'] for x in v),median_promotion_settled=statistics.median(x['incremental_promotion_settled'] for x in v),rent_paid_range=[min(x['contract_rent_paid'] for x in v),max(x['contract_rent_paid'] for x in v)]) for k,v in groups.items()}
monthly=[]
for r in outputs['results']:
    for m in r['finance_rows']:monthly.append(dict(id=r['id'],**m))
    for m in r['receipts']:receipts.append(dict(route=r['id'],phase='modeled',cycle=m['cycle'],reward=m['reward'],settled=m['sales_settled'],rent_paid=m['rent_paid'],cash=m['cash_after']))
for name,data in [('native-summary',native),('native-months',native_months),('native-common-calendar',native_pairs),('contract-receipts',receipts),('candidate-outcomes',tables),('early-late',paired),('overlay-months',monthly)]:
    with (OUT/(name+'.csv')).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
source=json.loads((OUT/'source-before.json').read_text())['files'];changed=[p for p,h in source.items() if hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
report=dict(native_routes=len(native),native_releases=sum(x['releases'] for x in native),contracts=len(traces),target_evaluations=len(tables),finance_timelines=len(results),source_changed=changed,baseline_errors=outputs['failures'],groups=summary,pair_summary={name:{'median':statistics.median(x['early_minus_late'] for x in paired if x['publisher']==name and x['both_complete']),'range':[min(x['early_minus_late'] for x in paired if x['publisher']==name and x['both_complete']),max(x['early_minus_late'] for x in paired if x['publisher']==name and x['both_complete'])]} for name in ['crown','neon']})
(OUT/'summary.json').write_text(json.dumps(report,indent=2));assert not changed
print(json.dumps({k:v for k,v in report.items() if k!='groups'},indent=2))
