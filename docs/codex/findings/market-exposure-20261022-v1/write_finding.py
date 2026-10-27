from pathlib import Path
import json

OUT=Path(__file__).resolve().parent
d=json.loads((OUT/'summary.json').read_text())
assert d['completed']==8 and all(c['status']=='PASS' for c in d['cases'])
cases=d['cases']
reports=[json.loads((OUT/(c['label']+'.json')).read_text()) for c in cases]
assert all(not r['failure_reason'] for r in reports)
arithmetic=json.loads((OUT/'review-arithmetic-final-v1.json').read_text())
assert not arithmetic['errors'] and not arithmetic['input_errors'] and len(arithmetic['cases'])==8
records=sum(c['checks'] for c in cases)
replays=sum(c['replay_checks'] for c in cases)
commands=sum(c['commands'] for c in cases)
player_releases=sum(c['player_releases'] for c in cases)
rival_releases=sum(c['rival_releases'] for c in cases)
player_reviews=[v for c in cases for v in c['actual_reviews']]
rival_reviews=[v/10 for c in cases for v in c['rival_review_tenths']]
review_deltas=[v/10 for c in cases for v in c['review_delta_tenths']]
gain_sets={k:sum(c['settled_gain_targets'][k] for c in cases) for k in ['actual','rival_facts_removed','all_facts_removed']}
rows=[]
performance=[]
for c in cases:
    rows.append('| '+c['label'].removesuffix('-v2')+' | '+str(c['raised_target_releases'])+'/6 | '+str(c['rival_units_lost'])+' | $'+f"{c['rival_entitlement_cents_lost']/100:,.2f}"+' | '+str(c['rival_changed_earned_age_months'])+'/'+str(c['age_months'])+' | $'+f"{c['final_cash_cents']/100:,.2f}"+' / '+str(c['final_fans'])+' |')
    performance.append('| '+c['label'].removesuffix('-v2')+' | '+f"{c['wall_seconds']:.2f} / {c['cpu_seconds']:.2f}"+' | '+f"{c['replay_wall_seconds']:.2f} / {c['replay_cpu_seconds']:.2f}"+' | '+f"{c['world_wall_us_total']/1e6:.3f}"+' | '+f"{c['first_checkpoint_bytes']:,} → {c['final_checkpoint_bytes']:,}"+' |')
