"""Clean current-source P1 release export using the maintained allowlist."""
import importlib.util,sys,runpy,json,subprocess
from pathlib import Path
from check import ROOT,OUT,sim

build=OUT/'export-clean';build.mkdir(exist_ok=False)
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py')
exporter=importlib.util.module_from_spec(spec);spec.loader.exec_module(exporter)
exporter.OUT=build
sys.argv=[__file__]
exporter.main()
script=ROOT/'docs/codex/findings/export-queue-v3/inspect.py'
(build/'inspect.py').write_bytes(script.read_bytes())
runpy.run_path(str(build/'inspect.py'),run_name='__main__')
manifest=sim.read_json(build/'build-manifest.json')
demo=Path(manifest['workspace'])/'demo'
for label,args in [('headless',['--headless']),('graphical',['--rendering-method','gl_compatibility'])]:
    command=[str(demo/'Patch Notes Demo.exe'),*args,'--quit-after','60']
    exporter.run(label,command,sim.isolated_environment(build/(label+'-profile')),build,90)
sim.write_json(build/'result.json',dict(export_pass=True,new_clean_import=True,release_ready=False))
