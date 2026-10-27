"""Isolated focused/native and real previous-source world checks."""
from pathlib import Path
import importlib.util,json,subprocess,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-store-prereq-20261024-v1')
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
spec=importlib.util.spec_from_file_location('prereq_sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
def run(name,project,script,args=(),native=False,pack=None,reuse=False):
 out=RAW/name;out.mkdir(exist_ok=False)
 if pack is None:
  if reuse:
   source=sim.source_hashes(project);sim.write_json(out/'source.json',source)
   command=[str(GODOT),'--path',str(project)]
  else:
   source=sim.copy_snapshot(project,out/'project');sim.write_json(out/'source.json',source)
   env=sim.isolated_environment(out/'import-profile');sim.import_project(GODOT,out/'project',out,env,180)
   command=[str(GODOT),'--path',str(out/'project')]
 else:
  command=[str(GODOT),'--main-pack',str(pack)]
 env=sim.isolated_environment(out/'profile');env['PN_CHECKPOINT_TEST_PORT']='47739'
 command+=([] if native else ['--headless'])+['--script',str(script),'--','--out='+str(out/('capture' if native else 'result.json'))]+list(args)
 if native:(out/'capture').mkdir()
 with (out/'run.log').open('x',encoding='utf8') as stream:
  child=subprocess.Popen(command,env=env,cwd=out,stdout=stream,stderr=subprocess.STDOUT)
  import time
  started=time.monotonic()
  while child.poll() is None:
   text=(out/'run.log').read_text(encoding='utf8',errors='replace')
   if time.monotonic()-started>180 or any(x in text for x in ['SCRIPT ERROR','Assertion failed','Parse Error']):child.kill();break
   time.sleep(.25)
  child.wait()
 log=(out/'run.log').read_text(encoding='utf8',errors='replace');errors=[l for l in log.splitlines() if l.startswith('ERROR:') or 'FAIL:' in l or 'SCRIPT ERROR' in l]
 receipt={'command':command,'exit':child.returncode,'errors':errors,'pass':child.returncode==0 and not errors,'harness_sha256':sim.sha(script)}
 if reuse:assert sim.source_hashes(project)==source,'Reused immutable source changed'
 sim.write_json(out/'receipt.json',receipt);print(name,json.dumps(receipt),flush=True)
 return receipt
if __name__=='__main__':
 name=sys.argv[1]
 if name=='previous-editor':result=run(name,RAW/'red/project',HERE/'world_probe.gd')
 elif name=='previous-pack':
  m=json.loads((ROOT/'docs/codex/findings/queue-closeout-20261024-v1/external-artifacts.json').read_text())
  build=json.loads((Path(m['root'])/'package-v2/build-manifest.json').read_text())
  pack=Path(build['workspace'])/'demo/Patch Notes Demo.pck';result=run(name,None,HERE/'world_probe.gd',pack=pack)
 elif name.startswith('restore-'):result=run(name,ROOT/'patch-notes',HERE/'world_probe.gd',['--input='+str(RAW/name.removeprefix('restore-')/'result.json')])
 elif name.startswith('native'):result=run(name,ROOT/'patch-notes',ROOT/'patch-notes/scripts/debug/verify_store_prerequisite_links.gd',native=True)
 elif name=='keyboard-red-v2':result=run(name,RAW/'keyboard-red/project',HERE/'keyboard_probe.gd',reuse=True)
 elif name.startswith('keyboard'):result=run(name,ROOT/'patch-notes',HERE/'keyboard_probe.gd')
 else:raise SystemExit('Unknown check: '+name)
 raise SystemExit(0 if result['pass'] else 1)
