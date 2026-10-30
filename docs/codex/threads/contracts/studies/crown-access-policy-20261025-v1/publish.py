from run import *
from collections import Counter
def money(c):return f'${c/100:,.2f}'
def main():
    a=load(HERE/'analysis.json');rows=a['rows'];assert len(rows)==18 and len(a['controls'])==6 and len(a['prefix_checks'])==6
    before=load(HERE/'source-before.json');after=load(HERE/'source-after.json')
    assert before['canonical']==after['canonical'] and before['candidate']==after['candidate']
    selection=load(HERE/'verification-selection.json');verification={};hashes=load(HERE/'evidence-manifest.json')
    for typ,cid in [('replay',selection['success']),('replay',selection['failure']),('reduce',selection['failure'])]:
        if not cid:continue
        name=typ+'-'+cid;e=load(HERE/(name+'-exit.json'));assert e['exit_code']==0;verification[name]=e
        report=RAW/name/('replay-report.json' if typ=='replay' else 'reduction-run.json');assert load(report)['ok']
        for p in (RAW/name).rglob('*.json'):
            if any(part in ['project','profile','confirmation-profile'] for part in p.relative_to(RAW/name).parts):continue
            hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    cold=None
    if selection['success']:
        assert load(HERE/'cold-exit.json')['exit_code']==0
        s=next(r for r in rows if r['case']==selection['success']);prior=load(RAW/s['bundle']/'cases'/s['case']/'result.json');cold=load(RAW/'cold/cases/policy-cold/result.json')
        assert cold['status']=='completed' and cold['initial_state']==prior['final_state'] and cold['initial_rng']==prior['final_rng']
        verification['cold']=dict(status=cold['status'],commands=cold['commands'],initial_state_rng_exact=True,final_releases=cold['final_release_count'])
        for p in (RAW/'cold').rglob('*.json'):
            if any(part in ['project','profile'] for part in p.relative_to(RAW/'cold').parts):continue
            hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    preview=load(HERE/'preview-evidence.json');assert preview['status']=='PASS' and preview['checks']==24
    diagnostics=[]
    for genre in ['action','puzzle','simulation']:
        assert load(HERE/(genre+'-exit.json'))['exit_code']==1
        for name in ['import.log','experiment.log']:
            p=RAW/genre/name
            lines=[line for line in p.read_text(encoding='utf-8').splitlines() if line.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))]
            diagnostics.append(dict(file=str(p),messages=lines))
            assert not any(line.startswith(('ERROR:','SCRIPT ERROR:')) for line in lines),lines
    write(HERE/'verification.json',dict(checks=verification,source_unchanged=True,historical_controls_exact=6,paired_initial_groups=6,matched_prefixes=6,preview_assertions=24,engine_diagnostics=diagnostics))
    write(HERE/'verification-manifest.json',hashes)
    summary=[]
    for arm in ['control','exit','reserve']:
        rs=[r for r in rows if r['arm']==arm];cs=[r['access']['cycle'] for r in rs if r['access']]
        summary.append(dict(arm=arm,completed=sum(r['status']=='completed' for r in rs),access=sum(r['access'] is not None for r in rs),arrears=sum(r['max_overdue_cents']>0 for r in rs),cycles=cs))
    write(HERE/'summary.json',summary)
    table='\n'.join(f"| {r['case']} | {r['releases']} | {', '.join(str(x) for x in r['reviews'])} | {r['access']['cycle'] if r['access'] else 'Not reached'} | {money(r['minimum_cash_cents'])} | {money(r['max_overdue_cents'])} |" for r in rows)
    st='\n'.join(f"| {r['arm']} | {r['completed']}/6 | {r['access']}/6 | {r['arrears']}/6 | {', '.join(map(str,r['cycles'])) or 'None'} |" for r in summary)
    decisions=Counter(e['reason'] for e in a['exits'])
    text=f'''# Crown access: shorter production and selective Research v1

2026-10-25. **Completed bounded policy study; no gameplay adoption or balance approval.** User delegated the cheaper-access follow-up. Rewards unchanged; redraw research parked. [Preregistered methods](studies/crown-access-policy-20261025-v1/PLAN.md) · [review handoff](CROWN-ACCESS-POLICY-HANDOFF-2026-10-25-v1.md) · [paid-Search preview handoff v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md).

## Results

| Policy | Completed4 releases | Earned Crown access | Any arrears | First qualifying release cycles |
|---|---:|---:|---:|---|
{st}

All cases use six real paid SideStreet cash searches. The controls reproduce the previous failures exactly, including initial/final state and RNG. Shorter production can preserve runway and reach later releases; this study separates that policy change from reducing Research. Access means an actual released Review>=7, not a projected quality score. See every case below before generalizing.

## Source and exact method

Branch main; HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; dirty shared worktree preserved. Named owner contracts variant `crown-access-policy-20261025-v1` forks immutable `crown-search-access-20261025-v1`. Full canonical, parent and candidate source identity `{before['candidate_identity']}`; no runtime delta. [Full before/after source pins](studies/crown-access-policy-20261025-v1/source-before.json) match. External [policy](studies/crown-access-policy-20261025-v1/policy.gd) and [its exact hash/preregistered plan hash](studies/crown-access-policy-20261025-v1/pin.json) are separate research inputs. No old checkpoint identity was edited.

18 fresh legal recipes: Action/Puzzle/Simulation × seeds4417/4521 × control/exit/reserve. Six triples have exact initial state/RNG/source and roster-v3 fixture checks. All control/exit pairs also match at Game2 Begin; reserve shares an exactly verified state prefix until its declared Research choice changes. Game1 remains2/2/2. Six paid searches plus real Ironclad precede Game2; no Bank, employees, hidden future draws, Brief rewards or fabricated funds. Exact candidate commands and return codes are in `studies/crown-access-policy-20261025-v1/*-command.json` and `*-exit.json`.

Control: four legal purchases, Game2 10/10/12 hands, later6/6/6. Exit: same purchases/selection, bounded quality/cash-based phase exits. Reserve: same exit policy, at most two purchases with quoted acquisition cost leaving$6,000. The reserve and phase thresholds are research heuristics, not newly approved game rules or player restrictions. Design cap6; Alpha cap10; Beta cap6; minimums/quality/known-bug/cash triggers are fully declared in PLAN. Static Core quality proxy is not actual frozen-market Review and ignores hidden bugs/variance. Known bugs0 does not prove bug-free.

Each case stops at4 releases,420 commands, first rejection or timeout; each genre has a separate isolated runner/cache/profile and600sec import/run limit. Three run invocations return nonzero when retained controls reject; case-level reports distinguish those economic failures from process faults. No seeds or budgets were adjusted after outcomes. {a['accepted_commands']} accepted commands in the18 declared cases. Exit reasons: `{dict(decisions)}`.

## Complete result table

| Case | Releases | Reviews in release order | First Crown cycle | Minimum transaction cash | Maximum arrears |
|---|---:|---|---:|---:|---:|
{table}

[Analysis](studies/crown-access-policy-20261025-v1/analysis.json) retains final cash/cycles, purchases/actions, Game2 starting cash, rejection sample and every logged exit. [Evidence hashes](studies/crown-access-policy-20261025-v1/evidence-manifest.json). Raw complete sources/tapes/checkpoints/logs: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-access-policy-20261025-v1/`.

## Verification and limits

- PASS: six historical controls match exact initial/final state/RNG, counters and statuses; six three-arm initial matches and six shared-prefix checks;18 current-roster fixtures.
- PASS: fresh-process replay of `{selection['success']}` and `{selection['failure']}`, including telemetry and the original rejection. First failure reduced with500-command/240sec bounds and fresh confirmation. This reproduces an economic policy failure, not a repaired runtime bug.
- PASS: first successful non-control Studio Continue to one additional release, max100commands/240sec; exact checkpoint state/RNG preserved. [Receipts and coverage](studies/crown-access-policy-20261025-v1/verification.json).
- PASS: independent integer/card recomputation of12 previously recorded paid-Search hand projections and six settlements (24 assertions). These witnesses use the existing private Crown Search candidate, not this unchanged access baseline. [Preview evidence and explicit source](studies/crown-access-policy-20261025-v1/preview-evidence.json).
- NOT RUN here: graphical/native/export acceptance, human comprehension, broader seeds/specialties, actual new-policy post-unlock Brief campaigns, active-rival migration. No additional maintained runtime suite was needed for an external policy-only delta; previous runtime acceptance remains separately scoped.

Two seeds per specialty cannot establish universal accessibility. Release quality/cash/cycle changes are mediated by chosen hand counts, Research ownership, RNG consumption and calendar sales. Equal starting state does not promise identical later draws after policies diverge. All six reserve routes share65 exact telemetry samples with control, through the same first two purchases; they diverge at the third admission versus Begin. Thus the observed Research intervention is stopping at two purchases; the$6,000 filter never changes those first two selections and its independent benefit is NOT established. It reserves quoted acquisition costs only, excluding future rent/production/sales, so later cash can legally fall below$6,000. Design's quality trigger never fires: all36 Design exits hit the six-hand cap. The shorter policy combines fixed caps, six Alpha quality exits,20 known-clear Beta exits and30 cash-reserve exits; it does not isolate the benefit of quality awareness. The earlier18-search access result is historical context, not a paired estimate of twelve searches' causal cost in these new policies.
'''
    (THREAD/'CROWN-ACCESS-POLICY-FINDINGS-2026-10-25-v1.md').write_text(text,encoding='utf-8')
    print(json.dumps(summary));print(json.dumps(verification))
if __name__=='__main__':main()
