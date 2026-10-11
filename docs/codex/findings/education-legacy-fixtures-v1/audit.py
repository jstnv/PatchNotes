"""Offline audit of immutable, pre-education native fixture bytes."""
from pathlib import Path
import hashlib,json,re
H=Path(__file__).resolve().parent
checks=0
def check(value,label):
 global checks
 checks+=1
 if not value:raise AssertionError(label)
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
source=json.loads((H/'source-before.json').read_text(encoding='utf8'))
check((H/'source-before.json').read_bytes()==(H/'source-after.json').read_bytes(),'source pin unchanged')
check(len(source['files'])==215,'relevant source inventory')
fixtures=[(f'v{version}-{trait}',trait,version) for version in [3,4,5] for trait in ['college_dropout','graduate']]+[('v5-ordinary','',5)]
rows=[];profiles=[];run_ids=[]
for name,trait,version in fixtures:
 manifest=json.loads((H/(name+'.manifest.json')).read_text(encoding='utf8'))
 check(manifest['source_sha256']==sha(H/'source-before.json'),'source manifest binding')
 for ext,h in manifest['files'].items():check(sha(H/(name+'.'+ext))==h,'exact '+name+' '+ext)
 envelope=json.loads((H/(name+'.checkpoint.json')).read_text(encoding='utf8'))
 raw=(H/(name+'.payload.json')).read_bytes();payload=json.loads(raw)
 check(envelope['format']=='patch-notes-studio-checkpoint' and envelope['schema_version']=='1','old envelope format')
 check(envelope['payload_utf8'].encode('utf8')==raw and hashlib.sha256(raw).hexdigest()==envelope['payload_sha256'],'exact envelope payload hash')
 result=json.loads((H/(name+'.result.json')).read_text(encoding='utf8'));selection=payload['run']['studio_traits'];f=payload['run']['studio_finance']
 check(result['passed'] and result['old_runtime_hydrate_exact'] and result['exported_exact'],'strict old-runtime validation')
 check(selection['version']==str(version) and selection['trait_ids']==([trait] if trait else []),'canonical selected historical version')
 check(selection['active_ids']==[] and selection['refunded_points']=='0' and selection['spent_points']=='0','inactive and no education refund')
 check(selection['remaining_points']=='4' and selection['point_cash_cents']=='20000','unchanged ordinary point conversion')
 check(payload['run']['cash_cents']=='570000' and payload['run']['completed_run_cycles']=='0','creation cash and cycle')
 check('education' not in f and 'education_account' not in f and f['bank_loans']==[] and f['obligations']==[],'no debt/account/bill fabricated')
 check(len(f['transactions'])==2 and f['transactions'][0]['kind']=='starting_funding' and f['transactions'][0]['amount_cents']=='550000','genuine base receipt')
 receipt=f['transactions'][1]
 check(receipt['kind']=='financing_in' and receipt['source_id']=='studio_trait_unspent_points_v1' and receipt['amount_cents']=='20000','only normal point financing')
 command=json.loads((H/(name+'.command.json')).read_text(encoding='utf8'))
 check(command['exit_code']==0 and command['command'][-4:]==[name,trait or 'none',str(version),str(H)],'native exact fixture inputs')
 log=(H/(name+'.log')).read_text(encoding='utf8')
 errors=[line for line in log.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b',line,re.I) and line.strip()!='ERROR: Failed to read the root certificate store.']
 check(not errors,'no unclassified native error')
 profiles.append(command['profile']);run_ids.append(payload['run_id'])
 rows.append(dict(fixture=name,version=version,trait=trait,payload_sha256=sha(H/(name+'.payload.json')),envelope_sha256=sha(H/(name+'.checkpoint.json')),content_revision=payload['content_revision']))
check(len(set(profiles))==7 and len(set(run_ids))==7,'independent profiles and genuine identities')
check(len({r['content_revision'] for r in rows})==1,'single old-runtime revision')
result=dict(passed=True,checks=checks,fixtures=7,source_files=215,content_revision=rows[0]['content_revision'],rows=rows)
(H/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in result.items() if k!='rows'},indent=2))
