"""Produce the bounded Stage 2 findings from verified current-engine traces."""
from pathlib import Path
import json, statistics
from feature_store_stage2_v1_analyze import cash_sources, releases, states
from feature_store_stage2_v1_supplement import supplemental_rows

ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/feature-store-staged-v1'
POLICIES=['cautious','ordinary','optimizer']
def read(name):return json.loads((OUT/name).read_text())['rows']
def avg(xs):return statistics.mean(xs)
def money(cents):return f'${cents/100:,.2f}'
def load_main(policy,arm):return read(f'stage2_{policy}_{arm}_discovery.json')+read(f'stage2_{policy}_{arm}_expanded_8.json')

def main():
    summary=json.loads((OUT/'stage2_summary_v1.json').read_text())
    catalog=json.loads((ROOT/'analysis/feature_store_stage2_v1_catalog.json').read_text())
    lines=['# Patch Notes — Feature Store Stage 2 findings v1','',
    'Status: read-only simulation complete. No candidate card, price, fee, AND rule, hardware rule, or balance value was implemented or approved. Source: main `608a2c62ab0850cf607f7ff627b042a49b5d2dfb` plus the preserved pending first-game tutorial changes; current-source manifest and baseline log are adjacent.', '',
    f"Verified {summary['cases']} route executions across {len(summary['jobs'])} successful jobs. These reuse **12 production seeds**, with paired QA/Marketing cases and three policies. The four main arms have 24 cases / 12 seeds per policy after expansion; isolated cards, bundles, price cells, focus cells and platform cells generally have 4 cases / 2 seeds. There are {summary['unique_matched_first_game_routes']} distinct first-game seed/policy/Beta/focus configurations. These are matched experiments, not thousands of independent seeds or human playtests.", '',
    f"All reported rows satisfy {summary['trace_invariant_checks']:,} trace assertions, including actual productive-cycle cash/settlement parity, finite Feature plays, same-ID redraw exclusion, supply/ownership compatibility, preserved earlier familiarity, passive summary state, and frozen released projects through Contracts. Every row's cash closes exactly to the cent after separately accounting for starter spending, Store chains, production, direct Beta cash, Contract payouts, settled release sales and campaigns. Invalid historical attempts are excluded: {summary['excluded']}.", '',
    '## What was actually exercised', '',
    'Actual Godot scenes and action handlers drive Studio creation, legal 20–23-Scope starter pools under the $4,000 starter cap, Pre-Development, Design, Alpha, Beta, Review, release, Store transactions, Ironclad, release-linked SideStreet, and three released games. Monthly earning and settlement use the current Month 2+ numeric-trial implementation. Main comparisons have campaigns off. No free Wait, cash injection, fabricated Review, payroll, employee, fanbase, publisher offer, or platform selector was added.', '',
    'The current scripted first-game tutorial is followed: matching dominant-priority specialization, then the other-category one-away guaranteed redraw. Design/Alpha RNGs are seeded before priority confirmation and first dealing; Contract initial category/definition rolls are installed before `_ready`, then the RNG resumes after those 14 rolls. Current 50/50 redraw-class rules apply outside the tutorial. A two-case full three-game base-RunState versus shadow-subclass parity check matched exactly after mapping random release IDs; the six-case smoke/parity set is separate from reported experimental counts.', '',
    '| Policy | Design / Alpha / Beta hands per game | Ordinary redraw attempts | Priority commits |',
    '|---|---|---|---|',
    '| Cautious | 2 / 2 / 1 | none beyond tutorial | none |',
    '| Ordinary | 4 / 4 / 3 | 1 per production hand when allowance remains | Design and Beta after hand 1 |',
    '| Optimizer heuristic | 6 / 6 / 5 | 2 per production hand when allowance remains | Design, Alpha and Beta after hand 1 |', '',
    'Ordinary/optimizer enumerate legal affordable four-card hands, favor Scope/Core/Specialization, and use internal hidden/known Bug counts for QA ranking. They are automated internal-state-informed heuristics, not blinded novice models or a mathematical optimum. Review variance uses the disclosed legal fixture roll `floor(seed / 97) % 100`; this seed range clusters variance bands. Percentiles/shares in the CSV describe these fixtures. They are not a human progression ceiling; the user has reported Reviews above 9 after the first game.', '',
    'Candidates exist only in isolated process memory. Twenty first-era definitions are representable with two printed Core fields. Two-parent gates/combined familiarity, candidate play fees, and synthetic compatibility are explicit analysis-only RunState overrides. The real scorer, finite supply, cycle transaction, cash, Review and sales remain current Godot code. Boss Battles never enters a live owned/drawn pool because its third printed Core effect cannot be represented. The full 59-node catalog is therefore blocked, not approximated by silently omitting T3.', '',
    '## Expanded matched shopping results', '',
    'Center base prices, zero candidate play fee, 24 Beta cases / 12 production seeds per policy and arm. Deltas compare exactly matched current-Store controls. “Final cash” is spendable cash after Game 3 and its SideStreet; it is not purchase ROI. Different purchase cycles can leave different earned-but-unsettled amounts.', '',
    '| Policy | Arm | G2 Review | Δ G2 Review | G3 Review | Δ final cash | Mean chain cycles |',
    '|---|---|---:|---:|---:|---:|---:|']
    for policy in POLICIES:
        controls={r['case']:r for r in load_main(policy,'none')}
        for arm in ['none','background_music','sub_areas','pair']:
            rs=load_main(policy,arm)
            lines.append(f"| {policy} | {arm} | {avg(r['game_2']['final_review'] for r in rs):.2f} | {avg(r['game_2']['final_review']-controls[r['case']]['game_2']['final_review'] for r in rs):+.2f} | {avg(releases(r)[3]['final_review'] for r in rs):.2f} | {money(avg(r['final_state']['cash_cents']-controls[r['case']]['final_state']['cash_cents'] for r in rs))} | {avg(sum(t['bought'] for t in r['trial_purchases']) for r in rs):.2f} |")
    lines += ['', 'Discovery also included reserve-only, matched parent reserves, staged pair, and current upgrades at 8 cases / 4 seeds per policy. These are retained in the CSV and raw traces; the one failed cautious-upgrade harness attempt was fixed and rerun in `discovery_fixed`. Current-upgrade play fees remain their actual $0 behavior even when a candidate-fee sensitivity is enabled. Parent purchases can also improve the fixed Primitive Contract supply; new later cards never enter that pool. Direct Beta “Playtest Rival Games” cash can change when a policy chooses different Beta hands. Both sources are separated from release sales in the CSV and cent-exact closure records.', '',
    '## Card-level screen and recommendations', '',
    'Each row below uses the first four matched cases per policy (12 case executions / 2 seeds × three policies). Background Music and Sub-Areas use zero candidate fees here; other rows use the Primitive-formula analogue. Center trial prices apply. ΔReview and Δcash are **whole shopping-route effects**, including required parent purchases, draw dilution and available production cash, not the intrinsic isolated effect of one card. “Retain” means retain for further trial/design review, not approve for implementation.', '',
    '| Card | Fee | Child bought | Child plays, G2+G3 | Δ G2 Review | Δ final cash | Recommendation |',
    '|---|---:|---:|---:|---:|---:|---|']
    for id,entry in catalog.items():
        if entry['unsupported_tertiary']:
            lines.append(f"| {entry['name']} | — | — | — | — | — | Defer live scoring: tertiary schema unavailable; retain exact ledger definition. |")
            continue
        measures=[]
        for policy in POLICIES:
            path=f'stage2_{policy}_{id}_isolated.json'
            if not (OUT/path).exists():path=f'stage2_{policy}_{id}_discovery.json'
            rs=read(path)[:4]; controls={r['case']:r for r in read(f'stage2_{policy}_none_discovery.json')}
            for r in rs:
                measures.append((any(t['id']==id and t['bought'] for t in r['trial_purchases']),sum(a.get('selected',[]).count(id) for a in r['actions']),r['game_2']['final_review']-controls[r['case']]['game_2']['final_review'],r['final_state']['cash_cents']-controls[r['case']]['final_state']['cash_cents']))
        if entry['direct_tags']:recommendation='Defer live availability; retain explicitly compatible synthetic test until platform rules exist.'
        elif id in ['branching_story','branching_paths','ambient_sound']:recommendation='Revise staged access/reserve planning; defer broad early chain rollout.'
        elif len(entry['parents'])>1:recommendation='Retain printed definition; revise AND gate/quote UI and test production reserve.'
        else:recommendation='Retain bounded trial; price and play fee remain candidates.'
        fee='$0' if id in ['background_music','sub_areas'] else money((entry['primary_value']+entry['secondary_value']+2*entry['scope'])*1000)
        lines.append(f"| {entry['name']} | {fee} | {sum(m[0] for m in measures)}/12 | {sum(m[1] for m in measures)} | {avg(m[2] for m in measures):+.2f} | {money(avg(m[3] for m in measures))} | {recommendation} |")
    lines += ['', 'All 13 authored definitions retain their ledger values. Boss Battles is a capability blocker; the other 12 can be scored through the isolated two-field fixtures. Eight new candidates remain invented, unapproved inputs. Three small nonredundant bundles were exercised; the full 59-node arm remains blocked by the missing tertiary capability and unavailable real platform model.', '',
    '## Price, fee and reserve interaction', '',
    'Ordinary policy, 4 cases / 2 seeds per cell: A (Background Music), B (Sub-Areas), B+ (Recorded Instruments), and C2 (Branching Story) were tested at every low/center/high base price × zero/analogue/double play fee. C1 has no supported first-era representative in this catalog; its later-era economics belong to the separate reachability gate.', '',
    '| Card | Base price | Bought out of 4 | G2 Review, fee 0 / analogue / double | Final cash, fee 0 / analogue / double |',
    '|---|---:|---|---|---|']
    for id in ['background_music','sub_areas','recorded_instruments','branching_story']:
        for band in range(3):
            cells=[read(f'stage2_ordinary_{id}_price{band}_fee{fee}.json') for fee in range(3)]
            bought=[sum(any(t['id']==id and t['bought'] for t in r['trial_purchases']) for r in rs) for rs in cells]
            lines.append(f"| {catalog[id]['name']} | ${catalog[id]['price_bands'][band]:,} | {' / '.join(map(str,bought))} | {' / '.join(f'{avg(r["game_2"]["final_review"] for r in rs):.2f}' for rs in cells)} | {' / '.join(money(avg(r['final_state']['cash_cents'] for r in rs)) for rs in cells)} |")
    lines += ['', 'The important nonmonotonic result is Branching Story: a lower price can make the immediate-buy policy cross the purchase threshold and spend its production reserve, then complete fewer paid hands. This is a shopping-policy/reserve interaction, not evidence that the cheaper card intrinsically scores worse. Every hand is replanned for actual current cash, and an unaffordable candidate pool can end the phase early through the existing legal under-Scope path. Such a block is not an irrecoverable inability to release. Long-chain retry-at-Game-3 arms explicitly buy only after another legal release/Contract has earned cash; no free time or cash is inserted.', '',
    '## Synthetic compatibility and policy sensitivities', '',
    'The fixtures are `ALL_DECLARED_TAGS`, `EMPTY`, and `EMPTY → ALL_DECLARED_TAGS for Game 3`. They are not historical machines or a playable platform selector. All six conditional early candidates were tested under each relevant fixture. In EMPTY they can remain owned but are absent from project supply and never consume a candidate slot. In the transition fixture, ownership is retained and the next compatible project receives the card without repurchase. Direct tags are read only from the card; ancestors do not automatically impose tags. Earlier parent familiarity is retained.', '',
    'Forced Sound and mixed priority arms use identical seed/roster/Beta combinations for current control, Background Music, Sub-Areas and pair (4 cases per focus per policy). The automatic focus strata in the larger cohort correlate with starter Scope, so only these forced-focus arms support a focus comparison. QA and Marketing are separately paired on every production seed; current all-four-Marketing specialization is included. Six separate campaign jobs attempt one real $100/one-cycle campaign if eligible; rejected offers remain unchanged. No campaign result is included in the primary shopping means.', '',
    '## Evidence and boundaries', '',
    '`stage2_summary_v1.csv` contains per-job Review percentiles/shares, ownership-chain costs/cycles, low cash, purchase/production blocks, direct Beta cash, Contract payouts, and per-release earned versus settled units/cents. Settled units are explicitly derived by inverting the current exact $9.99 × 70% net calculation and checked against the settled cents; they are not a stored RunState field. `stage2_month_boundaries_v1.json` uses successful productive-action after-states at even run cycles, excluding zero-cycle accept bonuses. `stage2_metrics_v1.json` has per-run source-to-cash closure and first intended action blocker. `stage2_exposure_v1.json` separates purchase, final ownership, project eligibility, initial/redraw appearances and actual plays. The raw `stage2_<policy>_<arm>_<tag>.json` and matching log files contain complete action traces.', '',
    'Reproduce from the repository with the bundled Python: run `analysis/feature_store_stage2_v1_batch.py` with the smoke, discovery, isolated and sensitivity manifests (the latter used 3 workers; prior batches used 2), then `analysis/feature_store_stage2_v1_analyze.py` and this report generator. Every subprocess command, exit code, runtime and script-error list is saved in the manifest `_results.json`. Godot uses a new isolated APPDATA/LOCALAPPDATA profile for each job. Default-profile startup crashed before initialization; isolated profiles resolved that environment issue. An early typed-array harness error affected only the explicitly excluded 8-case cautious current-upgrade arm; its corrected rerun is separate evidence.', '',
    'No gameplay source, ledger, To Do List, canonical authority rule, or unrelated worktree change was edited. The baseline retains the known live-versus-DOCX primary-order differences for Split Screen and Multiple Endings; see Stage 1 rather than silently rebasing them. No native mouse/keyboard or human UI playtest is claimed. Readable Store warnings, actual platform choices, AND badge navigation and tertiary card presentation remain implementation/design boundaries.', '',
    'Human follow-up: observe whether a player understands the total parent-chain price and production reserve; whether they deliberately stage expensive branches; which new cards they actually notice and play; whether hardware compatibility is clear; whether they use the guaranteed tutorial synergies; and whether a longer, Genre-aware second/third project changes the automated policy results. No numerical balance recommendation is locked by these tests.', '']
    document='\n'.join(lines).replace('## Evidence and boundaries', supplemental_rows()+'\n## Evidence and boundaries')
    (OUT/'stage2_findings_v1.md').write_text(document,encoding='utf8')
    print('stage2_findings_v1.md written')

if __name__=='__main__': main()
