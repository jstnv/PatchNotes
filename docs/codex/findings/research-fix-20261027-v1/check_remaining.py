"""Preflight remaining suites after the retained UI-timing assertion failure.
Not a release gate; the official fresh gate is run after corrections.
"""
from pathlib import Path
import importlib.util,json,os
OUT=Path(__file__).resolve().parent/'remaining-preflight';OUT.mkdir(exist_ok=False)
ROOT=OUT.parents[4]
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
gate=load('release_gate',ROOT/'tools/release_gate.py')
checks=load('checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE=OUT;checks.GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe';checks.PROFILE=OUT/'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
report={'passed':[],'failed':[],'purpose':'remaining-suite preflight, not release acceptance'}
started=False
for name,path in gate.verifier_jobs():
 if name=='verify_main_menu_history':started=True
 if not started:continue
 evidence=OUT/'verifier-artifacts'/name;evidence.mkdir(parents=True)
 os.environ['PN_CARD_FRAME_OUTPUT']=str(evidence/'result.json')
 script,metadata=gate.checkpoint_wrapper(path,OUT/'checkpoint-wrappers')
 os.environ.update(gate.verifier_environment(OUT,name))
 profile=gate.continuation_profile(OUT,'verify_rival_gameplay_activation') if name=='verify_rival_gameplay_cold_continue' else None
 try:
  checks.run(name,gate.verifier_arguments(OUT,name,str(script)),timeout=gate.verifier_timeout(name),profile=profile)
  report['passed'].append(name)
 except Exception as error:
  report['failed'].append({'name':name,'error':str(error)})
 (OUT/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
