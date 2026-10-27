"""Read-only full sealed-packet, evidence and current-drift audit."""
from pathlib import Path
import hashlib,json,zipfile
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
def sha(b):return hashlib.sha256(b).hexdigest()
report={}
for tag,folder in [('contracts','contracts-challenges-runtime-v2'),('ai-competitors','market-save-review-20261018-v1')]:
 packet=ROOT/'docs/codex/threads'/tag/'handoffs'/folder
 h=json.loads((packet/'handoff.json').read_text())
 count=0
 for name,digest in json.loads((packet/'handoff-integrity.json').read_text()).items():
  assert sha((packet/name).read_bytes())==digest,name
  count+=1
 manifests={}
 for revision in ['base','candidate']:
  manifest=json.loads((packet/(revision+'-manifest.json')).read_text())
  assert sha(json.dumps(manifest,sort_keys=True).encode())==h[revision+'_identity']
  with zipfile.ZipFile(packet/(revision+'-source.zip')) as z:
   assert set(z.namelist())==set(manifest)
   for name,digest in manifest.items():assert sha(z.read(name))==digest,name
  manifests[revision]={'identity':h[revision+'_identity'],'verified_entries':len(manifest)}
 evidence=[]
 for bundle in h['evidence']:
  for name,digest in bundle['files'].items():assert sha((Path(bundle['bundle'])/name).read_bytes())==digest,name
  evidence.append({'bundle':bundle['bundle'],'verified_entries':len(bundle['files']),'source_identity':bundle['source_identity']})
 rows=[]
 for d in h['changes']:
  p=ROOT/'patch-notes'/d['path'];current=sha(p.read_bytes()) if p.exists() else None
  rows.append({**d,'current_sha256':current,'status':'baseline' if current==d['before_sha256'] else 'candidate' if current==d['after_sha256'] else 'reconcile'})
 report[tag]={'packet':str(packet.relative_to(ROOT)),'integrity_files':count,'manifests':manifests,'evidence':evidence,'rows':rows}
(OUT/'packet-audit-final.json').write_text(json.dumps(report,indent=2)+'\n')
for tag,r in report.items():print(tag,'PASS',r['manifests'],'current overlaps',[x['path'] for x in r['rows'] if x['status']=='reconcile'])
