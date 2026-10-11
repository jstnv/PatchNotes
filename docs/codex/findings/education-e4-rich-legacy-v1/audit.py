"""Read-only independent audit of the two rich prior-journal migration processes."""
from pathlib import Path
import json,hashlib,copy,re,zipfile
H=Path(__file__).resolve().parent;ROOT=H.parents[3]
checks=0
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path):return json.loads(Path(path).read_text(encoding='utf8'))
def check(value,label):
    global checks
    checks+=1
    if not value:raise AssertionError(label)
def equal(a,b,label='state'):
    check(type(a)==type(b),label+' type')
    if isinstance(a,dict):
        check(set(a)==set(b),label+' keys')
        for key in a:equal(a[key],b[key],label+'.'+key)
    elif isinstance(a,list):
        check(len(a)==len(b),label+' length')
        for i,(x,y) in enumerate(zip(a,b)):equal(x,y,label+'.'+str(i))
    else:check(a==b,label+' value')
def norm(a):
    a=copy.deepcopy(a);a['sequence']='1';return a
provenance=read(H/'provenance.json');source=read(H/'source-before.json')
check(source==read(H/'source-after.json'),'all current source unchanged')
check(source['provenance_sha256']==sha(H/'provenance.json'),'old input/provenance binding')
for path,digest in source['drivers'].items():check(sha(ROOT/path)==digest,'execution driver unchanged')
for path,digest in provenance['files'].items():check(sha(ROOT/path)==digest,'original source/evidence unchanged '+path)
OLD=H.parent/'starwave-implementation-v1';pin=read(OLD/'source-pin-recovery-v3.json');manifest=read(OLD/'source-manifest-v3.json');original_audit=read(OLD/'audit-summary-v3.json')
check(pin['complete'] and pin['source_manifest_sha256']==sha(OLD/'source-manifest-v3.json') and pin['original_audit_summary_sha256']==sha(OLD/'audit-summary-v3.json'),'authentic prior source/audit chain')
with zipfile.ZipFile(OLD/pin['archive']) as z:
    check(set(z.namelist())==set(pin['archive_files']),'complete supplemental archive inventory')
    for name in z.namelist():check(hashlib.sha256(z.read(name)).hexdigest()==pin['archive_files'][name]==manifest['files'][name],'archive member original source match '+name)
fixture=OLD/'native-v3/before-starwave.checkpoint.1.json';outer=read(fixture);original=json.loads(outer['payload_utf8'])
check(sha(fixture)=='01a7a395dc5c60543886a6840714d2c32de6cd83c6e28e48df579ce81010c202','exact approved original envelope')
check(hashlib.sha256(outer['payload_utf8'].encode()).hexdigest()==outer['payload_sha256']=='761448df55e1e7e99721d297a39a715d2115d8c10084d2e84631b745fb1d977c','exact approved payload bytes')
check(original['content_revision']==provenance['revision']=='c7f6f3165ea85f7afd5070042d053ce581f84338437640c3e4b6de787c1f5a5b','actual supported content revision')
route=read(OLD/'native-v3/native-route.json');check(route['valid'] and route['errors']==route['blockers']==[],'valid prior native route')
equal(route['before_checkpoint'],original,'archived native checkpoint')
results={}
for mode in ['migrate','verify']:
    result=read(H/(mode+'.result.json'));binding=read(H/(mode+'.manifest.json'));before=read(H/(mode+'.before.json'));after=read(H/(mode+'.after.json'));command=read(H/(mode+'.command.json'))
    check(binding['source_sha256']==sha(H/'source-before.json') and before['source']==after==source,'process source bound before/after')
    check(binding['inputs']==before['inputs'],'process exact input binding')
    for path,digest in binding['inputs'].items():check(sha(path)==digest,'native input retained')
    for path,digest in binding['outputs'].items():check(sha(path)==digest,'native output retained')
    for ext,digest in binding['artifacts'].items():check(sha(H/(mode+'.'+ext))==digest,'process artifact hash')
    check(command['exit_code']==0 and command['command']==before['command'] and command['profile']==before['profile'],'native command/profile/exit')
    errors=[s for s in (H/(mode+'.log')).read_text(encoding='utf8').splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b|E4_ASSERT:',s,re.I) and s.strip()!='ERROR: Failed to read the root certificate store.']
    check(not errors and result['passed'] and result['failures']==[],'native error/assertion status')
    projected=norm(result['capture']);check(projected['run']['studio_finance'].pop('education')=={},'new education field empty')
    check(projected['run']['studio_finance']['schema_version']=='6','new finance6')
    projected['run']['studio_finance']['schema_version']='5';projected['content_revision']=original['content_revision']
    equal(projected,norm(original),'every prior value '+mode)
    equal(norm(result['stored']),result['capture'],'stored captured equality '+mode)
    check(result['stored']['sequence']=='2','new saved generation2')
    check(result['files_after']['checkpoint.1.json']==sha(fixture),'exact original generation remains')
    results[mode]=result
equal(results['migrate']['capture'],results['verify']['capture'],'independent-process exact state')
check(results['migrate']['files_after']==results['verify']['files_before']==results['verify']['files_after'],'cold restore no file mutation')
r=original['run'];f=r['studio_finance']
check(r['completed_run_cycles']=='54' and r['cash_cents']=='1684767','rich state time/cash')
check(len(f['actions'])==59 and len(f['transactions'])==198 and len(f['obligations'])==38,'nontrivial journal counts')
check(len(f['credit']['history'])==27 and len(r['fanbase']['months'])==27,'credit and Fan history retained')
check(len(f['bank_loans'])==1 and not f['bank_loans'][0]['closed'] and f['bank_loans'][0]['schedule']['principal_cents']=='50000','active accepted Bank loan retained')
check(f['bank_loans'][0]['issued']=='0','explicit Bank limit: no installment issued at this endpoint')
check(len(f['employees'])==1 and f['employees'][0]['issued']=='11','11 genuine payroll boundaries')
check(len(r['released_games'])==3 and r['fanbase']['fans']=='240','three titles and240 Fans')
awards={p['key']:int(p['value']) for p in r['promotion_awards']};consumed={p['key']:p['value'] for p in r['promotion_consumed']}
check(sum(amount for key,amount in awards.items() if key not in consumed)==18,'18 Promotion still pending')
check(r['studio_traits']['version']=='5' and 'education' not in f,'historical no-education source')
cash=0
for i,tx in enumerate(f['transactions'],1):
    check(int(tx['sequence'])==i and int(tx['cash_before_cents'])==cash,'original transaction ordered cash')
    cash+=int(tx['cash_delta_cents']);check(int(tx['cash_after_cents'])==cash,'original cash delta reconciliation')
check(cash==1684767,'full journal final cash')
summary=read(H/'summary.json');check(summary['passed'] and summary['processes']==2,'two bounded fresh processes')
result={'passed':True,'checks':checks,'processes':2,'native_checks':summary['native_checks'],'source_files':len(source['runtime']),'archive_members':provenance['archive_members'],'cycle':54,'cash_cents':1684767,'finance_actions':59,'finance_transactions':198,'bills':38,'payroll_bills':11,'fans':240,'pending_promotion':18,'new_revision':results['verify']['capture']['content_revision'],'source_manifest_sha256':sha(H/'source-before.json'),'auditor_sha256':sha(__file__),'original_checkpoint_sha256':sha(fixture)}
(H/'audit.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8');print(json.dumps(result,indent=2))
