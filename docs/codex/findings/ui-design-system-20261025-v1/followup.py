"""Verifier-only continuation on the identical already-imported runtime."""
from pathlib import Path
import importlib.util,json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
c=module('ui_followup_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1')
gate=module('ui_followup_gate',ROOT/'tools/release_gate.py')
out=c.RAW/'final-followup';out.mkdir(exist_ok=False)
prior=json.loads((c.RAW/'final-matrix/canonical-source.json').read_text())
current=c.sim.source_hashes(ROOT/'patch-notes')
delta=[k for k in prior.keys()|current.keys() if prior.get(k)!=current.get(k)]
assert all(k.startswith('scripts/debug/') for k in delta),delta
report={'runtime_identical_to':'final-matrix/canonical-source.json','verifier_only_delta':delta,'checks':[]}
for name in ['verify_studio_specialties','verify_ui_folder_navigation']:
    source=ROOT/'patch-notes/scripts/debug'/(name+'.gd')
    if name=='verify_studio_specialties':
        wrapper,meta=gate.checkpoint_wrapper(source,out/'wrappers'/name)
        text=wrapper.read_text(encoding='utf8').replace('47733','47739')
        text=text.replace('extends "res://scripts/debug/'+name+'.gd"','extends '+json.dumps(source.as_posix()))
        marker='func _initialize() -> void:\n'
        text=text.replace(marker,marker+'\tassert(preload("res://scripts/tutorial/onboarding_preferences.gd").new().answer(true))\n')
        wrapper.write_text(text,encoding='utf8')
        script=wrapper
    else:script=source
    receipt=c.run('final-followup/'+name,c.RAW/'final-matrix/project',script,reuse=True)
    report['checks'].append({'name':name,**receipt})
report['pass']=all(r['pass'] for r in report['checks'])
c.sim.write_json(out/'result.json',report)
raise SystemExit(0 if report['pass'] else 1)
