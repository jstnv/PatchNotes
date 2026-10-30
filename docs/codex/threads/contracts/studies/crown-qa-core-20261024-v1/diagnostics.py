from setup import HERE, RAW, write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
a=load(HERE/'analysis.json');assert a['complete']
exits=[];reviews=[]
for row in a['rows']:
    if row['arm']!='candidate':continue
    ordinal=row['first_qualifying_release'] or 6
    q=row['review_details'][ordinal-1]
    reviews.append({'case':row['case'],'release':ordinal,'unlocked':row['unlocked'],'review':q,'zero_variance':row['zero_variance'][ordinal-1],'component_diagnostic':row['diagnostics'][ordinal-1]})
    if not row['pair'].startswith('qa-'):continue
    with (RAW/row['pair']/'experiment.log').open(encoding='utf-8-sig') as stream:
        for line in stream:
            if not line.startswith('FOLLOWUP '):continue
            n=json.loads(line[9:]);cmd=n['command'];d=n['development']
            if n['case']!=row['case'] or cmd['type']!='development' or d['phase']!='beta' or cmd['payload']['request']['type']!='request_exit':continue
            exits.append({'case':n['case'],'release':n['releases']+1,'cycle':n['cycle'],'cash_cents':n['cash'],'known_bugs':d['known_bugs'],'fixed_bugs':d['fixed_bugs'],'redraws_available':d['redraws'],'visible':[c['definition'] for c in d['candidates']]})
write(HERE/'diagnostics.json',{'status':'descriptive post-run evidence; no extra intervention','candidate_qualifying_or_final_reviews':reviews,'qa_observed_exits':exits})
print(json.dumps({'candidate_reviews':[{'case':r['case'],'release':r['release'],'review':r['review']['final_review'],'zero_variance':r['zero_variance'],'bugs':r['review']['remaining_bugs']} for r in reviews],'final_beta_exits':[e for e in exits if e['release']==6]},indent=2))
