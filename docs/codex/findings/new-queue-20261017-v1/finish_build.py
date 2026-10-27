from run_checks import *
import runpy,shutil
out=BASE/'build-v1'
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',out/'inspect-v2.py')
runpy.run_path(str(out/'inspect-v2.py'),run_name='__main__')
spec=importlib.util.spec_from_file_location('builder',ROOT/'docs/codex/findings/export-queue-v3/export.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder);builder.OUT=out
manifest=sim.read_json(out/'build-manifest.json')
assert 'queries/market_release_index.gd' in manifest['included']
assert all(sim.sha(ROOT/'patch-notes'/key)==value for key,value in manifest['included'].items())
exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
builder.run('headless-startup',[exe,'--headless','--audio-driver','Dummy','--quit-after','120'],sim.isolated_environment(out/'smoke-profile'),exe.parent)
