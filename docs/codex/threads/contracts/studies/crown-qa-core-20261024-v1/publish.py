from setup import HERE, ROOT, RAW, write, sha
import json,re,hashlib,subprocess,datetime
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
digest=lambda b:hashlib.sha256(b).hexdigest()

def main():
    s=load(HERE/'summary.json');a=load(HERE/'analysis.json');v=load(HERE/'verification.json');m=load(HERE/'evidence-manifest.json');thread=HERE.parents[1]
    assert s['complete'] and all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in a['rows'])
    assert len(v['replays'])==2 and all(r['exact'] for r in v['replays']) and v['cold']['state_rng_exact']
    assert (thread/'CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md').exists()
    body='Eight current-source cases complete48 releases/1,526 accepted commands with no observed arrears. Automatic QA extension reduces mean Bugs but lowers Simulation Crown access1/2→0/2; do not adopt it. Optional Core purchasing raises Puzzle access1/2→2/2: Music supplies a new Game6 witness, while Sound Effects delays an already-successful route one cycle and leaves$698.12 less cash. Keep both outcomes and variance dependence visible. Next proposed DESIGN test moves the existing one-card Beta redraw allowance to a visible Search-starved exit, with unchanged total redraw/extension budgets, purchases, Review7 and rewards. Two exact replays, cold Studio state/RNG and policy/source audits pass. Neutral-market evidence only; no gameplay/default-AI adoption. Crown relationship terms/activation/migration remain OPEN; CP2 rewards held; SideStreet trial authority unchanged.'
    note='**2026-10-24 Crown QA/Core follow-up — CA1c/CA1d COMPLETE bounded privately.** [Findings](CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md) · [proposed handoff](CROWN-QA-CORE-HANDOFF-2026-10-24-v1.md). '+body+' Older next-question labels below are historical.'
    receipts=[]
    for name in ['README.md','HANDOFF.md']:
        path=thread/name;before=path.read_bytes();match=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before);assert match and note.encode() not in before
        insert=note.encode()+match.group(1)*2;at=match.end();after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before and path.read_bytes()==before
        path.write_bytes(after);assert path.read_bytes()==after
        receipts.append({'path':str(path.relative_to(ROOT)),'before':digest(before),'after':digest(after),'unrelated_bytes_preserved':True})
    path=ROOT/'docs/codex/TODO.md';before=path.read_bytes()
    matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    match=matches[0];old=match.group();ending=old[len(old.rstrip(b'\r')):]
    text='**Crown progression — CA1c/CA1d COMPLETE bounded privately; reserved Beta redraw timing DESIGN review needed,2026-10-24.** [Eight-case QA/Core findings](threads/contracts/CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md) and [proposed acceptance tasks](threads/contracts/CROWN-QA-CORE-HANDOFF-2026-10-24-v1.md). '+body+' No canonical implementation queued by this study. [CA1b evidence](threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) retains the prior route comparisons.'
    new=text.encode()+ending;after=before[:match.start()]+new+before[match.end():]
    assert after[:match.start()]+old+after[match.start()+len(new):]==before
    (HERE/'todo-entry-before.txt').write_bytes(old)
    assert path.read_bytes()==before,'Concurrent TODO edit; stopped before write'
    path.write_bytes(after);assert path.read_bytes()==after
    receipts.append({'path':'docs/codex/TODO.md','before':digest(before),'after':digest(after),'changed_entries':1,'unrelated_bytes_preserved':True})
    write(HERE/'documentation-update.json',receipts)
    def git(*args):
        result=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        return {'args':['git',*args],'exit_code':result.returncode,'stdout':result.stdout,'stderr':result.stderr}
    state={'branch':git('branch','--show-current'),'head':git('rev-parse','HEAD'),'status':git('status','--short','--untracked-files=no'),'diff':git('diff','--stat')}
    check=git('-c','core.safecrlf=false','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md');assert check['exit_code']==0,check
    for item in receipts:assert sha(ROOT/item['path'])==item['after'],'Document changed after recorded edit; inspect before closing'
    log=f'''# Session log — Crown QA/Core independent comparisons v1

2026-10-24. User “Go for it” approved the two follow-ups after CA1b. Scope: private headless experiment policies, thread-owned records and minimal authorized TODO update. No computer control or canonical gameplay implementation.

## Source and files

Read current state/TODO, publisher authority, prior CA1b findings/handoff, local logging conventions and simulator usage/versioning. Intake and closeout branch `{state['branch']['stdout'].strip()}`, HEAD `{state['head']['stdout'].strip()}`, dirty shared checkout. Current-source variant `crown-qa-core-v1`, baseline `99cef068ed691d23768fffa4143b1b8e6187a87cd61ccba5732585868e85d672`; only private project addition is the existing legacy debug helper. Old study records/archives/checkpoint identities are preserved. Source drift from CA1b and any later canonical drift are recorded, never silently rebased.

Wrote the predeclared plan, `studies/crown-qa-core-20261024-v1/` policy/config/source/command/audit/report files, findings, proposed handoff, this log, and new simulator version. Large immutable evidence is at `{RAW.as_posix()}`. README/HANDOFF each receive one latest-status paragraph. Exactly one existing Crown TODO paragraph is replaced after immediate reread/concurrency check; [byte-preservation receipt](studies/crown-qa-core-20261024-v1/documentation-update.json). All other shared queue entries preserved at this edit.

No canonical gameplay/tests/assets/config, shared design authority, player saves, `.codex-godot-temp`, commits or pushes changed by this work. Source/branch/status/diff and tool hashes are captured in [closeout](studies/crown-qa-core-20261024-v1/closeout.json).

## Commands and results

Full executable paths/argv are linked in [findings](CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md). Ran variant create, `setup.py`, `prepare_analysis.py`, `run.py first`, initial `analyze_all.py`, then `run.py remaining`, partial/final `analyze_all.py`, `run_verification.py`, `diagnostics.py`, `verify.py`, `write_findings.py`, `publish.py`. Each case is a fresh legal recipe,6-release/320-command cap; each runner600seconds, at most two concurrent runners, new output/cache/profile every time. Policy and seeds never retuned after outcomes.

- **PASS:**8 cases,48 releases,1,526 commands accepted, no observed arrears, rejected/incomplete/timed-out cases. No retries or failure reduction required.
- **PASS:**{s['study_checks']} study assertions +{s['policy_checks']} policy guard/exposure checks, maintained input/source/telemetry validation and four exact initial state/RNG pairs.
- **PASS:** two independent-process replays: {', '.join(r['case']+' '+str(r['commands'])+' commands/'+str(r['samples'])+' samples' for r in v['replays'])}.
- **PASS:** Studio-only QA cold Continue preserves exact final state/RNG, then{v['cold']['commands']} commands to release7/cycle{v['cold']['cycle']}. Policy-local instance counters are not a general persisted-state guarantee.
- **PASS:** protected baseline/variant, unchanged policy/plan hashes, only helper project delta;{len(m['files'])} raw evidence hashes. Retained shutdown warnings are not claimed fixed.
- **CORRECTED tooling checks:** one unmatched parenthesis in verification writer was caught and corrected before that writer ran; a later AST-check command failed because Windows default cp1252 could not decode UTF-8 source, then passed with explicit UTF-8. [Retained check failures](studies/crown-qa-core-20261024-v1/tooling-checks.json). No policy/inputs/run outcomes changed; no runtime policy failure occurred.
- **PASS:** scoped `git -c core.safecrlf=false -c core.whitespace=cr-at-eol diff --check`, exit0; new-document links and post-edit hashes checked in closeout receipt.
- **NOT RUN:** GUI/native/export/human/device acceptance, broad balance, active-rival pressure, relationship adoption/migration. All48 releases have neutral-market/zero-recent-competitor observations despite updated rival code being present in source.

## Recommendation and remaining work

{body}

No user ruling is required to finish this bounded study. The next redraw-timing policy remains a proposed experiment, and canonical Crown relationships still need separate terms/activation and supported migration authority. No chat dispatch or release-readiness claim.
'''
    path=thread/'SESSION-LOG-2026-10-24-crown-qa-core-v1.md'
    with path.open('x',encoding='utf-8') as f:f.write(log)
    links=[]
    docs=[thread/name for name in ['CROWN-QA-CORE-PLAN-2026-10-24-v1.md','CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md','CROWN-QA-CORE-HANDOFF-2026-10-24-v1.md','SESSION-LOG-2026-10-24-crown-qa-core-v1.md']]+[HERE/'recommendation.md']
    for doc in docs:
        for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
            if target.startswith(('https:','http:','#')):continue
            resolved=doc.parent/target.split('#')[0]
            assert resolved.exists() or resolved==HERE/'closeout.json',(doc,target)
            links.append({'doc':doc.name,'target':target})
    write(HERE/'closeout.json',{'status':'PASS','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git':state,'diff_check':check,'new_record_links':links,'post_edit_hashes_match':True,'audit_tools':{p:sha(ROOT/p) for p in ['tools/simulate.py','tools/compare_simulations.py','tools/simulator_variant.py']}})
    print(json.dumps({'status':'PASS','changed_todo_entries':1,'links':len(links),'diff_check_exit':0,'head':state['head']['stdout'].strip()}))

if __name__=='__main__':main()
