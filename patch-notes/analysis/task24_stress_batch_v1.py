"""Native isolated-profile stress captures. No gameplay/source mutations."""
from pathlib import Path
import hashlib, json, sys
import tutorial_task17_verify_v1 as v
v.OUT = v.ROOT / 'design-logs/task24-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()
arms = sys.argv[1:] or ['priority', 'empty', 'repeat']
before = {str(p.relative_to(v.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
          for folder in ['scripts','scenes','data'] for p in (v.ROOT/folder).rglob('*') if p.is_file()}
(v.OUT/'stress-source-before.json').write_text(json.dumps(before,indent=2),encoding='utf-8')
results=[]
for arm in arms:
    results.append(v.run('stress-'+arm,v.ROOT,['--script','res://analysis/task24_stress_v1.gd','--','--stress='+arm,'--cap=1104'],1200))
(v.OUT/'stress-verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
after={s:hashlib.sha256((v.ROOT/s).read_bytes()).hexdigest() for s in before}
assert before == after, 'Runtime source changed during stress capture'
assert all(r['exit']==0 and not r['errors'] for r in results)
