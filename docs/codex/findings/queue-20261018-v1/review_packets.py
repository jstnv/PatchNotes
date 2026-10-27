from pathlib import Path
import json,zipfile,hashlib,difflib
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
def sha(b):return hashlib.sha256(b).hexdigest()
def identity(d):return sha(json.dumps(d,sort_keys=True,separators=(',',':')).encode())
for tag,folder in [('contracts','contracts/handoffs/contracts-challenges-runtime-v2'),('ai','ai-competitors/handoffs/market-save-review-20261018-v1')]:
 packet=ROOT/'docs/codex/threads'/folder
 h=json.loads((packet/'handoff.json').read_text())
 base=zipfile.ZipFile(packet/'base-source.zip');candidate=zipfile.ZipFile(packet/'candidate-source.zip')
 rows=[]
 for d in h['changes']:
  name=d['path'];old=base.read(name) if name in base.namelist() else None;new=candidate.read(name) if name in candidate.namelist() else None
  assert (sha(old) if old else None)==d['before_sha256'],name
  assert (sha(new) if new else None)==d['after_sha256'],name
  f=ROOT/'patch-notes'/name;current=f.read_bytes() if f.exists() else None
  rows.append({**d,'current_sha256':sha(current) if current else None,'status':'unchanged baseline' if current==old else 'already candidate' if current==new else 'current drift'})
 result={'packet':str(packet.relative_to(ROOT)),'changed_bytes_verified':True,'rows':rows,'base_identity':h['base_identity'],'candidate_identity':h['candidate_identity']}
 (OUT/(tag+'-packet-review.json')).write_text(json.dumps(result,indent=2)+'\n')
 print(tag,len(rows),'changed paths verified;',sum(r['status']=='current drift' for r in rows),'overlaps')
