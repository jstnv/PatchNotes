from pathlib import Path
import json, subprocess, sys

out = Path(__file__).resolve().parent
results = []
def run(label, script, *args):
    result = subprocess.run([sys.executable, str(out/'run.py'), label, 'res://scripts/debug/'+script+'.gd', *map(str,args)], capture_output=True, text=True)
    results.append({'label':label,'exit':result.returncode,'stdout':result.stdout,'stderr':result.stderr})
    (out/'closeout-runs.json').write_text(json.dumps(results,indent=2))
    print(label,result.returncode,flush=True)
    if result.returncode: raise SystemExit(result.returncode)

run('campaign-closeout','campaign_experiment_cli','--config='+str(out/'campaign-config.json'),'--output-dir='+str(out/'campaign-closeout-cases'),'--output='+str(out/'campaign-closeout-report.json'))
for label, folder in [(g,out/'campaign-closeout-cases'/g) for g in ['action','strategy','simulation','sports']] + [('ai-first',out/'ai-compare-final.json.first/adventure-4417-trial'),('ai-second',out/'ai-compare-final.json.second/adventure-4417-trial-second')]:
    run('closeout-replay-'+label,'campaign_replay_cli','--case='+str(folder/'case.variant.json'),'--tape='+str(folder/'replay.tape.json'),'--output='+str(out/('closeout-replay-'+label+'.json')))
before=json.loads((out/'campaign-report.json').read_text())
after=json.loads((out/'campaign-closeout-report.json').read_text())
keys=['initial_state','initial_rng','final_state','final_rng','commands','accepted_commands','productive_commands','final_run_cycle','final_release_count']
comparisons=[{'case_id':a['case_id'],'equal':{k:a[k]==b[k] for k in keys}} for a,b in zip(before['results'],after['results'])]
(out/'player-parity.json').write_text(json.dumps(comparisons,indent=2))
assert all(all(row['equal'].values()) for row in comparisons),comparisons
print('PLAYER_CAMPAIGNS_UNCHANGED',len(comparisons),flush=True)
