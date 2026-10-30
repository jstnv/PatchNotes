from setup import HERE, ROOT, RAW
import json
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
money=lambda n:('-' if int(n)<0 else '')+f'${abs(int(n))/100:,.2f}'
thread=HERE.parents[1]
prefix='studies/crown-extra-hand-20261024-v1/'

def access(row):
    return f"Game {row['first_qualifying_release']}, cycle {row['first_qualifying_cycle']}" if row['first_qualifying_release'] else 'none by Game 6'

def main():
    a=load(HERE/'analysis.json');s=load(HERE/'summary.json');v=load(HERE/'verification.json');m=load(HERE/'evidence-manifest.json');d=load(HERE/'component-diagnostics.json');e=load(HERE/'extra-audit.json')
    assert a['complete'] and s['complete'] and v['replay_ok'] and v['cold_ok']
    assert len(a['rows'])==12 and all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in a['rows'])
    c=s['arms']['control'];x=s['arms']['extra'];n=sum(r['commands'] for r in a['rows'])
    table=[];calendar=[];reviews=[]
    for p in sorted(s['pairs'],key=lambda p:p['pair']):
        left=p['control'];right=p['extra'];last=p['last_shared_calendar']
        table.append(f"| {p['pair']} | {access(left)} | {access(right)} | {p['additional_hand_count']} | {left['cycle']} → {right['cycle']} | {money(left['cash_cents'])} → {money(right['cash_cents'])} |")
        calendar.append(f"| {p['pair']} | {last['run_cycle']} | {money(last['delta_right_minus_left']['cash_cents'])} | {last['delta_right_minus_left']['release_count']} |")
        reviews.append(f"| {p['pair']} | {', '.join(map(str,left['reviews']))} | {', '.join(map(str,right['reviews']))} |")
    misses=[]
    for row in d['rows']:
        if row['case'].startswith('extra-') and not row['unlocked']:
            q=row['best_actual_release']
            misses.append(f"- `{row['case']}`: best actual release Game {q['release']}, Review {q['review']}, Scope {q['scope']}/30, {q['bugs']} remaining Bugs, production {q['production_rating']:.3f}; Cores {q['cores']} against {q['standards']}. Weakest normalized Core: {q['weakest_core']} ({q['minimum_core_ratio']:.3f}). Zero-variance diagnostic {q['zero_variance']}. These arithmetic diagnostics are not alternate simulated releases.")
    drift='\n'.join('- `'+item['path']+'` ('+item['change']+')' for item in m['canonical_drift_at_closeout']) or '- None observed.'
    warnings='\n'.join('- '+str(count)+' retained log occurrences: ``'+line+'``. This warning is not claimed fixed.' for line,count in m['warnings'].items()) or '- No warning/error prefixes observed in the retained log scan.'
    commands='\n'.join(f"- [{pair['pair']} command]({prefix}{pair['pair']}-command.json) · [config]({prefix}{pair['pair']}.json) · [paired report]({prefix}{pair['pair']}-comparison.md)." for pair in s['pairs'])
    finding=f'''# Crown extra-hand utilization — findings v1

2026-10-24. **COMPLETE bounded private study; DESIGN review, no gameplay/default-AI adoption.**

## Recommendation

Keep Crown's Review 7 gate and publisher rewards. Retain the extra-hand Action witness as a reachable route, but do not adopt this stopping policy as universal player guidance or default AI. It changes pacing and cash unevenly and does not establish a general cure for remaining Crown-access misses. Next investigate the two misses separately: bounded visible-information QA stopping for Simulation, and selective Core-aware purchases against the original acquisition control for Puzzle. Preserve the favorable no-purchase Action witness; avoid making shopping mandatory.

## Authority and exact sources

User authorized the proposed CA1b follow-up with “Go ahead and cook.” [Predeclared plan](CROWN-EXTRA-HAND-PLAN-2026-10-24-v1.md), [audit amendment](CROWN-EXTRA-HAND-AMENDMENT-2026-10-24-v1.md), [proposed handoff](CROWN-EXTRA-HAND-HANDOFF-2026-10-24-v1.md), [intake]({prefix}intake.json), [source pins]({prefix}source-pins.json).

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared checkout, 158 tracked changed files at intake. Existing edits and `.codex-godot-temp` preserved.
- Contracts child variant `crown-extra-hand-v1`, parent `crown-acquisition-v1`; protected canonical baseline `1338299b4fc7b6e4462609b9458a6b39e2c205854705795fa9d7bd53427a62e2`; candidate project `5b3b6fac6ad5acb4a3006d3f4ef243e068c0bbac91f9006aeaeca5145f78bdbe`.
- Common actual mechanics `{a['identities'][0]['source']}`; Godot `{a['identities'][0]['godot']}`; frozen external policy `51b197e068c6189f757fa53988338a4dcf9a52e3d65f24d9d69e911a07277f3e`.
- Only inherited private project delta is `scripts/debug/crown_access_legacy_v1.gd`, SHA-256 `1ee14d9a22b0cbfc58a80a16e2f68db06e20aad33ddf1cab5e60124b99936b55`. This study edits no private gameplay rule; [policy.diff]({prefix}policy.diff) records the external decision-policy delta. Original baseline and ancestry remain intact.
- Two host runners are explicitly accepted under the byte-exact `.ico` allowlist amendment, not described as identical. [All identities and compatibility proof]({prefix}runner-compatibility.json). Common frozen mechanics, runtime, policy and non-import source identities pass.

Canonical source matched the parent baseline at intake, then other work changed it during this frozen study. The following final drift is retained rather than overwritten. This is evidence on the recorded source, not final-current-source acceptance; regenerate legal prefixes on any new gameplay revision instead of patching checkpoint identities.

{drift}

## Setup and policies

Twelve fresh legal campaigns: seeds 4521/4522 × Action/Puzzle/Simulation × control/extra, no Traits/employees. Six releases and maximum 300 commands per case, six two-case batches, at most two runner processes concurrently, 600-second execution timeout per invocation. The bound explicitly increases CA1's 280 to accommodate extra hands. First Simulation 4522 pair was inspected before remaining batches. Both arms share exact initial state/RNG; all six controls reproduce the prior CA1 acquisition trajectory, including final state/RNG and every telemetry sample.

Control retains CA1's exact-quote acquisition strategy, $4,000 admission reserve, one purchase completion per release window/five overall, stopping at owned Scope 30; specialty/Fantasy, priorities, ordinary phase caps 3/2/3 then 6/4/6, one legal one-card redraw per phase and Beta QA/stopping stay fixed.

Candidate alone may play one extra four-card hand at the Design/Alpha policy ceiling while played Scope is below required Scope, if a visible positive-Scope Feature can be included and the entire hand fits cash after reserving four current monthly rents. Existing Core/Scope scoring ranks combinations. After that extra hand, exit normally. Ordinary hands reserve three rents. Later Store Features retain zero play fee; Primitive fees use current printed-score formula. Actual rent is due every second productive cycle, so the extra full-rent screen is conservative. No extra Beta hands/redraws, loans, hidden Bug/RNG reads, invented money/cards or rule changes.

Different subsequent purchases, draws, RNG, sales and calendar are downstream policy effects. Equal seeds do not imply identical later states. This is a strategy comparison, not a change to canonical hand limits.

## Outcomes

**12/12 finish six releases; {n:,} commands all accepted; no observed arrears.** Crown access is **{c['crown_unlocks']}/6 → {x['crown_unlocks']}/6**. Actual full-Scope releases: **{c['full_scope_releases']}/36 → {x['full_scope_releases']}/36**. Descriptive mean Review {c['mean_review']:.3f} → {x['mean_review']:.3f}; mean remaining Bugs {c['mean_remaining_bugs']:.3f} → {x['mean_remaining_bugs']:.3f}. Two seeds per specialty do not estimate population success rates.

| Start | Control first Crown access | Extra first Crown access | Extra hands used | End cycle | End cash |
|---|---|---|---:|---|---|
{chr(10).join(table)}

| Start | Control Reviews, Games 1–6 | Extra Reviews, Games 1–6 |
|---|---|---|
{chr(10).join(reviews)}

All {s['extra_hand_attempts']} attempted extra hands are accepted and independently checked for phase, ceiling, incomplete Scope, visible four-card legality, Feature content, full-hand cash screen and post-hand three-rent reserve. Exposure by game: `{d['extra_hands_by_release']}`. [Exact hand events and phase/redraw counts]({prefix}extra-audit.json). No-exposure cases: `{e['unexposed_cases']}`; their full trajectories equal their controls.

The early extra hands alter later draw/RNG paths. Improved Game 6 Scope is not proof of a Game 6 extra-hand intervention. For Simulation 4522, the only extra hand is Game 1 Design (Controller); it ends with full Scope but still misses Crown and less cash. Action 4522's favorable outcome and Action 4521's adverse cash/pacing outcome are both retained. End cash combines sales, Contracts, purchases, rent and fees; it is not simply the cost of extra hands. [Per-case finance totals and components]({prefix}analysis.json).

### Remaining quality gaps

{chr(10).join(misses)}

Core order is Graphics/Sound/Technology/Design, from the frozen ProjectState enum. Scope completion, Core coverage, remaining Bugs and Review variance interact. These observations support a separate targeted-acquisition investigation; they do not approve a purchase or demonstrate a hypothetical extra Core score is legally reachable.

Simulation 4522 Game 6 now has production 7.142 and full Scope, but six remaining Bugs. Its observed Beta exit has **{d['simulation4522_game6_observed_beta_exit']['known_bugs']} known Bugs**, at cycle {d['simulation4522_game6_observed_beta_exit']['cycle']} with {money(d['simulation4522_game6_observed_beta_exit']['cash_cents'])}. The post-run bug-free, zero-variance diagnostic is 7.1. This makes bounded legal playtesting/QA a better next question for this route than assuming more purchases are required. That diagnostic does not prove another hand can discover/fix those Bugs; the next policy must use visible information and a predeclared stopping rule, never hidden Bug counts.

Puzzle's original acquisition control reaches full Scope in Game 4 but has Sound9/13 and production6.505. Existing Music remains a specific purchase hypothesis for that control. The extra-hand route's best Game2 instead has Scope29, no remaining Bugs, weak Design48/59 and zero-variance Review7.0 but actual6.8. Sound is therefore not a universal diagnosis of every Puzzle miss; draw paths, incomplete Scope and variance also matter. Keep these routes distinct in the next experiment.

### Matched calendar

| Pair | Last shared observed cycle | Extra minus control cash | Release-count delta |
|---|---:|---:|---:|
{chr(10).join(calendar)}

These are observed command boundaries at the same calendar cycle, not necessarily the same phase/title age. Paired reports also preserve release milestones. No interpolation, equal-sales-exposure assumption or pure card-stat causal claim is made.

## Verification and retained failures

- **PASS:** {s['study_assertions']:,} study assertions and {s['extra_assertions']:,} extra-hand/control-reproduction assertions, plus maintained bundle/input/source/telemetry comparison. All six initial state/RNG pairs match; all six controls exactly reproduce CA1.
- **PASS:** predeclared policy/plan hashes and protected variant baseline/ancestry. [Verification]({prefix}verification.json).
- **PASS:** planned extra-Simulation-4522 fresh-process replay: {v['replay_commands']} commands/{v['replay_telemetry_samples']} telemetry samples; Studio-only cold Continue restores exact state/RNG and completes {v['cold_commands']} commands to release {v['cold_releases']}/cycle {v['cold_cycle']}. Cold mechanics equal study mechanics.
- **RETAINED audit failure, resolved explicitly:** initial three-batch aggregate stopped at `AssertionError: common runner`. The only code difference was adding `.ico` to the host snapshot allowlist. Both runners and failure record remain; byte-exact exception and identical frozen non-import source are checked. No run/policy/seed/budget was replaced to fix the audit.
- **NONE observed:** runtime rejected commands, incomplete campaigns, timeouts or recovery reruns. Failure reduction NOT APPLICABLE; no command rejected.
- [Manifest]({prefix}evidence-manifest.json): {len(m['files'])} hashed raw artifacts, frozen projects and private profiles retained at `{RAW.as_posix()}`.
{warnings}
- **NOT RUN / not established:** GUI/export/human/device acceptance, broad balance, alternate Traits/employees, later Store upgrades/discounts, default rival AI or Crown relationship migration/adoption. All measured releases use neutral market standards with zero recent competitors: `{d['all_neutral_market']}`. Concurrent rival source changes are outside this study.

## Exact commands and evidence

Creation: `python tools/simulator_variant.py create --id crown-extra-hand-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-acquisition-v1 --output docs/codex/threads/contracts/simulators/crown-extra-hand-v1`. Study scripts: `setup.py`; `run.py first`; `run.py remaining`; `analyze_all.py`; `run_verification.py`; `verify.py`; `diagnostics.py`. The initially failing audit and repeated partial audits are distinguished from the final complete audit above. Every runner uses a unique output folder. Exact executable paths/argv/limits:

{commands}
- [Replay]({prefix}replay-command.json), [prepare cold]({prefix}prepare-cold-command.json), [cold]({prefix}cold-command.json); corresponding driver logs/exit records and raw runner reports are retained.

## Next work and authority boundaries

CA1b is complete as bounded evidence. Proposed CA1d first: compare a bounded visible-information Beta playtesting/QA stopping policy against the retained extra-hand route, prioritizing Simulation4522; hold purchases/Design/Alpha/redraws/gates/rewards fixed, predeclare legal hands/reserve/budget and test actual Bug discovery/fixing, rent, cash, release timing and Crown access. Separately, CA1c compares existing exact-quote purchases aimed at weakest released Core coverage against unchanged CA1 acquisition, especially the original Puzzle Sound gap. Predeclare selection/reserve/purchase limits and actual acquired/drawn/played exposure. Keep the two interventions separate. Current-source drift requires a fresh source audit and legal starts.

Crown relationship terms, activation and supported predecessor migration remain OPEN. SideStreet P2/P3/P4 retain their separately accepted bounded ACTIVE/TRIAL scope; CP2 reward changes remain held. No user ruling is required to close this study. Canonical Crown relationship adoption still needs those separate design decisions and migration acceptance. No canonical gameplay, player save, commit, push, chat dispatch or release readiness is claimed.
'''
    # Never overwrite a prior published version accidentally.
    path=thread/'CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md'
    with path.open('x',encoding='utf-8') as f:f.write(finding)
    print('Wrote findings '+str(path))

if __name__=='__main__':main()
