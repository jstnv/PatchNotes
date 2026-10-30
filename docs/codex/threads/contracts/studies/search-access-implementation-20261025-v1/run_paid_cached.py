"""Serial continuation of the exact tool-frozen v2 artifact; no new import."""
from pathlib import Path
import importlib.util,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5]
BASE=Path('C:/Users/64jus/AppData/Local/Temp/pn-crown-paid-brief-20261025-v1')
OUT=BASE/'cached-serial-v4';OUT.mkdir(exist_ok=False);(OUT/'configs').mkdir()
PROJECT=BASE/'run-v2/project'
spec=importlib.util.spec_from_file_location('cached_crown_checks',ROOT/'docs/codex/findings/store-prerequisite-links-20261024-v1/checks.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.RAW=OUT
config=json.loads((BASE/'run-v2/inputs/experiment.json').read_text());rows=[]
for case in config['cases']:
 name=case['case_id'];path=OUT/'configs'/(name+'.json');path.write_text(json.dumps({**config,'cases':[case]},indent=2))
 r=c.run(name,PROJECT,PROJECT/'scripts/debug/campaign_experiment_cli.gd',['--config='+str(path),'--output-dir='+str(OUT/name/'cases'),'--output='+str(OUT/name/'experiment-report.json')],reuse=True)
 rows.append({'name':name,**r});(OUT/'driver-result.json').write_text(json.dumps({'complete':False,'records':rows},indent=2))
for name in ['paid-4417-greedy','paid-4417-mean']:
 cp=OUT/name/'cases'/name/'studio_checkpoint.json'
 if cp.exists():
  r=c.run(name+'-cold',PROJECT,HERE/'paid_cold_consumer.gd',['--input='+str(cp)],reuse=True);rows.append({'name':name+'-cold',**r})
  r=c.run(name+'-replay',PROJECT,PROJECT/'scripts/debug/campaign_replay_cli.gd',['--case='+str(cp.parent/'case.variant.json'),'--tape='+str(cp.parent/'replay.tape.json'),'--output='+str(OUT/(name+'-replay')/'replay-report.json')],reuse=True);rows.append({'name':name+'-replay',**r})
(OUT/'driver-result.json').write_text(json.dumps({'complete':True,'records':rows},indent=2));print('PAID_CACHED_DONE',flush=True)
