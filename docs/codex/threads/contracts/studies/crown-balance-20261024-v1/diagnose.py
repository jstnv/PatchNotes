"""Post-run visible-choice diagnosis; no hidden draws or hypothetical gameplay."""
from pathlib import Path
from itertools import combinations
import json

study=Path(__file__).resolve().parent
bundle=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-balance-20261024-v1/candidate-v1')
stats={'graphics':0,'sound':1,'technology':2,'design':3}
before={}; results=[]
def project(scope,cores,hand):
    out=cores[:]; multiplier=3 if len({c['primary_stat'] for c in hand})==1 else 2
    for c in hand:
        scope+=c['scope']; out[stats[c['primary_stat']]]+=multiplier*c['primary_value']
        if c['secondary_stat']: out[stats[c['secondary_stat']]]+=multiplier*c['secondary_value']
    n=2*min(scope,9)+sum(min(x,8) for x in out)+2*min(min(out),8)
    completion=10000*n//66; promise=max(0,10000-1250*max(0,max(out)-min(out)-4))
    return min(completion,promise),scope,out
for line in (bundle/'experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
    if not line.startswith('PN_CB_HAND '): continue
    row=json.loads(line.split(' ',1)[1]); key=(row['case'],row['offer'])
    scope,cores=before.get(key,(0,[0,0,0,0]))
    options=[project(scope,cores,list(hand))[0] for hand in combinations(row['visible'],4)]
    hand=[next(c for c in row['visible'] if c['token']==t) for t in row['chosen']]
    grade,scorescope,scorecores=project(scope,cores,hand)
    assert scorescope==row['projected']['scope'] and scorecores==row['projected']['cores']
    assert options.count(10000)==row['full_options']
    if row['hand']==1:
        if row['case'].startswith('balanced'): assert grade==max(options)
        results.append(dict(case=row['case'],offer=row['offer'],maximum_visible_final_grade=max(options),
                            chosen_grade=grade,positive_options=sum(x>0 for x in options),
                            full_options=options.count(10000),options=len(options)))
    before[key]=(scorescope,scorecores)
output={'scope':'All35 current final-hand choices from the actually chosen first hand; no claim about alternative first-hand futures.',
        'observations':results,'balanced_zero_with_no_positive_option':sum(x['case'].startswith('balanced') and x['maximum_visible_final_grade']==0 for x in results),
        'full_options_across_observed_final_hands':sum(x['full_options'] for x in results)}
with (study/'visible-choice-diagnosis.json').open('x',encoding='utf-8') as f: json.dump(output,f,indent=2); f.write('\n')
print(json.dumps(output,indent=2))
