from setup import HERE, ROOT, write
import json, subprocess, re, hashlib, datetime
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    a=load(HERE/'analysis.json');s=load(HERE/'summary.json');v=load(HERE/'verification.json');m=load(HERE/'evidence-manifest.json')
    updates=load(HERE/'documentation-update.json');thread=HERE.parents[1]
    assert a['complete'] and s['complete'] and all(r['ok'] and r['commands']==r['accepted_commands'] for r in a['rows'])
    def git(*args):
        result=subprocess.run(['git',*args],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
        return {'args':['git',*args],'exit_code':result.returncode,'stdout':result.stdout,'stderr':result.stderr}
    state={'branch':git('branch','--show-current'),'head':git('rev-parse','HEAD'),'status':git('status','--short','--untracked-files=no'),'diff':git('diff','--stat')}
    check=git('-c','core.safecrlf=false','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md')
    assert check['exit_code']==0,check
    for item in updates:
        assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['after'], 'Shared document changed after our recorded edit; inspect before claiming byte check'
    total=sum(r['commands'] for r in a['rows'])
    log=f'''# Session log — Crown extra-hand utilization v1

2026-10-24. User: “Go ahead and cook,” accepting the CA1b completion-aware extra-hand experiment. Authorized private headless experiments, Contracts-owned documentation and a minimal TODO handoff. No GUI/computer control or canonical implementation.

## Source and changes

- Intake `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout with158 tracked changes. Closeout branch `{state['branch']['stdout'].strip()}`, HEAD `{state['head']['stdout'].strip()}`; [full status/diff receipt](studies/crown-extra-hand-20261024-v1/closeout.json).
- Read local current state/TODO/workflow and relevant Contracts findings, handoff and simulator usage/versioning. Used existing Contracts folder and created child variant `crown-extra-hand-v1`; protected baseline/ancestry preserved. Only inherited project delta is the legacy debug helper; candidate experiment changes external policy decisions only.
- Wrote predeclared plan, runner audit amendment, versioned findings/handoff, this log and the `studies/crown-extra-hand-20261024-v1/` policy/config/command/audit/report records. Large run/replay/cold bundles remain outside OneDrive in the declared Contracts evidence folder.
- Added one current-status paragraph to each owned README/HANDOFF and replaced exactly one existing Crown TODO paragraph after immediate reread and compare-before-write. [Receipt](studies/crown-extra-hand-20261024-v1/documentation-update.json) proves all unrelated bytes preserved at our edit. Other implementation/design entries retained.
- Concurrent canonical drift is recorded in [manifest](studies/crown-extra-hand-20261024-v1/evidence-manifest.json); this study retained its original source. Existing edits, `.codex-godot-temp` and player saves were not touched by this work. No canonical gameplay/tests/assets/config, shared design authority, commit or push was changed by this work.

## Exact work and checks

Full executable/argv records are linked in the [finding](CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md). Created child via `tools/simulator_variant.py create`; ran study `setup.py`, `run.py first`, then `run.py remaining`. Ran partial and final `analyze_all.py`, `run_verification.py`, `verify.py`, `diagnostics.py`, `write_findings.py`, `update_records.py`, and this `closeout.py`. Each simulation had unique folders,600-second execution bound and at most two concurrent runners; no seed/policy/run-bound changes after starts.

- **PASS:**12 cases/72 releases;{total:,} commands accepted, no observed arrears, rejected commands, incomplete cases or timeouts. No recovery rerun or failure reduction needed.
- **PASS:**{s['study_assertions']:,} study assertions +{s['extra_assertions']:,} extra-hand/control assertions, maintained source/input/telemetry checks, six paired exact initial states/RNG and six exact prior CA1 control trajectories.
- **PASS:**{s['extra_hand_accepted']} legal extra-hand attempts and frozen plan/policy hashes. No-exposure trajectories checked exactly.
- **RETAINED then resolved audit failure:** first three-batch aggregate hit `AssertionError: common runner`. Shared `.ico` allowlist addition produced two runner hashes. Byte-exact comparison shows that sole difference, with identical frozen mechanics/non-import source; explicit amendment accepts only those hashes. No runner identity is falsely described as identical; no runtime failure occurred.
- **PASS:** planned fresh-process extra-Simulation4522 replay,{v['replay_commands']} commands/{v['replay_telemetry_samples']} telemetry samples. Studio-only cold Continue restores exact state/RNG, completes{v['cold_commands']} commands to release7/cycle{v['cold_cycle']}.
- **PASS:** variant/base protection, only inherited helper delta,{len(m['files'])} artifact hashes. Log warnings and concurrent source drift retained in manifest; neither claimed fixed.
- **PASS:** scoped `git -c core.safecrlf=false -c core.whitespace=cr-at-eol diff --check` for TODO and owned indexes; exit0. New record links and post-edit hashes checked in closeout receipt.
- **NOT RUN:** GUI/native/export/human/device acceptance, broad balance/active-competitor pressure, default AI adoption, Crown relationship terms/migration acceptance.

## Outcome and next work

Crown access{s['arms']['control']['crown_unlocks']}/6→{s['arms']['extra']['crown_unlocks']}/6; full-Scope releases{s['arms']['control']['full_scope_releases']}/36→{s['arms']['extra']['full_scope_releases']}/36. Extra hands improve some reachable paths but do not solve remaining misses; adverse cash/pacing outcomes stay visible. Keep Review7/rewards unchanged. Next proposed DESIGN work separates visible-information Beta QA stopping for the Simulation route from Core-aware acquisition against the original Puzzle control. Simulation's full-Scope production7.142 release has6 remaining Bugs despite0 known at exit; the original Puzzle control has Sound9/13. Do not combine interventions or feed hidden Bugs into a policy. Source-audit and regenerate legal prefixes before working against newer canonical mechanics.

Crown relationship activation/terms and supported predecessor migration remain OPEN. SideStreet P2/P3/P4 remain accepted bounded ACTIVE/TRIAL; CP2 rewards held. No new user ruling is required to finish this experiment; separate authority/migration gates still block canonical Crown relationship adoption. No chat dispatch or release-readiness claim.
'''
    path=thread/'SESSION-LOG-2026-10-24-crown-extra-hand-v1.md'
    with path.open('x',encoding='utf-8') as f:f.write(log)
    links=[]
    docs=[thread/name for name in ['CROWN-EXTRA-HAND-PLAN-2026-10-24-v1.md','CROWN-EXTRA-HAND-AMENDMENT-2026-10-24-v1.md','CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md','CROWN-EXTRA-HAND-HANDOFF-2026-10-24-v1.md','SESSION-LOG-2026-10-24-crown-extra-hand-v1.md']]
    for doc in docs:
        for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
            if target.startswith(('https:','http:','#')):continue
            resolved=doc.parent/target.split('#')[0]
            assert resolved.exists() or resolved==HERE/'closeout.json',(doc,target)
            links.append({'doc':doc.name,'target':target})
    tools={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['tools/simulate.py','tools/compare_simulations.py','tools/simulator_variant.py']}
    write(HERE/'closeout.json',{'status':'PASS','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git':state,'diff_check':check,'post_edit_document_hashes_match':True,'new_record_links':links,'audit_tool_hashes_at_closeout':tools,'scope':'Completed bounded private evidence; DESIGN handoff only'})
    print(json.dumps({'status':'PASS','new_record_links':len(links),'diff_check_exit':check['exit_code'],'head':state['head']['stdout'].strip()}))

if __name__=='__main__':main()
