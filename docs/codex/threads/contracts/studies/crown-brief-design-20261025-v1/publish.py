from pathlib import Path
import json,re,hashlib,subprocess,datetime,ast
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
digest=lambda b:hashlib.sha256(b).hexdigest()
def save(name,data):
    with (HERE/name).open('x',encoding='utf-8') as f:json.dump(data,f,indent=2);f.write('\n')
def main():
    results=json.loads((HERE/'results.json').read_text());assert results['status']=='PASS' and results['checks']==87
    body='Beta redraw work PARKED by user. Candidate two-hand balanced-craft Brief keeps separate cash work, up to10R from min(completion,balance), one pending release-paced offer, no cash/Promotion/Investment and no hidden perfect-Brief requirement at proposed R20. Partial, zero and cap outcomes, prospective migration and owner/publisher isolation are specified. P4 is accepted locally; old in-flight status is historical.87 constructed-arithmetic assertions and a fresh builder review pass; legal Brief accessibility is NOT RUN. Next: Brief-only private candidate with current-source legal unlock prefixes, balanced/completion/naive/skip and Pass-heavy evidence. Crown numerical terms/activation, commissions/support and migration selection remain OPEN; existing rewards and SideStreet ACTIVE/TRIAL authority unchanged. No canonical implementation queued.'
    note='**2026-10-25 Crown Brief/progression design refreshed — PROPOSED.** [Design](CROWN-BRIEFS-DESIGN-2026-10-25-v1.md) · [source/arithmetic findings](CROWN-BRIEFS-FINDINGS-2026-10-25-v1.md) · [handoff](CROWN-BRIEFS-HANDOFF-2026-10-25-v1.md). '+body+' Earlier proposed next questions below are historical.'
    receipts=[]
    for name in ['README.md','HANDOFF.md']:
        path=THREAD/name;before=path.read_bytes();m=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before);assert m and note.encode() not in before
        at=m.end();insert=note.encode()+m.group(1)*2;after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before and path.read_bytes()==before
        path.write_bytes(after);receipts.append({'path':str(path.relative_to(ROOT)),'before':digest(before),'after':digest(after),'unrelated_bytes_preserved':True})
    path=ROOT/'docs/codex/TODO.md';before=path.read_bytes();matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    m=matches[0];old=m.group();ending=old[len(old.rstrip(b'\r')):]
    entry='**Crown progression — Brief/progression DESIGN proposal refreshed; private accessibility study next,2026-10-25.** [Design](threads/contracts/CROWN-BRIEFS-DESIGN-2026-10-25-v1.md), [findings](threads/contracts/CROWN-BRIEFS-FINDINGS-2026-10-25-v1.md) and [proposed acceptance tasks](threads/contracts/CROWN-BRIEFS-HANDOFF-2026-10-25-v1.md). '+body+' Retain [parked CA1f](threads/contracts/CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md), [CA1b access witnesses](threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) and [QA/Core tradeoffs](threads/contracts/CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md). CP2 rewards remain held.'
    new=entry.encode()+ending;after=before[:m.start()]+new+before[m.end():]
    assert after[:m.start()]+old+after[m.start()+len(new):]==before
    (HERE/'todo-entry-before.txt').write_bytes(old);assert path.read_bytes()==before,'Concurrent TODO edit; stopped'
    path.write_bytes(after);receipts.append({'path':'docs/codex/TODO.md','before':digest(before),'after':digest(after),'changed_entries':1,'unrelated_bytes_preserved':True})
    save('documentation-update.json',receipts)
    def git(*args):
        p=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        return {'argv':['git',*args],'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    state={'branch':git('branch','--show-current'),'head':git('rev-parse','HEAD'),'status':git('status','--short','--untracked-files=no'),'diff':git('diff','--stat')}
    check=git('-c','core.safecrlf=false','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md');assert check['exit_code']==0,check
    scripts=[]
    for p in HERE.glob('*.py'):ast.parse(p.read_text(encoding='utf-8'));scripts.append(p.name)
    pins=json.loads((HERE/'source-pins.json').read_text());drift=[p for p,h in pins['files'].items() if p.startswith('patch-notes/') and digest((ROOT/p).read_bytes())!=h]
    log=f'''# Session — Crown Brief/progression design refresh

2026-10-25. User explicitly parked Beta redraw work and delegated Crown Brief/progression design. No gameplay implementation requested or performed. Used local authority, current source, historical source-pinned evidence and the brainstorming/design-thread workflow; no Drive needed.

Branch `{state['branch']['stdout'].strip()}`, HEAD `{state['head']['stdout'].strip()}`, dirty shared checkout. [Source/intake hashes](studies/crown-brief-design-20261025-v1/source-pins.json) and [closeout](studies/crown-brief-design-20261025-v1/closeout.json) record status/diff. Selected canonical source drift during this pass: {json.dumps(drift)}. Preserve concurrent work and `.codex-godot-temp`.

Created `CROWN-BRIEFS-DESIGN/FINDINGS/HANDOFF-2026-10-25-v1.md`, this log and `studies/crown-brief-design-20261025-v1/` plan/check/source/results/review/receipt files. Prepended one status paragraph to each Contracts README/HANDOFF. Re-read and replaced only the Crown TODO paragraph with a DESIGN pointer; [byte-preservation receipts](studies/crown-brief-design-20261025-v1/documentation-update.json). No other queue entries, shared design authority, gameplay/tests/assets/config, player saves, old evidence, commits/pushes or external chat messages edited.

## Checks and review

- Read current state/TODO first, branch/HEAD/status/diff, relevant publisher authority, prior Crown design and legal access findings, actual Contract/relationship/run/commission/support/browser source.
- Ran the exact installed-Python `check.py` command in [findings](CROWN-BRIEFS-FINDINGS-2026-10-25-v1.md): **PASS87** constructed arithmetic assertions, eight examples,17 spread values, seven constant-award opportunity sequences,12 cap examples. No gameplay seeds/state or simulator invocation. Existing formula retained; no failure/retry.
- Fresh skill-required builder review: no important unanswered design question blocks planning the Brief-only private prototype. Its requested explicit policies/bounds/rival-save stance are preserved in handoff acceptance. Reviewer made no edits and ran no gameplay.
- **PASS:** UTF-8 AST for{len(scripts)} local scripts; scoped diff check exit0; new-record link and post-write hash checks in closeout.
- **Retained inspection limitation:** Windows rg wildcard-path attempt failed; explicit source paths resolved inspection. No gameplay check failed or was rerun.
- **NOT RUN:** legal Crown Brief/full/partial-accessibility, headless variant, runtime regressions, migration, native/UI/export/human acceptance. Arithmetic and past unlock witnesses do not close these gates.

## Disposition

{body}

No blocker to completing the design packet. Useful legal grades/partial-route cost, numerical pilot approval and later adoption/migration authority remain genuine future gates. No additional user answer was needed for this delegated proposal; designer choices are labeled proposed.
'''
    session=THREAD/'SESSION-LOG-2026-10-25-crown-brief-design-v1.md'
    with session.open('x',encoding='utf-8') as f:f.write(log)
    docs=[THREAD/n for n in ['CROWN-BRIEFS-DESIGN-2026-10-25-v1.md','CROWN-BRIEFS-FINDINGS-2026-10-25-v1.md','CROWN-BRIEFS-HANDOFF-2026-10-25-v1.md',session.name]]
    links=[]
    for doc in docs:
        for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
            if target.startswith(('http:','https:','#')):continue
            p=doc.parent/target.split('#')[0];assert p.exists() or p==HERE/'closeout.json',(doc,target)
            links.append({'doc':doc.name,'target':target})
    for r in receipts:assert digest((ROOT/r['path']).read_bytes())==r['after'],'Document changed after write; inspect'
    save('closeout.json',{'status':'PASS','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git':state,'diff_check':check,'links':links,'post_edit_hashes_match':True,'ast_scripts':scripts,'selected_canonical_drift':drift,'records':{str(p.relative_to(ROOT)):digest(p.read_bytes()) for p in docs}})
    print(json.dumps({'status':'PASS','todo_entries_changed':1,'links_checked':len(links),'diff_check_exit':0,'selected_canonical_drift':drift}))
if __name__=='__main__':main()
