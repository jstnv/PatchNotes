"""Clean internal export, package audit and isolated startup; no player release."""
from pathlib import Path
import hashlib,importlib.util,json,os,runpy,shutil,subprocess,sys
OUT=Path(__file__).resolve().parent/'current-export'
assert not OUT.exists(),'Preserve earlier evidence; use a fresh output'
ROOT=OUT.parents[4]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
spec=importlib.util.spec_from_file_location('exporter',ROOT/'docs/codex/findings/export-queue-v3/export.py')
exporter=importlib.util.module_from_spec(spec);spec.loader.exec_module(exporter);exporter.OUT=OUT
source={str(p.relative_to(ROOT/'patch-notes')):sha(p) for base in ['scripts','queries','scenes','data'] for p in (ROOT/'patch-notes'/base).rglob('*') if p.is_file()}
sys.argv=['export.py','--godot',r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe']
exporter.main()
(OUT/'source.json').write_text(json.dumps(source,indent=2),encoding='utf-8')
shutil.copy2(ROOT/'docs/codex/findings/export-queue-v3/inspect.py',OUT/'inspect.py');runpy.run_path(str(OUT/'inspect.py'),run_name='__main__')
manifest=json.loads((OUT/'build-manifest.json').read_text(encoding='utf-8'));exe=Path(manifest['workspace'])/'demo/Patch Notes Demo.exe'
profile=OUT/'smoke-profile';env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
 path=profile/key;path.mkdir(parents=True);env[key]=str(path.resolve())
rows=[]
for name,flags in [('headless',['--headless']),('graphical',['--rendering-method','gl_compatibility'])]:
 command=[str(exe),*flags,'--audio-driver','Dummy','--quit-after','60']
 result=subprocess.run(command,env=env,capture_output=True,timeout=90)
 output=(result.stdout+result.stderr).decode('utf-8',errors='replace');(OUT/(name+'.log')).write_text(output,encoding='utf-8')
 errors=[line for line in output.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
 rows.append({'mode':name,'command':command,'exit':result.returncode,'errors':errors})
 assert not result.returncode and not errors,rows[-1]
changed=[name for name,digest in source.items() if sha(ROOT/'patch-notes'/name)!=digest]
report={'ok':not changed,'source_changes':changed,'checks':rows,'artifacts':manifest['artifacts'],'scope':'Internal clean export/package audit/startup only, not Research timing, player saves or complete release acceptance.'}
(OUT/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
raise SystemExit(0 if report['ok'] else 1)
