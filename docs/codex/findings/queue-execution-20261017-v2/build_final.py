from pathlib import Path
import importlib.util, json, shutil, runpy, os
BASE=Path(__file__).resolve().parent; ROOT=BASE.parents[3]
spec=importlib.util.spec_from_file_location('builder',ROOT/'docs/codex/findings/export-queue-v3/export.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
m.ROOT=BASE/'final-export-source';m.OUT=BASE/'final-delivery-v3'
temp=ROOT/'.codex-godot-temp/qv2-build-temp';temp.mkdir(exist_ok=False)
original_run=m.run
def checked_run(name,argv,env,cwd,timeout=180):
    env=dict(env,TMP=str(temp),TEMP=str(temp))
    result=original_run(name,argv,env,cwd,timeout)
    errors=[s for s in (m.OUT/(name+'.log')).read_text(errors='replace').splitlines() if s.startswith('ERROR:') and 'root certificate' not in s]
    if errors: raise RuntimeError(str(errors))
    return result
m.run=checked_run
# Keep this task's build and profiles inside its evidence directory.
tmp=BASE/'final-tmp';tmp.mkdir(exist_ok=True);m.tempfile.tempdir=str(tmp)
m.main()
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',m.OUT/'inspect.py')
runpy.run_path(str(m.OUT/'inspect.py'),run_name='__main__')
pack=json.loads((m.OUT/'pack-manifest-verified.json').read_text())
assert pack['files']['res://project.binary']['bytes']>0
