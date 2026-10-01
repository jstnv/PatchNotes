"""Task 21 source snapshot and isolated-profile Godot verification."""
from pathlib import Path
import sys, json, hashlib, subprocess
import tutorial_task17_verify_v1 as v
v.OUT = v.ROOT / 'design-logs/task21-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()
if '--snapshot' in sys.argv:
    for name,args in [('status',['status','--short']),('diff',['diff']),('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('origin',['rev-parse','origin/main'])]:
        (v.OUT/('initial-'+name+'.txt')).write_bytes(v.git(*args))
    files={}
    for folder in ['scripts','scenes','data']:
        for p in (v.ROOT/folder).rglob('*'):
            if p.is_file():
                rel=p.relative_to(v.ROOT)
                files[str(rel)]=hashlib.sha256(p.read_bytes()).hexdigest()
                dest=v.OUT/'before'/rel
                dest.parent.mkdir(parents=True,exist_ok=True)
                dest.write_bytes(p.read_bytes())
    (v.OUT/'source-before.json').write_text(json.dumps(files,indent=2),encoding='utf-8')
else:
    results=[v.run('editor-import',v.ROOT,['--editor','--import'])]
    paths=sorted((v.ROOT/'scripts/debug').glob('verify_*.gd')) if '--full' in sys.argv else [v.ROOT/'scripts/debug'/('verify_'+s+'.gd') for s in ['sidestreet_scope_and_year','sidestreet_contract','run_calendar_and_studio_entry']]
    if results[0]['exit']==0 and not results[0]['errors']:
        for p in paths:
            results.append(v.run(p.stem,v.ROOT,['--script','res://scripts/debug/'+p.name]))
    (v.OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    sys.exit(0 if all(r['exit']==0 and not r['errors'] for r in results) else 1)
