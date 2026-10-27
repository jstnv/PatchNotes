"""Private compiled acceptance pack, not a player release or canonical export."""
from pathlib import Path
import importlib.util, json, subprocess, time, hashlib
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
PROJECT=ROOT/'docs/codex/threads/contracts/simulators/crown-feedback-20261026-v1/project'
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
preset=PROJECT/'export_presets.cfg'
s=(ROOT/'patch-notes/export_presets.cfg').read_text();s=s.replace('scripts/debug/*,','')
preset.write_text(s,newline='\n')
dest=OUT/'exports';dest.mkdir(exist_ok=False)
command=[r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(PROJECT),'--export-pack','Patch Notes v0.01',str(dest/'crown-feedback-private.pck')]
env=sim.isolated_environment(ROOT/'.codex-godot-temp/crown-feedback-pack')
start=time.monotonic()
with (OUT/'export.log').open('xb') as log:
 r=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=240)
result={'command':command,'exit':r.returncode,'seconds':round(time.monotonic()-start,3),'private':True,'debug_verifiers_included':True,'canonical_exported':False}
if r.returncode==0:result['pack_sha256']=hashlib.sha256((dest/'crown-feedback-private.pck').read_bytes()).hexdigest()
(OUT/'export-run.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result));raise SystemExit(r.returncode)
