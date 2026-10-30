from pathlib import Path
import json,statistics
study=Path(__file__).resolve().parent
raw=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-lookahead-20261024-v1')
analysis=json.loads((study/'analysis-v1.json').read_text())
rows=[]
for r in analysis['results']:
    if not r['ok']:continue
    rows.append({'case':r['case'],'redraws':r['redraws'],'remaining_redraws':r['remaining_redraws'],'commands':r['commands'],'awards':[b['award'] for b in r['results']],'tokens_per_brief':[b['redraws'] for b in r['results']]})
times=[r['planning_ms'] for r in analysis['lookahead_audit']]
report=json.loads((raw/'candidates/run-report.json').read_text())
monotone=[];decisions=[]
for line in (raw/'candidates/experiment.log').read_text(encoding='utf-8',errors='replace').splitlines():
    if line.startswith('PN_CB_SAFE_MONOTONE '):monotone.append(json.loads(line.split(' ',1)[1]))
    if line.startswith('PN_CB_SAFE_DECISION '):decisions.append(json.loads(line.split(' ',1)[1]))
result={'rows':rows,'planning_ms':{'count':len(times),'min':min(times),'median':statistics.median(times),'max':max(times),'total':sum(times)},
    'recorded_commands':sum(r['commands'] for r in analysis['results']),'briefs':sum(r.get('briefs',0) for r in analysis['results']),'zero':sum(r.get('zero',0) for r in analysis['results']),'full':sum(r.get('full',0) for r in analysis['results']),
    'safe_redraw_count':len(monotone),'safe_improved':sum(r['after']>r['before'] for r in monotone),'safe_unchanged':sum(r['after']==r['before'] for r in monotone),'safe_worsened':sum(r['after']<r['before'] for r in monotone),'safe_skipped_no_benefit':sum(d['decision']['token']==-1 for d in decisions),'safe_events':monotone,
    'identities':{k:report['variant'][k] for k in ['base_identity','creation_identity','candidate_identity','canonical_identity']},'frozen':report['frozen_source_identity'],'canonical_delta_count':len(report['variant']['canonical_delta']),
    'batch_elapsed_seconds':{n:json.loads((raw/n/'experiment.command.json').read_text()).get('elapsed_seconds') for n in ['controls-v2','candidates']}}
with (study/'summary-v1.json').open('x',encoding='utf-8') as f:json.dump(result,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in result.items() if k!='safe_events'},indent=2))
