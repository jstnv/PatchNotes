"""Compact source-pinned economics; retain full journals/tapes in raw evidence."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent
RAW=Path('C:/Users/64jus/AppData/Local/Temp/pn-qa-employees-20261025-v1/quality-wages-v3')
driver=json.loads((RAW/'driver-result.json').read_text())
assert driver['complete'] and len(driver['records'])==12 and all(r['pass'] for r in driver['records'])
rows=[];groups={};sources=[]
for rec in driver['records']:
    path=RAW/rec['name']/'result.json';result=json.loads(path.read_text());r=result['rows'][0]
    assert result['source']==json.loads((RAW/driver['records'][0]['name']/'result.json').read_text())['source']
    employees=list(r['employees']['employees'].values())
    row={k:r.get(k) for k in ['hands','seed','arm','release_count','cash','minimum_cash','post_hire_minimum_cash','blocked','end_cycle','commands','course_spend','payroll','next_game_affordable','studio_valid']}
    row['boundary']={k:r['boundary'][k] for k in ['cycle','cash','state_digest']}
    row['qa_training']=[{k:e.get(k) for k in ['trained','swap_trained','search_count','debug_count']} for e in employees if e['type']=='qa']
    row['finance']=r['finance'];row['finance'].pop('rows',None)
    row['file']=str(path);row['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    rows.append(row);groups.setdefault((r['hands'],r['seed']),[]).append(r)
matches=[]
for key,arms in groups.items():
    assert len(arms)==3 and len({r['initial_digest'] for r in arms})==1 and len({r['boundary']['state_digest'] for r in arms})==1
    matches.append({'hands':key[0],'seed':key[1],'initial_exact':True,'post_game2_exact':True})
summary={'source':result['source'],'raw':str(RAW),'records':rows,'matched_prefixes':matches,'outcomes':{arm:{'six_releases':sum(r['arm']==arm and r['release_count']==6 for r in rows),'blocked':sum(r['arm']==arm and bool(r['blocked']) for r in rows)} for arm in ['none','qa','both']},'gate':'FAIL: all four dual-hire continuations block. QA-alone succeeds on this stronger route; no universal affordability or both-raise sustainability claim. Retain the two earlier failed studies. No post-hire Contracts, Bank or synthetic income.'}
(HERE/'quality-wages-v3-summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps({'outcomes':summary['outcomes'],'matched_prefixes':matches,'gate':summary['gate']}))
