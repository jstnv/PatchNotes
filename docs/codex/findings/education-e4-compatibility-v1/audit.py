"""Independent artifact audit. Never invokes Godot or changes fixture bytes."""
from pathlib import Path
import hashlib, json, re, copy

H=Path(__file__).resolve().parent
OLD=H.parent/'education-legacy-fixtures-v1'
FIXTURES=[f'v{v}-{t}' for v in (3,4,5) for t in ('college_dropout','graduate')]+['v5-ordinary']
CASES=['unsupported_revision','checksum','numeric_cash','extra_education','old_version6','cash_discontinuity','retroactive_refund']
checks=0
def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path): return json.loads(Path(path).read_text(encoding='utf8'))
def check(value,label):
    global checks
    checks+=1
    if not value: raise AssertionError(label)
def normalize(value):
    value=copy.deepcopy(value);value['sequence']='1';return value
def projection(value,original):
    value=normalize(value);value['content_revision']=original['content_revision']
    check(value['run']['studio_finance'].pop('education')=={},'only empty education field removed')
    value['run']['studio_finance']['schema_version']='5';return value
def fixture(name):
    manifest=read(OLD/(name+'.manifest.json'))
    check(manifest['source_sha256']==sha(OLD/'source-before.json'),'authentic pre-education source binding')
    for ext,digest in manifest['files'].items():check(sha(OLD/(name+'.'+ext))==digest,name+' original '+ext)
    outer=read(OLD/(name+'.checkpoint.json'));raw=(OLD/(name+'.payload.json')).read_bytes()
    check(outer['payload_utf8'].encode()==raw,'authentic exact payload bytes')
    check(outer['payload_sha256']==hashlib.sha256(raw).hexdigest(),'authentic envelope checksum')
    return json.loads(raw)
