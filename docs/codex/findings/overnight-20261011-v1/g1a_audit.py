from pathlib import Path
import json
HERE=Path(__file__).resolve().parent
checks=[]
def check(ok,label):
    checks.append({'ok':bool(ok),'label':label})
    if not ok:raise AssertionError(label)
def read(p):return json.loads(p.read_text())
original=read(HERE/'g1a-two-release-input.json')
for seed in ['4417','90210']:
    case='g1a-incumbent-'+seed
    initial=next(c for c in original['cases'] if c['case_id']==case)['initial']['recipe']['incumbent']['historical_titles']
    for folder,identifier,total in [('g1a-two-release-run-v1',case,2)]+([('g1a-continuation-run-v1','g1a-continued-4417',3)] if seed=='4417' else []):
        result=read(HERE/folder/'cases'/identifier/'result.json')
        outcome=result['outcome']
        payload=read(HERE/folder/'cases'/identifier/'studio_checkpoint.json')['studio_payload']
        state=payload['run']; archived={r['id'] for r in initial}
        check(result['ok'] and result['final_release_count']==total,identifier+' completed legal live releases')
        check(outcome['historical_titles']==initial,identifier+' archive byte-equivalent JSON fields')
        live={r['id'] for r in outcome['releases']}
        check(len(live)==total and not live & archived,identifier+' distinct archive/live IDs')
        check({r['key'] for r in state['released_games']}==live,identifier+' only live IDs in ordinary sales ledger')
        check({r['key'] for r in state['release_metadata']}==live,identifier+' only live IDs in launch metadata')
        check(all(':project:' in r for r in live),identifier+' generated project namespace')
        check(not any(a in json.dumps(state['fanbase']) for a in archived),identifier+' archive never enters Fanbase journal')
        check(not any(a in json.dumps(state['studio_finance']) for a in archived),identifier+' archive never enters finance journal')
        check(outcome['opening_snapshot']['fans']==20 and outcome['opening_snapshot']['cash_cents']==585000,identifier+' unchanged example opening resources')
    replay=read(HERE/('g1a-replay-'+seed+'-v1')/'replay-report.json')
    check(replay['ok'],case+' fresh-process replay passed')
    # Recompute outcome summaries separately from success flags in the runner.
    for step in replay['steps']:check(step['accepted'],case+' replay command '+str(step['step']))
(HERE/'g1a-audit.json').write_text(json.dumps({'passed':len(checks),'checks':checks},indent=2))
print(len(checks),'checks passed')
