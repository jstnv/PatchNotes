from setup import HERE,ROOT,RAW,write,sha
import json,re,hashlib,subprocess,datetime,ast
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
digest=lambda b:hashlib.sha256(b).hexdigest()
def main():
    facts=load(HERE/'record-facts.json');rec=load(HERE/'recommendation.json');a=load(HERE/'analysis.json');v=load(HERE/'verification.json');thread=HERE.parents[1]
    assert a['complete'] and len(a['rows'])==6 and all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in a['rows'])
    assert v['cold']['state_rng_exact'] and all(r['exact'] for r in v['replays'])
    scripts=[]
    for path in HERE.glob('*.py'):ast.parse(path.read_text(encoding='utf-8'),filename=str(path));scripts.append(path.name)
    body=rec['queue_body']
    note='**2026-10-24 Crown CA1f first-hand Beta redraw — COMPLETE bounded privately.** [Findings](CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md) · [design handoff](CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md). '+body+' Earlier next-test labels below are historical; prior source-pinned findings remain retained.'
    receipts=[]
    for name in ['README.md','HANDOFF.md']:
        path=thread/name;before=path.read_bytes();match=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before);assert match and note.encode() not in before
        at=match.end();insert=note.encode()+match.group(1)*2;after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before and path.read_bytes()==before
        path.write_bytes(after);assert path.read_bytes()==after
        receipts.append({'path':str(path.relative_to(ROOT)),'before':digest(before),'after':digest(after),'unrelated_bytes_preserved':True})
    path=ROOT/'docs/codex/TODO.md';before=path.read_bytes()
    matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    match=matches[0];old=match.group();ending=old[len(old.rstrip(b'\r')):]
    text='**Crown progression — CA1f first-hand Beta redraw COMPLETE privately; Crown Brief/progression DESIGN review next,2026-10-24.** [Six-case findings](threads/contracts/CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md) and [proposed handoff](threads/contracts/CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md). '+body+' [CA1e timing](threads/contracts/CROWN-BETA-REDRAW-FINDINGS-2026-10-24-v1.md), [QA/Core tradeoffs](threads/contracts/CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md) and [CA1b access witnesses](threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) remain evidence; no canonical implementation queued.'
    new=text.encode()+ending;after=before[:match.start()]+new+before[match.end():]
    assert after[:match.start()]+old+after[match.start()+len(new):]==before
    (HERE/'todo-entry-before.txt').write_bytes(old)
    assert path.read_bytes()==before,'Concurrent TODO edit; stopped before write'
    path.write_bytes(after);assert path.read_bytes()==after
    receipts.append({'path':'docs/codex/TODO.md','before':digest(before),'after':digest(after),'changed_entries':1,'unrelated_bytes_preserved':True})
    write(HERE/'documentation-update.json',receipts)
    def git(*args):
        p=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        return {'args':['git',*args],'exit_code':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    state={'branch':git('branch','--show-current'),'head':git('rev-parse','HEAD'),'status':git('status','--short','--untracked-files=no'),'diff':git('diff','--stat')}
    diff=git('-c','core.safecrlf=false','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md');assert diff['exit_code']==0,diff
    for item in receipts:assert sha(ROOT/item['path'])==item['after'],'Concurrent document edit after recorded write; inspect'
    session=thread/'SESSION-LOG-2026-10-24-crown-first-beta-v1.md'
    log=f'''# Session log — Crown first-hand Beta redraw CA1f v1

2026-10-24. User approved the first-hand Beta redraw test with rewards unchanged. Authorized scope: private isolated experiment, thread evidence/handoff and minimal existing Crown DESIGN TODO update.

## Intake, source and changed files

Read current state/TODO, CA1e findings/handoff, policy and prior audits; retained repository logging/simulator usage and versioning boundaries. Intake/closeout `{state['branch']['stdout'].strip()}`, HEAD `{state['head']['stdout'].strip()}`, shared dirty checkout. [Intake](studies/crown-first-beta-20261024-v1/intake.json) and [closeout](studies/crown-first-beta-20261024-v1/closeout.json) preserve status/diff.

Created `CROWN-FIRST-BETA-PLAN/FINDINGS/HANDOFF-2026-10-24-v1.md`, this log, `studies/crown-first-beta-20261024-v1/`, and fresh `simulators/crown-first-beta-v1/`. Baseline `3a657520108df3a42efca0abf7347c43a3068bf6e47074016772072b1c1483d3`; only private project addition is existing legacy helper. New external policy adds the predeclared first-hand timing flag. Prior variants/archives/evidence remain intact. Raw evidence: `{RAW.as_posix()}`.

README/HANDOFF each receive one current-status paragraph; one Crown TODO paragraph changes after immediate reread/CAS. [Byte-preservation receipts](studies/crown-first-beta-20261024-v1/documentation-update.json) prove unrelated entries preserved at this edit. No canonical gameplay/tests/assets/config, shared design authority, player saves, `.codex-godot-temp`, GUI, commit/push or chat dispatch changed by this work.

## Exact work and checks

[Findings](CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md) link exact create/run/replay/Continue argv and all source hashes. Sequence: create; setup; prepare checks; first triple; first analyze/audit/summary; second triple alongside representative replay/Continue; final analyze/audit/summary/control continuity; verify; records and publish. At most two runners, new isolated output/cache/profile per invocation,600-second import/execution limit. Six fresh legal recipes, six releases/320commands each; cold continuation one extra release/80commands. No policy/seed/budget retuning.

- **PASS:**{facts['cases']} cases/{facts['releases']} releases/{facts['commands']} accepted commands; no runtime rejection/incomplete/timeout or observed arrears.
- **PASS:**{facts['study_checks']} study +{facts['policy_checks']} independent policy assertions; four same-state/RNG pair reports, exact trigger/tie/resource/cap and exposure checks.
- **PASS:** all four controls exactly reproduce prior initial/final state/RNG, commands, final cycle and outcomes on compatible mechanics; fresh runs were still performed.
- **PASS:** candidate4522 exact{v['replays'][0]['commands']}-command/{v['replays'][0]['samples']}-sample replay; cold Studio Continue exact state/RNG then{v['cold']['commands']} commands to release7/c{v['cold']['cycle']}.
- **PASS:** protected baseline/plan/policy and helper-only delta;{facts['evidence_hashes']} evidence hashes. Three shutdown warning occurrences retain six leaked ObjectDB instances; not fixed.
- **RETAINED/CORRECTED tooling:** progress helper initially interpreted the initial report placeholder as final; an early driver-log read found no file. One premature verifier invocation failed on still-partial analysis; waited for analysis completion and reran the unchanged verifier successfully. [Record](studies/crown-first-beta-20261024-v1/tooling-checks.json). No simulation retry, policy/input or assertion change.
- **PASS:** UTF-8 AST of{len(scripts)} study scripts; scoped git diff check exit0; new-document links and post-edit hashes checked.
- **NOT RUN:** graphical/native/export/human/device, active-rival pressure, broad balance, canonical Crown activation or migration. All36 study releases are neutral-market/zero-recent-competitor; no gameplay rejection required failure reduction.

## Disposition

{body}

No execution blocker remains. Next design work is proposed, with no canonical adoption queued. Future terms/activation require separate authority and source reconciliation.
'''
    with session.open('x',encoding='utf-8') as f:f.write(log)
    links=[]
    for doc in [thread/name for name in ['CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md','CROWN-FIRST-BETA-FINDINGS-2026-10-24-v1.md','CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md',session.name]]:
        for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
            if target.startswith(('http:','https:','#')):continue
            resolved=doc.parent/target.split('#')[0];assert resolved.exists() or resolved==HERE/'closeout.json',(doc,target)
            links.append({'doc':doc.name,'target':target})
    write(HERE/'closeout.json',{'status':'PASS','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git':state,'diff_check':diff,'new_record_links':links,'post_edit_hashes_match':True,'utf8_ast_checks':scripts,'audit_tools':{p:sha(ROOT/p) for p in ['tools/simulate.py','tools/compare_simulations.py','tools/simulator_variant.py']}})
    print(json.dumps({'status':'PASS','todo_entries_changed':1,'links':len(links),'ast_scripts':len(scripts),'diff_check_exit':0}))
if __name__=='__main__':main()
