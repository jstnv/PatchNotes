from run import *
import re
p=load(HERE/'publication.json');count=0
for name in p['files']:
    path=THREAD/name
    for target in re.findall(r'\]\(([^)]+)\)',path.read_text(encoding='utf-8')):
        if target.startswith(('https:','http:','#')):continue
        assert (path.parent/target.split('#')[0]).exists(),(name,target)
        count+=1
todo=(ROOT/'docs/codex/TODO.md').read_bytes();new=p['todo_replacement_line'].encode();old=p['todo_original_line'].encode()
assert todo.count(new)==1 and todo.replace(new,old,1)==(HERE/'TODO.before.md').read_bytes()
for name,change in p['indexes'].items():
    current=(THREAD/name).read_bytes();addition=change['addition'].encode()
    assert current.count(addition)==1 and current.replace(addition,b'',1)==(HERE/(name+'.before')).read_bytes()
before=load(HERE/'source-before.json');after=load(HERE/'source-after.json');assert before['candidate']==after['candidate']
assert (HERE/'head-after.txt').read_text().strip()=='0132c4dab398a2a94dbeae3caa68a36505fbfa4f'
assert (HERE/'branch-after.txt').read_text().strip()=='main'
manifest=load(HERE/'evidence-manifest.json')
for name,sha in manifest.items():assert hashlib.sha256(Path(name).read_bytes()).hexdigest()==sha,name
docs={name:hashlib.sha256((THREAD/name).read_bytes()).hexdigest() for name in p['files']}
scripts={path.name:hashlib.sha256(path.read_bytes()).hexdigest() for path in HERE.glob('*.py')}
result=dict(status='PASS',local_links=count,evidence_hashes=len(manifest),unrelated_todo_bytes_preserved=True,old_index_bodies_preserved=True,source_scope='Frozen private candidate verified; canonical concurrent drift recorded in source-after.json and requires adoption reconciliation.',document_hashes=docs,study_script_hashes=scripts)
write(HERE/'final-check.json',result);print(json.dumps(result))
