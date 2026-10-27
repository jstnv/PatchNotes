from pathlib import Path
import importlib.util,json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
c=module('studio_extra_checks',HERE.parent/'store-prerequisite-links-20261024-v1/checks.py')
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1')
gate=module('studio_extra_gate',ROOT/'tools/release_gate.py')
out=c.RAW/'supplement';out.mkdir(exist_ok=False)
records=[]
for name in ['verify_balanced_primitive_contract','verify_contract_presentation','verify_studio_checkpoint']:
    wrapper,meta=gate.checkpoint_wrapper(ROOT/'patch-notes/scripts/debug'/(name+'.gd'),out/'wrappers'/name)
    text=wrapper.read_text().replace('47733','47739')
    text=text.replace('func _initialize() -> void:\n','func _initialize() -> void:\n\tassert(OnboardingPreferences.new().answer(true))\n')
    wrapper.write_text(text,encoding='utf8')
    records.append({'name':name,**c.run('supplement/'+name,c.RAW/'green/project',wrapper,reuse=True)})
c.sim.write_json(out/'result.json',{'pass':all(r['pass'] for r in records),'checks':records})
raise SystemExit(0 if all(r['pass'] for r in records) else 1)
