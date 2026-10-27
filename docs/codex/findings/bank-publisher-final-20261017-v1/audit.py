from pathlib import Path
import datetime, hashlib, json, re

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[3]
checks=0; failures=[]; files={}; outcomes={}
def check(ok,label):
 global checks
 checks+=1
 if not ok: failures.append(label)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):
 files[str(p.relative_to(ROOT))]=sha(p)
 x=json.loads(p.read_text(encoding='utf-8'))
 if 'payload_utf8' in x:
  check(hashlib.sha256(x['payload_utf8'].encode()).hexdigest()==x['payload_sha256'],str(p)+' envelope')
  return json.loads(x['payload_utf8'])
 return x
def rows(a): return {r['key']:r['value'] for r in a}
def save(folder,seq): return next((BASE/folder).rglob(f'checkpoint.{seq}.json'))
def finance(f,label):
 cash=0
 for i,t in enumerate(f['transactions']):
  check(int(t['sequence'])==i+1,label+' sequence')
  check(int(t['cash_before_cents'])==cash,label+' continuity')
  check(cash+int(t['cash_delta_cents'])==int(t['cash_after_cents']),label+' cash arithmetic')
  cash=int(t['cash_after_cents']);check(cash>=0,label+' nonnegative')
 check(cash==int(f['cash_cents']),label+' closing cash')
 for b in f['obligations']:
  check(int(b['paid_cents'])+int(b['unpaid_cents'])==int(b['due_cents']),label+' original due amount')
  check(sum(int(p['cents']) for p in b['payments'])==int(b['paid_cents']),label+' payment sum')
  if int(b.get('recovery_overdue_cycles','0'))>0:
   check(int(b['settled_cycle'])-int(b['due_cycle'])==int(b['recovery_overdue_cycles']),label+' recovery age')
