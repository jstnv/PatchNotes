from pathlib import Path
import hashlib, importlib.util, json, subprocess, zipfile
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
(HERE/'.gdignore').touch()
manifest=sim.copy_snapshot(ROOT/'patch-notes',HERE/'old-project-02')
sim.write_json(HERE/'old-source-manifest.json',manifest)
paths=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))
paths += [ROOT/'docs/codex/TODO.md',ROOT/'docs/codex/design/studio-traits.md',ROOT/'docs/codex/CURRENT_STATE.md']
with zipfile.ZipFile(HERE/'before-source.zip','x',zipfile.ZIP_DEFLATED) as z:
    for p in paths:z.write(p,p.relative_to(ROOT))
sim.write_json(HERE/'before-hashes.json',{p.relative_to(ROOT).as_posix():sim.sha(p) for p in paths})
for name,args in [('head.txt',['rev-parse','HEAD']),('status-before.txt',['status','--short']),('diff-before.patch',['diff'])]:
    (HERE/name).write_bytes(subprocess.check_output(['git',*args],cwd=ROOT,stderr=subprocess.DEVNULL))
print('Frozen old runtime files:',len(manifest))
