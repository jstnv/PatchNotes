"""Independent exact-integer audit of the predeclared target sensitivity."""
from collections import Counter
from pathlib import Path
import csv
import hashlib
import json

HERE = Path(__file__).resolve().parent
V3 = HERE.parent / 'sim-v3'
PROJECT = HERE / 'project'
ROUTES = (
    ('crown', 'legacy', 'route-legacy-ordinary-0-0.bin', '83e8df43cb78f9913b634c67c55c71cfd697a3ea80e8af4b989b6556644c776c'),
    ('crown', 'trait', 'route-trait-ordinary-0-0.bin', '0af2ded18f1f787fefc7ec2a0472a58dcd1c516fb2addf2acc8a76e7194ec057'),
    ('neon', 'legacy', 'route-legacy-ordinary-0-1.bin', '5c19295b148c3aef24377423d36f24d24f06d4c0849ec94630d76c12ff415a33'),
    ('neon', 'trait', 'route-trait-ordinary-0-1.bin', '486e0f9584b862e56f4c6c382b87b904f9e9083e1c03d9229db98372110eb431'),
)
SOURCE_HEAD = 'b84d1a5b4e4957b044b4b52c41553cf611aff3ae'
BASE_SHA = 'e6e163d5d9ef42d393b5563febdb8c9006785ac43954917993a3f254aa010970'
MANIFEST_SHA = '2d13075a1093810b4e254294fcf3557e921a2866b98436fdd1010957798842e2'

checks = 0

def check(condition, message):
    global checks
    checks += 1
    if not condition:
        raise AssertionError(message)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def fraction(pub, scope, half, target, focus):
    if pub == 'crown':
        weights = [min(x, 8) for x in half]
        numerator = 18 * min(scope, target) + target * (sum(weights) + 2 * min(weights))
        denominator = 66 * target
    else:
        numerator = 20 * min(scope, target) + 3 * min(half[focus], 18) * target
        numerator += target * sum(min(half[i], 4) for i in range(4) if i != focus)
        denominator = 86 * target
    return [max(0, min(numerator, denominator)), denominator]

def audit_arm(a, pub, startup, target, seed):
    check(a['publisher'] == pub and a['target'] == target and a['seed'] == seed, 'Arm identity')
    check(a['advance'] == 0 and a['policy'] == 'low_scope', 'Predeclared policy and advance')
    check(a['source_checkpoint'].startswith('release'), 'Native release checkpoint')
    check(a['completed'] and len(a['hands']) == 2, 'Two completed native hands')
    check(len(a['rows']) == 3 and [r['phase'] for r in a['rows']] == ['accept','hand1','hand2'], 'Accepted action rows')
    check(a['final']['cycle'] == a['initial']['cycle'] + 2, 'Two productive cycles')
    check(a['final']['cash'] == a['ledger']['cash_cents'], 'Final cash equals ledger')
    check(a['final']['arrears'] == 0, 'No final arrears in this stress route')
    for hand in a['hands']:
        check(hand['success'], 'Native hand accepted')
        check(len(hand['pool']) == 7 and len(hand['selected']) == 4, 'Seven shown and four selected')
        check(not (Counter(hand['selected']) - Counter(hand['pool'])), 'Selected cards from native pool')
        check(hand['scope_if_committed'] > 0 and sum(hand['half_if_committed']) > 0, 'Positive Scope and Core')
    owned = set(a['owned_primitive'])
    first_features = owned.intersection(a['hands'][0]['selected'])
    second_features = owned.intersection(a['hands'][1]['selected'])
    check(not first_features.intersection(second_features), 'Finite owned Features not replayed')
    check(a['hands'][0]['completion_receipt'] == 0, 'No first-hand candidate payout')
    scope = a['hands'][-1]['scope_if_committed']
    half = a['hands'][-1]['half_if_committed']
    check(scope < target, 'Predeclared low-Scope case actually binds')
    n,d = fraction(pub,scope,half,target,a['focus'])
    check(a['fraction'] == [n,d], 'Exact independent rational fraction')
    cap,promocap = (192000,12) if pub == 'crown' else (156000,20)
    payout = cap*n//d
    promotion = promocap*n//d
    check(a['direct_cash'] == payout and a['hands'][-1]['completion_receipt'] == payout, 'Exact-cent payout')
    check(a['promotion_conditional'] == promotion, 'Whole conditional Promotion')
    actions = a['ledger']['actions']
    check([x['source_id'] for x in actions[-3:]] == ['task34_candidate_acceptance','task34_candidate_hand','task34_candidate_hand'], 'Three candidate actions')
    check([x['direct_delta'] for x in actions[-3:]] == [0,0,payout], 'One direct payout on hand2')
    check([x['productive'] for x in actions[-3:]] == [False,True,True], 'Zero-cycle acceptance and productive hands')
    check([x['kind'] for x in actions[-3:]] == ['publisher_receipt','contract_hand','publisher_receipt'], 'Candidate transaction kinds')
    tx = a['ledger']['transactions']
    check(bool(tx), 'Nonempty exact-cent transaction journal')
    check(tx[0]['kind'] == 'starting_funding' and tx[0]['cash_before_cents'] == 0 and
          tx[0]['cash_after_cents'] == a['ledger']['initial_cash_cents'], 'Transaction starting funding')
    for prior,current in zip(tx,tx[1:]):
        check(prior['cash_after_cents'] == current['cash_before_cents'], 'Transaction cash continuity')
        check(current['sequence'] == prior['sequence']+1, 'Transaction sequence continuity')
    for row in tx:
        check(row['cash_after_cents'] == row['cash_before_cents'] + row['cash_delta_cents'], 'Exact-cent transaction arithmetic')
    check(tx[-1]['cash_after_cents'] == a['final']['cash'], 'Transaction end cash')
    return {'publisher':pub,'startup':startup,'seed':seed,'target':target,'checkpoint':a['source_checkpoint'],
            'initial_cash_cents':a['initial']['cash'],'final_scope':scope,'core_half':','.join(map(str,half)),
            'fraction_n':n,'fraction_d':d,'direct_cash_cents':payout,'conditional_promotion':promotion,
            'final_cash_cents':a['final']['cash'],'final_arrears_cents':a['final']['arrears']}

