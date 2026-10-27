from pathlib import Path
import difflib, hashlib, json
out=Path(__file__).resolve().parent;root=out.parents[3]
sha=lambda data:hashlib.sha256(data).hexdigest()
paths=['scripts/ui/card_score_floats.gd','scripts/market/rival_world_checkpoint.gd','scripts/debug/verify_score_floats.gd']
files={};patch=[]
for name in paths:
    before=(out/'before'/name).read_bytes();after=(root/'patch-notes'/name).read_bytes()
    files[name]={'before_sha256':sha(before),'sha256':sha(after)}
    patch.extend(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(out/'scoped.patch').write_text(''.join(patch),encoding='utf-8',newline='')
actual=json.loads((out/'identity-final.json').read_text())
for resource,digest in actual['rows']:
    assert sha((root/'patch-notes'/resource.removeprefix('res://')).read_bytes())==digest,resource
old=[]
for path,digest in actual['rows']:
    original=out/'before'/path.removeprefix('res://')
    old.append([path,sha(original.read_bytes()) if original.is_file() else digest])
identity=lambda rows:sha(json.dumps(rows,ensure_ascii=False,separators=(',',':')).encode())
before_source=json.loads((out/'before-pair.json').read_text())['rival_world']['source_identity']
assert identity(old)==before_source
assert identity(actual['rows'])==actual['identity']
labels=['green-final-v2','native-final','sync','cold-final']
for label in labels:
    receipt=json.loads((out/(label+'-run.json')).read_text())
    assert receipt['exit']==0 and not receipt['errors'],label
result={'head':'087df09d653858b72c6e2dc344352237433dd3ac','branch':'main','source_identity':actual['identity'],'before_source_identity':before_source,'exact_before_reconstruction':True,'files':files,'passing_labels':labels}
(out/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({key:value for key,value in result.items() if key!='files'},indent=2))