SOURCE=read(H/'source-before.json')
check(SOURCE==read(H/'source-after.json'),'source unchanged across complete run')
for name,digest in SOURCE['drivers'].items():check(sha(H/name)==digest,'execution driver stable '+name)
check(SOURCE['old_source']==sha(OLD/'source-before.json'),'old source pin')
def accepted(name):
    manifest=read(H/(name+'.manifest.json'));before=read(H/(name+'.before.json'))
    after=read(H/(name+'.after.json'));command=read(H/(name+'.command.json'))
    check(manifest['source_sha256']==sha(H/'source-before.json'),'process manifest source binding')
    check(before['source']==SOURCE and after==SOURCE,'process exact before/after source')
    check(before['inputs']==manifest['inputs'],'process inputs manifest binding')
    for ext,digest in manifest['artifacts'].items():check(sha(H/(name+'.'+ext))==digest,'artifact hash '+name+' '+ext)
    for path,digest in manifest['inputs'].items():check(sha(path)==digest,'accepted input retained '+path)
    for path,digest in manifest['outputs'].items():check(sha(path)==digest,'accepted output retained '+path)
    check(command['command']==before['command'] and command['profile']==before['profile'],'command/profile binding')
    check(command['exit_code']==0,'native zero exit')
    text=(H/(name+'.log')).read_text(encoding='utf8')
    errors=[s for s in text.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b|E4_ASSERT:',s,re.I) and s.strip()!='ERROR: Failed to read the root certificate store.']
    check(not errors,'no unclassified engine/assertion error')
    report=read(H/(name+'.result.json'))
    check(report['passed'] and report['failures']==[],'native assertions all passed')
    return report
def capture_valid(payload,original):
    check(payload['content_revision']!=original['content_revision'],'new revision')
    check(payload['run']['studio_finance']['schema_version']=='6','new schema')
    check(projection(payload,original)==normalize(original),'every old serialized field retained')
    check(payload['run']['studio_traits']==original['run']['studio_traits'],'canonical historical trait identity')
    t=payload['run']['studio_traits'];f=payload['run']['studio_finance']
    check(t['active_ids']==[] and t['refunded_points']=='0' and t['point_cash_cents']=='20000','no trait activation/refund/reprice')
    check(f['education']=={} and f['obligations']==[] and f['bank_loans']==[],'no new debt/bill')
    check(len(f['actions'])==1 and len(f['transactions'])==2,'no extra creation action/receipt')
    check(f['transactions'][1]['amount_cents']=='20000' and f['transactions'][1]['source_id']=='studio_trait_unspent_points_v1','exact original point receipt')
    check(payload['run']['cash_cents']=='570000' and payload['run']['completed_run_cycles']=='0','unchanged cash/time')
    check(payload['rng']==original['rng'] and payload['run_id']==original['run_id'],'RNG and identity preserved')
    return t
rows=[]
for name in FIXTURES:
    original=fixture(name);migrate=accepted(name+'-migrate');cold=accepted(name+'-verify')
    check(migrate['original']==original,'actual old input represented')
    check(migrate['capture']==cold['capture'],'separate-process canonical equality')
    check(migrate['stored']==cold['stored'],'same new-generation payload')
    check(migrate['stored']['sequence']=='2','new generation sequence')
    check(normalize(migrate['stored'])==migrate['capture'],'stored/current sequence normalization only')
    t=capture_valid(migrate['capture'],original);capture_valid(cold['capture'],original)
    check(migrate['files_before']=={'checkpoint.1.json':sha(OLD/(name+'.checkpoint.json'))},'exact original copy before load')
    check(migrate['files_after']['checkpoint.1.json']==migrate['files_before']['checkpoint.1.json'],'old bytes survive new save')
    check(cold['files_before']==cold['files_after']==migrate['files_after'],'cold Continue performs no file mutation')
    check(cold['component_fixture'] and cold['synthetic_income_per_even_cycle_cents']==50000,'component limit explicitly labeled')
    check(set(cold['component_boundaries'])=={'24','26','28'},'grace/firstdue/secondduelike boundary coverage')
    for boundary,finance in cold['component_boundaries'].items():
        cycle=int(boundary);months=cycle//2
        check(finance['schema_version']==6 and finance['last_cycle']==cycle,'component schema/cycle')
        check(finance['cash_cents']==570000 and finance['initial_cash_cents']==550000,'component cash/base')
        check(finance['education']=={} and finance['bank_loans']==[] and finance['employees']==[],'no component account introduced')
        check(len(finance['obligations'])==months,'only ordinary monthly rent bill count')
        for i,bill in enumerate(finance['obligations'],1):
            check(bill['expense_type']=='rent' and bill['due_cycle']==i*2 and bill['due_cents']==50000,'exact rent bill')
            check(bill['paid_cents']==50000 and bill['unpaid_cents']==0 and bill['paid_on_time'],'rent fully serviced')
        check(len(finance['actions'])==cycle+1,'component actions plus single original receipt')
        for action in finance['actions'][1:]:
            check(action['productive'] and action['source_id']=='e4_component_rent_funding' and action['kind']=='other_income','declared component inputs')
            check(action['direct_delta']==(50000 if action['cycle']%2==0 else 0) and action['cash_before']==570000,'exact component income/cash input')
        receipts=[a for a in finance['actions'] if a['source_id']=='studio_trait_unspent_points_v1']
        check(len(receipts)==1 and receipts[0]['direct_delta']==20000,'no extra historical refund/point action')
        cash=0
        for index,tx in enumerate(finance['transactions'],1):
            check(tx['sequence']==index and tx['cash_before_cents']==cash,'component ordered cash provenance')
            cash+=tx['cash_delta_cents'];check(tx['cash_after_cents']==cash,'component cash delta reconciles')
            check(tx['kind'] not in ['education_payment','education_payoff','education_interest_due'],'no component education transaction')
        check(cash==570000,'component final cash independently reconciled')
        for row in finance['monthly_rows']:
            check(row['rent_due_cents']==row['rent_paid_cents']==50000 and row['rent_unpaid_cents']==0,'component monthly rent')
            check(row['interest_cents']==row['interest_paid_cents']==row['principal_paid_cents']==0,'zero debt principal/interest')
            check(row['other_income_cents']==50000 and row['net_profit_cents']==0,'explicit component funding offsets rent only')
    rows.append({'fixture':name,'version':t['version'],'cash_cents':570000,'new_revision':cold['capture']['content_revision'],'native_checks':migrate['checks']+cold['checks']})
original=fixture('v5-graduate');negative=accepted('rejections');recovered=accepted('recovery-cold')
check(set(negative['records'])==set(CASES)==set(recovered['records']),'all seven negative/recovery cases')
for name in CASES:
    item=negative['records'][name];cold=recovered['records'][name]
    check(item['classification']==('incompatible' if name=='unsupported_revision' else 'invalid') and bool(item['reason']),'correct rejection classification/reason')
    check(item['before']['checkpoint.1.json']==sha(OLD/'v5-graduate.checkpoint.json'),'negative valid backup authentic')
    check(all(item['rejected_directory_after'][key]==value for key,value in item['before'].items()),'both input generations preserved through rejection/recovery')
    check(item['capture']==cold['capture'],'fresh recovered state exact')
    check(item['recovery_files']==cold['files'],'fresh recovery files exact')
    capture_valid(cold['capture'],original)
    if name=='unsupported_revision':check(item['before']==item['rejected_directory_after'] and set(item['recovery_files'])=={'checkpoint.1.json'},'unsupported original directory untouched, separate valid-copy recovery')
    else:check(set(item['recovery_files'])=={'checkpoint.1.json','checkpoint.2.json','checkpoint.3.json'},'explicit backup restore retains damaged bytes')
summary=read(H/'summary.json')
check(summary['passed'] and summary['processes']==16,'all16 native processes')
check(len({r['new_revision'] for r in rows})==1,'one supported new revision')
result={'passed':True,'checks':checks,'processes':16,'authentic_fixture_pairs':7,'rejection_cases':7,'component_boundaries_per_fixture':[24,26,28],'native_checks':summary['native_checks'],'old_revision':original['content_revision'],'new_revision':rows[0]['new_revision'],'rows':rows,'auditor_sha256':sha(__file__),'source_manifest_sha256':sha(H/'source-before.json')}
(H/'audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps({k:v for k,v in result.items() if k!='rows'},indent=2))
