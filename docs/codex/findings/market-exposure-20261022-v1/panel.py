"""Sequential predeclared panel; never substitutes a seed after a failure."""
from pathlib import Path
import json
import subprocess
import sys

OUT=Path(__file__).resolve().parent
SOURCE='5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536'
results=[]
for route in ['action-war','action-fantasy','puzzle-war','puzzle-fantasy']:
    for seed in ['4417','4418']:
        label=f'{route}-{seed}-v2'
        report=OUT/(label+'.json')
        result_file=OUT/(label+'-run.json')
        if result_file.exists():
            execution=json.loads(result_file.read_text())
        else:
            rc=subprocess.run([sys.executable,str(OUT/'run.py'),label,'--route='+route,'--seed='+seed,'--source='+SOURCE],check=False).returncode
            execution=json.loads(result_file.read_text()) if result_file.exists() else {'exit':rc,'missing_result':True}
        results.append({'label':label,'record':execution})
        (OUT/'panel-progress.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
        if execution.get('exit')!=0 or execution.get('errors') or not report.exists():
            print('RECORD_FAILED '+label,flush=True)
            continue
        data=json.loads(report.read_text())
        if data.get('failures') or not data.get('completed') or data.get('source_drift'):
            print('RECORD_INCOMPLETE '+label,flush=True)
            continue
        replay='replay-'+label
        replay_file=OUT/(replay+'-run.json')
        if replay_file.exists():
            replay_execution=json.loads(replay_file.read_text())
        else:
            rc=subprocess.run([sys.executable,str(OUT/'run.py'),replay,'--route='+route,'--seed='+seed,'--source='+SOURCE,'--mode=replay','--input='+str(report)+'.tape.json'],check=False).returncode
            replay_execution=json.loads(replay_file.read_text()) if replay_file.exists() else {'exit':rc,'missing_result':True}
        results[-1]['replay']=replay_execution
        (OUT/'panel-progress.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
        print('PANEL_ROUTE '+label+' '+str(execution.get('exit'))+' '+str(replay_execution.get('exit')),flush=True)
print('PANEL_FINISHED',flush=True)
