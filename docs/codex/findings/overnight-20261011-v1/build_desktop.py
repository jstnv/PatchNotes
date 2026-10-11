"""Build-only application/profile override so Sky can launch safely on the desktop."""
from pathlib import Path
import hashlib,importlib.util,json,os,runpy,shutil,tempfile
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
base=json.loads((HERE/'exported-build-v1/build-manifest.json').read_text())
out=HERE/'desktop-build-v1';out.mkdir()
profile_name='Patch Notes Overnight 20261011 Implementation'
assert not (Path(os.environ['APPDATA'])/profile_name).exists(), 'Refuse to reuse an existing user profile'
workspace=Path(tempfile.mkdtemp(prefix='patch-notes-overnight-ui-'))
project=workspace/'source';shutil.copytree(Path(base['workspace'])/'source',project)
demo=workspace/'demo';demo.mkdir()
config=project/'project.godot';text=config.read_text(encoding='utf-8');needle='config/name="Patch Notes Demo"';assert text.count(needle)==1
config.write_text(text.replace(needle,'config/name="Patch Notes Overnight"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="'+profile_name+'"'),encoding='utf-8')
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py');exporter=importlib.util.module_from_spec(spec);spec.loader.exec_module(exporter);exporter.OUT=out
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    path=workspace/key;path.mkdir();env[key]=str(path)
    if key=='APPDATA':shutil.copytree(Path(base['workspace'])/key/'Godot/export_templates',path/'Godot/export_templates')
exporter.run('desktop-import',[exporter.GODOT,'--headless','--path',project,'--editor','--import','--quit'],env,workspace)
exe=demo/'Patch Notes Overnight.exe'
exporter.run('desktop-export',[exporter.GODOT,'--headless','--path',project,'--export-release','Windows Desktop',exe],env,workspace)
manifest=dict(base);manifest['workspace']=str(workspace)
manifest['build_only_override']='Application name=Patch Notes Overnight; custom user profile='+profile_name
manifest['custom_profile']=str(Path(os.environ['APPDATA'])/profile_name)
manifest['copied_project_godot_sha256']=exporter.sha(config)
manifest['artifacts']={p.name:{'sha256':exporter.sha(p),'bytes':p.stat().st_size} for p in demo.iterdir() if p.is_file()}
(out/'build-manifest.json').write_text(json.dumps(manifest,indent=2))
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',out/'inspect.py')
# Inspector uses the conventional package name; retain a byte-identical audit copy.
shutil.copy2(demo/'Patch Notes Overnight.pck',demo/'Patch Notes Demo.pck')
runpy.run_path(str(out/'inspect.py'),run_name='__main__')
assert all(exporter.sha(ROOT/'patch-notes'/p)==h for p,h in base['included'].items())
print(json.dumps({'exe':str(exe),'profile':manifest['custom_profile'],'artifacts':manifest['artifacts']}))
