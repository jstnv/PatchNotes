"""Current source export using the maintained pinned exporter and PCK audit."""
from pathlib import Path
import hashlib,importlib.util,json,os,runpy,shutil,subprocess,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
OUT=HERE/'exported-build-v1'
assert not OUT.exists()
OUT.mkdir()
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py'); exporter=importlib.util.module_from_spec(spec);spec.loader.exec_module(exporter)
exporter.OUT=OUT
saved=sys.argv;sys.argv=['export.py']
try:exporter.main()
finally:sys.argv=saved
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',OUT/'inspect.py')
runpy.run_path(str(OUT/'inspect.py'),run_name='__main__')
manifest=json.loads((OUT/'build-manifest.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
drift=[p for p,h in manifest['included'].items() if sha(ROOT/'patch-notes'/p)!=h]
assert not drift,drift
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    path=OUT/'smoke-profile'/key;path.mkdir(parents=True);env[key]=str(path)
exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
command=[str(exe),'--headless','--quit-after','60']
result=subprocess.run(command,env=env,capture_output=True,timeout=90)
log=(result.stdout+result.stderr).decode(errors='replace');(OUT/'startup.log').write_text(log)
errors=[x for x in log.splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:')) and 'root certificate store' not in x]
record={'command':command,'exit':result.returncode,'errors':errors,'included_source_drift':drift}
(OUT/'startup.command.json').write_text(json.dumps(record,indent=2));print(json.dumps(record))
assert result.returncode==0 and not errors
