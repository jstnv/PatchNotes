"""Independent read-only arithmetic, provenance and acceptance-evidence audit."""
from pathlib import Path
import datetime, hashlib, json

BASE=Path(__file__).resolve().parent
REPO=BASE.parents[3]
checks=[]
def expect(value,label):
    checks.append({'pass':bool(value),'label':label})
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def payload(path):
    e=json.loads(path.read_text())
    expect(hashlib.sha256(e['payload_utf8'].encode()).hexdigest()==e['payload_sha256'],str(path.relative_to(BASE))+': envelope hash')
    return json.loads(e['payload_utf8'])
def saved(profile):
    p=BASE/'profiles'/profile/'APPDATA/Godot/app_userdata/Patch Notes Demo/saves/studio'
    files=sorted(p.glob('checkpoint.*.json'),key=lambda x:int(x.name.split('.')[1]))
    return files[-1],payload(files[-1])

latest_pin=json.loads((BASE/'latest/pin.json').read_text())
drift=[]
for rel,digest in latest_pin['source'].items():
    p=REPO/'patch-notes'/rel
    if not p.exists() or sha(p)!=digest:drift.append(rel)
expect(not drift,'Latest pinned source still matches canonical bytes')
origins=json.loads((BASE/'profile-origins.json').read_text())
for item in origins:
    if item['profile'] not in ('crown-rollback','neon-completed','education-distress','legacy-preview'):continue
    path,data=saved(item['profile'])
    expect(sha(path)==item['sha256'],item['profile']+': original generation unchanged after actual UI Continue/rejection/rollback')
    expect('rival_world' not in data,item['profile']+': no retroactive rival world')
    expect(int(data['run']['cash_cents'])==int(item['cash_cents']),item['profile']+': saved cash unchanged')
    expect(int(data['run']['completed_run_cycles'])==int(item['cycle']),item['profile']+': saved cycle unchanged')

reports={}
for profile in ('new-ai','new-ai-latest','crown-rollback','neon-completed','starwave-bank','education-recovered','education-distress','legacy-preview'):
    path,d=saved(profile);r=d['run'];f=r['studio_finance']
    reports[profile]={'file':str(path.relative_to(BASE)),'sha256':sha(path),'sequence':d['sequence'],'cycle':r['completed_run_cycles'],'cash_cents':r['cash_cents'],'rivals':'rival_world' in d}
    expect(r['cash_cents']==f['cash_cents'],profile+': finance cash equals RunState cash')
    expect(r['completed_run_cycles']==f['last_cycle'],profile+': finance calendar agrees')
    tx=f['transactions']
    for i,row in enumerate(tx):
        expect(int(row['cash_before_cents'])+int(row['cash_delta_cents'])==int(row['cash_after_cents']),f'{profile}: transaction {i} arithmetic')
        if i:expect(row['cash_before_cents']==tx[i-1]['cash_after_cents'],f'{profile}: transaction {i} continuity')
    expect(not tx or tx[-1]['cash_after_cents']==r['cash_cents'],profile+': final transaction reconciles')
    expect(len({row['sequence'] for row in tx})==len(tx),profile+': unique transaction sequence')
    for bill in f['obligations']:
        expect(int(bill['paid_cents'])+int(bill['unpaid_cents'])==int(bill['due_cents']),profile+': original bill conserved '+bill['bill_id'])
        expect(sum(int(x['cents']) for x in bill['payments'])==int(bill['paid_cents']),profile+': payment history reconciles '+bill['bill_id'])
    for month in f['monthly_rows']:
        expect(int(month['opening_cash_cents'])+int(month['cash_change_cents'])==int(month['closing_cash_cents']),profile+': monthly cash reconciles '+month['month'])

_,new=saved('new-ai-latest')
world=new['rival_world']
expect(new['run']['completed_run_cycles']==world['cycle']=='0','Fresh final-source Continue remains cycle zero')
expect(len(world['studios'])==2,'Fresh final-source save has two rivals')
archive_ids=[title['id'] for row in world['studios'] for title in row['archive']]
expect(len(archive_ids)==len(set(archive_ids)) and len(archive_ids)>0,'Frozen archive IDs unique across world')
expect(all(row['archive'] for row in world['studios']),'Each rival retains a frozen archive')

