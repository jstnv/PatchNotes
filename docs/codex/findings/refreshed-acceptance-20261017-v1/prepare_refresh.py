"""Pin the concurrent archive validation/formatting delta as a new snapshot."""
from pathlib import Path
import datetime, hashlib, json, shutil

BASE=Path(__file__).resolve().parent
REPO=BASE.parents[3]
OUT=BASE/'latest'
OUT.mkdir(exist_ok=False)
shutil.copytree(BASE/'snapshot',OUT/'snapshot',ignore=shutil.ignore_patterns('.godot','__pycache__'))
old=json.loads((BASE/'pin.json').read_text())
project=REPO/'patch-notes'
source={}
for folder in ('scripts','scenes','data','assets','resources','autoload'):
    if not (project/folder).exists():continue
    for p in (project/folder).rglob('*'):
        if p.is_file():source[p.relative_to(project).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
for name in ('project.godot','export_presets.cfg','icon.svg','icon.svg.import'):
    if (project/name).exists():source[name]=hashlib.sha256((project/name).read_bytes()).hexdigest()
for rel,digest in source.items():
    target=OUT/'snapshot/patch-notes'/rel
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(project/rel,target)
    assert hashlib.sha256(target.read_bytes()).hexdigest()==digest
changed=[rel for rel,digest in source.items() if old['source'].get(rel)!=digest]
(OUT/'pin.json').write_text(json.dumps({'head':old['head'],'time_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':source,'changed_from_initial':changed},indent=2)+'\n')
for name in ('build.py','run_world_processes.py','world_process_probe.gd'):
    shutil.copy2(BASE/name,OUT/name)
probe=OUT/'world_process_probe.gd'
text=probe.read_text()
anchor='\t\t\texpect(coordinator.store.inspect().payload==committed,"rejected validation preserves durable generation")'
assert anchor in text
text=text.replace(anchor,'\t\t\tmalformed = committed.duplicate(true)\n\t\t\tmalformed.rival_world.studios[0].archive = []\n\t\t\texpect(not coordinator._validate_payload(malformed).is_empty(),"empty frozen archive rejected")\n\t\t\tmalformed = committed.duplicate(true)\n\t\t\tmalformed.rival_world.studios[1].archive[0].id = malformed.rival_world.studios[0].archive[0].id\n\t\t\texpect(not coordinator._validate_payload(malformed).is_empty(),"archive ID shared across rivals rejected")\n'+anchor)
probe.write_text(text)
print(json.dumps({'changed':changed,'files':len(source)}))
