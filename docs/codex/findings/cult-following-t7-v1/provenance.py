"""Source-bound result acceptance; legacy captures are explicitly post-hoc reconciled."""
from pathlib import Path
import hashlib,json,difflib,re
HERE=Path(__file__).resolve().parent
SOURCE=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-integration-v1-source-copy')
COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/cult-t7-v1-candidate-copy')
HOOKS=['scripts/studio_traits.gd','scripts/run_state.gd','scripts/fanbase/studio_fanbase.gd','scripts/persistence/studio_checkpoint.gd','scripts/fanbase/cult_candidate.gd']
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def digest(value):return hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def validate_log(text):
 failures=[];allowed=[]
 for line in text.splitlines():
  if line.strip()=='ERROR: Failed to read the root certificate store.':allowed.append(line.strip())
  elif re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b',line,re.I):failures.append(line.strip())
 assert not failures,('unclassified native errors',failures)
 return {'allowed_root_certificate_warnings':len(allowed),'unclassified_errors':failures}
def capture(driver):
 original=json.loads((HERE/'source-manifest.json').read_text(encoding='utf8'))['files']
 for name,h in original.items():
  assert sha(SOURCE/name)==h,('original source drift',name)
  if name not in HOOKS:assert sha(COPY/name)==h,('unexpected candidate source drift',name)
 expected=set(original)|set(HOOKS)|{'scripts/debug/candidate_route.gd','scripts/debug/candidate_restart.gd','scripts/debug/candidate_neutral_continue.gd'}
 for p in COPY.rglob('*.gd'):
  assert p.relative_to(COPY).as_posix() in expected,('unexpected candidate script',p)
 path=COPY/'scripts/debug'/driver
 assert sha(path)==sha(HERE/driver),'driver copy drift'
 hooks={name:sha(COPY/name) for name in HOOKS}
 result=dict(original_manifest_sha256=sha(HERE/'source-manifest.json'),original_file_count=len(original),hooks=hooks,driver=driver,driver_sha256=sha(path),plan_sha256=sha(HERE/'PLAN.md'))
 if driver=='candidate_neutral_continue.gd':
  result['inherited_driver_sha256']=sha(COPY/'scripts/debug/candidate_route.gd')
  result['continuation_plan_sha256']=sha(HERE/'NEUTRAL-CONTINUATION-PLAN.md')
 return result
def write_result(name,source,mode='captured before and checked after native process'):
 command=HERE/(name+'.command.json');data=json.loads(command.read_text(encoding='utf8'))
 assert data['exit_code']==0,name
 validate_log((HERE/(name+'.log')).read_text(encoding='utf8'))
 record=dict(mode=mode,source=source,source_sha256=digest(source),command_sha256=sha(command),result_sha256=sha(HERE/(name+'.json')),log_sha256=sha(HERE/(name+'.log')),inputs=dict(command=data['command'],candidate_seed=data['candidate_seed'],candidate_price=data['candidate_price']))
 (HERE/(name+'.result-manifest.json')).write_text(json.dumps(record,indent=2),encoding='utf8')
def validate(name,source,expected_command,build):
 record=json.loads((HERE/(name+'.result-manifest.json')).read_text(encoding='utf8'))
 assert record['source']==source and record['source_sha256']==digest(source),('stale source',name)
 assert record['command_sha256']==sha(HERE/(name+'.command.json')),('command changed',name)
 assert record['result_sha256']==sha(HERE/(name+'.json')),('result changed',name)
 assert record['log_sha256']==sha(HERE/(name+'.log')),('log changed',name)
 assert record['inputs']==dict(command=expected_command,candidate_seed=build[1],candidate_price=build[2]),('inputs changed',name)
 validate_log((HERE/(name+'.log')).read_text(encoding='utf8'))
 return record
if __name__=='__main__':
 # This reconciliation preserves commands/results. It is not represented as a
 # pre-run cryptographic capture: source pin, hook/driver timestamps, and exact
 # input/result bytes are verified now, then future reuse requires these hashes.
 count=0
 sources={driver:capture(driver) for driver in ['candidate_route.gd','candidate_restart.gd']}
 for command in sorted(HERE.glob('route-*.command.json')):
  name=command.name.removesuffix('.command.json');driver='candidate_restart.gd' if '-restart-' in name else 'candidate_route.gd'
  source=sources[driver]
  for p in [COPY/h for h in HOOKS]+[COPY/'scripts/debug'/driver]:
   assert p.stat().st_mtime_ns<command.stat().st_mtime_ns,('source newer than completion',name,p)
  if (HERE/(name+'.result-manifest.json')).exists():
   data=json.loads(command.read_text(encoding='utf8'))
   validate(name,source,data['command'],('',data['candidate_seed'],data['candidate_price']))
  else:write_result(name,source,'post-hoc source-pin and timestamp reconciliation; no pre-run cryptographic snapshot')
  count+=1
 patch=''
 for name in HOOKS:
  a=(SOURCE/name).read_text(encoding='utf8').splitlines(True) if (SOURCE/name).exists() else []
  b=(COPY/name).read_text(encoding='utf8').splitlines(True)
  patch+=''.join(difflib.unified_diff(a,b,fromfile='pinned/'+name,tofile='candidate/'+name))
 (HERE/'candidate.patch').write_text(patch,encoding='utf8')
 (HERE/'candidate-hook-hashes.json').write_text(json.dumps({h:sha(COPY/h) for h in HOOKS},indent=2),encoding='utf8')
 print('Bound existing commands/results:',count)
