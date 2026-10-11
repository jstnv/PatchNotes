from pathlib import Path
import json,hashlib,re
HERE=Path(__file__).resolve().parent
COPY=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/cult-t7-high-v1-candidate-copy')
SOURCE=Path(r'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-integration-v1-source-copy')
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def capture():
 manifest=json.loads((HERE/'source-manifest.json').read_text());hooks=json.loads((HERE.parent/'cult-following-t7-v1/candidate-hook-hashes.json').read_text())
 for name,h in manifest['files'].items():
  assert sha(SOURCE/name)==h,('original drift',name)
  assert sha(COPY/name)==hooks.get(name,h),('candidate drift',name)
 for name,h in hooks.items():assert sha(COPY/name)==h,('hook drift',name)
 drivers={name:sha(HERE/name) for name in ['candidate_high.gd','candidate_route.gd','candidate_restart.gd']}
 for name,h in drivers.items():assert sha(COPY/'scripts/debug'/name)==h,('driver drift',name)
 expected=set(manifest['files'])|set(hooks)|{'scripts/debug/'+n for n in drivers}|{'scripts/debug/candidate_neutral_continue.gd'}
 for p in COPY.rglob('*.gd'):assert p.relative_to(COPY).as_posix() in expected,('unexpected script',p)
 return dict(original_manifest_sha256=sha(HERE/'source-manifest.json'),files=len(manifest['files']),hooks=hooks,drivers=drivers,plan_sha256=sha(HERE/'PLAN.md'),foundation_sha256=sha(HERE/'foundation.json'),runner_sha256=sha(HERE/'run.py'),evidence_sha256=sha(HERE/'evidence.py'))
def check_log(s):
 errors=[line for line in s.splitlines() if re.search(r'SCRIPT ERROR:|\bERROR:|\bFAIL(?:ED|URE)?\b',line,re.I) and line.strip()!='ERROR: Failed to read the root certificate store.']
 assert not errors,errors
def accept(name,source,args,build):
 m=json.loads((HERE/(name+'.manifest.json')).read_text());c=json.loads((HERE/(name+'.command.json')).read_text())
 assert m['source']==source and c['command']==args and c['seed']==build[1] and c['price']==build[2] and c['exit_code']==0,('source/config mismatch',name)
 for ext in ['json','log','command.json']:assert sha(HERE/(name+'.'+ext))==m['files'][ext],('evidence changed',name,ext)
 check_log((HERE/(name+'.log')).read_text(encoding='utf8'))
 return m
