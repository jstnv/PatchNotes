"""Finish the immutable export after correcting a PNG-remap verifier assumption."""
from pathlib import Path
import hashlib, importlib.util, json, shutil, subprocess, zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = Path('C:/Users/64jus/AppData/Local/Temp/pn-paper-icon-build-20261025-v1')
DELIVERY = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Paper Icon')
read = lambda p: json.loads(p.read_text(encoding='utf8'))
def module(name,path):
    spec = importlib.util.spec_from_file_location(name,path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result
sim = module('paper_sim',ROOT/'tools/simulate.py')
export = module('paper_export',ROOT/'docs/codex/findings/export-queue-v3/export.py')
export.OUT = OUT
before = read(OUT/'canonical-source-before.json')
assert sim.source_hashes(ROOT/'patch-notes') == before
manifest = read(OUT/'build-manifest.json')
workspace = Path(manifest['workspace'])
project = workspace/'source'
executable = workspace/'demo/Patch Notes v0.02 - Paper Icon.exe'
export_receipt = read(OUT/'export-release.command.json')
assert export_receipt['exit'] == 0 and not export_receipt['errors']
assert manifest['artifacts'][executable.name]['sha256'] == sim.sha(executable)
editor_identity = read(OUT/'editor-world/result.json')['world']['source_identity']
expected = {
    'project.godot': lambda t: t.replace('config/name="Patch Notes"','config/name="Patch Notes"\nconfig/version="0.02"'),
    'export_presets.cfg': lambda t: t.replace('Patch Notes v0.01','Patch Notes v0.02 - Paper Icon')
        .replace('binary_format/embed_pck=false','binary_format/embed_pck=true')
        .replace('debug/export_console_wrapper=1','debug/export_console_wrapper=0')
        .replace('application/file_version=""','application/file_version="0.0.2.0"')
        .replace('application/product_version=""','application/product_version="0.0.2.0"')
        .replace('application/product_name="Patch Notes Demo"','application/product_name="Patch Notes v0.02"')
        .replace('application/file_description="Patch Notes Demo"','application/file_description="Patch Notes v0.02"'),
    'scripts/market/rival_world_checkpoint.gd': lambda t: t.replace('const USABILITY_PRESENTATION_SOURCES := [',
        'const USABILITY_PRESENTATION_SOURCES := [\n\t"'+editor_identity+'", # Exact canonical editor source for this export.'),
}
overrides = {}
for relative,digest in manifest['included'].items():
    source = ROOT/'patch-notes'/relative
    assert sim.sha(source) == digest, relative
    if relative in expected:
        assert (project/relative).read_text(encoding='utf8') == expected[relative](source.read_text(encoding='utf8')), relative
        overrides[relative] = {'canonical_sha256':digest,'build_sha256':sim.sha(project/relative)}
    else:
        assert sim.sha(project/relative) == digest, relative

export.run('embedded-probe-v2',[export.GODOT,'--headless','--main-pack',executable,'--script',HERE/'package_probe.gd','--',
    OUT/'pack-manifest-verified.json',OUT/'editor-world/result.json',OUT/'embedded-result.json'],
    sim.isolated_environment(OUT/'probe-v2-profile'),workspace,90)
for name,flags in [('headless-startup',['--headless']),('native-startup',[])]:
    export.run(name,[executable,*flags,'--quit-after','30'],sim.isolated_environment(OUT/(name+'-profile')),executable.parent,90)
pe = module('paper_pe',HERE.parent/'logo-icon-20261024-v1/inspect_icon.py')
pe.verify(executable,ROOT/'patch-notes/assets/branding/patch_notes_paper.ico',OUT/'pe-icons.json')
assert not list(DELIVERY.glob('*.exe'))
for path in executable.parent.iterdir():
    if path.is_file(): shutil.copy2(path,DELIVERY/path.name)
(DELIVERY/'README.txt').write_text('Patch Notes v0.02 - Paper Icon\nWindows 64-bit\n\nRun Patch Notes v0.02 - Paper Icon.exe. All game data is embedded in the EXE.\nFolded-paper icon; current tutorial/save invitation. Uses the existing Patch Notes save/settings folder.\n',encoding='utf8')
archive = DELIVERY.parent/'Patch Notes v0.02 - Paper Icon.zip'
assert not archive.exists()
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(DELIVERY.iterdir()): z.write(path,DELIVERY.name+'/'+path.name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert hashlib.sha256(z.read(DELIVERY.name+'/'+executable.name)).hexdigest() == sim.sha(executable)
old_packages = {}
for finding in ['build-v002-20261024-v1','logo-icon-20261024-v1']:
    record = read(HERE.parent/finding/'result.json')
    for kind in ['exe','zip']:
        item = record[kind]
        assert sim.sha(Path(item['path'])) == item['sha256']
        old_packages[item['path']] = item['sha256']
assert sim.source_hashes(ROOT/'patch-notes') == before
manifest['build_only_override'] = {'application/config/name':'Patch Notes','application/config/version':'0.02',
    'packaging':'embedded x86_64 EXE','editor_save_compatibility':editor_identity,'files':overrides}
sim.write_json(OUT/'build-manifest.json',manifest)
result = {'pass':True,'canonical_unchanged':True,'export_inputs_unchanged':True,'version':'0.02',
    'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'exe':{'path':str(DELIVERY/executable.name),'bytes':executable.stat().st_size,'sha256':sim.sha(executable)},
    'zip':{'path':str(archive),'bytes':archive.stat().st_size,'sha256':sim.sha(archive)},
    'package':read(OUT/'embedded-result.json'),'build_only_overrides':manifest['build_only_override'],
    'previous_packages_unchanged':old_packages,'probe_sha256':sim.sha(HERE/'package_probe.gd'),
    'raw':str(OUT),'release_ready':False,'scope':'Icon/package integrity, exact editor-world/RNG restore and actual EXE startup; no full gameplay acceptance rerun.'}
sim.write_json(HERE/'result.json',result)
sim.write_json(HERE/'source.json',before)
for name in ['build-manifest.json','pack-manifest-verified.json','embedded-result.json','clean-import.command.json','export-release.command.json',
             'validation-pack.command.json','embedded-probe.command.json','embedded-probe-v2.command.json','headless-startup.command.json','native-startup.command.json','pe-icons.json']:
    shutil.copy2(OUT/name,HERE/name)
shutil.copy2(OUT/'embedded-probe.log',HERE/'initial-probe-failure.log')
print(json.dumps(result),flush=True)
