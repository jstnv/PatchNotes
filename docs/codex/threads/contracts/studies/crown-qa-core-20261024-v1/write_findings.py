from setup import HERE, RAW, write
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
money=lambda n:('-' if int(n)<0 else '')+f'${abs(int(n))/100:,.2f}'
LINK='studies/crown-qa-core-20261024-v1/'

def main():
    a=load(HERE/'analysis.json');s=load(HERE/'summary.json');p=load(HERE/'policy-audit.json');v=load(HERE/'verification.json');m=load(HERE/'evidence-manifest.json');pins=load(HERE/'source-pins.json')
    assert a['complete'] and len(a['rows'])==8 and all(r['ok'] and r['commands']==r['accepted_commands'] for r in a['rows'])
    recommendation=(HERE/'recommendation.md').read_text(encoding='utf-8').replace('(diagnostics.json)','('+LINK+'diagnostics.json)')
    outcomes=[];calendar=[];details=[];experiments=[]
    for exp in ['qa','core']:
        c=s['experiments'][exp]['control'];t=s['experiments'][exp]['candidate']
        experiments.append(f"| {exp} | {c['unlocked']}/2 → {t['unlocked']}/2 | {c['mean_review']:.3f} → {t['mean_review']:.3f} | {c['mean_bugs']:.3f} → {t['mean_bugs']:.3f} | {c['full_scope']}/12 → {t['full_scope']}/12 |")
    for pair in a['pairs']:
        rows=[next(r for r in a['rows'] if r['pair']==pair['pair'] and r['arm']==arm) for arm in ['control','candidate']]
        access=lambda r:f"G{r['first_qualifying_release']}/cycle{r['first_qualifying_cycle']}" if r['first_qualifying_release'] else 'none by G6'
        c,t=rows
        outcomes.append(f"| {pair['pair']} | {access(c)} | {access(t)} | {c['cycle']} → {t['cycle']} | {money(c['cash_cents'])} → {money(t['cash_cents'])} |")
        for row in rows:
            details.append(f"| {row['case']} | {', '.join(map(str,row['reviews']))} | {', '.join(str(q['scope']) for q in row['review_details'])} | {', '.join(str(q['remaining_bugs']) for q in row['review_details'])} |")
        q=pair['calendar'][-1];delta=q['delta_right_minus_left']
        calendar.append(f"| {pair['pair']} | {q['run_cycle']} | {money(delta['cash_cents'])} | {delta['release_count']} |")
    purchases=[]
    for event in p['core_purchases']:
        b=event['basis'];q=event['quote'];names=['Graphics','Sound','Technology','Design']
        purchases.append(f"- `{event['case']}`: after Game{event['after_release']}, cycle{event['cycle']}, buys **{b['feature_id']}** for weak {names[b['weakest']]} ({b['review']['cores'][b['weakest']]}/{b['review']['standards'][b['weakest']]}). Quoted down+remaining {money(int(q['down_cents'])+int(q['remaining_cents']))}, expense including Research-rent screen {money(b['expense'])}; cash before {money(event['cash_before'])}. Research completed: {event['research_completed']}; drawn releases {event['drawn_releases']}; played releases {[x['release'] for x in event['played_releases']]}. Exact quote and rational rank are retained.")
    qa=p['qa_extensions'];zero=sum(e['discovered']==0 and e['fixed']==0 for e in qa)
    warnings='\n'.join(f'- {count} log occurrences: ``{message}``. Not claimed fixed.' for message,count in m['warnings'].items()) or '- No retained warning/error prefixes.'
    drift='\n'.join('- `'+item['path']+'` ('+item['change']+')' for item in m['canonical_drift']) or '- No canonical drift from this study baseline observed at the evidence audit.'
    sourcechanges='\n'.join('- `'+item['path']+'` ('+item['change']+')' for item in pins['from_ca1b_baseline'])
    replays='\n'.join(f"- **PASS:** {r['case']} independent-process replay, {r['commands']} commands/{r['samples']} exact telemetry samples." for r in v['replays'])
    commands='\n'.join(f"- [{p['pair']} command]({LINK}{p['pair']}-command.json) · [config]({LINK}{p['pair']}.json) · [comparison]({LINK}{p['pair']}-comparison.md)." for p in a['pairs'])
    neutral=all(q['market']['snapshot_id']=='market-0-neutral' and q['market']['recent_count']==0 for r in a['rows'] for q in r['review_details'])
    text=f'''# Crown QA and Core acquisition — findings v1

2026-10-24. **COMPLETE bounded private evidence; DESIGN review, no gameplay/balance adoption.**

## Recommendation

{recommendation}

## Authority, source and setup

User “Go for it” authorized the two separate investigations after CA1b. [Predeclared plan](CROWN-QA-CORE-PLAN-2026-10-24-v1.md), [handoff](CROWN-QA-CORE-HANDOFF-2026-10-24-v1.md), [intake]({LINK}intake.json), [source pins]({LINK}source-pins.json), [policy delta]({LINK}policy.diff).

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout. Current-source Contracts variant `crown-qa-core-v1`: baseline `{pins['variant']['base_identity']}`, candidate project `{pins['candidate_identity']}`. Actual common mechanics `{a['identities'][0]['source']}`, Godot `{a['identities'][0]['godot']}`, runner `{a['identities'][0]['runner']}`, external policy `{pins['policy_sha256']}`. Original baseline/archive/metadata remain protected. Only private project addition is the pre-existing debug helper `scripts/debug/crown_access_legacy_v1.gd`; no gameplay rule changes. External policy decisions are the experiment.

Current baseline includes canonical changes since CA1b; fresh legal prefixes were regenerated. Old checkpoints were not reused or relabeled. The recorded baseline differences are:

{sourcechanges}

Eight declared fresh campaigns, seeds4521/4522: Simulation control/QA and Puzzle control/Core; no Traits/employees. Each has six releases/320 commands;600-second runner execution bounds, at most two concurrent isolated runners, new outputs/profiles/caches. First QA Simulation4522 pair was audited before remaining cases. All four pairs share exact initial state/RNG and common mechanics/runtime/runner/policy/non-import inputs. Historical numerical comparisons are not cross-source parity claims.

## Independent policies

QA holds CA1b acquisition and Design/Alpha extra-hand policy fixed. When ordinary Beta play would exit, candidate can make up to two further affordable four-card QA hands, reserving four current monthly rents. Prefer a combination containing both visible Search for Bugs and Debug; if only Search is available require Search, or require Debug only when known Bugs>0. Rank eligible combinations using unchanged Beta scoring. No hidden Bug/RNG reads, extra redraws or Host Playtest. The latter supplies corrective Core passes, not Bug search. Extensions may carry Marketing or alter later draws, so measure the whole policy effect.

Core holds original CA1 production/QA/redraws fixed, without Design/Alpha extensions. Ordinary below-Scope30 acquisition is unchanged. At owned Scope>=30 and most recent actual Review<7, candidate may complete one additional Core-targeted purchase within the original five-completion/one-per-release-window caps. Target the weakest actual Core/frozen-standard ratio below1; rank eligible positive-Scope Design/Alpha Features by printed contribution capped at the observed deficit per exact quote completion expense plus Research-rent screen; tie by expense then ID. Preserve $4,000 admission reserve and exact FIFO quotes. Printed gains guide purchasing but do not grant scores. Skip unaffordable choices. These values/formulas are experimental, not approved gameplay.

Both experiments retain current reward/gate rules, priorities, specialty/Fantasy, ordinary hand choices, one-card redraws, cash Contracts and legal engine resolution. Downstream calendar/RNG/research/Contract choices may diverge. No loans, hires, invented money/cards or saves. Ordinary rent is due every second productive cycle; full-rent hand reserves are conservative.

## Outcomes

**8/8 complete,48 releases,{sum(r['commands'] for r in a['rows']):,} commands accepted.** Maximum observed arrears {money(max(r['arrears_max'] for r in a['rows']))}. Two seeds per comparison provide bounded witnesses, not population rates.

| Experiment | Crown access | Mean Review | Mean remaining Bugs | Full-Scope releases |
|---|---|---|---|---|
{chr(10).join(experiments)}

| Pair | Control Crown access | Candidate Crown access | End cycle | End cash |
|---|---|---|---|---|
{chr(10).join(outcomes)}

| Case | Reviews G1–G6 | Scope G1–G6 | Bugs G1–G6 |
|---|---|---|---|
{chr(10).join(details)}

### Actual intervention exposure

{len(qa)} accepted QA extension hands: {sum(e['discovered'] for e in qa)} Bugs discovered and {sum(e['fixed'] for e in qa)} fixed directly during those hands. {zero} extensions produce neither Bug discovery nor a fix; other effects such as Marketing can still occur. This is direct hand accounting, not the total treatment effect on subsequent games. [Per-hand visible state, selected cards, cash and QA reconciliation]({LINK}policy-audit.json). Later reductions can occur in a game with no extra hand because the earlier path changed. Policy observes known Bugs only; final remaining Bugs are evaluation data.

{chr(10).join(purchases) if purchases else 'No targeted Core acquisition occurred; exposure is absent, so no claim about a played purchase effect is supported.'}

[Analysis]({LINK}analysis.json) retains actual acquired/drawn/played exposure, frozen Review/Core/Scope/Bug components, finance totals, rent/play/research costs and zero-variance arithmetic diagnostics. Those diagnostics are not alternate legal simulated releases and are never supplied to policy.

### Matched calendar

| Pair | Last shared observed cycle | Candidate minus control cash | Release-count delta |
|---|---:|---:|---:|
{chr(10).join(calendar)}

End cash covers different calendars. The shared-cycle observations above also may differ in phase/title age; paired reports retain matched release milestones. No interpolation or assumed equal sales exposure. Do not attribute total cash differences solely to a Feature's price or added rent.

## Verification, failures and limits

- **PASS:** {s['study_checks']:,} source/decision/legality assertions and {s['policy_checks']:,} QA/Core guard/exposure assertions, plus maintained bundle/input/telemetry comparisons; four exact initial state/RNG pairs.
- **PASS:** protected variant and fixed plan/policy hashes, only the named helper project delta. [Verification]({LINK}verification.json).
{replays}
- **PASS:** QA Studio-only cold Continue restores exact final state/RNG, then {v['cold']['commands']} commands to release7/cycle{v['cold']['cycle']}. Policy instances reinitialize on Continue; this is engine checkpoint/replay evidence, not general persistence of arbitrary policy-local counters.
- **NONE observed:** rejected runtime commands, incomplete campaigns or timeouts; no recovery rerun or seed/budget/policy change. Failure reduction NOT APPLICABLE. Authoring checks caught an unmatched parenthesis in the Python verification writer before it ran, then a default-cp1252 decoding failure in the final AST-check command. The writer was corrected and the final check passed with explicit UTF-8. [Tooling failures/resolutions]({LINK}tooling-checks.json); no policy, variant, input or run result was changed.
- [Manifest]({LINK}evidence-manifest.json) retains {len(m['files'])} artifact hashes, warnings and canonical drift; raw frozen projects/profiles remain at `{RAW.as_posix()}`.
{warnings}
- **NOT RUN / not established:** GUI/native/export/human/device acceptance, broad balance, Traits/employees, active-rival pressure, support/commission economics, default-AI adoption or Crown relationship migration. All48 releases neutral with zero recent competitors: `{neutral}`. Updated rival code in the source does not establish exposure to a live rival world.

Canonical drift at the evidence audit:

{drift}

## Exact commands and records

Created `python tools/simulator_variant.py create --id crown-qa-core-v1 --owner contracts --output docs/codex/threads/contracts/simulators/crown-qa-core-v1`. Study scripts: `setup.py`, `prepare_analysis.py`, `run.py first`, `run.py remaining`, `analyze_all.py` (first-pair and final audits), `run_verification.py`, `verify.py`. Actual Python/Godot executable paths and every runner argv/config/output/timeout:

{commands}
- [QA replay]({LINK}replay-qa-command.json), [Core replay]({LINK}replay-core-command.json), [prepare cold]({LINK}prepare-cold-command.json), [cold]({LINK}cold-command.json). Driver logs and exit receipts are beside these commands. Fresh-process replay verifies frozen source rather than the mutable canonical checkout.

## Design boundary

This closes CA1c/CA1d at the declared evidence scope only. Crown Review7 and publisher rewards remain unchanged. No automatic additional QA, mandatory acquisition or default-AI rule is approved. SideStreet P2/P3/P4 keep their accepted bounded ACTIVE/TRIAL authority. Crown relationship terms/activation and supported predecessor migration remain OPEN; CP2 rewards remain held. No canonical gameplay/tests/assets/config, player-save write, commit, push or chat dispatch by this study. See the versioned handoff for proposed next work and acceptance criteria.
'''
    path=HERE.parents[1]/'CROWN-QA-CORE-FINDINGS-2026-10-24-v1.md'
    with path.open('x',encoding='utf-8') as f:f.write(text)
    print('Wrote '+str(path))

if __name__=='__main__':main()
