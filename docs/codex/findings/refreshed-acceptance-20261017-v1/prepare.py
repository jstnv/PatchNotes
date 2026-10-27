"""Freeze current source and test helpers without touching canonical caches/saves."""
from pathlib import Path
import datetime, hashlib, json, shutil, subprocess

OUT = Path(__file__).resolve().parent
REPO = OUT.parents[3]
SNAPSHOT = OUT / 'snapshot'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

SNAPSHOT.mkdir(exist_ok=False)
(OUT / '.gdignore').touch()
project = REPO / 'patch-notes'
for directory in ('scripts','scenes','data','assets','resources','autoload'):
    if (project / directory).exists():
        shutil.copytree(project / directory, SNAPSHOT / 'patch-notes' / directory)
for name in ('project.godot','export_presets.cfg','icon.svg','icon.svg.import'):
    if (project / name).exists(): shutil.copy2(project / name, SNAPSHOT / 'patch-notes' / name)
helpers = ['tools/release_gate.py','docs/codex/findings/checkpoint-runtime-v1/run_checks.py',
           'docs/codex/findings/export-queue-v3/export.py','docs/codex/findings/export-queue-v3/inspect.py']
for relative in helpers:
    target = SNAPSHOT / relative
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(REPO / relative,target)
source = {p.relative_to(SNAPSHOT / 'patch-notes').as_posix(): sha(p)
          for p in sorted((SNAPSHOT / 'patch-notes').rglob('*')) if p.is_file()}
for relative,digest in source.items():
    assert sha(project / relative)==digest, 'Source moved while copying: '+relative
metadata = {'time_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'branch':subprocess.check_output(['git','branch','--show-current'],cwd=REPO,text=True).strip(),
            'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip(),
            'source':source,'helpers':{p:sha(REPO/p) for p in helpers},
            'purpose':'Immutable acceptance copy of current dirty canonical source; no gameplay changes or candidate adoption.'}
(OUT/'pin.json').write_text(json.dumps(metadata,indent=2)+'\n')
(OUT/'status-before.txt').write_text(subprocess.check_output(['git','status','--short','--untracked-files=no'],cwd=REPO,text=True))
(OUT/'runtime-before.diff').write_text(subprocess.check_output(['git','diff','--','patch-notes'],cwd=REPO,text=True))
print(json.dumps({'snapshot':str(SNAPSHOT),'files':len(source),'head':metadata['head']}))
