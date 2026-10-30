from run import *
from collections import Counter
def money(v):return f'${v/100:,.2f}'
def main():
    a=load(HERE/'analysis.json');rows=a['rows'];selection=load(HERE/'selection.json');winner=selection['selected'];ver=load(HERE/'verification-selection.json');receipts={}
    assert len(rows)==12 and len(a['historical_controls'])==2 and len(a['prefixes'])==8
    before=load(HERE/'source-before.json');after=load(HERE/'source-after.json');assert before['canonical']==after['canonical'] and before['candidate']==after['candidate']
    hashes=load(HERE/'evidence-manifest.json')
    for cid in ver['replays']:
        name='replay-'+cid;assert load(HERE/(name+'-exit.json'))['exit_code']==0
        r=load(RAW/name/'replay-report.json');assert r['ok'];receipts[name]=dict(ok=True,commands=len(r['steps']))
        for p in (RAW/name).rglob('*.json'):
            if any(x in ['project','profile'] for x in p.relative_to(RAW/name).parts):continue
            hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    if ver['reduction']:
        name='reduce-'+ver['reduction'];assert load(HERE/(name+'-exit.json'))['exit_code']==0;assert load(RAW/name/'reduction-run.json')['ok'];receipts[name]=True
    if ver['cold']:
        assert load(HERE/'cold-exit.json')['exit_code']==0
        row=next(r for r in rows if r['case']==ver['cold']);old=load(RAW/row['bundle']/'cases'/row['case']/'result.json');new=load(RAW/'cold/cases/puzzle-cold/result.json')
        assert new['status']=='completed' and new['initial_state']==old['final_state'] and new['initial_rng']==old['final_rng']
        receipts['cold']=dict(status='completed',commands=new['commands'],initial_state_rng_exact=True,releases=new['final_release_count'],excluded_from_access_comparison=True)
        for p in (RAW/'cold/cases/puzzle-cold').glob('*.json'):hashes[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    diagnostics=[]
    for bundle in ['discovery-4417','discovery-4521','confirmation']:
        for filename in ['import.log','experiment.log']:
            p=RAW/bundle/filename;lines=[s for s in p.read_text(encoding='utf-8').splitlines() if s.startswith(('ERROR:','SCRIPT ERROR:','WARNING:'))]
            assert not any(s.startswith(('ERROR:','SCRIPT ERROR:')) for s in lines);diagnostics.append(dict(file=str(p),messages=lines))
    write(HERE/'verification.json',dict(status='PASS',receipts=receipts,source_unchanged=True,exact_historical_controls=2,initial_state_groups=4,shared_prefix_checks=8,diagnostics=diagnostics))
    write(HERE/'verification-manifest.json',hashes)
    table='\n'.join(f"| {r['case']} | {', '.join(str(x) for x in r['reviews'])} | {r['access']['cycle'] if r['access'] else 'Not reached'} | {r['cycles']} | {money(r['cash_cents'])} | {money(r['minimum_cash_cents'])} |" for r in rows)
    ranks='\n'.join(f"| {r['arm']} | {r['successful_access']}/2 | {r['completed_no_arrears']}/2 | {r['cycle_sum']} | {money(r['minimum_cash_cents'])} |" for r in selection['ranking'])
    brief=[]
    for phase in ['discovery','confirmation']:
        for arm in (list(PAIRS) if phase=='discovery' else ['baseline',winner]):
            rs=[r for r in rows if r['bundle'].startswith(phase) and r['arm']==arm]
            brief.append(dict(stage=phase,arm=arm,n=len(rs),completed=sum(r['status']=='completed' for r in rs),access=sum(r['access'] is not None for r in rs),arrears=sum(r['max_overdue_cents']>0 for r in rs),access_cycles=[r['access']['cycle'] if r['access'] else None for r in rs]))
    write(HERE/'summary.json',brief)
    text=f'''# Puzzle Research and Crown access — findings v1

2026-10-25. **Bounded research; rewards, Review7 gate and canonical gameplay unchanged.** User requested Puzzle Research investigation. [Preregistered plan](studies/puzzle-research-20261025-v1/PLAN.md) · [review handoff](PUZZLE-RESEARCH-HANDOFF-2026-10-25-v1.md).

## Exact source and comparison

Branch main, HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f, shared dirty checkout retained. Named private variant `puzzle-research-20261025-v1` is an immutable-source child of `crown-access-policy-20261025-v1`; full parent/canonical/candidate identity `{before['candidate_identity']}`. **Zero runtime delta.** Only external research policy/configs and public-score logging differ. [Before pin](studies/puzzle-research-20261025-v1/source-before.json), [after pin](studies/puzzle-research-20261025-v1/source-after.json), [policy/plan hashes](studies/puzzle-research-20261025-v1/pin.json).

Four ordered two-Feature pairs: baseline8-bit Sound + General Combat; Music + General Combat;8-bit Sound + Sprites; Music + Sprites. Each selected card has Scope2 and actual quote$450; each completed pair costs$900, two Research actions and the same normal calendar costs at acquisition. No extra funding, synthetic ownership or prerequisite bypass. The research policy requires the existing$6,000 quoted post-acquisition reserve, but this is not an exact future-bills guarantee or a gameplay constraint.

Discovery uses the retained Puzzle4417/4521 recipes with current v3 roster and no traits, four arms each. Baselines exactly reproduce previous initial/final state/RNG, counters and outcomes. Four-arm starts match, and every arm shares the same full state prefix until its first changed purchase. Same real Ironclad/six paid cash searches, first game2/2/2, priorities15/10/30/45 and Beta50/25/25, visible selection and bounded exit policy. No redraw, Bank, employee, extra Research, reward, price, target, gate or phase-policy changes. Additional exit logs include only observable Cores.

Discovery ranking was fixed before runs: completed/arrears-free access count, then completed/arrears-free count, then earliest summed unlock cycles (non-access421), minimum cash, lexical name. Chosen alternative **{winner}**. Fresh confirmation compares it against baseline on predeclared seeds4418 and4522; those seeds were not replaced after seeing results. This selection is adaptive, and the confirmation is reported separately.

| Alternative | Discovery access | Completed/no arrears | Cycle score | Minimum cash across discovery |
|---|---:|---:|---:|---:|
{ranks}

Each case: four total releases,420 commands, first rejection/bound/timeout stops; three serial bundles,600sec import/run each. Fresh-process replays240sec each; cold Studio Continue100commands/240sec. The extra cold release is verification only, excluded from four-release access counts. Exact argv/exit files are alongside [run.py](studies/puzzle-research-20261025-v1/run.py); frozen bundles retain runner/Godot/import/experiment command manifests. No seed, budget or horizon was silently changed.

## All declared results

| Case | Reviews in order | First Crown cycle | Final cycle | Final cash | Minimum transaction cash |
|---|---|---:|---:|---:|---:|
{table}

{len(rows)} measured cases, {a['accepted_commands']} accepted commands. [Full analysis](studies/puzzle-research-20261025-v1/analysis.json) includes completed/rejected status, arrears, exact purchased IDs/costs/actions, paired-prefix checks and observable exit scores. [Selection/ranking](studies/puzzle-research-20261025-v1/selection.json). Raw complete bundles retained at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/puzzle-research-20261025-v1/`; [evidence hashes](studies/puzzle-research-20261025-v1/evidence-manifest.json).

## Verification and limits

- PASS: two exact historical baselines, four matched initial-state/RNG groups, eight exact shared-prefix checks,12 current-roster fixtures. Completed cases must actually purchase their exact two IDs, spend90000c and perform two Research actions/six Searches.
- PASS: fresh-process selected-alternative replay on4417 and4418, including exact telemetry. Fresh Studio Continue reaches a fifth release with exact initial state/RNG. [Receipts and retained diagnostics](studies/puzzle-research-20261025-v1/verification.json). Reduction is applicable only if a case rejects, not for a completed four-release campaign below Review7.
- Retained engine diagnostics include exit ObjectDB leak warnings; no ERROR/SCRIPT ERROR in the three import/experiment logs. These warnings were not repaired by this policy study.
- NOT RUN: native/UI/export/human acceptance, additional specialties, other card-selection/phase strategies, actual Crown Brief play from the earlier unlocks, later eras or mandatory shopping advice. Existing preview/migration/world/exposure gates remain separate.

Owned card totals are an explanation hypothesis, not realized hand totals. Changing a Feature changes the draw pool, exhaustion and subsequent RNG consumption; exact starting RNG does not mean identical later draws. The pair comparison includes phase placement and printed value together (Music7 Alpha versus8-bit Sound5 Design; Sprites7 Design versus General Combat5 Alpha), so it cannot isolate either stat strength or phase alone. It does not establish that the winning pair is globally optimal. Two discovery and two confirmation seeds are a bounded check; passing runs never approve balance or a mandatory purchase path. Retain the original four-purchase exit-only comparison as separately pinned historical context, not a newly run arm.
'''
    (THREAD/'PUZZLE-RESEARCH-FINDINGS-2026-10-25-v1.md').write_text(text,encoding='utf-8')
    print(json.dumps(brief));print(json.dumps(receipts))
if __name__=='__main__':main()