def main():
    manifest = json.loads((V3/'source-manifest.json').read_text(encoding='utf-8'))
    check(digest(V3/'source-manifest.json') == MANIFEST_SHA and manifest['head'] == SOURCE_HEAD, 'Pinned source manifest')
    check(digest(V3/'advance.gd') == BASE_SHA and digest(PROJECT/'analysis/task34_advance_v3.gd') == BASE_SHA, 'Pinned native analysis base')
    check(digest(HERE/'low_scope.gd') == digest(PROJECT/'analysis/task34_low_scope_v4.gd'), 'Policy script copy')
    copied = json.loads((HERE/'copy-manifest.json').read_text(encoding='utf-8'))
    check(copied['source_head'] == SOURCE_HEAD and copied['checked_original_files'] == 599, 'Pinned project copy')
    rows=[]
    paired=[]
    native_checks=0
    for pub,startup,filename,expected in ROUTES:
        check(digest(V3/filename) == expected, 'Typed checkpoint hash: '+filename)
        name=f'{pub}-{startup}'
        command=json.loads((HERE/(name+'.command.json')).read_text(encoding='utf-8'))
        check(command['exit'] == 0, 'Godot exit: '+name)
        log=(HERE/(name+'.log')).read_text(encoding='utf-8',errors='replace')
        check('TARGET_V4' in log and 'SCRIPT ERROR' not in log, 'Godot marker: '+name)
        data=json.loads((HERE/(name+'.json')).read_text(encoding='utf-8'))
        check(data['eligible'] and not data['failures'] and len(data['results'])==6, 'Six eligible legal arms: '+name)
        native_checks += data['checks']
        arms={(x['seed'],x['target']):x for x in data['results']}
        lo,hi=(9,10) if pub=='crown' else (10,11)
        check(set(arms)=={(seed,target) for seed in (200929000,200929001,200929002) for target in (lo,hi)},'Exact seed/target grid')
        for seed in (200929000,200929001,200929002):
            low,high=arms[seed,lo],arms[seed,hi]
            rows.append(audit_arm(low,pub,startup,lo,seed))
            rows.append(audit_arm(high,pub,startup,hi,seed))
            check(low['draw_events']==high['draw_events'] and low['owned_primitive']==high['owned_primitive'], 'Paired cards/pool frozen')
            for x,y in zip(low['hands'],high['hands']):
                for field in ('initial_pool','pool','selected','success','scope_if_committed','half_if_committed'):
                    check(x[field]==y[field], 'Paired hand '+field)
            nl,dl=low['fraction']; nh,dh=high['fraction']
            check(nl*dh >= nh*dl, 'Harder target rational monotonicity')
            cash_delta=low['direct_cash']-high['direct_cash']
            check(cash_delta>0, 'Low Scope distinguishes cash targets')
            check(low['final']['cash']-high['final']['cash']==cash_delta, 'Matched final cash difference is direct payout')
            paired.append({'publisher':pub,'startup':startup,'seed':seed,'scope':low['hands'][-1]['scope_if_committed'],
                           'lower_target':lo,'higher_target':hi,'lower_cash_cents':low['direct_cash'],
                           'higher_cash_cents':high['direct_cash'],'cash_delta_cents':cash_delta,
                           'lower_promotion':low['promotion_conditional'],'higher_promotion':high['promotion_conditional']})
    check(len(rows)==24 and len(paired)==12 and native_checks==580, 'Predeclared complete evidence')
    for name,items in (('arms.csv',rows),('pairs.csv',paired)):
        with (HERE/name).open('w',newline='',encoding='utf-8') as f:
            writer=csv.DictWriter(f,fieldnames=items[0].keys());writer.writeheader();writer.writerows(items)
    report={'source_head':SOURCE_HEAD,'routes':4,'arms':len(rows),'paired_targets':len(paired),
            'native_model_checks':native_checks,'independent_checks':checks,'failures':0,
            'scope_values':sorted(set(x['scope'] for x in paired)),
            'crown_cash_deltas_cents':sorted(set(x['cash_delta_cents'] for x in paired if x['publisher']=='crown')),
            'neon_cash_deltas_cents':sorted(set(x['cash_delta_cents'] for x in paired if x['publisher']=='neon'))}
    (HERE/'audit-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__':
    main()
