from pathlib import Path
import json,hashlib,subprocess,re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,x):(HERE/name).write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8')
assert not (HERE/'publication.json').exists()
git={}
for label,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('status',['status','--short']),('diff',['diff','--stat'])]:
    r=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0
    (HERE/(label+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8');git[label]=r.stdout.strip() if label in ['head','branch'] else label+'.txt'
source=['patch-notes/scripts/phases/studio_phase.gd','patch-notes/scripts/contracts/contract_challenges.gd']
pins={s:sha(ROOT/s) for s in source}
receipts=[]
def edit(path,old,new,label):
    before=path.read_bytes();assert before.count(old)==1
    after=before.replace(old,new,1);backup=HERE/(label+'-before.md');assert not backup.exists();backup.write_bytes(before)
    assert path.read_bytes()==before,'Concurrent write: '+str(path)
    path.write_bytes(after);assert path.read_bytes()==after
    receipts.append(dict(path=str(path.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(path),old=old.decode('utf-8'),new=new.decode('utf-8'),backup=backup.name))
summary='**2026-10-25 Search follow-ups — acceptance clarified; parallel catalog DESIGN queued.** [CS9–CS10 addendum](CONTRACT-SEARCH-ACCEPTANCE-ADDENDUM-2026-10-25-v1.md) makes empty-offer search access and source-pinned career evidence explicit within the existing implementation scope. [Parallel workplan](PUBLISHER-CATALOG-WORKPLAN-2026-10-25-v1.md) recommends Crown authored work templates and qualitative progression, followed by Neon/Starwave. Prepare post-search comparisons here; run them after accepted source is available. No new rewards, thresholds, Crown activation or redraw work approved; current gameplay preserved.'
for name,label in [('README.md','readme'),('HANDOFF.md','handoff')]:
    path=THREAD/name;b=path.read_bytes();nl=b'\r\n' if b'\r\n' in b[:200] else b'\n';heading=b[:b.index(nl)+len(nl)]
    edit(path,heading,heading+nl+summary.encode()+nl,label)

# Fresh shared-TODO read immediately before replacing exactly its existing Search paragraph.
path=ROOT/'docs/codex/TODO.md';before=path.read_bytes()
rows=[line for line in before.splitlines(keepends=True) if line.startswith(b'**Contracts search ')]
assert len(rows)==1
old=rows[0];nl=b'\r\n' if old.endswith(b'\r\n') else b'\n'
extra=' [CS9–CS10 acceptance/evidence addendum](threads/contracts/CONTRACT-SEARCH-ACCEPTANCE-ADDENDUM-2026-10-25-v1.md): ensure search remains reachable with no pending offers and after last completion/cold Continue; distinguish free browsing from blocked searches. Preserve source/standing/offer/cycle evidence needed for subsequent legal career comparisons. These clarify the existing CS7/CS8 scope; no duplicate implementation or new tuning requirement.'
design='**Searchable publisher catalog and post-search pacing — DESIGN review, 2026-10-25.** [Parallel workplan](threads/contracts/PUBLISHER-CATALOG-WORKPLAN-2026-10-25-v1.md). Contracts design thread can draft Crown-specific work templates, qualitative Reputation progression and readable objectives, then Neon/Starwave, without changing the active Search implementation. Retain current rewards and parked redraw research; new numerical tiers, longer hands, offer-selection randomness and Crown activation remain OPEN. Prepare Contract-led/release-led/no-search comparisons and low-resource entry coverage; execute only after accepted search source is pinned with regenerated legal starts where necessary. This is research/content review, not queued canonical publisher activation; existing Crown preview/adoption gates remain separate.'
new=old.rstrip(b'\r\n')+extra.encode()+nl+nl+design.encode()+nl
edit(path,old,new,'todo')
for r in receipts:
    b=(ROOT/r['path']).read_bytes();assert b.replace(r['new'].encode(),r['old'].encode(),1)==(HERE/r['backup']).read_bytes()
for s,h in pins.items():assert sha(ROOT/s)==h,s
links=0
for name in ['CONTRACT-SEARCH-ACCEPTANCE-ADDENDUM-2026-10-25-v1.md','PUBLISHER-CATALOG-WORKPLAN-2026-10-25-v1.md']:
    p=THREAD/name;t=p.read_text(encoding='utf-8');assert all(x==x.rstrip() for x in t.splitlines())
    for target in re.findall(r'\]\(([^)]+)\)',t):assert (p.parent/target).exists();links+=1
args=['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0,r.stdout+r.stderr
write('publication.json',dict(status='PASS',git=git,source_hashes=pins,source_files_unchanged=True,records=receipts,local_links=links,diff_check=dict(command=args,exit_code=r.returncode),gameplay_edits=0,runtime_checks=0,new_simulations=0))
print('PASS: Search acceptance reference + one DESIGN entry; unrelated queue bytes preserved; no source changes.')