def contract(run,publisher,label):
 entry=next(x for x in run['publisher_offers'] if x['value']['publisher_id']==publisher)
 s=entry['value']['state'];r=s['result'];core_map=rows(r['cores']);c=[int(core_map[str(i)]) for i in range(4)];scope=int(r['scope'])
 if publisher=='crown_quill': n=2*min(scope,9)+sum(min(v,8) for v in c)+2*min(8,min(c));d=66;advance=15000;pool=177000;promo=12
 elif publisher=='neon_circuit':
  focus=int(s['neon_focus']);n=2*min(scope,10)+sum((3*min(v,18) if i==focus else min(v,4)) for i,v in enumerate(c));d=86;advance=0;pool=156000;promo=20
  eligible=rows(s['eligible']);totals=[0,0,0,0];stats=['graphics','sound','technology','design']
  for card in json.loads((ROOT/'patch-notes/data/card_ledger.json').read_text()):
   if card['id'] in eligible and card.get('type')=='feature' and card.get('phase') in ['design','alpha']:
    totals[stats.index(card['primary_stat'])]+=int(card['primary_value'])
  check(focus==max(range(4),key=lambda i:totals[i]),label+' automatic eligible primary focus with stable tie order')
  outcomes[label+'-focus']=dict(eligible=list(eligible),primary_totals=totals,focus=focus)
 else: n=4*min(scope,14)+sum(min(v,14) for v in c);d=112;advance=0;pool=224000;promo=0
 expected=dict(numerator=n,denominator=d,upfront=advance,remainder=pool*n//d,payout=advance+pool*n//d,promotion=promo*n//d)
 for k,v in expected.items():check(int(r[k])==v,label+' '+k)
 check(s['paid'] and int(s['hands'])==(3 if publisher=='starwave' else 2),label+' completed once')
 tx=[t for t in run['studio_finance']['transactions'] if t['source_id']==entry['key'] and int(t['cash_delta_cents'])>0]
 check(sum(int(t['cash_delta_cents']) for t in tx)==expected['payout'],label+' receipt total')
 check(len(tx)==(2 if advance else 1),label+' receipt count')
 check(int(tx[-1]['cycle'])==int(run['completed_run_cycles']),label+' final receipt cycle')
 outcomes[label]=dict(expected,scope=scope,core_half_units=c,offer_id=entry['key'],receipts=tx,focus=s['neon_focus'])
 return entry['key']

for folder in ['bank-before-cold','bank-after-cold','crown-before-cold','crown-after-cold','crown-promoted','starwave-preaccept','starwave-rollback-restored','starwave-before-cold','starwave-after-cold','neon-before-cold','neon-after-cold','neon-promoted','crown-after-launch-before-cold','crown-after-launch-cold','neon-after-launch-cold']:
 for p in (BASE/folder).glob('checkpoint.*.json'):
  x=load(p);finance(x['run']['studio_finance'],folder+'/'+p.name)
for before,after,seq in [('bank-before-cold','bank-after-cold',34),('crown-before-cold','crown-after-cold',15),('starwave-preaccept','starwave-rollback-restored',12),('starwave-before-cold','starwave-after-cold',13),('neon-before-cold','neon-after-cold',3),('crown-after-launch-before-cold','crown-after-launch-cold',17),('neon-promoted','neon-after-launch-cold',4)]:
 check(save(before,seq).read_bytes()==save(after,seq).read_bytes(),before+' exact cold restore including RNG/credit/identity')

bank=load(save('bank-before-cold',34))['run'];f=bank['studio_finance']
check(int(bank['completed_run_cycles'])==51 and int(bank['cash_cents'])==51619,'Bank recovery Studio/cash')
dues={b['expense_type']:b for b in f['obligations'] if int(b['due_cycle'])==50}
for kind,due,principal,interest in [('bank_installment',4500,4167,333),('student_loan',7068,4045,3023)]:
 b=dues[kind]
 check(int(b['due_cents'])==due and int(b['paid_cents'])==due and int(b['unpaid_cents'])==0,kind+' paid exact original bill')
 check(int(b['principal_cents'])==principal and int(b['interest_cents'])==interest,kind+' principal interest retained')
 check(int(b['recovery_overdue_cycles'])==1 and b['late'] and not b['paid_on_time'],kind+' late recovery age one')
 check(b['payments']==[dict(cents=str(due),cycle='51',month='26')],kind+' payment history')
check([int(p['cents']) for p in dues['rent']['payments']]==[33374,16626],'Rent partial history retained')
credit=f['credit']['history'][-1]
check(int(credit['cycle'])==50 and int(credit['change'])==-20 and [r['type'] for r in credit['reasons']]==['rent','bank_installment','student_loan'],'Typed original credit penalties retained')
outcomes['bank_age']=dict(bills=dues,credit=credit,cash_cents=51619)
def numeric(v):
 if isinstance(v,dict):return {k:numeric(x) for k,x in v.items()}
 if isinstance(v,list):return [numeric(x) for x in v]
 return int(v) if isinstance(v,str) and re.fullmatch(r'-?\d+',v) else v
probe=load(BASE/'legal-age-probe.json')
check(all(a['result']['ok'] for a in probe['actions']),'Legal age probe all commands accepted')
check(numeric(probe['actions'][-1]['finance'])==numeric(f),'Legal age probe matches complete exported finance ledger')
contract(bank,'neon_circuit','bank-neon')

crown=load(save('crown-before-cold',15))['run'];crown_id=contract(crown,'crown_quill','crown')
neon=load(save('neon-before-cold',3))['run'];neon_id=contract(neon,'neon_circuit','neon')
star=load(save('starwave-before-cold',13))['run'];star_id=contract(star,'starwave','starwave')
check(star_id not in rows(star['promotion_awards']),'Starwave grants no Promotion entry')
for kind,amount in [('rent_payment',50000),('payroll_payment',1000),('bank_payment',4667)]:
 tx=[t for t in star['studio_finance']['transactions'] if int(t['cycle'])==36 and t['kind']==kind]
 check(sum(int(t['cash_delta_cents']) for t in tx)==-amount,'Starwave monthly '+kind)

for profile,publisher,seq in [('crown-small','crown_quill',15),('starwave-small','starwave',12)]:
 p=save('profiles/'+profile,seq);r=load(p)['run'];finance(r['studio_finance'],profile);contract(r,publisher,profile)

for folder,seq,offer,awareness,promo in [('crown-promoted',16,crown_id,153,8),('neon-promoted',4,neon_id,144,20)]:
 r=load(save(folder,seq))['run'];awards=rows(r['promotion_awards']);consumed=rows(r['promotion_consumed'])
 check(int(awards[offer])==promo and offer in consumed,folder+' consumed award identity retained')
 release=rows(r['released_games'])[consumed[offer]]
 check(int(release['launch_awareness'])==awareness,folder+' frozen Awareness')
 check(all(k in consumed for k in awards),folder+' no unconsumed award')
 outcomes[folder]=dict(release=release,awards=awards,consumed=consumed)
later=load(save('profiles/crown',17))['run'];latest=later['released_games'][-1]['value']
check(latest['base_name']=='q' and int(latest['launch_awareness'])==121,'Crown next launch has no duplicate Promotion')
first_promoted=next(v['key'] for v in later['released_games'] if v['value']['base_name']=='p')
check(rows(later['promotion_consumed'])[crown_id]==first_promoted,'Crown consumed identity does not move to second launch')
finance(later['studio_finance'],'Crown subsequent launch')
outcomes['crown_next_release']=latest

manifest=load(BASE.parent/'queue-execution-20261017-v2/final-delivery-v4/build-manifest.json')
for p,digest in manifest['included'].items():check(sha(ROOT/'patch-notes'/p)==digest,'Final runtime '+p)
for p,meta in manifest['artifacts'].items():check(sha(Path(manifest['workspace'])/'demo'/p)==meta['sha256'],'Final artifact '+p)
for row in load(BASE/'focused/results.json'):check(row['exit']==0 and not row['errors'],row['name'])
recovery=load(BASE/'recovery-credit-result.json');check(recovery['exit']==0 and not recovery['errors'],'Recovery-period and subsequent clean-month credit checks')
processes=[json.loads(l) for l in (BASE/'processes.jsonl').read_text().splitlines()]
for row in processes:check(row['exit_code']==0,'Export process '+row['profile'])
for p in (BASE/'profiles').rglob('godot*.log'):
 check(not any(l.startswith(('ERROR:','SCRIPT ERROR:')) for l in p.read_text(errors='replace').splitlines()),str(p)+' runtime log')
captures=[json.loads(l) for l in (BASE/'captures/index.jsonl').read_text().splitlines()]
for r in captures:check((BASE/'captures'/r['file']).exists(),'Capture '+r['file'])
result=dict(checks=checks,failures=failures,files=files,outcomes=outcomes,process_count=len(processes),capture_count=len(captures),utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
(BASE/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:result[k] for k in ['checks','failures','process_count','capture_count']},indent=2))
raise SystemExit(bool(failures))