_,edu=saved('education-recovered')
before_path=BASE/'profiles/education-recovered/APPDATA/Godot/app_userdata/Patch Notes Demo/saves/studio/checkpoint.35.json'
before=payload(before_path)
expect(int(before['run']['cash_cents'])-int(edu['run']['cash_cents'])==24998,'Bank payoff charges exactly 24998 cents')
ef=edu['run']['studio_finance'];bf=before['run']['studio_finance']
expect(ef['education']==bf['education'],'Bank payoff preserves full education account')
expect(ef['credit']==bf['credit'],'Bank payoff preserves complete credit history')
expect(edu['run']['completed_run_cycles']==before['run']['completed_run_cycles']=='52','Bank payoff consumes zero cycles')
extra=ef['transactions'][len(bf['transactions']):]
expect(ef['transactions'][:len(bf['transactions'])]==bf['transactions'] and [x['kind'] for x in extra]==['calendar','bank_payoff'] and extra[0]['cash_delta_cents']=='0' and extra[0]['cycle']=='52','One payoff appended after zero-cash same-cycle calendar synchronization')
expect(ef['bank_loans'][-1]['closed'] and ef['bank_loans'][-1]['principal_paid_cents']=='50000','Bank principal closed exactly')

_,star=saved('starwave-bank')
prepay=payload(next((BASE/'checkpoints/starwave-cycle40').glob('*.json')))
sf=star['run']['studio_finance'];pf=prepay['run']['studio_finance'];loan=pf['bank_loans'][-1]
expect(loan['schedule']['accepted_cycle']=='37' and loan['schedule']['first_due_cycle']=='40','Starwave loan retains first full-month payday')
expect(loan['principal_paid_cents']=='4167' and loan['interest_paid_cents']=='500' and loan['issued']=='1','First installment splits 4167 principal and 500 interest once')
month=next(row for row in pf['monthly_rows'] if row['month']=='20')
expect(month['rent_paid_cents']=='50000' and month['payroll_paid_cents']=='1000','Rent and payroll settle with Bank in month20')
expect(month['sales_settled_cents']=='61539' and month['principal_paid_cents']=='4167' and month['interest_paid_cents']=='500','Sales, principal and interest reconcile in month20')
payments=[row['kind'] for row in pf['transactions'] if row['cycle']=='40' and row['kind'] in ('rent_payment','payroll_payment','bank_payment')]
expect(payments==['rent_payment','payroll_payment','bank_payment'],'Monthly recovery order rent then payroll then Bank')
expect(int(prepay['run']['cash_cents'])-int(star['run']['cash_cents'])==45833,'Post-installment payoff charges remaining principal once')
expect(star['run']['completed_run_cycles']=='40' and star['run']['cash_cents']=='1496351','Starwave final cold Continue checkpoint amounts')
origin=next(x for x in origins if x['profile']=='starwave-bank')
original=json.loads(json.loads((BASE.parent/origin['source']).read_text())['payload_utf8'])
for field in ('publisher_offers','promotion_awards','promotion_consumed','sidestreet_results'):
    expect(star['run'][field]==original['run'][field],'Starwave route preserves '+field)
expect(sf['bank_loans'][-1]['closed'] and sf['bank_loans'][-1]['interest_paid_cents']=='500','Closed loan preserves paid interest')

ui_errors=[];log_count=0
for log in (BASE/'profiles').rglob('*.log'):
    log_count+=1
    for line in log.read_text(errors='replace').splitlines():
        if line.startswith('ERROR:') or 'SCRIPT ERROR' in line:ui_errors.append([str(log.relative_to(BASE)),line])
expect(not ui_errors,'Exported UI logs have no runtime error markers')
captures=[json.loads(x) for x in (BASE/'captures/index.jsonl').read_text().splitlines()]
expect(all((BASE/'captures'/x['file']).read_bytes().startswith(bytes.fromhex('ffd8ff')) for x in captures),'All referenced captures exist as original JPEG evidence')
processes=[json.loads(x) for x in (BASE/'ui-processes.jsonl').read_text().splitlines()]
expect(all(x['exit_code']==0 for x in processes),'Recorded exported processes exit successfully')
native=json.loads((BASE/'latest/world-process-v2/world-process-results.json').read_text())
expect(len(native)==4 and all(x['exit']==0 and not x['errors'] for x in native),'Final-source four-process world checks pass')
report={'date_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'checks':len(checks),'failures':[x for x in checks if not x['pass']], 'source_drift':drift,'profiles':reports,'ui_log_count':log_count,'ui_errors':ui_errors,'captures':len(captures),'recorded_processes':len(processes),'assertions':checks}
(BASE/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ('checks','failures','source_drift','ui_log_count','captures','recorded_processes')}))
raise SystemExit(bool(report['failures']))
