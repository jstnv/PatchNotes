from run_checks import *
import runpy,shutil
spec=importlib.util.spec_from_file_location('builder',ROOT/'docs/codex/findings/export-queue-v3/export.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
builder.ROOT=BASE/'build-source/project'
sim.write_json(BASE/'build-source/source.json',sim.copy_snapshot(ROOT/'patch-notes',builder.ROOT))
shutil.copy2(ROOT/'patch-notes/export_presets.cfg',builder.ROOT/'export_presets.cfg')
builder.OUT=BASE/'build-v1'
builder.main()
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',builder.OUT/'inspect.py')
runpy.run_path(str(builder.OUT/'inspect.py'),run_name='__main__')
manifest=sim.read_json(builder.OUT/'build-manifest.json')
assert 'queries/market_release_index.gd' in manifest['included']
assert all(sim.sha(ROOT/'patch-notes'/key)==value for key,value in manifest['included'].items())
exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
builder.run('headless-startup',[exe,'--headless','--audio-driver','Dummy','--quit-after','120'],sim.isolated_environment(builder.OUT/'smoke-profile'),exe.parent)
