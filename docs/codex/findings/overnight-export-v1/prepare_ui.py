from pathlib import Path
import json,os,importlib.util
root=Path.cwd();out=root/'docs/codex/findings/overnight-ui-v1';out.mkdir(exist_ok=True)
spec=importlib.util.spec_from_file_location('exporter',root/'docs/codex/findings/export-queue-v3/export.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.OUT=out
old=json.loads((root/'docs/codex/findings/overnight-export-v1/build-manifest.json').read_text());w=Path(old['workspace']);cfg=w/'source/project.godot'
cfg.write_text(cfg.read_text().replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="Patch Notes Overnight Acceptance 20261009"'))
env=os.environ.copy()
for k in ['APPDATA','LOCALAPPDATA']:env[k]=str(w/k)
(out/'.gdignore').touch()
m.run('export-release',[m.GODOT,'--headless','--path',w/'source','--export-release','Windows Desktop',w/'demo/Patch Notes Demo.exe'],env,w)
old['build_only_override']='config/name=Patch Notes Demo; use_custom_user_dir=true; custom_user_dir_name=Patch Notes Overnight Acceptance 20261009'
old['build_project_sha256']=m.sha(cfg)
old['artifacts']={p.name:{'sha256':m.sha(p),'bytes':p.stat().st_size} for p in (w/'demo').iterdir() if p.is_file()}
(out/'build-manifest.json').write_text(json.dumps(old,indent=2))
s=(root/'docs/codex/findings/export-queue-v3/inspect.py').read_text();exec(compile(s.replace('OUT=Path(__file__).resolve().parent','OUT=Path('+repr(str(out))+')'),'inspect','exec'))
print(w/'demo/Patch Notes Demo.exe')
