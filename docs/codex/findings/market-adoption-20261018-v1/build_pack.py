"""Refresh the already-clean export source; retain prior package and all evidence."""
from pathlib import Path
import importlib.util,json,shutil,subprocess,sys
OUT=Path(__file__).resolve().parent/'export-v3';OUT.mkdir(exist_ok=False)
ROOT=OUT.parents[4];PROJECT=ROOT/'patch-notes'
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.OUT=OUT
previous=json.loads((OUT.parent/'export-v2/build-manifest.json').read_text(encoding='utf-8'))
source=Path(previous['workspace'])/'source'
manifest=json.loads(json.dumps(previous));manifest['workspace']=str(OUT.resolve());manifest['source_project']=str(source)
manifest['previous_package']='../export-v2/clean/demo/Patch Notes Demo.pck'
manifest['source_refresh']=[]
for rel in manifest['included']:
    path=PROJECT/rel
    digest=m.sha(path)
    if digest!=manifest['included'][rel]:
        assert rel not in ['project.godot','export_presets.cfg'],'Unexpected build input change'
        shutil.copy2(path,source/rel)
        manifest['source_refresh'].append(rel)
    manifest['included'][rel]=digest
env=m.isolated_export_environment(OUT)
godot=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
m.run('refresh-import',[godot,'--headless','--path',source,'--editor','--import','--quit'],env,OUT)
demo=OUT/'demo';demo.mkdir();pack=demo/'Patch Notes Demo.pck'
m.run('export-pack',[godot,'--headless','--path',source,'--export-pack','Windows Desktop',pack],env,OUT)
manifest['artifacts']={pack.name:{'sha256':m.sha(pack),'bytes':pack.stat().st_size}}
manifest['status']='current pack exported; final native/release checks separately recorded'
(OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',OUT/'inspect.py')
subprocess.run([sys.executable,str(OUT/'inspect.py')],check=True)
print(json.dumps({'refresh':manifest['source_refresh'],'artifacts':manifest['artifacts']}),flush=True)
