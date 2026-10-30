from pathlib import Path
import json,hashlib,subprocess,re
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,obj):(HERE/name).write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8')
assert not (HERE/'publication.json').exists()
git={}
for name,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('status',['status','--short']),('diff',['diff','--stat'])]:
    r=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0
    (HERE/(name+'.txt')).write_text(r.stdout+r.stderr,encoding='utf-8');git[name]=r.stdout.strip() if name in ['head','branch'] else name+'.txt'
paths=['patch-notes/scripts/run_state.gd','patch-notes/scripts/contracts/contract_definitions.gd','patch-notes/scripts/contracts/publisher_relationship_rules.gd','patch-notes/scripts/contracts/publisher_relationship_brief.gd','patch-notes/scripts/contracts/publisher_commission_trial.gd','patch-notes/scripts/simulation/studio_actions.gd','patch-notes/scripts/publishers/publisher_browser.gd']
pins={p:sha(ROOT/p) for p in paths}
write('intake.json',dict(git=git,source_hashes=pins,inspection_only=True,checks_run=[],campaign_runs=0,approved_user_scope=['search costs one cycle','publisher-specific Reputation eligibility','replace repeatable automatic offers','preserve introductory and already-pending offers','include commissions at existing Reputation gates'],implementation_recommendations=['SideStreet first catalog','choose publisher and type','one durable offer per successful search','no extra cash fee or empty-result charge','one pending/active offer per publisher/type, preserving legacy backlog','existing rewards and deal requirements unchanged']))
receipts=[]
def prepend(path,paragraph,label):
    before=path.read_bytes();nl=b'\r\n' if b'\r\n' in before[:200] else b'\n';cut=before.index(nl)+len(nl)
    inserted=nl+paragraph.encode()+nl
    after=before[:cut]+inserted+before[cut:]
    backup=HERE/(label+'-before.md');assert not backup.exists();backup.write_bytes(before)
    assert path.read_bytes()==before,'Concurrent change: '+str(path)
    path.write_bytes(after);assert path.read_bytes()==after
    receipts.append(dict(path=str(path.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(path),cut=cut,inserted=inserted.decode(),backup=backup.name))
summary='**2026-10-25 Contract search — approved direction; queued for PN Implementation.** [Decisions and operating recommendations](CONTRACT-SEARCH-DIRECTION-2026-10-25-v1.md) · [handoff](CONTRACT-SEARCH-HANDOFF-2026-10-25-v1.md). User approves one-cycle search, publisher-Reputation eligibility, replacement of future repeatable automatic offers while preserving introductory/pending work, and commissioned games at existing gates. Recommended first catalog: existing SideStreet cash work/Briefs/R20 commissions with unchanged rewards. Requires trusted search sources, atomic cycle/offer commitment and prospective migration; new publisher tiers remain OPEN. No gameplay implementation or new simulations in this design pass. Previous release-paced findings remain historical; Crown preview/activation approval stays separate.'
for name,label in [('README.md','readme'),('HANDOFF.md','handoff')]:prepend(THREAD/name,summary,label)
# Re-read shared queue immediately before a single insertion. Preserve all other bytes.
entry='**Contracts search — QUEUED implementation, approved direction, 2026-10-25.** User requests a one-cycle search action generating work from publisher Reputation; explicitly approves replacing repeatable automatic offers while preserving introductory/already-pending offers, and including commissioned games at existing Reputation gates. [Decisions and recommended operating defaults](threads/contracts/CONTRACT-SEARCH-DIRECTION-2026-10-25-v1.md) · [CS1–CS8 implementation handoff and acceptance](threads/contracts/CONTRACT-SEARCH-HANDOFF-2026-10-25-v1.md). Implement trusted Studio-owned search receipts, atomic productive cycle plus durable offer, Reputation-gated catalog, commission invitation/binding, prospective legacy preservation, UI/headless parity and replay/Continue/native/export acceptance. Recommended first catalog uses existing SideStreet cash work, Briefs and R20 commissions; preserve current rewards, publisher unlocks and other deal prerequisites. Introductory advances must not become repeatable; support stays separate. Preserve concurrent source/.codex-godot-temp; no Crown numerical/preview activation, new higher-tier terms, rival policy change or automatic commit/push is authorized. Source inspection only here; implementation/evidence pending.'
prepend(ROOT/'docs/codex/TODO.md',entry,'todo')
for p,h in pins.items():assert sha(ROOT/p)==h,'Concurrent inspected source change: '+p
links=0
for name in ['CONTRACT-SEARCH-DIRECTION-2026-10-25-v1.md','CONTRACT-SEARCH-HANDOFF-2026-10-25-v1.md']:
    p=THREAD/name;s=p.read_text(encoding='utf-8');assert all(x==x.rstrip() for x in s.splitlines())
    for t in re.findall(r'\]\(([^)]+)\)',s):assert (p.parent/t).exists(),t;links+=1
for r in receipts:
    data=(ROOT/r['path']).read_bytes();cut=r['cut'];ins=r['inserted'].encode()
    assert data[cut:cut+len(ins)]==ins and data[:cut]+data[cut+len(ins):]==(HERE/r['backup']).read_bytes()
args=['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert r.returncode==0,r.stdout+r.stderr
write('publication.json',dict(status='PASS',records=receipts,source_read_hashes_unchanged=True,links=links,diff_check=dict(command=args,exit_code=r.returncode),campaign_runs=0))
print(json.dumps(dict(status='PASS',source_files=len(pins),shared_todo='one queued entry; all other bytes preserved',canonical_changes=0,campaign_runs=0)))
