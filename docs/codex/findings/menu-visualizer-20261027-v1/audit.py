from pathlib import Path
import difflib,hashlib,json
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
sha=lambda b:hashlib.sha256(b).hexdigest()
paths=['scripts/phases/main_menu.gd','scripts/market/rival_world_checkpoint.gd','scripts/ui/menu_audio_visualizer.gd','scripts/debug/verify_menu_visualizer.gd']
added={'scripts/ui/menu_audio_visualizer.gd','scripts/debug/verify_menu_visualizer.gd'}
files={};patch=[]
for name in paths:
    before=b'' if name in added else (OUT/'before'/name).read_bytes()
    after=(ROOT/'patch-notes'/name).read_bytes()
    files[name]={'before_sha256':None if name in added else sha(before),'after_sha256':sha(after),'added':name in added}
    patch.extend(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(OUT/'scoped.patch').write_text(''.join(patch),encoding='utf-8',newline='')
actual=json.loads((OUT/'identity-final.json').read_text());old=[]
for resource,digest in actual['rows']:
    rel=resource.removeprefix('res://')
    assert sha((ROOT/'patch-notes'/rel).read_bytes())==digest,resource
    if rel in added:continue
    previous=OUT/'before'/rel
    old.append([resource,sha(previous.read_bytes()) if previous.is_file() else digest])
identity=lambda rows:sha(json.dumps(rows,ensure_ascii=False,separators=(',',':')).encode())
preceding=json.loads((OUT/'before-pair.json').read_text())['rival_world']['source_identity']
assert identity(old)==preceding
assert identity(actual['rows'])==actual['identity']
labels=['headless-final','native-final','folder-navigation','settings-motion','settings','sync','cold-verified']
for label in labels:
    r=json.loads((OUT/(label+'-run.json')).read_text());assert r['exit']==0 and not r['errors'],label
result={'head':'087df09d653858b72c6e2dc344352237433dd3ac','branch':'main','before_source_identity':preceding,'source_identity':actual['identity'],'exact_before_reconstruction':True,'files':files,'passing_labels':labels}
(OUT/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k!='files'},indent=2))
