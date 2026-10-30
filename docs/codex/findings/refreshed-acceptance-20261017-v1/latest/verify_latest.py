from pathlib import Path
import importlib.util, json, os, subprocess

BASE=Path(__file__).resolve().parent
SNAP=BASE/'snapshot'
OUT=BASE/'focused'
OUT.mkdir(exist_ok=False)
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
checks=load('checks_latest',SNAP/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
gate=load('gate_latest',SNAP/'tools/release_gate.py')
checks.HERE=OUT;checks.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47836'
checks.run('import',['--editor','--import','--quit'])
for name in ('verify_rival_trial_activation','verify_rival_gameplay_activation','verify_checkpoint_codec','verify_bank_integration'):
    script,meta=gate.checkpoint_wrapper(SNAP/f'patch-notes/scripts/debug/{name}.gd',OUT/'wrappers')
    script.write_text(script.read_text().replace('47733','47836'))
    checks.run(name,['--script',str(script)])
profiles=list(checks.PROFILE.glob('verify_rival_gameplay_activation-*'))
assert len(profiles)==1
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):env[key]=str(profiles[0]/key)
command=[checks.GODOT,'--headless','--path',str(checks.PROJECT),'--script','res://scripts/debug/verify_rival_gameplay_cold_continue.gd']
with (OUT/'cold-continue.log').open('wb') as log:
    result=subprocess.run(command,env=env,cwd=SNAP,stdout=log,stderr=subprocess.STDOUT,timeout=90)
text=(OUT/'cold-continue.log').read_text()
errors=[line for line in text.splitlines() if line.startswith('ERROR:') or 'SCRIPT ERROR' in line]
(OUT/'cold-continue.command.json').write_text(json.dumps(dict(command=command,profile=str(profiles[0]),exit=result.returncode,errors=errors),indent=2))
assert result.returncode==0 and not errors,text[-2000:]
print('LATEST_FOCUSED_PASS import + 5 suites (paired cold Continue)')
