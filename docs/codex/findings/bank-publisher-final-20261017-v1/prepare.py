from pathlib import Path
import json, hashlib, shutil, subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[3]
OLD=BASE.parent/'queue-execution-20261017-v2'
sha=lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((OLD/'final-delivery-v4/build-manifest.json').read_text(encoding='utf-8'))
changed=[k for k,v in manifest['included'].items() if sha(ROOT/'patch-notes'/k)!=v]
artifacts={k:sha(Path(manifest['workspace'])/'demo'/k) for k in manifest['artifacts']}
assert not changed, changed
assert all(artifacts[k]==v['sha256'] for k,v in manifest['artifacts'].items())
pin={'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'manifest':str(OLD/'final-delivery-v4/build-manifest.json'),'runtime_files_checked':len(manifest['included']),'changed':changed,'artifacts':artifacts}
(BASE/'source-pin.json').write_text(json.dumps(pin,indent=2),encoding='utf-8')
(BASE/'.gdignore').touch()
print(json.dumps(pin,indent=2))
for directory in ['queue-completion-20261011-v1/checkpoints','refreshed-acceptance-20261017-v1/profiles']:
 for p in (BASE.parent/directory).rglob('checkpoint.*.json'):
  try:
   payload=json.loads(json.loads(p.read_text(encoding='utf-8'))['payload_utf8']); run=payload['run']
   print(str(p.relative_to(BASE.parent)), 'cycle',run.get('completed_run_cycles',run.get('run_cycles')), 'cash',run.get('cash_cents'))
  except Exception as e: print(type(e).__name__,str(p))
