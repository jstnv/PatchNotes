"""Clean, pinned Windows export; canonical resources are never rewritten."""
from pathlib import Path
import importlib.util,json,os,shutil,subprocess,sys,tempfile
sys.stdout.reconfigure(encoding='utf-8',errors='replace')
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3];PROJECT=ROOT/'patch-notes'
sys.path.insert(0,str(ROOT))
from tools import simulate as sim
spec=importlib.util.spec_from_file_location('export_support',ROOT/'docs/codex/findings/export-queue-v3/export.py')
support=importlib.util.module_from_spec(spec);spec.loader.exec_module(support);support.OUT=OUT
support.GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
local=Path('C:/Users/64jus/.codex/visualizations/2026/10/07/01a11488-6601-7cf0-9b09-7fa2b3f5efdd')
workspace=Path(tempfile.mkdtemp(prefix='pn-save-fix-export-',dir=local));project=workspace/'source';project.mkdir()
artifact=OUT/'release/Patch Notes v0.03 - Save Fix';artifact.mkdir(parents=True,exist_ok=True)
assert not any(artifact.iterdir()),'Refuse to overwrite an existing build'
env=support.isolated_export_environment(workspace)
before=sim.source_hashes(PROJECT)
pinned=json.loads((ROOT/'docs/codex/findings/export-queue-v3/build-manifest.json').read_text(encoding='utf-8'))
templates=Path(env['APPDATA'])/'Godot/export_templates/4.7.1.stable';templates.mkdir(parents=True)
hashes={}
for name in ['windows_debug_x86_64.exe','windows_release_x86_64.exe']:
    src=Path('C:/Users/64jus/AppData/Roaming/Godot/export_templates/4.7.1.stable')/name
    hashes[name]=support.sha(src);assert hashes[name]==pinned['template_files'][name],name
    shutil.copy2(src,templates/name)
version=subprocess.check_output([str(support.GODOT),'--version'],text=True).strip()
assert version==pinned['version'],version
manifest={'workspace':str(workspace),'project':str(project),'artifact':str(artifact),'version':version,'editor_sha256':support.sha(support.GODOT),'template_files':hashes,'included':{},'import_settings':{},'build_only_overrides':[],'source_manifest':before,'status':'copying; not yet accepted'}
for path in PROJECT.rglob('*'):
    if not path.is_file():continue
    rel=path.relative_to(PROJECT);parts=rel.parts
    if parts[0]=='assets' and path.suffix=='.import':
        dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
        manifest['import_settings'][rel.as_posix()]=support.sha(path);continue
    include=rel.as_posix() in ['project.godot','export_presets.cfg','icon.svg'] or (parts[0] in ['scripts','scenes','data','assets','resources','autoload','queries','certified'] and not (parts[0]=='scripts' and len(parts)>1 and parts[1]=='debug') and path.suffix.lower() in ['.gd','.uid','.tscn','.tres','.res','.json','.png','.svg','.jpg','.webp','.ogg','.wav','.ttf','.otf','.ico'])
    if not include:continue
    dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
    manifest['included'][rel.as_posix()]=support.sha(path)
manifest['export_preset']=support.windows_export_preset(project/'export_presets.cfg')
def save():
    (OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8',newline='\n')
save()
support.run('clean-import',[support.GODOT,'--headless','--path',project,'--editor','--import','--quit'],env,workspace,timeout=240)
exe=artifact/'Patch Notes v0.03.exe'
support.run('export-release',[support.GODOT,'--headless','--text-driver','Dummy','--path',project,'--export-release',manifest['export_preset'],exe],env,workspace,timeout=240)
licenses=artifact/'Licenses';licenses.mkdir()
for path in PROJECT.rglob('OFL.txt'):
    if 'assets' not in path.relative_to(PROJECT).parts:continue
    label=path.parent.name if path.parent.name!='fonts' else 'Tiny5'
    shutil.copy2(path,licenses/(label+'-OFL.txt'))
(artifact/'README.txt').write_text('Patch Notes v0.03 - Save Fix\n\nWindows 64-bit. Extract the entire ZIP into a folder, then run Patch Notes v0.03.exe.\nKeep the PCK file beside the EXE. Existing Studio saves are not included or modified by this package.\n\nThis build includes the current shared checkout and the November 1 save-validation fixes.\nGame rules and monthly financial values were not changed by the save-performance fix.\n',encoding='utf-8',newline='\n')
manifest['source_unchanged']=sim.source_hashes(PROJECT)==before
assert manifest['source_unchanged'],'Source changed during export'
manifest['artifacts']={p.relative_to(artifact).as_posix():{'sha256':support.sha(p),'bytes':p.stat().st_size} for p in artifact.rglob('*') if p.is_file()}
manifest['status']='exported; pack, executable and package acceptance pending'
save();print(json.dumps({'artifact':str(artifact),'workspace':str(workspace),'files':len(manifest['included']),'source_unchanged':True}),flush=True)
