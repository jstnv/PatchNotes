from setup import HERE,ROOT,RAW,write,sha
import json,re,hashlib,subprocess,datetime,ast
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
digest=lambda b:hashlib.sha256(b).hexdigest()

def main():
    s=load(HERE/'summary.json');a=load(HERE/'analysis.json');v=load(HERE/'verification.json');thread=HERE.parents[1]
    assert s['complete'] and all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in a['rows'])
    assert all(r['exact'] for r in v['replays']) and v['cold']['state_rng_exact']
    assert sum(r['commands'] for r in a['rows'])==788
    ast_checked=[]
    for path in HERE.glob('*.py'):
        ast.parse(path.read_text(encoding='utf-8'),filename=str(path));ast_checked.append(path.name)
    body='Four cases complete 24 releases/788 accepted commands with no observed arrears. Reserved Beta redraws find Search in 3/7 attempts; mean Bugs 1.75→1.50 and Review 5.417→5.467, but Crown access stays 0/2 in both arms. Seed4522 finishes +1 cycle/-$360.15;4521 +2 cycles/+$667.82. Do not adopt blanket reservation. Proposed next DESIGN test: Search-aware first-hand timing with unchanged total redraw/QA budgets, purchases, Review7 and rewards. Exact replay, cold Studio state/RNG and policy/source audits pass. Neutral-market evidence only; no canonical/default-AI adoption. Crown relationship terms/activation/migration remain OPEN; CP2 rewards held; SideStreet trial authority unchanged.'
    note='**2026-10-24 Crown CA1e reserved Beta redraw — COMPLETE bounded privately.** [Findings](CROWN-BETA-REDRAW-FINDINGS-2026-10-24-v1.md) · [design handoff](CROWN-BETA-REDRAW-HANDOFF-2026-10-24-v1.md). '+body+' Earlier next-question labels below are historical; prior QA/Core evidence remains valid at its recorded source.'
    receipts=[]
    for name in ['README.md','HANDOFF.md']:
        path=thread/name;before=path.read_bytes();match=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before)
        assert match and note.encode() not in before
        insert=note.encode()+match.group(1)*2;at=match.end();after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before and path.read_bytes()==before
        path.write_bytes(after);assert path.read_bytes()==after
        receipts.append({'path':str(path.relative_to(ROOT)),'before':digest(before),'after':digest(after),'unrelated_bytes_preserved':True})
    path=ROOT/'docs/codex/TODO.md';before=path.read_bytes()
    matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    match=matches[0];old=match.group();ending=old[len(old.rstrip(b'\r')):]
    text='**Crown progression — CA1e reserved Beta redraw COMPLETE bounded privately; first-hand Search timing DESIGN review needed,2026-10-24.** [Four-case findings](threads/contracts/CROWN-BETA-REDRAW-FINDINGS-2026-10-24-v1.md) and [proposed next tasks](threads/contracts/CROWN-BETA-REDRAW-HANDOFF-2026-10-24-v1.md). '+body+' [Prior QA/Core evidence](threads/contracts/CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md) retains the automatic-QA miss and optional Music/Sound Effects tradeoffs; [CA1b](threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) retains earlier access witnesses. No canonical implementation queued.'
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
    diff=git('-c','core.safecrlf=false','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md')
    assert diff['exit_code']==0,diff
    for item in receipts:assert sha(ROOT/item['path'])==item['after'],'Document changed since recorded edit; inspect'
    log=f'''# Session log — Crown reserved Beta redraw CA1e v1

2026-10-24. User approved reserving the Beta redraw when Search is missing, with rewards unchanged. Scope: bounded private policy experiment, thread evidence/handoff and authorized minimal Crown TODO update.

Read current state/TODO, publisher authority, prior QA/Core findings/handoff and policy, logging/versioning/isolated-run guidance. Intake/closeout on `{state['branch']['stdout'].strip()}`, HEAD `{state['head']['stdout'].strip()}`, shared dirty checkout. [Intake](studies/crown-beta-redraw-20261024-v1/intake.json) and [closeout](studies/crown-beta-redraw-20261024-v1/closeout.json) retain status/diff.

## Files and isolation

Created versioned plan, finding, handoff, this session log, `studies/crown-beta-redraw-20261024-v1/`, failed capture `simulators/crown-beta-redraw-v1/` and successful fresh `simulators/crown-beta-redraw-v2/`. Protected baseline `4e5fba8f4b76f677bd5e32d502cca383bc132c801a93bafa0544a7a89eda1a4f`; only private project addition is existing legacy helper. External policy changes Beta redraw timing; source/state/RNG identity guards remain intact. Source delta from prior study and later canonical drift are recorded.

Large evidence root: `{RAW.as_posix()}`. README/HANDOFF each receive one latest-status paragraph; only the existing Crown TODO paragraph changes after immediate reread/CAS. [Byte-preservation receipts](studies/crown-beta-redraw-20261024-v1/documentation-update.json). Existing edits and `.codex-godot-temp` preserved. No canonical gameplay/tests/assets/config, player saves, shared design authority, GUI, commit/push or chat dispatch changed by this work.

## Commands and actual outcomes

Exact executable argv and all source hashes are linked in [findings](CROWN-BETA-REDRAW-FINDINGS-2026-10-24-v1.md). Sequence: variant createv1 (failed), createv2 (passed), setup, first pair, initial analysis/audit, second pair and representative verification (at most two runners), final analysis/audit/summary/verification, write findings and publish. Each run/replay uses isolated runner/new output/profile/cache and600-second import/execution limits; four cases each six releases/320commands. Cold Continue is one extra release/80commands. No policy, seed or budget retuning after outcomes.

- **PASS:**4 cases/24 releases/788 accepted commands; no runtime rejected/incomplete/timed-out cases or observed arrears.
- **PASS:**1,586 study +3,368 policy assertions, exact initial state/RNG pairs, deterministic discard/guard/resource checks and actual QA exposure.
- **PASS:** independent-process197-command/198-sample exact replay; Studio-only cold Continue exact state/RNG and35 commands to release7/c114.
- **PASS:** protected baseline/plan/policy; only helper project delta;133 raw artifact hashes.
- **RETAINED:** source capturev1 rejected a concurrent `rival_world_checkpoint.gd` change; source was freshly recaptured tov2. Three shutdown-log occurrences of six leaked ObjectDB instances. An inspection-only Windows rg glob error was replaced with direct-file reads. No gameplay failure needed reduction.
- **PASS:** explicit UTF-8 AST parsing of {len(ast_checked)} study scripts, scoped git diff check exit0, new-record link validation and post-edit hashes in closeout.
- **NOT RUN:** GUI/native/export/human/device acceptance, active-rival pressure, broad balance or canonical relationship activation/migration. All24 study releases are neutral-market/zero-recent-competitor.

## Recommendation and follow-up

{body}

No execution blocker remains. The next first-hand policy is proposed and needs a predeclared experiment; no canonical implementation task is requested. Prior QA/Core and faster CA1b access evidence remains linked. Findings do not approve balance or release readiness.
'''
    session=thread/'SESSION-LOG-2026-10-24-crown-beta-redraw-v1.md'
    with session.open('x',encoding='utf-8') as f:f.write(log)
    links=[]
    for doc in [thread/name for name in ['CROWN-BETA-REDRAW-PLAN-2026-10-24-v1.md','CROWN-BETA-REDRAW-FINDINGS-2026-10-24-v1.md','CROWN-BETA-REDRAW-HANDOFF-2026-10-24-v1.md',session.name]]:
        for target in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
            if target.startswith(('https:','http:','#')):continue
            resolved=doc.parent/target.split('#')[0]
            assert resolved.exists() or resolved==HERE/'closeout.json',(doc,target)
            links.append({'doc':doc.name,'target':target})
    write(HERE/'closeout.json',{'status':'PASS','at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'git':state,'diff_check':diff,'new_record_links':links,'post_edit_hashes_match':True,'utf8_ast_checks':ast_checked,'audit_tools':{p:sha(ROOT/p) for p in ['tools/simulate.py','tools/compare_simulations.py','tools/simulator_variant.py']}})
    print(json.dumps({'status':'PASS','todo_entries_changed':1,'links':len(links),'ast_scripts':len(ast_checked),'diff_check_exit':0}))

if __name__=='__main__':main()
