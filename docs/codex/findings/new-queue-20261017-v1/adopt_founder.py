from run_checks import *
packet=ROOT/'docs/codex/threads/founder-legacy-ownership/handoffs/victory-ledger-v1'
candidate=ROOT/'docs/codex/threads/founder-legacy-ownership/simulators/victory-ledger-v1/project'
handoff=sim.read_json(packet/'handoff.json')
review=[]
for row in handoff['changes']:
 source=candidate/row['path'];target=ROOT/'patch-notes'/row['path']
 assert sim.sha(source)==row['after_sha256'],row['path']
 assert (sim.sha(target) if target.exists() else None)==row['before_sha256'],row['path']
 review.append(row)
sim.write_json(BASE/'founder-reconciliation.json',{'changes':review,'baseline_conflicts':[]})
for row in review:
 target=ROOT/'patch-notes'/row['path'];target.parent.mkdir(parents=True,exist_ok=True)
 target.write_bytes((candidate/row['path']).read_bytes())
