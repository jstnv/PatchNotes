from pathlib import Path
import difflib,hashlib,importlib.util,json,shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1')
spec=importlib.util.spec_from_file_location('studio_collect_sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
before=json.loads((HERE/'before-source.json').read_text())
after=sim.source_hashes(ROOT/'patch-notes')
delta={k:{'before':before.get(k),'after':after.get(k)} for k in sorted(before.keys()|after.keys()) if before.get(k)!=after.get(k)}
runtime=[k for k in delta if k.endswith('.gd') and not k.startswith('scripts/debug/')]
assert runtime==['scripts/market/rival_world_checkpoint.gd','scripts/phases/studio_phase.gd'],runtime
sim.write_json(HERE/'source-delta.json',{'files':delta,'runtime_files':runtime,'note':'before-source pinned after adding the two failing regression assertions; complete verifier diff also retained'})
old=Path('C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1/final-matrix/project')
patch=[]
for name in runtime+['scripts/debug/verify_beta_finalization_and_launch.gd']:
    patch.extend(difflib.unified_diff((old/name).read_text().splitlines(True),(ROOT/'patch-notes'/name).read_text().splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(HERE/'scoped-delta.patch').write_text(''.join(patch),encoding='utf8')
target=HERE/'receipts';target.mkdir(exist_ok=True)
for folder in RAW.iterdir():
    if not folder.is_dir():continue
    dest=target/folder.name;dest.mkdir(exist_ok=True)
    for p in folder.iterdir():
        if p.is_file() and (p.name in ['receipt.json','result.json','run.log','canonical-source.json'] or p.name.endswith('.command.json') or p.name.startswith('verify_') and p.suffix=='.log'):
            shutil.copy2(p,dest/p.name)
    if folder.name=='supplement':
        for test in folder.iterdir():
            if not test.is_dir() or not test.name.startswith('verify_'):continue
            d=dest/test.name;d.mkdir(exist_ok=True)
            for name in ['receipt.json','run.log']:shutil.copy2(test/name,d/name)
for name in ['model-comparison.json']:
    shutil.copy2(RAW/name,HERE/name)
caps=HERE/'captures';caps.mkdir(exist_ok=True)
for p in (RAW/'played-fixed-exe/capture').glob('*.png'):shutil.copy2(p,caps/p.name)
green=json.loads((RAW/'green/result.json').read_text())
extra=json.loads((RAW/'supplement/result.json').read_text())
assert all(r['pass'] for r in green['checks']) and len(green['checks'])==6
assert extra['pass'] and len(extra['checks'])==3
stable=json.loads((RAW/'green/canonical-source.json').read_text())
import_delta=[k for k in stable.keys()|after.keys() if stable.get(k)!=after.get(k)]
assert all(k.endswith('.import') and k not in stable for k in import_delta),import_delta
for name in ['fixed-exe-launch','played-fixed-exe','restore-ui','exe-prior-save']:
    assert json.loads((RAW/name/'receipt.json').read_text())['pass'],name
old_exe=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Paper Icon/Patch Notes v0.02 - Paper Icon.exe')
assert sim.sha(old_exe)=='1d509c0dd14a8e2c9e3adf12b5ef4fb398ac2d8672a39c466e93d3ad6f049fe0'
sim.write_json(HERE/'verification.json',{'pass':True,'maintained_passing_receipts':9,'single_green_gate':False,'canonical_generated_import_additions':import_delta,'runtime_unchanged_during_checks':True,'old_exe_red_failures':2,'fixed_exe_red_regressions_pass':True,'native_exe_played_checks':18,'native_route':'12 legal headless Design/Alpha commands, two native Beta hands, real launch, pointer Summary/Contracts','old_exe_unchanged':True,'build':json.loads((HERE/'result.json').read_text())['exe'],'release_ready':False})
print(json.dumps({'pass':True,'runtime_files':runtime,'maintained_suites':9,'native_checks':18}))
