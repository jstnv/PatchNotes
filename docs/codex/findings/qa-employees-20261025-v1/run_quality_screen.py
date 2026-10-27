from pathlib import Path
import importlib.util,json,time
root=Path(__file__).resolve().parents[4];base=Path('C:/Users/64jus/AppData/Local/Temp/pn-contract-search-20261025-v1')
while True:
 f=base/'final-ui-continuation-v1/result.json'
 if f.exists() and 'canonical_unchanged' in json.loads(f.read_text()):break
 time.sleep(5)
spec=importlib.util.spec_from_file_location('wage_c',root/'docs/codex/findings/store-prerequisite-links-20261024-v1/checks.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c)
c.RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-qa-employees-20261025-v1/quality-wages-v3');c.RAW.mkdir(exist_ok=False)
records=[]
for hands in [2,3]:
 for seed in [4417,61001]:
  for arm in ['none','qa','both']:
   name=f'h{hands}-s{seed}-{arm}'
   r=c.run(name,base/'native-current/project',root/'docs/codex/findings/qa-employees-20261025-v1/quality_wage_screen.gd',[f'--hands={hands}',f'--seed={seed}',f'--arm={arm}'],reuse=True)
   records.append({'name':name,**r});(c.RAW/'driver-result.json').write_text(json.dumps({'complete':False,'records':records},indent=2))
(c.RAW/'driver-result.json').write_text(json.dumps({'complete':True,'records':records},indent=2));print('QUALITY_WAGE_SCREEN done',len(records),flush=True)
