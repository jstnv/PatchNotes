"""Versioned single-file Windows export; canonical source is read-only."""
from pathlib import Path
import importlib.util, json, re, shutil, subprocess, sys, zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = Path('C:/Users/64jus/AppData/Local/Temp/pn-build-v002-20261024-v1')
DELIVERY = Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02')
OUT.mkdir(exist_ok=False)
DELIVERY.mkdir(exist_ok=False)
def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    item = importlib.util.module_from_spec(spec); spec.loader.exec_module(item); return item

sim = module('version_sim', ROOT/'tools/simulate.py')
c = module('version_checks', HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
before = sim.source_hashes(ROOT/'patch-notes')
baseline = Path('C:/Users/64jus/AppData/Local/Temp/pn-employee-button-20261024-v2/final/project')
assert sim.source_hashes(baseline) == before, 'Current editor fixture source drift'
c.RAW = OUT
prior = c.run('editor-world',baseline,HERE.parent/'employee-button-20261024-v1/probe.gd',
    ['--prior','--input=C:/Users/64jus/AppData/Local/Temp/pn-employee-button-20261024-v2/previous/result.json'],reuse=True)
assert prior['pass']
fixture = json.loads((OUT/'editor-world/result.json').read_text())
editor_identity = fixture['world']['source_identity']

export = module('version_export', ROOT/'docs/codex/findings/export-queue-v3/export.py')
export.OUT = OUT
export.ROOT = ROOT/'patch-notes'
original_run = export.run
overrides = {}
def version_run(name, argv, env, cwd, timeout=180):
    command = list(argv)
    if name == 'clean-import':
        project = Path(command[command.index('--path')+1])
        edits = {
            'project.godot': lambda t: t.replace('config/name="Patch Notes Demo"','config/name="Patch Notes"\nconfig/version="0.02"'),
            'export_presets.cfg': lambda t: t.replace('Patch Notes v0.01','Patch Notes v0.02')
                .replace('binary_format/embed_pck=false','binary_format/embed_pck=true')
                .replace('debug/export_console_wrapper=1','debug/export_console_wrapper=0')
                .replace('application/file_version=""','application/file_version="0.0.2.0"')
                .replace('application/product_version=""','application/product_version="0.0.2.0"')
                .replace('application/product_name="Patch Notes Demo"','application/product_name="Patch Notes v0.02"')
                .replace('application/file_description="Patch Notes Demo"','application/file_description="Patch Notes v0.02"'),
            'scripts/market/rival_world_checkpoint.gd': lambda t: t.replace('const USABILITY_PRESENTATION_SOURCES := [',
                'const USABILITY_PRESENTATION_SOURCES := [\n\t"'+editor_identity+'", # Exact canonical editor source for this export.'),
        }
        for relative, transform in edits.items():
            path = project/relative
            original = path.read_text(encoding='utf-8')
            changed = transform(original)
            assert changed != original, relative
            path.write_text(changed,encoding='utf-8')
            overrides[relative] = {'canonical_sha256':sim.sha(ROOT/'patch-notes'/relative),'build_sha256':sim.sha(path)}
    if '--export-release' in command:
        command[command.index('--export-release')+1] = 'Patch Notes v0.02'
        command[-1] = Path(command[-1]).parent/'Patch Notes v0.02.exe'
    return original_run(name,command,env,cwd,timeout)

export.run = version_run
sys.argv = [str(HERE/'build.py')]
export.main()
manifest = json.loads((OUT/'build-manifest.json').read_text())
workspace = Path(manifest['workspace'])
project = workspace/'source'
env = {key:value for key,value in __import__('os').environ.items()}
receipt = json.loads((OUT/'export-release.command.json').read_text())
env.update(receipt['profile'])
validation_pack = OUT/'validation.pck'
original_run('validation-pack',[export.GODOT,'--headless','--text-driver','Dummy','--path',project,'--export-pack','Patch Notes v0.02',validation_pack],env,workspace)
inspection = ROOT/'docs/codex/findings/export-queue-v3/inspect.py'
script = inspection.read_text(encoding='utf-8').replace('OUT=Path(__file__).resolve().parent','OUT=Path('+repr(str(OUT))+')')
script = script.replace("path=Path(m['workspace'])/'demo/Patch Notes Demo.pck'",'path=Path('+repr(str(validation_pack))+')')
exec(compile(script,str(inspection),'exec'),{'__file__':str(inspection)})
executable = workspace/'demo/Patch Notes v0.02.exe'
probe_env = sim.isolated_environment(OUT/'probe-profile')
original_run('embedded-probe',[export.GODOT,'--headless','--main-pack',executable,'--script',HERE/'package_probe.gd','--',OUT/'pack-manifest-verified.json',OUT/'editor-world/result.json',OUT/'embedded-result.json'],probe_env,workspace)
for name, flags in [('headless-startup',['--headless']),('native-startup',[])]:
    environment = sim.isolated_environment(OUT/(name+'-profile'))
    original_run(name,[executable,*flags,'--quit-after','30'],environment,executable.parent,90)

for path in executable.parent.iterdir():
    if path.is_file(): shutil.copy2(path,DELIVERY/path.name)
assert not list(DELIVERY.glob('*.pck')) and not list(DELIVERY.glob('*.console.exe'))
(DELIVERY/'README.txt').write_text('Patch Notes v0.02\nWindows 64-bit\n\nRun Patch Notes v0.02.exe. All game data is embedded in the EXE.\nThe existing Patch Notes save/settings folder is preserved.\n',encoding='utf-8')
archive = DELIVERY.parent/'Patch Notes v0.02.zip'
assert not archive.exists()
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for path in sorted(DELIVERY.iterdir()): z.write(path,'Patch Notes v0.02/'+path.name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert __import__('hashlib').sha256(z.read('Patch Notes v0.02/'+executable.name)).hexdigest() == sim.sha(executable)
assert sim.source_hashes(ROOT/'patch-notes') == before, 'Canonical drift during export'
assert all(sim.sha(ROOT/'patch-notes'/path)==digest for path,digest in manifest['included'].items()), 'Canonical export inputs drifted'
manifest['build_only_override'] = {'application/config/name':'Patch Notes','application/config/version':'0.02','packaging':'embedded x86_64 EXE','editor_save_compatibility':editor_identity,'files':overrides}
sim.write_json(OUT/'build-manifest.json',manifest)
result = {'pass':True,'canonical_unchanged':True,'version':'0.02','head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'exe':{'path':str(DELIVERY/executable.name),'bytes':executable.stat().st_size,'sha256':sim.sha(executable)},
    'zip':{'path':str(archive),'bytes':archive.stat().st_size,'sha256':sim.sha(archive)},
    'package':json.loads((OUT/'embedded-result.json').read_text()),'build_only_overrides':manifest['build_only_override'],
    'raw':str(OUT),'release_ready':False,'scope':'Current-source Windows package, resource integrity, exact editor-save restore and headless/native startup; no full gameplay acceptance rerun.'}
sim.write_json(HERE/'result.json',result)
sim.write_json(HERE/'source.json',before)
for name in ['build-manifest.json','pack-manifest-verified.json','embedded-result.json','clean-import.command.json','export-release.command.json','validation-pack.command.json','embedded-probe.command.json','headless-startup.command.json','native-startup.command.json']:
    shutil.copy2(OUT/name,HERE/name)
print(json.dumps(result),flush=True)
