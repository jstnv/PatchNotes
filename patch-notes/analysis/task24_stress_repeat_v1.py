"""Required repeated-full-Scope arm independently of the long empty continuation."""
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-v1'
r=v.run('stress-repeat-independent',v.ROOT,['--script','res://analysis/task24_stress_v1.gd','--','--stress=repeat','--cap=1104','--tag=independent'],600)
assert r['exit']==0 and not r['errors']
