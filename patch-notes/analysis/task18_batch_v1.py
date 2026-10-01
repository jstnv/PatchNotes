from pathlib import Path
import json,hashlib,sys
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task18-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT/'.gdignore').touch()
manifest={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for f in ['scripts','scenes','data'] for p in (v.ROOT/f).rglob('*') if p.is_file()}
(v.OUT/'source-before.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
(v.OUT/'initial-status.txt').write_bytes(v.git('status','--short'))
(v.OUT/'initial-diff.patch').write_bytes(v.git('diff'))
results=[v.run('import',v.ROOT,['--editor','--import'])]
for policy in ['ordinary','synergy']:
    for mode in ['normal','curated','core']:
        results.append(v.run(policy+'-'+mode,v.ROOT,['--script','res://analysis/task18_curated_trial_v1.gd','--','--policy='+policy,'--reward='+mode,'--count=12','--game3-count=2'],240))
for name in ['atomic_selected_redraw','redraw_class_parity','shared_redraw_and_priority_adjustment','first_game_scripted_tutorial','sidestreet_scope_and_year','game_lifespan_trial']:
    results.append(v.run('verify_'+name,v.ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
(v.OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
assert all(hashlib.sha256((v.ROOT/p).read_bytes()).hexdigest()==h for p,h in manifest.items())
