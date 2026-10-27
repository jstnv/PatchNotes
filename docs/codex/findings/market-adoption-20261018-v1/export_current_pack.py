"""Low-disk current PCK refresh; no executable copy or temporary project copy."""
from pathlib import Path
import importlib.util,json,shutil,subprocess,sys
OUT=Path(__file__).resolve().parent/'export-v5'
OUT.mkdir(exist_ok=True)
ROOT=OUT.parents[4];PROJECT=ROOT/'patch-notes'
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.OUT=OUT
previous=json.loads((OUT.parent/'export-v2/build-manifest.json').read_text(encoding='utf-8'))
manifest=json.loads(json.dumps(previous));manifest['workspace']=str(OUT.resolve());manifest['source_project']=str(PROJECT)
manifest.pop('build_only_override',None);manifest.pop('build_only_template_paths',None)
manifest['method']='Current canonical PCK export after clean v2 export; every packed runtime entry audited. No new full executable allocation.'
for rel in manifest['included']:manifest['included'][rel]=m.sha(PROJECT/rel)
env=m.isolated_export_environment(OUT)
godot=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
pack=OUT/'demo/Patch Notes Demo.pck'
pack.parent.mkdir(parents=True,exist_ok=True)
exe=pack.with_suffix('.exe')
if not exe.exists():
    shutil.copy2(OUT.parent/'export-v4/demo/Patch Notes Demo.exe',exe)
m.run('export-pack',[godot,'--headless','--path',PROJECT,'--export-pack','Windows Desktop',pack],env,OUT)
manifest['artifacts']={p.name:{'sha256':m.sha(p),'bytes':p.stat().st_size} for p in [pack,exe]}
manifest['runtime_provenance']='Byte-identical copy of the hash-verified official runtime from queue-20261018-v1/export-v5; no resource editing.'
manifest['status']='current package exported; acceptance separately recorded'
(OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',OUT/'inspect.py')
subprocess.run([sys.executable,str(OUT/'inspect.py')],check=True)
print(json.dumps(manifest['artifacts']),flush=True)
