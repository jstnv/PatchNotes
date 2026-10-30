from pathlib import Path
from collections import defaultdict
import json
p=Path(__file__).resolve().parent
raw=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-planning-20261024-v1/candidate-v1')
notes=defaultdict(lambda:defaultdict(list))
for line in (raw/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
    if line.startswith('PN_CB_'):
        k,s=line.split(' ',1);r=json.loads(s);notes[r['case']][k[6:]].append(r)
same=[];changes=[]
for seed in ['4417','4418']:
    for a,b in [('balanced','retained'),('balanced_redraw','retained_redraw')]:
        x=notes[f'{a}-{seed}'];y=notes[f'{b}-{seed}']
        same.append({'seed':seed,'arms':[a,b],'same_visible_play_choices':[(h['visible'],h['chosen']) for h in x['HAND']]==[(h['visible'],h['chosen']) for h in y['HAND']],'same_results':[{k:v for k,v in h.items() if k!='case'} for h in x['RESULT']]==[{k:v for k,v in h.items() if k!='case'} for h in y['RESULT']]})
    for arm in ['balanced_redraw','retained_redraw']:
        n=notes[f'{arm}-{seed}']
        for result in n['RESULT']:
            redraw=[r for r in n['REDRAW'] if r['offer']==result['offer']]
            changes.append({'case':f'{arm}-{seed}','ordinal':result['ordinal'],'grades_before_each_redraw':[r['before_grade'] for r in redraw],'actual_final_grade':result['grade'],'actual_award_bp':result['award'],'redraws':result['redraws'],'net_grade_change_from_first_redraw':result['grade']-redraw[0]['before_grade'] if redraw else 0})
out={'retained_forecast_comparison':same,'redraw_local_changes':changes}
with (p/'diagnosis-v1.json').open('x',encoding='utf-8') as f:json.dump(out,f,indent=2);f.write('\n')
print(json.dumps(out,indent=2))
