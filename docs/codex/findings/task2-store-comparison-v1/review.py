"""Print bounded review tables from the final paired evidence, keeping strata."""
from collections import defaultdict
from pathlib import Path
import json
import statistics

out = Path(__file__).resolve().parent
rows = json.loads((out / 'paired-routes.json').read_text())
groups = defaultdict(list)
for row in rows:
    groups[(row['band'], row['specialty'], row['policy'], row['startup'], row['store'], row['parent'], row['fee'])].append(row)

def counts(group):
    return dict(n=len(group), buyers=sum(r['bought'] for r in group),
        played=sum(r['bought'] and bool(r['play_count']) for r in group),
        played_within_two=sum(r['played_within_two'] for r in group),
        clean=sum(r['clean_played_buyer'] for r in group),
        partial=sum(r['partial_chain'] for r in group),
        added_arrears=sum(bool(r['extra_arrears_peak_cents'] or r['extra_end_arrears_cents']) for r in group),
        earlier_block=sum(r['earlier_block'] for r in group),
        six_releases=sum(r['release_count'] == 6 for r in group),
        followthrough=sum(r['stop'] == 'six releases and subsequent earning actions' for r in group))

for fields, group in sorted(groups.items()):
    if fields[4] == 'none':
        print(json.dumps(dict(stratum=fields, counts=counts(group))))
        continue
    print(json.dumps(dict(stratum=fields,
        timings={t: counts([r for r in group if r['timing'] == t]) for t in sorted({r['timing'] for r in group})})))

fees = json.loads((out / 'fee-pairs.json').read_text())
print('FEES', json.dumps(dict(n=len(fees), paid_plays=sum(f['actual_fee_cents'] // f['fee_cents'] for f in fees),
    actual_fee_cents=sum(f['actual_fee_cents'] for f in fees),
    production_selection_sequence_changed=sum(f['production_selection_sequence_changed'] for f in fees),
    purchase_sequence_changed=sum(f['purchase_sequence_changed'] for f in fees),
    fewer_releases=sum(f['paid_release_count'] < f['zero_release_count'] for f in fees))))

for store in ('sub_areas', 'background'):
    for fee in sorted({r['fee'] for r in rows if r['store'] == store}):
        eligible = [r for r in rows if r['band'] == 'early' and r['store'] == store and r['parent'] == 'none' and r['fee'] == fee and r['bought']]
        positive = [r for r in eligible if r.get('cash_delta_at_game5_cycle_cents') is not None and r['cash_delta_at_game5_cycle_cents'] >= 0]
        played_two = [r for r in eligible if any(r['buy_game'] < game <= r['buy_game'] + 2 for game in r['play_games'])]
        age4 = [r for r in eligible if r.get('game5_settled_age4_delta_cents') is not None]
        print('BUYERS', json.dumps(dict(store=store, fee=fee, n=len(eligible), played_within_two=len(played_two),
            observed_game5_calendar_cash=sum(r.get('cash_delta_at_game5_cycle_cents') is not None for r in eligible),
            nonnegative_game5_calendar_cash=len(positive), observed_age4=len(age4),
            positive_age4_sales=sum(r['game5_settled_age4_delta_cents'] > 0 for r in age4),
            median_age4_delta_cents=statistics.median(r['game5_settled_age4_delta_cents'] for r in age4) if age4 else None)))

examples = [r for r in rows if r['band'] == 'early' and r['seed'] == 1104 and r['startup'] == 'trait' and r['store'] in ('sub_areas', 'background') and r['timing'] == 'stronger_settled' and r['parent'] == 'none']
for row in examples:
    print('EXAMPLE', json.dumps(row))

lines=['# Complete comparison count tables', '',
    'Generated from the final paired rows. Cells are **buyers / played within two projects / clean played buyers**. Each row states its seed count; ordinary/synergy and genuine startup ledgers remain separate. Clean is a relative access/downside test, not cash payback.', '']
for band,store,parent,fee in sorted({(r['band'],r['store'],r['parent'],r['fee']) for r in rows if r['store']!='none'}):
    lines += [f'## {band} / {store} / parent {parent} / fee {fee} cents', '',
        '| Specialty | Policy | Startup | Seeds per timing | No-buy six releases | Immediate B/P/C | Reserve B/P/C | Stronger-settled B/P/C |',
        '|---|---|---|---:|---:|---:|---:|---:|']
    strata=sorted({(r['specialty'],r['policy'],r['startup']) for r in rows if (r['band'],r['store'],r['parent'],r['fee'])==(band,store,parent,fee)})
    for specialty,policy,startup in strata:
        subset=[r for r in rows if (r['band'],r['specialty'],r['policy'],r['startup'],r['store'],r['parent'],r['fee'])==(band,specialty,policy,startup,store,parent,fee)]
        seeds={r['seed'] for r in subset}
        control=[r for r in rows if r['band']==band and r['specialty']==specialty and r['policy']==policy and r['startup']==startup and r['store']=='none' and r['seed'] in seeds]
        cells=[]
        for timing in ('immediate','buffer','stronger_settled'):
            selected=[r for r in subset if r['timing']==timing]
            cells.append(f"{sum(r['bought'] for r in selected)}/{sum(r['played_within_two'] for r in selected)}/{sum(r['clean_played_buyer'] for r in selected)}" if selected else '—')
        lines.append(f"| {specialty} | {policy} | {startup} | {len(seeds)} | {sum(r['release_count']==6 for r in control)}/{len(control)} | {' | '.join(cells)} |")
    lines.append('')
(out/'review-tables.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')

