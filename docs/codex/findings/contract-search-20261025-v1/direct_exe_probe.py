"""Actual release EXE, external harness only; no main-pack/path override."""
from pathlib import Path
import json,importlib.util,subprocess,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
spec=importlib.util.spec_from_file_location('direct_sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
out=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1/direct-exe-native-v2');out.mkdir(exist_ok=False);(out/'capture').mkdir()
b=json.loads((HERE/'refresh-v2/result.json').read_text());exe=Path(b['exe']['path']);assert sim.sha(exe)==b['exe']['sha256']
script=HERE/'exe-probe/direct.gd';env=sim.isolated_environment(out/'profile');env.update(PN_CHECKPOINT_TEST_PORT='47739',PN_DIRECT_EXE_IDENTITY=str(out/'identity.json'))
command=[str(exe),'--script',str(script),'--','--out='+str(out/'capture')]
start=time.monotonic()
with (out/'run.log').open('x',encoding='utf8') as stream:
 child=subprocess.Popen(command,env=env,cwd=out,stdout=stream,stderr=subprocess.STDOUT)
 while child.poll() is None:
  log=(out/'run.log').read_text(errors='replace')
  if time.monotonic()-start>180 or any(x in log for x in ['SCRIPT ERROR','Parse Error','Assertion failed']):child.kill();break
  time.sleep(.25)
 child.wait()
log=(out/'run.log').read_text(errors='replace');identity=json.loads((out/'identity.json').read_text()) if (out/'identity.json').exists() else {}
ok=child.returncode==0 and 'CONTRACT_SEARCH_UI checks=38 failures=0' in log and Path(identity.get('executable','')).resolve()==exe.resolve() and not any(x in log for x in ['SCRIPT ERROR','ERROR:','FAIL:'])
record={'pass':ok,'command':command,'exit':child.returncode,'identity':identity,'exe_sha256':sim.sha(exe),'harness_sha256':sim.sha(script),'native_captures':sorted(p.name for p in (out/'capture').glob('*.png')),'elapsed_seconds':time.monotonic()-start,'scope':'Actual release executable with test-only in-engine pointer/keyboard harness; not physical device/human comprehension'}
sim.write_json(out/'receipt.json',record);sim.write_json(HERE/'direct-exe-receipt.json',record);print(json.dumps(record));raise SystemExit(not ok)
