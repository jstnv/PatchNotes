"""Independent read-only audit of captured actual exported UI checkpoints."""
from pathlib import Path
import json,sys,hashlib
H=Path(__file__).resolve().parent
sys.path.insert(0,str(H.parent/'queue-completion-v1'))
import finance_audit as a
data={}
for folder in sorted(H.iterdir()):
 if not (folder/'decoded.json').exists():continue
 d=json.loads((folder/'decoded.json').read_text(encoding='utf-8'));data[folder.name]=d
 a.ledger(d['studio_finance'])
 s=json.loads((folder/'summary.json').read_text(encoding='utf-8'))
 for name,digest in s['files'].items():
  p=folder/name;a.check(hashlib.sha256(p.read_bytes()).hexdigest()==digest,'captured file hash')
  e=json.loads(p.read_text(encoding='utf-8'));a.check(hashlib.sha256(e['payload_utf8'].encode()).hexdigest()==e['payload_sha256'],'envelope checksum')
for before,after in [('first-release','first-continue'),('loan-accepted','loan-continued'),('second-release','second-continue')]:
 if after in data:a.check(data[before]==data[after],'exact actual restart '+after)
d=data['loan-payoff'];loan=d['studio_finance']['bank_loans'][0]
a.check(loan['closed'] and loan['early_payoff'],'closed early')
a.check(loan['principal_paid_cents']==50000 and loan['interest_paid_cents']==500,'principal and interest paid')
a.check(loan['schedule']['first_due_cycle']==14,'original first due')
a.check(data['first-installment']['cash_cents']-d['cash_cents']==45833,'exact payoff cash')
tx=d['studio_finance']['transactions']
for kind in ['bank_payment','bank_payoff']:a.check(sum(t['kind']==kind for t in tx)==1,'once-only '+kind)
a.check(len(data['second-release']['release_metadata'])==2,'two actual releases')
result={'pass':True,'checks':a.checks,'captured_boundaries':list(data),'first_installment_cents':4667,'payoff_cents':45833,'principal_paid_cents':50000,'interest_paid_cents':500,'limits':['UI route crosses explicitly recorded isolated builds; no clean-machine or audio acceptance.']}
(H/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
