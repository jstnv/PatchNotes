"""Synthetic design arithmetic; not gameplay, a legal pool, or runtime parity."""
from itertools import product
from pathlib import Path
import hashlib
import json


def grades(scope, cores):
    numerator = 2 * min(scope, 9) + sum(min(h, 8) for h in cores) + 2 * min(min(cores), 8)
    completion = 10000 * numerator // 66
    spread = max(cores) - min(cores)
    promise = 10000 if spread <= 4 else max(0, 10000 - (spread - 4) * 10000 // 8)
    combined = min(completion, promise)
    return dict(completion_bp=completion, promise_bp=promise, grade_bp=combined,
                reputation_bp=1000 * combined // 10000,
                multiplicative_bp=completion * promise // 10000)


def commission(scope_bp, review_tenths, target, fee):
    review_bp = min(10000, max(0, 500 * (review_tenths - (target - 20))))
    grade = min(scope_bp, review_bp)
    return dict(grade_bp=grade, fee_cents=fee * grade // 10000,
                requested_reputation_bp=1500 if grade == 10000 else 0,
                requested_investment_bp=1500 if grade == 10000 else 0)


def support(investment_bp, cash_share):
    budget = min(300000, 50000 + 2500 * (investment_bp // 100))
    nominal = budget * cash_share // 10000
    marketing = (budget - nominal) // 3500
    return dict(budget_cents=budget, funding_cents=budget - 3500 * marketing,
                marketing_points=marketing)


counts = dict(tuples=0, full=0, partial=0, zero=0, minimum_above_product=0)
for cores in product(range(17), repeat=4):
    for scope in range(15):
        g = grades(scope, cores)
        assert 0 <= g['reputation_bp'] <= 1000
        assert 0 <= g['multiplicative_bp'] <= g['grade_bp'] <= 10000
        assert (g['grade_bp'] == 10000) == (scope >= 9 and min(cores) >= 8 and max(cores)-min(cores) <= 4)
        assert g == grades(scope, tuple(reversed(cores)))
        counts['tuples'] += 1
        counts['full' if g['grade_bp'] == 10000 else 'zero' if g['grade_bp'] == 0 else 'partial'] += 1
        counts['minimum_above_product'] += g['grade_bp'] > g['multiplicative_bp']
assert counts['tuples'] == 1252815
samples = []
for scope, cores in [(0,(0,0,0,0)),(9,(0,0,0,0)),(5,(4,4,4,4)),(9,(6,6,6,6)),(9,(8,8,8,8)),(9,(8,8,8,12)),(9,(8,8,8,13)),(9,(8,8,8,16)),(9,(8,8,8,20))]:
    samples.append(dict(scope=scope, core_half_units=cores, **grades(scope,cores)))
assert grades(0,(0,0,0,0))['promise_bp'] == 10000
assert grades(0,(0,0,0,0))['reputation_bp'] == 0

commission_rows = []
for target, fee, scope_bp, review in product([70,75],[600000,800000],[5000,10000],range(101)):
    row=commission(scope_bp,review,target,fee)
    assert 0 <= row['fee_cents'] <= fee
    assert (row['requested_reputation_bp']>0) == (review>=target and scope_bp==10000)
    commission_rows.append(dict(target_tenths=target,fee_cap_cents=fee,scope_bp=scope_bp,review_tenths=review,**row))

packages=[]
for investment in [1500,2500,4000,10000]:
    for share in [8000,6000]:
        p=support(investment,share)
        assert p['funding_cents'] + 3500*p['marketing_points'] == p['budget_cents']
        packages.append(dict(investment_bp=investment,cash_share_bp=share,**p))

output = dict(status='PASS',scope='synthetic arithmetic only; no legal-accessibility or balance claim',
              script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              brief_counts=counts,brief_examples=samples,commission_cases=len(commission_rows),
              commission_rows=commission_rows,support_packages=packages)
destination=Path(__file__).with_name('arithmetic-results.json')
with destination.open('x',encoding='utf-8') as handle:
    json.dump(output,handle,indent=2); handle.write('\n')
print(json.dumps({k:v for k,v in output.items() if k not in ['commission_rows']},indent=2))
