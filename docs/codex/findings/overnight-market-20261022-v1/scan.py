"""Non-fail-fast diagnostic scan of the maintained gate, same real verifiers."""
from pathlib import Path
import importlib.util,json,os,sys
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent/'scan'
OUT.mkdir(exist_ok=False);(OUT/'.gdignore').touch()
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
gate=load('gate',ROOT/'tools/release_gate.py');sim=load('sim',ROOT/'tools/simulate.py')
checks=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE=OUT;checks.GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe';checks.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
for key in ['PN_ALPHA_COMMAND_MODE','PN_BETA_COMMAND_MODE','PN_DESIGN_COMMAND_MODE','PN_DEVELOPMENT_MODE','PN_PAUSE_PRIOR_WORLD']:os.environ.pop(key,None)
source=sim.source_hashes(ROOT/'patch-notes');sim.write_json(OUT/'source.json',source)
results=[]
for name,path in gate.verifier_jobs():
 try:
  (OUT/'verifier-artifacts'/name).mkdir(parents=True,exist_ok=True)
  os.environ.update(gate.verifier_environment(OUT,name))
  wrapper,metadata=gate.checkpoint_wrapper(path,OUT/'wrappers')
  profile=gate.continuation_profile(OUT,'verify_rival_gameplay_activation') if path.stem=='verify_rival_gameplay_cold_continue' else None
  checks.run(name,gate.verifier_arguments(OUT,name,str(wrapper)),timeout=gate.verifier_timeout(name),profile=profile)
  row={'name':name,'ok':True}
 except Exception as error:row={'name':name,'ok':False,'error':str(error)}
 results.append(row);sim.write_json(OUT/'results.json',results);print(json.dumps(row),flush=True)
sim.write_json(OUT/'source-check.json',{'unchanged':source==sim.source_hashes(ROOT/'patch-notes')})
sys.exit(0 if all(x['ok'] for x in results) else 1)
