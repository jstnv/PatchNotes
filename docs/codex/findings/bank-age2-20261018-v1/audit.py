from pathlib import Path
import hashlib,json,subprocess

out=Path(__file__).resolve().parent
root=out.parents[3]
read=lambda name:json.loads((out/name).read_text(encoding='utf-8'))
checks=[]
def check(value,label):
    checks.append({'ok':bool(value),'label':label})
    assert value,label
route=read('route-v1.json'); bank=read('bank-only-v1.json')
labels=['route-v1','bank-only-v1','policy-ages','save-recovered-v2','cold-recovered-v2','save-last-studio-v2','cold-last-studio-v2','cold-replay-ironclad','cold-replay-bank-only']
for label in labels:
    result=read(label+'-run.json')
    check(result['exit']==0 and not result['errors'],label+' successful process')
check(not route['still_unpaid_age2_reached'],'target reported as not reached')
check(route['source']==bank['source']=='1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82','same source for both routes')
for artifact in [route,bank]:
    check(hashlib.sha256(Path(artifact['input']).read_bytes()).hexdigest()==artifact['input_sha256'],'original prefix unchanged')
for index,row in enumerate(route['rows']):
    ledger=row['finance']
    check(ledger['cash_cents']==row['cash'] and ledger['last_cycle']==row['cycle'],f'row{index} finance/calendar reconcile')
    for bill in ledger['obligations']:
        check(bill['due_cents']==bill['paid_cents']+bill['unpaid_cents'] and sum(p['cents'] for p in bill['payments'])==bill['paid_cents'],f'row{index} bill identity {bill["bill_id"]}')
        if bill['expense_type']=='bank_installment' and bill['unpaid_cents']>0:
            check(row['cycle']==bill['due_cycle'],f'row{index} unpaid Bank never advanced beyond due cycle')
check(len(route['alternatives'])==35 and all(x['can_commit'] for x in route['alternatives']),'all visible second-hand alternatives finance-admissible')
check(route['selected']['income']==min(x['income'] for x in route['alternatives'])==137500,'lowest payout chosen deliberately')
check(route['rows'][5]['result']['ok'] is False and route['rows'][5]['cycle']==52,'insufficient-income priority action rejects')
check(route['rows'][6]['cycle']==52 and route['rows'][6]['finance']==route['rows'][5]['finance'],'legal redraw changes no bill age or finance')
final=route['rows'][-1]
check(final['cycle']==53 and final['cash']==90577,'successful recovery final cycle/cash')
due52={b['expense_type']:b for b in final['finance']['obligations'] if b['due_cycle']==52}
check(due52['bank_installment']['due_cents']==4459 and due52['bank_installment']['interest_paid_cents']==292 and due52['bank_installment']['principal_paid_cents']==4167,'Bank exact principal/interest')
for kind,bill in due52.items():
    check(bill['unpaid_cents']==0 and bill['settled_cycle']==53 and bill['recovery_overdue_cycles']==1,'recovery preserves due52 and age1 '+kind)
partial=next(b for b in bank['report']['outstanding_expenses'] if b['expense_type']=='bank_installment')
check(partial['paid_cents']==4417 and partial['unpaid_cents']==42 and partial['principal_paid_cents']==4125 and partial['interest_paid_cents']==292,'independent partial Bank bill reconciles')
check(bank['report']['unpaid_rent_cents']==0 and bank['report']['financially_blocked'],'Bank-only blocking counterexample to rent-only explanation')
for label in ['cold-recovered-v2','cold-last-studio-v2','cold-replay-ironclad','cold-replay-bank-only']:
    check(read(label+'.json')['source']==route['source'],'cold source match '+label)
previous=json.loads((root/'docs/codex/findings/queue-20261018-v2/final-source.json').read_text())
check(all(hashlib.sha256((root/p).read_bytes()).hexdigest()==h for p,h in previous['modified_by_this_pass'].items()),'all17 prior implementation source files unchanged')
sources=['patch-notes/scripts/run_state.gd','patch-notes/scripts/finance/studio_finance_ledger.gd','patch-notes/scripts/finance/outstanding_expenses.gd','patch-notes/scripts/finance/bank_loan.gd','patch-notes/scripts/simulation/campaign_session.gd','patch-notes/scripts/simulation/contract_session.gd','patch-notes/scripts/persistence/studio_checkpoint.gd','patch-notes/scripts/persistence/studio_checkpoint_store.gd']
pin={'branch':subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),'mechanic_source':route['source'],'files':{s:hashlib.sha256((root/s).read_bytes()).hexdigest() for s in sources},'original_inputs':{a['input']:a['input_sha256'] for a in [route,bank]}}
(out/'source-pin.json').write_text(json.dumps(pin,indent=2),encoding='utf-8')
(out/'audit.json').write_text(json.dumps({'checks':len(checks),'failures':sum(not x['ok'] for x in checks),'assertions':checks,'processes':labels,'target':'not reachable in tested legal progression; source guard explains why'},indent=2),encoding='utf-8')
print('AUDIT',len(checks),'checks',len(labels),'passing processes')
