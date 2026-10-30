"""Same six preregistered cases; separate serial engines avoid batch allocation pressure."""
from pathlib import Path
import json,subprocess,sys,time,importlib.util
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5]
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-crown-paid-brief-20261025-v1/serial-v3')
VARIANT=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/20261025-implementation-variants/crown-paid-brief-private-20261025-v1')
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
while not (ROOT/'docs/codex/findings/contract-search-20261025-v1/direct-exe-receipt.json').exists():time.sleep(2)
RAW.mkdir(exist_ok=False);(RAW/'configs').mkdir()
source=json.loads((HERE/'paid-experiment-v2.json').read_text());rows=[]
def invoke(label,args):
    with (RAW/(label+'.driver.log')).open('x',encoding='utf8') as stream:
        r=subprocess.run([sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),*args,'--godot',GODOT],cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=720)
    row={'label':label,'exit':r.returncode,'command':args};rows.append(row);(RAW/'driver-result.json').write_text(json.dumps({'complete':False,'records':rows},indent=2));print(label,r.returncode,flush=True)
for case in source['cases']:
    label=case['case_id'];cfg={**source,'cases':[case]};path=RAW/'configs'/(label+'.json');path.write_text(json.dumps(cfg,indent=2))
    invoke(label,['run','--variant',str(VARIANT),'--config',str(path),'--output',str(RAW/label),'--timeout','600'])
for label in ['paid-4417-greedy','paid-4417-mean']:
    if not json.loads((RAW/label/'run-report.json').read_text()).get('ok'):continue
    invoke(label+'-replay',['replay','--bundle',str(RAW/label),'--case',label,'--output',str(RAW/(label+'-replay')),'--timeout','600'])
spec=importlib.util.spec_from_file_location('private_cold_checks',ROOT/'docs/codex/findings/store-prerequisite-links-20261024-v1/checks.py');c=importlib.util.module_from_spec(spec);spec.loader.exec_module(c);c.RAW=RAW
for label in ['paid-4417-greedy','paid-4417-mean']:
    path=RAW/label/'cases'/label/'studio_checkpoint.json'
    if path.exists():
        r=c.run(label+'-cold',RAW/label/'project',HERE/'paid_cold_consumer.gd',['--input='+str(path)],reuse=True);rows.append({'label':label+'-cold',**r})
(RAW/'driver-result.json').write_text(json.dumps({'complete':True,'records':rows},indent=2));print('PAID_SERIAL_DONE',flush=True)