source=cases[0]['source']
assert all(c['source']==source and c['starting_source']==source for c in cases)
assert all(c['harness_sha256']==cases[0]['harness_sha256'] for c in cases)
text=f'''# Longer legal market exposure — 2026-10-22

**COMPLETE at bounded read-only study scope, with the timing deviation documented below.** Eight legal fresh campaigns completed six player releases each, followed by eight exact fresh-process replays. Simulation execution left canonical gameplay, Bank and coefficient files unchanged. Shared status is published separately by the implementation thread. Final balance, AI policy changes and leaderboard gameplay remain **OPEN**.

## Source and evidence

- `main` at HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing dirty worktree preserved. Mechanical identity is `{source}` before and after every process. Current repaired harness SHA-256 is `{cases[0]['harness_sha256']}`. [Harness provenance](harness-provenance.json) distinguishes normalized-LF and actual Windows file bytes.
- [Predeclared protocol](PLAN.md), [raw aggregate](summary.json), [sequential process records](panel-progress.json), [independent review](REVIEW.md), [final independent arithmetic audit](review-arithmetic-final-v1.json), and [session record](SESSION.md).
- Godot 4.7.1, eight fixed route/seed recipes, actual two-incumbent factory and canonical policy. Six releases/108 commands/42 productive cycles (21 months) in every record: **{player_releases} player releases, {rival_releases} actual rival releases, {commands} accepted recorded commands and {commands} exactly replayed commands**. Histories and preview rows were not substituted for real publications.
- Record assertions **{records:,}/{records:,}**, replay assertions **{replays:,}/{replays:,}**; all 16 processes exit 0 with no reported errors or source drift. These totals include repeated per-field ledger checks, not that many independent scenarios. Independent Python arithmetic passes **{arithmetic['checks']}/{arithmetic['checks']}** across all eight reports. The separate peer review initially inspected 432 arithmetic assertions on the first two cases only; its narrower scope remains recorded.
- A command-zero v1 parse failure from two untyped Dictionary return values is retained in `action-war-4417-v1.log` and `exposure-failed-parse-v1.gd`. The repair changed only this study harness; no seed, policy, rule or route was replaced.

## Actual player exposure and ordered attribution

The sales columns below compare actual earned sales with a pure replay of the same factual launch units/Review/Awareness/market multiplier, campaigns and elapsed cycles after removing rival facts **while keeping own-title crowding**. This is an ordered marginal removal under the 70% floor and integer rounding, not a unique additive causal share and not an observed alternative campaign. Review target attribution separately holds Core, Scope, Bugs and variance fixed; those altered Reviews are never fed into the sales comparison.

| Route / seed | Raised completed targets | Units lost to rival facts | Net earned revenue difference | Age months with changed earned units / observed age months | Actual final cash / Fans |
| --- | ---: | ---: | ---: | ---: | ---: |
{chr(10).join(rows)}

All four Action routes have five of six completed projects freeze raised standards. The first is the Genre base `[40,26,40,26]`; subsequent observed targets are `[42,28,42,28]` or `[44,30,44,30]` depending on one/two recent same-Genre rival publications. All four Puzzle routes retain their Genre base because neither incumbent publishes Puzzle. Across all 48 actual releases, the fixed-input target effect ranges from {min(review_deltas):.1f} to {max(review_deltas):.1f} Review points. The first project and non-overlapping Genre cases supply exact no-target-effect controls.

Action/War observes rival Genre-only crowding. Action/Fantasy observes an Action pair plus Adventure Theme-only crowding. Puzzle/Fantasy observes Theme-only crowding. Puzzle/War is disjoint from both rivals: it has zero direct rival units/cents effect even though its own repeated Puzzle/War titles still crowd each other. All routes retain actual own-title crowding and 12-cycle fact expiry. Each route has 54 saved age-month factor observations; these include partial final months and dormant titles. A factor decrease is therefore distinguished from an actual integer unit decrease in the table. Exact per-age exclusive counts, unit deltas and per-title cents are in `summary.json` and the raw reports.

The actual player Reviews range from {min(player_reviews):.1f} to {max(player_reviews):.1f}. Cumulative settled gain targets sum to `{gain_sets}` across the eight independent worlds. {'Every sampled player Review is below 5.0, so there is no positive Fan-gain exposure in this panel. Zero gain differences do not show that crowding cannot reduce gains for better releases.' if max(player_reviews)<5 else 'Fan-gain differences use the actual fixed launch reserve and Review; they are not alternative total Studio Fans.'} Actual Fan losses remain driven by the market-neutral loss shadow at the same factual inputs; the alternative whole-Studio shared-loss/Fan/Awareness trajectory was not simulated.

## Where challenge is missing

1. **Publication density is present in this bounded ordinary route.** Each world produces six Action and six Adventure incumbent releases in 42 cycles, and their real recent facts repeatedly raise Action population standards and affect matching sales. The formula is demonstrably connected to actual releases. This does not characterize a larger population, every player route or longer survival.
2. **Quality is weak.** The {rival_releases} actual rival Reviews range from {min(rival_reviews):.1f} to {max(rival_reviews):.1f}; {sum(c['rival_strong_releases'] for c in cases)} reach the 7.0 strong-Core gate. Consequently this panel's rival-to-player target pressure is population-driven. It supplies no evidence for strong-rival benchmarking; the separate adoption strong-player route retains its own scope. The low player Reviews also reflect this study's ordinary two-hand Feature-first control, not expert human capability.
3. **Variety is narrow.** Rival Genres stay Action/Adventure and every rival Theme stays Fantasy. Puzzle is never exposed to rival Core targets; War/Puzzle avoids both rival sales buckets. This is a policy/cohort coverage limitation visible without changing any coefficient. It does not select a new Genre/Theme policy.
4. **The current competence improvement is bounded.** The [G4 synergy trial decision](../../threads/ai-competitors/2026-10-18-g4-synergy-trial-decision-v1.md) retains two hands and the Primitive cohort; it does not promise competitive final Reviews. The [benefit-choice review](../../threads/ai-competitors/2026-10-18-g4-benefit-choice-design-review-v1.md) already rejected universal printed-benefit and cheapest-affordable policies. The [quote review](../../threads/ai-competitors/2026-10-18-g4-current-hand-quote-design-review-v1.md) leaves unavailable reasons and population cost unresolved. There is also a concrete current observation limitation: `patch-notes/scripts/market/rival_synergy_choice.gd:72` uses `get_genre_profile(current.genre)`, while `scripts/simulation/development_session.gd:172` supplies Genre/Core/Scope but no frozen market standards. The trial hand proxy therefore still ranks against Genre base targets. This panel does not isolate the score cost of that choice. A separate policy/observation study should expose and evaluate the frozen project standards with legal future exits and an explicit CPU bound; no hand-count or weight increase follows automatically.
5. **Store planning remains a separate design dependency.** The [G2/G3 ruling](../../threads/ai-competitors/2026-10-11-design-review-rulings-v1.md) requires one held project plan/allowance and a complete known-liability Research-window screen. The [reserve comparison](../../threads/ai-competitors/2026-10-11-g2-reserve-window-finding-v1.md) showed full-project reserves can stall all admissions while a short screen does not guarantee later funding. Exact allowances, hands, liabilities algorithm, search/CPU limits and actual later-project continuation remain OPEN. This no-Store panel neither validates nor selects those values.

**Disposition:** retain the current ACTIVE/TRIAL coefficients. The bounded exposure question is answered; final challenge balance is not. A new AI policy needs its own explicit objective, legal exits, Store/solvency coverage, comparison controls and population CPU bound before another implementation handoff.

## CPU, save and timing observations

| Route / seed | Record wall / CPU seconds | Replay wall / CPU seconds | Record world-advance wall seconds | First → sixth serialized checkpoint pair bytes |
| --- | ---: | ---: | ---: | ---: |
{chr(10).join(performance)}

Processes ran sequentially with isolated profiles, while other host activity could continue. CPU is the actual Godot process's kernel+user time. Whole-process measurements include observation, hashing, negative controls, checkpoint validation and counterfactual arithmetic; the world column is separately timed production-world advancement. Peak sampled Godot static allocation ranges from {min(c['peak_memory_bytes'] for c in cases):,} to {max(c['peak_memory_bytes'] for c in cases):,} bytes, not total OS working set. Checkpoint sizes include the serialized player/world pair and digest, not the complete profile or isolated incremental cost of the market feature. These observations establish no population CPU or memory budget.

The predeclaration said 180 wall seconds in Godot. The original harness actually checks that cutoff between command-loop steps; final counterfactual/report/cleanup work occurs afterward. The external 210-second process timeout is the hard total cap. Whole-process wall times above 180 seconds remain visible in the table and exceed a literal 180-second whole-process reading of the plan; they are not represented as under 180 seconds. This timing-measurement deviation does not change the legal campaign results.

No numeric loop-elapsed field was saved. A successful record checks the bound again before its completed-six-release break, and all record `failure_reason` fields are empty, providing stop-check evidence rather than an exact duration. Replays check before each step; the final step and post-loop work are not separately timed by the bound. No corrected process recorded a bound stop, returned a policy rejection, or was externally killed. Existing shutdown ObjectDB warnings, where present, remain in raw logs. This is not certification of a strict 180-second full-process performance budget.

## Acceptance and remaining design boundaries

This study began only after the implementation thread confirmed source-matched mechanical adoption. Ordinary old-save/backup migration and graphical/compiled Continue are separately documented in the [adoption finding](../market-adoption-20261018-v1/README.md); they are not fresh acceptance results from this study. Physical release-EXE input and human/device acceptance remain separate. No UI interaction was needed to produce these campaigns.

The separate leaderboard still needs a dated design decision for eligible releases/history, units versus earned or settled net revenue, ranking period, ties, update timing, ownership transfers and placement. Rankings must use actual frozen Reviews and authoritative title ledgers. Nothing here chooses those rules or queues leaderboard gameplay. Entrants, following-month news, Store/Core planning, new AI policies, final coefficients and long-run challenge thresholds remain **OPEN**. Bank rules remain unchanged.
'''
(OUT/'README.md').write_text(text,encoding='utf-8')
session=f'''# Market exposure study session — 2026-10-22

- Task: execute the post-adoption read-only work order after the implementation thread's source-matched acceptance confirmation; preserve Bank rules and shared dirty work.
- Branch/HEAD: `main` / `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Read CURRENT_STATE, TODO, repository README, the October 19 work order, current trial source and G2/G3/G4 design records. Inspected status/diff before edits; existing modifications and `.codex-godot-temp` were preserved.
- Changed files: only this new `docs/codex/findings/market-exposure-20261022-v1/` folder. It contains the predeclaration, derived harness and archived failed parser version, isolated runner/coordinator, provenance, raw process logs/reports/tapes/checkpoints, read-only aggregation/audit tools, this session record and final finding. Peer reviewer added bounded `REVIEW.md`, `audit.py` and the first-two-case arithmetic audit here. No canonical gameplay, Bank, shared TODO/CURRENT_STATE, commit or push edits.
- Exact source: `{source}`. Repaired harness `{cases[0]['harness_sha256']}`. Every corrected process records identical source before/after; the counterfactual pass preserves full live state and RNG.
- Commands: `python prepare.py` generated the local harness; `python run.py action-war-4417-v2 --route=action-war --seed=4417 --source={source}` ran the first corrected case. `python panel.py` then ran all predeclared cases/replays sequentially, retaining the completed first record. Full executable/argument arrays and isolated profile paths are in each `*-run.json`/`*-process.json`. `python summarize.py` rebuilt the final aggregate. `python audit.py --source {source} --output review-arithmetic-final-v1.json <the eight explicit v2 record JSONs>` independently checked all reports. `python write_finding.py` rendered this record and README from verified complete summaries.
- Results: eight records/eight exact fresh replays; 48 actual player plus 96 actual incumbent releases; {commands} recorded and {commands} replayed accepted commands; records {records:,}/0, replays {replays:,}/0; independent arithmetic {arithmetic['checks']}/0. All corrected processes exit 0, no errors, drift, legal-policy rejection or timeout. The command-zero v1 parse error is retained; two Dictionary annotations were the only harness repair.
- Documentation verification: final README and session readback completed; all 16 relative links resolved, no trailing whitespace in study text/source files, and the focused `git diff --check` passed. `documentation-check.json` records the link results and final README hash.
- Timing qualification: internal 180 s is a between-command stop; report/counterfactual work follows it, with a 210 s external cap. Whole-process timing above 180 s is explicitly reported. Host activity means no stable population-performance claim.
- Remaining: final market balance/challenge, Store/Core policy, liability/planning numbers, entrants/news, leaderboard rules and human/device acceptance. No further gameplay action follows automatically from this evidence. Root implementation thread owns shared status updates.
'''
(OUT/'SESSION.md').write_text(session,encoding='utf-8')
print(json.dumps({'records':records,'replays':replays,'arithmetic':arithmetic['checks'],'player_releases':player_releases,'rival_releases':rival_releases,'commands':commands,'source':source}))
