"""Independent integer journal and monthly-row reconciliation, no game imports."""
checks=0
def check(ok, label):
 global checks
 checks+=1
 if not ok: raise AssertionError(label)
def ledger(f):
 cash=0
 for i,t in enumerate(f['transactions']):
  check(t['sequence']==i+1,'journal sequence')
  check(t['cash_before_cents']==cash,'journal cash before')
  cash+=t['cash_delta_cents']
  check(cash==t['cash_after_cents'] and cash>=0,'journal cash after')
 check(cash==f['cash_cents'],'closing cash')
 prior=0
 for row in f['monthly_rows']:
  check(row['opening_cash_cents']==prior,'month continuity')
  tx=[t for t in f['transactions'] if t['month']==row['month']]
  delta=sum(t['cash_delta_cents'] for t in tx)
  check(row['cash_change_cents']==delta,'month cash movement')
  check(row['closing_cash_cents']==prior+delta,'month closing cash')
  check(row['net_profit_cents']==row['operating_revenue_cents']-row['operating_expenses_cents'],'month accrued profit')
  for bill in ['rent','payroll']:
   check(row[bill+'_due_cents']==row[bill+'_paid_cents']+row[bill+'_unpaid_cents'],'bill due/paid/unpaid')
  prior=row['closing_cash_cents']
 check(prior==cash,'monthly/journal final cash')
 check(sum(a['settled'] for a in f['actions'])==sum(r['sales_settled_cents'] for r in f['monthly_rows']),'sales settlement actions/rows')
