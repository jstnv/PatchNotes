"""Resume verification after the retained whole-tree source-fence failure.

Every shipped input is required byte-exact; no broad canonical-unchanged claim.
The original export, successful probes and failure log remain untouched.
"""
from pathlib import Path
import importlib.util,json,shutil,subprocess,zipfile
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-logo-icon-20261024-v1')
DELIVERY=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Logo')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);item=importlib.util.module_from_spec(spec);spec.loader.exec_module(item);return item
sim=module('logo_sim',ROOT/'tools/simulate.py')
pe=module('logo_pe',HERE/'inspect_icon.py')
m=json.loads((RAW/'build-manifest.json').read_text())
production=ROOT/'patch-notes'
drift={name:{'export_source':sha,'current':sim.sha(production/name)} for name,sha in m['included'].items() if sim.sha(production/name)!=sha}
assert set(drift)<={'scripts/market/rival_trial.gd','scripts/market/rival_world.gd'},drift
snapshot=Path(m['workspace'])/'source'
overridden={'project.godot','export_presets.cfg','scripts/market/rival_world_checkpoint.gd'}
assert all(sim.sha(snapshot/name)==sha for name,sha in m['included'].items() if name not in overridden),'Frozen export input mismatch'
frozen=sim.source_hashes(snapshot)
# Inventory all current production code/data, including additions; debug is not shipped.
current={p.relative_to(production).as_posix() for folder in ['scripts','data','queries'] for p in (production/folder).rglob('*') if p.is_file() and p.suffix in {'.gd','.json'} and 'debug' not in p.relative_to(production).parts}
assert current=={name for name in m['included'] if name.startswith(('scripts/','data/','queries/')) and name.endswith(('.gd','.json'))}
source=sim.source_hashes(production)
for name in ['clean-import','export-release','validation-pack','embedded-probe','headless-startup','native-startup']:
    result=json.loads((RAW/(name+'.command.json')).read_text())
    assert result['exit']==0 and not result['errors'],name
pack=json.loads((RAW/'pack-manifest-verified.json').read_text())
embedded=json.loads((RAW/'embedded-result.json').read_text())
assert embedded['pass'] and embedded['current_editor_save_exact'] and embedded['unknown_source_rejected'] and embedded['payloads']==pack['count']==392
exe=DELIVERY/'Patch Notes v0.02 - Logo.exe'
assert sim.sha(exe)==m['artifacts'][exe.name]['sha256']
pe.verify(exe,production/'assets/branding/patch_notes.ico',RAW/'pe-icons-final.json')
archive=DELIVERY.parent/'Patch Notes v0.02 - Logo.zip'
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    import hashlib
    assert hashlib.sha256(z.read('Patch Notes v0.02 - Logo/'+exe.name)).hexdigest()==sim.sha(exe)
prior=json.loads((HERE.parent/'build-v002-20261024-v1/result.json').read_text())
for key in ['exe','zip']:assert sim.sha(Path(prior[key]['path']))==prior[key]['sha256'],'Original package changed'
tests=(RAW/'tool-tests-v2.log').read_text(encoding='utf8')
assert 'Ran 43 tests' in tests and '\nOK\n' in tests,tests[-1200:]
assert sim.source_hashes(snapshot)==frozen,'Frozen export changed during final verification'
def artifact(path):return {'path':str(path),'bytes':path.stat().st_size,'sha256':sim.sha(path)}
result={'pass':True,'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'exe':artifact(exe),'zip':artifact(archive),'png':artifact(production/'assets/branding/patch_notes_logo.png'),'ico':artifact(production/'assets/branding/patch_notes.ico'),
    'canonical_unchanged':False,'export_matches_frozen_source':True,'current_runtime_drift':drift,
    'source_scope':'Source-pinned export before concurrent rival_trial/rival_world edits. Frozen export inputs and branding remain exact; current production code/data inventory matches but those two current file bytes are newer. Original whole-tree fence failure retained. No parallel edit was overwritten.',
    'package':embedded,'raw':str(RAW),'original_v002_unchanged':True,'tool_tests':43,'release_ready':False,'commit_push':False}
sim.write_json(HERE/'result.json',result);sim.write_json(HERE/'current-source-at-finalization.json',source);sim.write_json(HERE/'source.json',frozen)
for name in ['build-manifest.json','pack-manifest-verified.json','embedded-result.json','pe-icons-final.json','clean-import.command.json','export-release.command.json','validation-pack.command.json','embedded-probe.command.json','headless-startup.command.json','native-startup.command.json','tool-tests.log','tool-tests-v2.log']:
    shutil.copy2(RAW/name,HERE/name)
shutil.copy2(RAW.parent/'pn-logo-icon-20261024-v1-driver.log',HERE/'original-driver.log')
print(json.dumps(result),flush=True)
