"""Offline audit of exact exported-game checkpoints; never edits save bytes."""
import hashlib, json, struct
from pathlib import Path

BASE = Path(__file__).resolve().parent
checks = []
def check(ok, label):
    checks.append({'pass': bool(ok), 'label': label})
def pairs(rows): return {x['key']: x['value'] for x in rows}
def number(v): return struct.unpack('>d', bytes.fromhex(v['f64']))[0]
def checkpoint(label):
    files = list((BASE/'checkpoints'/label).glob('checkpoint.*.json'))
    p = max(files, key=lambda x:int(x.stem.split('.')[-1]))
    e = json.loads(p.read_text())
    check(hashlib.sha256(e['payload_utf8'].encode()).hexdigest()==e['payload_sha256'],label+': payload hash')
    return json.loads(e['payload_utf8'])['run'], hashlib.sha256(p.read_bytes()).hexdigest()

summaries = {}
for folder in sorted((BASE/'checkpoints').iterdir()):
    if not folder.is_dir() or not list(folder.glob('checkpoint.*.json')): continue
    r, digest = checkpoint(folder.name)
    finance = r['studio_finance']
    cash = 0  # Starting funding is transaction one, not an extra opening balance.
    for i,t in enumerate(finance['transactions'],1):
        check(int(t['sequence'])==i, f'{folder.name}: transaction {i} sequence')
        check(int(t['cash_before_cents'])==cash, f'{folder.name}: transaction {i} opening')
        cash += int(t['cash_delta_cents'])
        check(int(t['cash_after_cents'])==cash, f'{folder.name}: transaction {i} closing')
    check(cash==int(r['cash_cents'])==int(finance['cash_cents']),folder.name+': final cash')
    for bill in finance['obligations']:
        check(int(bill['due_cents'])==int(bill['paid_cents'])+int(bill['unpaid_cents']),folder.name+': bill '+bill['bill_id'])
        check(sum(int(x['cents']) for x in bill['payments'])==int(bill['paid_cents']),folder.name+': payments '+bill['bill_id'])
    for row in finance['monthly_rows']:
        check(int(row['opening_cash_cents'])+int(row['cash_change_cents'])==int(row['closing_cash_cents']),folder.name+': monthly cash '+row['month'])
        check(int(row['operating_revenue_cents'])-int(row['operating_expenses_cents'])==int(row['net_profit_cents']),folder.name+': monthly operating '+row['month'])
    summaries[folder.name]={'sha256':digest,'cycle':int(r['completed_run_cycles']),'cash_cents':cash,'fans':int(r['fanbase']['fans']), 'arrears_cents':sum(int(x['unpaid_cents']) for x in finance['obligations'])}

for before,after in [('bank-distressed-committed','bank-late-cold-restored'),('bank-paid-off','bank-paid-off-cold-restored')]:
    check(summaries[before]['sha256']==summaries[after]['sha256'],before+': cold Continue bytes unchanged')
late,_=checkpoint('bank-distressed-committed')
paid,_=checkpoint('bank-paid-off')
final,_=checkpoint('bank-post-payoff-month-and-neon-no-reuse')
check(summaries['bank-distressed-committed']['arrears_cents']==28168,'Bank: original total arrears')
late_bills={x['bill_id']:x for x in late['studio_finance']['obligations'] if int(x['unpaid_cents'])>0}
for key,bill in late_bills.items():
    restored=next(x for x in final['studio_finance']['obligations'] if x['bill_id']==key)
    check(restored['due_cycle']==bill['due_cycle']=='28','Bank: original due retained '+key)
    check(restored['late'] and not restored['paid_on_time'] and int(restored['unpaid_cents'])==0,'Bank: cleared late history '+key)
    check(restored['payments'][:len(bill['payments'])]==bill['payments'],'Bank: earlier payments retained '+key)
loan=final['studio_finance']['bank_loans'][0]
check(loan['closed'] and loan['early_payoff'] and loan['closed_cycle']=='30','Bank: zero-cycle payoff closure')
check(int(loan['principal_paid_cents'])==50000 and int(loan['interest_paid_cents'])==2375,'Bank: exact total principal/interest')
check(summaries['bank-paid-off']['cash_cents']==187764 and summaries['bank-post-payoff-month-and-neon-no-reuse']['cash_cents']==143037,'Bank: payoff and later cash')
history=final['studio_finance']['credit']['history']
check([int(x['points']) for x in next(x for x in history if x['cycle']=='28')['reasons']]==[-5,-10],'Bank: rent and Bank credit categories')
check(all(int(x['change'])>=0 for x in history if int(x['cycle'])>28),'Bank: no further late penalty after recovery')
check(final['studio_finance']['credit']['score']=='594','Bank: past penalty retained')
for tag,r in [('Neon',final),('Crown',checkpoint('crown-no-reuse')[0])]:
    consumed=pairs(r['promotion_consumed']); awards=pairs(r['promotion_awards']); releases=pairs(r['release_metadata'])
    key=next(k for k in awards if tag.lower() in k)
    project=consumed[key]
    check(sum(1 for x in consumed if x==key)==1,tag+': one consumption key')
    review=releases[project]['review']
    # Frozen Fan Awareness is independent of the banked Promotion.
    promotion=int(awards[key])
    expected=155 if tag=='Neon' else 153
    check(int(review['awareness'])==expected,tag+': exact promoted launch Awareness')
    newest=max(releases.values(),key=lambda x:int(x['release_cycle']))
    check(int(newest['review']['awareness'])==(113 if tag=='Neon' else 121),tag+': next launch has no reused Promotion')
    settled=pairs(r['released_games'])[project]
    check(int(settled['settled_cents'])>0,tag+': promoted release earned actual positive settlement')
