"""Produce paired purchase/access, timing, settlement and downside findings."""
from collections import defaultdict
from pathlib import Path
import csv
import gzip
import json
import statistics

OUT=Path(__file__).resolve().parent
index=json.loads((OUT/'run-index.json').read_text())
traces={r['job']['key']:json.loads(gzip.decompress((OUT/'traces'/(r['job']['key']+'.json.gz')).read_bytes())) for r in index}

def states(d):
    result={s['cycle']:s for s in d['live_cycles']}
    result[d['initial']['cycle']]=d['initial']
    for a in d['actions']:
        if 'after' in a: result[a['after']['cycle']]=a['after']
    result[d['final']['cycle']]=d['final']
    return result

def title_sales(s,title):
    return next((x['settled_cents'] for x in s['sales'] if x['release_id']==title),None) if s else None

def release_at(d,n): return d['releases'][n-1] if len(d['releases'])>=n else None

def released_by(d,cycle):
    return [dict(game=n,release_id=r['release_id'],cycle=r['cycle'],review=r['final_review'],scope=r['scope'],required_scope=r['required_scope'])
        for n,r in enumerate(d['releases'],1) if r['cycle']<=cycle]

def low_by(d,cycle):
    return min(t['cash_after_cents'] for t in d['final_finance_snapshot']['transactions'] if t['cycle']<=cycle)

