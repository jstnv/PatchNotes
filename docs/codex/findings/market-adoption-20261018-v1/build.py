"""Clean bounded export, reusing hash-verified immutable official templates."""
from pathlib import Path
import hashlib, importlib.util, json, os, shutil, subprocess, sys, tempfile

OUT=Path(__file__).resolve().parent/'export-v2'
ROOT=OUT.parents[4]/'patch-notes'
REPO=ROOT.parent
OUT.mkdir(exist_ok=False)
(OUT/'.gdignore').touch()
spec=importlib.util.spec_from_file_location('exporter',REPO/'docs/codex/findings/export-queue-v3/export.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.OUT=OUT
godot=Path(r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
prior=json.loads((REPO/'docs/codex/findings/queue-20261018-v1/export-v5/build-manifest.json').read_text(encoding='utf-8'))
source_templates=Path(prior['workspace'])/'APPDATA/Godot/export_templates/4.7.1.stable'
workspace=OUT/'clean';workspace.mkdir();project=workspace/'source';project.mkdir();artifact=workspace/'demo';artifact.mkdir()
env=m.isolated_export_environment(workspace)
for name,digest in prior['template_files'].items():
    original=source_templates/name
    assert m.sha(original)==digest,(name,'template hash mismatch')
manifest={'version':subprocess.check_output([str(godot),'--version'],text=True).strip(),'editor_sha256':m.sha(godot),
          'archive_sha256':prior['archive_sha256'],'template_files':prior['template_files'],
          'template_provenance':'Verified existing official template bytes selected through build-only custom_template paths.',
          'workspace':str(workspace.resolve()),'included':{},'excluded_roots':['analysis','design-logs','scripts/debug','builds','.godot','.codex-godot-temp']}
for path in ROOT.rglob('*'):
    if not path.is_file():continue
    rel=path.relative_to(ROOT);parts=rel.parts
    settings=parts[0]=='assets' and path.name.endswith(('.ttf.import','.otf.import'))
    include=(rel.as_posix() in ['project.godot','export_presets.cfg','icon.svg'] or
        (parts[0] in ['scripts','scenes','data','assets','resources','autoload','queries'] and
        not (parts[0]=='scripts' and len(parts)>1 and parts[1]=='debug') and
        path.suffix.lower() in ['.gd','.uid','.tscn','.tres','.res','.json','.png','.svg','.jpg','.webp','.ogg','.wav','.ttf','.otf']))
    if not include and not settings:continue
    dest=project/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,dest)
    manifest.setdefault('import_settings' if settings else 'included',{})[rel.as_posix()]=m.sha(path)
config=project/'project.godot'
config.write_text(config.read_text(encoding='utf-8').replace('config/name="Patch Notes"','config/name="Patch Notes Demo"'),encoding='utf-8')
manifest['build_only_override']='application/config/name=Patch Notes Demo'
presets=project/'export_presets.cfg'
text=presets.read_text(encoding='utf-8')
for kind in ['debug','release']:
    text=text.replace('custom_template/'+kind+'=""','custom_template/'+kind+'="'+(source_templates/('windows_'+kind+'_x86_64.exe')).as_posix()+'"')
presets.write_text(text,encoding='utf-8')
manifest['build_only_template_paths']={kind:(source_templates/('windows_'+kind+'_x86_64.exe')).as_posix() for kind in ['debug','release']}
(OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
m.run('clean-import',[godot,'--headless','--path',project,'--editor','--import','--quit'],env,workspace)
exe=artifact/'Patch Notes Demo.exe'
m.run('export-release',[godot,'--headless','--path',project,'--export-release','Windows Desktop',exe],env,workspace)
shutil.copy2(ROOT/'assets/card_frame_kit/fonts/OFL.txt',artifact/'Tiny5-OFL.txt')
manifest['artifacts']={p.name:{'sha256':m.sha(p),'bytes':p.stat().st_size} for p in artifact.iterdir() if p.is_file()}
manifest['status']='clean export; graphical acceptance recorded separately'
(OUT/'build-manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
shutil.copy2(REPO/'docs/codex/findings/export-queue-v3/inspect.py',OUT/'inspect.py')
subprocess.run([sys.executable,str(OUT/'inspect.py')],check=True)
print(json.dumps({'artifacts':manifest['artifacts'],'workspace':str(workspace.resolve())}),flush=True)
