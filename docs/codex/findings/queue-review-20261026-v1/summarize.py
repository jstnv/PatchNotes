from pathlib import Path
import json
out=Path(__file__).resolve().parent
p=out/'campaign-run/cases/action-4417-three-releases/result.json'
r=json.loads(p.read_text()); outcome=r['outcome']
summary={k:r[k] for k in ['ok','commands','accepted_commands','final_run_cycle','final_release_count']}
summary.update({k:outcome.get(k) for k in ['cash_cents','fans','phase','in_studio','owned_features','research_queue']})
summary['reviews']=[{k:item.get('metadata',{}).get('review',{}).get(k) for k in ['final_review','scope','required_scope','remaining_bugs','development_cycles']} for item in outcome['releases']]
summary['finance_keys']=list(outcome['finance'])
summary['finance_status']={k:v for k,v in outcome['finance'].items() if not isinstance(v,(dict,list))}
(out/'campaign-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