rows=[]; checkpoints=[]; title_ages=[]; all_states={k:states(d) for k,d in traces.items()}
for record in index:
    j=record['job']; key=j['key']; d=traces[key]
    ck=f"{j['band']}_{j['specialty']}_{j['seed']}_{j['policy']}_{j['startup']}_none_none_none_0"
    c=traces[ck]; ds=all_states[key]; cs=all_states[ck]
    candidate='sub_areas' if j['store']=='sub_areas' else 'background_music' if j['store']=='background' else 'recorded_sounds' if j['store']=='existing_sound' else 'colored_text' if j['store']=='existing_value' else ''
    buys=[p for p in d['purchases'] if p.get('success') and p['id']==candidate]
    parent_buys=[p for p in d['purchases'] if p.get('success') and p['kind']=='required Primitive parent']
    plays=[a for a in d['actions'] if a['phase'] in ('design','alpha') and candidate in a.get('selected',[]) and 'after' in a and a['after']['cycle']==a['before']['cycle']+1]
    supply=[a['game'] for a in d['actions'] if candidate and candidate in a.get('eligible_supply',[])]
    draws=[a['game'] for a in d['actions'] if a['phase'] in ('design','alpha') and (candidate in a.get('draw',[]) or candidate in [r.get('to') for r in a.get('redraws',[])])]
    shared=sorted(ds.keys()&cs.keys())
    last=shared[-1]
    extra_peak=max((max(0,ds[n]['unpaid_rent_cents']-cs[n]['unpaid_rent_cents']) for n in shared),default=0)
    extra_end=max(0,d['final']['unpaid_rent_cents']-c['final']['unpaid_rent_cents'])
    shorter=len(d['releases'])<len(c['releases'])
    ended_earlier=d['final']['cycle']<c['final']['cycle'] and d['stop']!='six releases and subsequent earning actions'
    failed_followthrough=c['stop']=='six releases and subsequent earning actions' and d['stop']!='six releases and subsequent earning actions'
    first_block_cycle=d['blockers'][0]['state']['cycle'] if d['blockers'] else None
    control_first_block_cycle=c['blockers'][0]['state']['cycle'] if c['blockers'] else None
    earlier_action_block=first_block_cycle is not None and (control_first_block_cycle is None or first_block_cycle<control_first_block_cycle)
    within_two=bool(buys and any(buys[0]['game']<a['game']<=buys[0]['game']+2 for a in plays))
    clean=bool(within_two and not extra_peak and not extra_end and not shorter and not ended_earlier and not earlier_action_block and not failed_followthrough)
    g5,c5=release_at(d,5),release_at(c,5)
    g6,c6=release_at(d,6),release_at(c,6)
    row=dict(j,candidate=candidate,release_count=len(d['releases']),control_release_count=len(c['releases']),stop=d['stop'],
      final_cycle=d['final']['cycle'],final_cash_cents=d['final']['cash_cents'],final_arrears_cents=d['final']['unpaid_rent_cents'],final_credit=d['final']['credit'],
      bought=bool(buys),buy_game=buys[0]['game'] if buys else None,buy_cycle=buys[0]['after']['cycle'] if buys else None,
      purchase_cents=sum(p['quote']['price_cents'] for p in buys+parent_buys),parent_purchased=bool(parent_buys),partial_chain=bool(parent_buys and not buys),
      supply_games=sorted(set(supply)),draw_games=sorted(set(draws)),play_games=[a['game'] for a in plays],play_count=len(plays),
      played_within_two=within_two,clean_played_buyer=clean,extra_arrears_peak_cents=extra_peak,extra_end_arrears_cents=extra_end,failed_followthrough_vs_control=failed_followthrough,earlier_block=shorter or ended_earlier or earlier_action_block,
      first_block_cycle=first_block_cycle,control_first_block_cycle=control_first_block_cycle,earlier_productive_block=earlier_action_block,
      last_common_cycle=last,cash_delta_last_common_cents=ds[last]['cash_cents']-cs[last]['cash_cents'],
      game5_review_delta=(g5['final_review']-c5['final_review']) if g5 and c5 else None,
      game5_milestone_cash_delta_cents=(g5['cash_cents']-c5['cash_cents']) if g5 and c5 else None,
      cash_delta_at_game5_cycle_cents=(ds[g5['cycle']]['cash_cents']-cs[g5['cycle']]['cash_cents']) if g5 and g5['cycle'] in ds and g5['cycle'] in cs else None,
      game6_review_delta=(g6['final_review']-c6['final_review']) if g6 and c6 else None,
      game6_milestone_cash_delta_cents=(g6['cash_cents']-c6['cash_cents']) if g6 and c6 else None,
      development_cycles=sum(r['development_cycles'] for r in d['releases']),
      productive_store_cycles=sum(a['success'] for a in d['actions'] if a['phase']=='store'),
      productive_contract_cycles=sum(' hand' in a['phase'] and a.get('success',False) for a in d['actions']),
      curtailed_projects=sum(a.get('budget_curtailed',False) for a in d['actions'] if a['phase']=='launch'),
      cash_low_cents=min(t['cash_after_cents'] for t in d['final_finance_snapshot']['transactions']),peak_arrears_cents=max(s['unpaid_rent_cents'] for s in ds.values()),
      first_blocker=d['blockers'][0] if d['blockers'] else None)
    for cycle in (24,36,48,60,72,84,96,108,120):
        a,b=ds.get(cycle),cs.get(cycle)
        checkpoints.append(dict(key=key,cycle=cycle,observed=bool(a and b),cash_delta_cents=a['cash_cents']-b['cash_cents'] if a and b else None,
          arrears_delta_cents=a['unpaid_rent_cents']-b['unpaid_rent_cents'] if a and b else None,credit=a['credit'] if a else None,
          control_credit=b['credit'] if b else None,
          cash_cents=a['cash_cents'] if a else None,control_cash_cents=b['cash_cents'] if b else None,
          cash_low_cents=low_by(d,cycle) if a else None,control_cash_low_cents=low_by(c,cycle) if b else None,
          unpaid_rent_cents=a['unpaid_rent_cents'] if a else None,control_unpaid_rent_cents=b['unpaid_rent_cents'] if b else None,
          paid_rent_cents=50000*(cycle//2)-a['unpaid_rent_cents'] if a else None,
          control_paid_rent_cents=50000*(cycle//2)-b['unpaid_rent_cents'] if b else None,
          releases=released_by(d,cycle) if a else None,control_releases=released_by(c,cycle) if b else None,
          earned_cents=sum(s['entitlement_cents'] for s in a['sales']) if a else None,settled_cents=sum(s['settled_cents'] for s in a['sales']) if a else None,
          control_earned_cents=sum(s['entitlement_cents'] for s in b['sales']) if b else None,
          control_settled_cents=sum(s['settled_cents'] for s in b['sales']) if b else None))
    for n in range(1,7):
        ar,br=release_at(d,n),release_at(c,n)
        if not ar or not br: continue
        for age in (2,4,8):
            av,bv=ds.get(ar['cycle']+age),cs.get(br['cycle']+age)
            actual,baseline=title_sales(av,ar['release_id']),title_sales(bv,br['release_id'])
            if (av is not None and actual is None) or (bv is not None and baseline is None):
                raise ValueError(f'Observed state lacks its released title: {key} game {n} age {age}')
            title_ages.append(dict(key=key,game=n,age_cycles=age,observed=actual is not None and baseline is not None,
              settled_cents=actual,control_settled_cents=baseline,delta_cents=actual-baseline if actual is not None and baseline is not None else None))
            if n==5 and age==4:
                row['game5_settled_age4_cents']=actual
                row['control_game5_settled_age4_cents']=baseline
                row['game5_settled_age4_delta_cents']=actual-baseline if actual is not None and baseline is not None else None
    rows.append(row)

groups=defaultdict(list)
for r in rows:
    groups[(r['band'],r['specialty'],r['policy'],r['startup'],r['store'],r['timing'],r['parent'],r['fee'])].append(r)
aggregates=[]
for fields,group in sorted(groups.items()):
    agg=dict(zip(('band','specialty','policy','startup','store','timing','parent','fee'),fields))
    agg.update(routes=len(group),buyers=sum(r['bought'] for r in group),played_buyers=sum(bool(r['bought'] and r['play_count']) for r in group),
      clean_played_buyers=sum(r['clean_played_buyer'] for r in group),extra_arrears=sum(bool(r['extra_arrears_peak_cents']) for r in group),
      two_project_played_buyers=sum(r['played_within_two'] for r in group),
      earlier_block=sum(r['earlier_block'] for r in group),partial_chains=sum(r['partial_chain'] for r in group),
      extra_end_arrears=sum(bool(r['extra_end_arrears_cents']) for r in group),relative_followthrough_failure=sum(r['failed_followthrough_vs_control'] for r in group),
      six_releases=sum(r['release_count']==6 for r in group),buy_after_game1=sum(r['buy_game']==1 for r in group),
      buy_after_game2=sum(r['buy_game']==2 for r in group),buy_after_game3=sum(r['buy_game']==3 for r in group),buy_after_game4=sum(r['buy_game']==4 for r in group))
    for field in ('game5_review_delta','game5_milestone_cash_delta_cents','cash_delta_at_game5_cycle_cents','game5_settled_age4_delta_cents','game6_milestone_cash_delta_cents','cash_delta_last_common_cents'):
        observed=[r.get(field) for r in group if r['bought'] and r.get(field) is not None]
        agg[field+'_n']=len(observed); agg[field+'_median']=statistics.median(observed) if observed else None
    aggregates.append(agg)

def write_csv(name,data):
    keys=list(dict.fromkeys(k for r in data for k in r))
    with (OUT/name).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=keys);w.writeheader()
        for r in data: w.writerow({k:json.dumps(v,separators=(',',':')) if isinstance(v,(list,dict)) else v for k,v in r.items()})

write_csv('paired-routes.csv',rows)
write_csv('calendar-checkpoints.csv',checkpoints)
write_csv('title-age-sales.csv',title_ages)
(OUT/'aggregate.json').write_text(json.dumps(aggregates,indent=2))
(OUT/'paired-routes.json').write_text(json.dumps(rows,indent=2))
fee_pairs=[]
by_key={r['key']:r for r in rows}
for r in rows:
    if not r['fee']: continue
    d=traces[r['key']]
    zero_key=r['key'].rsplit('_',1)[0]+'_0'
    z=traces[zero_key]
    zr=by_key[zero_key]
    def hands(x):
        return [(a['game'],a['phase'],a.get('selected',[])) for a in x['actions'] if a['phase'] in ('design','alpha') and 'after' in a and a['after']['cycle']==a['before']['cycle']+1]
    def purchases(x):
        return [(a['id'],a['game'],a['after']['cycle']) for a in x['purchases'] if a.get('success')]
    shared=sorted(all_states[r['key']].keys()&all_states[zero_key].keys())
    cycle=shared[-1]
    fee_pairs.append(dict(key=r['key'],zero_fee_key=zero_key,fee_cents=r['fee'],actual_fee_cents=r['fee']*r['play_count'],
      production_selection_sequence_changed=hands(d)!=hands(z),purchase_sequence_changed=purchases(d)!=purchases(z),
      paid_clean=r['clean_played_buyer'],zero_clean=zr['clean_played_buyer'],
      paid_game5_calendar_cash_delta_cents=r['cash_delta_at_game5_cycle_cents'],zero_game5_calendar_cash_delta_cents=zr['cash_delta_at_game5_cycle_cents'],
      paid_game5_age4_sales_delta_cents=r.get('game5_settled_age4_delta_cents'),zero_game5_age4_sales_delta_cents=zr.get('game5_settled_age4_delta_cents'),
      paid_release_count=len(d['releases']),zero_release_count=len(z['releases']),common_cycle=cycle,
      cash_delta_cents=all_states[r['key']][cycle]['cash_cents']-all_states[zero_key][cycle]['cash_cents']))
(OUT/'fee-pairs.json').write_text(json.dumps(fee_pairs,indent=2))
print(json.dumps(dict(routes=len(rows),aggregate_groups=len(aggregates),buyers=sum(r['bought'] for r in rows),clean_played_buyers=sum(r['clean_played_buyer'] for r in rows),partial_chains=sum(r['partial_chain'] for r in rows),six_releases=sum(r['release_count']==6 for r in rows),observed_calendar_pairs=sum(r['observed'] for r in checkpoints),observed_equal_age_sales=sum(r['observed'] for r in title_ages)),indent=2))