star,_=checkpoint('starwave-completed')
receipts=[x for x in star['studio_finance']['transactions'] if x['kind']=='publisher_receipt' and 'starwave' in x['source_id']]
check(len(receipts)==1 and receipts[0]['cycle']=='37' and int(receipts[0]['amount_cents'])==224000,'Starwave: one final-hand receipt')
check(not any('starwave' in x['key'] for x in star['promotion_awards']),'Starwave: no Promotion award')
for before,after in [('education-distressed-committed','education-payoff-rejected'),('education-distressed-committed','education-late-cold-restored'),('education-bank-paid-off','education-paid-off-cold-restored')]:
    check(summaries[before]['sha256']==summaries[after]['sha256'],before+': rejection/Continue bytes unchanged '+after)
edu_late,_=checkpoint('education-distressed-committed')
edu_recovered,_=checkpoint('education-recovered-next-month')
edu_closed,_=checkpoint('education-bank-paid-off')
check(summaries['education-distressed-committed']['arrears_cents']==33998,'Education: exact genuine total arrears')
check(summaries['education-recovered-next-month']['cash_cents']==109801 and summaries['education-bank-paid-off']['cash_cents']==84803,'Education: recovery and Bank payoff cash')
check(summaries['education-bank-paid-off']['arrears_cents']==0,'Education: all arrears cleared')
ef=edu_recovered['studio_finance']
for original in [b for b in edu_late['studio_finance']['obligations'] if int(b['unpaid_cents'])>0]:
    bill=next(b for b in ef['obligations'] if b['bill_id']==original['bill_id'])
    check(bill['due_cycle']==original['due_cycle']=='50','Education: original due retained '+bill['bill_id'])
    check(bill['late'] and not bill['paid_on_time'] and int(bill['unpaid_cents'])==0,'Education: recovered late history '+bill['bill_id'])
    check(bill['payments'][:len(original['payments'])]==original['payments'],'Education: partial history retained '+bill['bill_id'])
service=[t for t in ef['transactions'] if t['cycle']=='50' and int(t['sequence'])>213]
check([t['kind'] for t in service]==['rent_payment','bank_payment','education_payment'],'Education: actual recovery service order')
check([int(t['amount_cents']) for t in service]==[22430,4500,7068],'Education: exact recovery components')
history=ef['credit']['history']
check([int(x['points']) for x in next(x for x in history if x['cycle']=='50')['reasons']]==[-5,-10,-5],'Education: rent/Bank/education category credit penalties')
check(all(int(x['change'])>=0 for x in history if int(x['cycle'])>50),'Education: no new late penalty after recovery')
check(ef['credit']['score']=='610','Education: historical penalties retained after next month')
account=ef['education']
check(not account['closed'] and account['issued']=='14' and account['principal_paid_cents']=='54615' and int(account['interest_paid_cents'])==38318+3023+2996,'Education: next scheduled due and exact principal/interest totals')
check(edu_closed['studio_finance']['education']==account,'Education: Bank payoff preserves account and future schedule')
check(edu_closed['studio_finance']['bank_loans'][0]['closed'] and edu_closed['completed_run_cycles']=='52','Education: recovered Bank payoff is zero-cycle')
legacy,_=checkpoint('legacy-preview-restored')
check(not legacy['studio_finance'].get('education'),'Legacy inactive preview: no debt activation')
errors=[]
for p in (BASE/'profiles').glob('*/APPDATA/Godot/app_userdata/Patch Notes Demo/logs/godot*.log'):
    hits=[s for s in p.read_text(errors='replace').splitlines() if 'ERROR:' in s or 'SCRIPT ERROR:' in s]
    if hits: errors.append({'path':str(p.relative_to(BASE)),'errors':hits})
check(not errors,'Current exported profile logs have no runtime errors')
result={'checks':len(checks),'failed':sum(not x['pass'] for x in checks),'summaries':summaries,'runtime_errors':errors,'results':checks,
        'limits':'Checkpoint arithmetic and captured ordinary input; not human comprehension, audible acceptance or performance evidence. Earlier summary promotion:null fields represented an absent property; consumed keys are authoritative.'}
(BASE/'audit-export.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:result[k] for k in ('checks','failed','runtime_errors')},indent=2))
for item in checks:
    if not item['pass']: print(item['label'])
raise SystemExit(bool(result['failed']))
