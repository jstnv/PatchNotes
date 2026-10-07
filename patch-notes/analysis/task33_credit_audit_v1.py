"""Independent integer credit replay for the eight native Task33 routes."""
from pathlib import Path
import csv
import json

OUT = Path(__file__).resolve().parents[1] / 'design-logs/task33-v1'
errors, rows = [], []
weights = {'rent': [5, 10, 20], 'bank_installment': [10, 20, 30],
           'payroll': [5, 10, 15], 'student_loan': [5, 10, 20]}
snapshots = 0
for path in sorted(OUT.glob('route_*.json')):
    route = json.loads(path.read_text(encoding='utf-8'))
    if 'actions' not in route: continue
    states = [route['initial']] + [a['after'] for a in route['actions'] if 'after' in a] + [route['final']]
    for state in states:
        snapshots += 1
        ledger = state['finance']
        credit = ledger['credit']
        score = 600
        for entry in credit['history']:
            end = 2 * entry['month']
            factors = {}
            for bill in ledger['obligations']:
                if bill['due_cycle'] > end: continue
                # Reconstruct balance at that original close from payment month.
                paid_at_due = sum(p['cents'] for p in bill['payments']
                                  if p['cycle'] == bill['due_cycle'] and p['month'] == bill['month'])
                if paid_at_due == bill['due_cents']: continue
                recovered = bill['settled_cycle']
                if recovered >= 0 and recovered <= end - 2: continue
                age = max(0, min(end, recovered) - bill['due_cycle']) if recovered >= 0 else end - bill['due_cycle']
                kind = bill['expense_type']
                factors[kind] = max(factors.get(kind, 0), weights[kind][min(2, age // 2)])
            profit = ledger['monthly_rows'][entry['month'] - 1]['net_profit_cents']
            delta = -sum(factors.values()) if factors else (3 if profit > 0 else 0)
            after = min(850, max(300, score + delta))
            if (entry['before'], entry['after'], entry['requested_change']) != (score, after, delta):
                errors.append((path.name, state['cycle'], entry['month'], 'credit'))
            score = after
        if score != credit['score'] or credit['last_processed_month'] != state['cycle'] // 2:
            errors.append((path.name, state['cycle'], 'last processed / score'))
    for entry in route['final']['finance']['credit']['history']:
        rows.append({'route': path.stem, **{k: v for k, v in entry.items() if k != 'reasons'},
                     'reasons': json.dumps(entry['reasons'])})
with (OUT / 'monthly-credit.csv').open('w', newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
result = {'snapshots': snapshots, 'final_months': len(rows), 'errors': errors}
(OUT / 'credit-audit.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result))
raise SystemExit(bool(errors))
