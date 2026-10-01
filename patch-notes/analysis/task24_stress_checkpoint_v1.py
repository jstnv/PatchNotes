"""Bounded empty-release evidence independent of the long capture."""
import json
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-v1'
r=v.run('stress-empty-checkpoint240',v.ROOT,['--script','res://analysis/task24_stress_v1.gd','--','--stress=empty','--cap=240','--tag=checkpoint240'],300)
assert r['exit']==0 and not r['errors']
row=json.loads((v.OUT/'stress_empty_checkpoint240.json').read_text(encoding='utf-8'))['rows'][0]
assert row['valid'] and row['final']['cycle']==240
assert not any(r['meets_required_scope'] for r in row['releases'])
assert all(not r['sidestreet_offer_available'] for r in row['releases'])
assert len({r['release_id'] for r in row['releases']})==len(row['releases'])
print('Empty bounded checkpoint passed:',len(row['releases']),'releases; cash',row['final']['cash_cents'])
