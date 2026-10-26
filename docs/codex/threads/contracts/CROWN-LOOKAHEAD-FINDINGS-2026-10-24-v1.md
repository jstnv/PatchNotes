# Crown first-hand lookahead and conservative redraw — findings v1

2026-10-24. **Completed private evidence; Crown relationship terms remain OPEN. Rewards unchanged.** [Predeclared plan](CROWN-LOOKAHEAD-PLAN-2026-10-24-v1.md) · [review handoff](CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md) · [exact commands](studies/crown-lookahead-20261024-v1/COMMANDS.md).

## Recommendation

Keep the current candidate rewards and use conservative redraw as the next accessibility-study reference: preserve the best four cards, consider only unselected cards for replacement, spend at most two tokens per Brief, and stop at full grade or no positive expected benefit. This reaches the proposedR20 threshold within three Briefs on both seeds that reach Crown. Stronger first-hand planning alone does not improve standing totals; adding it to conservative redraw produces mixed small changes, so it is optional research machinery, not a necessary player strategy or recommended production AI.

The earlier “no tested route reachesR20” result is superseded only for this bounded policy/cohort. Do not infer broad accessibility from two reachable seeds. First confirm on a current-source, predeclared wider cohort; do not weaken the balance/reward formula on the evidence available here. No Crown numerical approval or canonical activation occurs.

## Source, changes and legal starting conditions

Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. New variant `simulators/crown-lookahead-brief-v1` forks the preserved `crown-planning-brief-v1`. The only project delta from its immediate parent is `scripts/simulation/contract_session.gd`: a detached `planning_pool` containing already-owned, acceptance-eligible, unexhausted Feature definitions and public Core Passes. The existing redraw budget remains observed. No future draw order, actual RNG state, unseen content, mutable CardData or canonical/player-save access is provided to policies.

All reward, draw, finance, progression and save-rule files remain byte-identical to the parent. The inherited private Crown prototype still has no predecessor migration or playable Crown relationship UI. Its original11-path baseline delta and exact hashes are retained in [closeout](studies/crown-lookahead-20261024-v1/closeout.json).

| Identity | SHA-256 |
| --- | --- |
| Original baseline | `3f7df6cf437978aa9a119df09c175c8a720ce560d1a03abdaff46e26fd40fa10` |
| Parent / creation | `30435aa3146a1e1c8f7835138173d92b2bb1d2170a5409bb2ae9cc0a09579a4c` |
| Candidate | `d1d9b2eb3bad3ad5357f417cfbde634c2de9c284a723030b958dd83b6a97cd68` |
| Frozen source incl. policy, both batches | `34b77e990f8cf11e21baeffb91987dde5866a69eafcdcf69dc431ecde036ab78` |
| Runtime mechanics | `5283c43d1dcd0ace1400c2496b8d8ef3f87b07d31c6a9d6300a8233c1114d997` |
| Policy | `08efe53847b1778f35d588a4331302de00eaefd17b4547f86d72db259c696481` |
| Canonical at control capture | `35f3756d00f7bdf234431a2fa82420baa6aeb5d18684cce1b9a4749f272aa0c1` |
| Canonical at candidate capture | `a3cff578cf99087caba05549f2d7c24d2d7d8f87a23597138d16ef33b70ce2c7` |

Canonical usability work changed concurrently:30 drift paths at control capture,33 at candidate capture. Among relevant differences, new priority allocations now require10% per category while historical saves may retain5%. This experiment makes no priority changes and intentionally preserves the old legal baseline for comparisons. Other trait/preparation/source changes require fresh legal prefixes before interpreting results as current canonical balance. Full drift manifests are retained; a frozen candidate was not silently rebased. Runner/Godot hashes and exact process identities are in closeout.

Same legal Action/Cult Following recipes and Studio identities, seeds4417–4419, existing development route and cash-Crown unlock prefix. Three Brief maximum, stop accepting atR20, six-release/200-command cap per case,240-second process limit. Nine old-policy controls first, nine new-policy cases second, same frozen code and supplied policy. No injected money, unlock, cards or incompatible checkpoint. No seed/budget changes, hidden retries or outcome-driven policy tuning.

## Policy distinctions

The new first-hand planner enumerates35 actual opening quartets. It scores32 hypothetical legal refills per quartet, then all35 possible final quartets with actual synergies. It models known priorities, category/definition probabilities, sorted IDs, finite exhaustion and Pass reuse. The same independently generated planning rolls are used for every opening choice, from a local Park–Miller sequence reset to20261024; actual game RNG is never inspected/advanced. Recorded samples and all35 candidate ranks are independently reproduced in Python. This is sampled expectation, not globally optimal play. First-hand planning assumes no later redraw, isolating redraw as a second factor.

Conservative redraw keeps the best final quartet. For each remaining token it enumerates legal same-type replacements and their probabilities, scores every resulting legal quartet, and selects a positive expected improvement. It never replaces a protected token, never exceeds two tokens/Brief or actual budget, and never adds a productive cycle. Preserving the old quartet guarantees that immediately available maximum grade cannot decrease; this does not guarantee better whole-route results because consuming draws changes later Contract RNG.

## Outcomes

| Policy | Seed4417 Reputation | Seed4418 Reputation | Tokens4417 /4418 | R20 within three Briefs |
| --- | ---: | ---: | ---: | --- |
| Old balanced, no redraw |7.50|12.50|0 /0|Neither|
| Old aggressive redraw |9.69|10.00|6 /6|Neither|
| Old first hand + conservative redraw |24.69|22.50|5 /5|Both|
| Lookahead, no redraw |7.50|12.50|0 /0|Neither|
| Lookahead + conservative redraw |24.39|24.39|5 /4|Both|
| Skip Briefs |0|0|0 /0|Neither|

All four conservative-policy routes passR20 on Brief3, cycle40, after four released games. This meets a **proposed** future commission gate arithmetically; no Crown commission was created or tested. Combined-policy individual awards are4417 `9.39/5.00/10.00R`,4418 `9.39/10.00/5.00R`. Old-first-hand conservative awards are4417 `9.69/5.00/10.00R`,4418 `7.50/10.00/5.00R`.

Across19 conservative redraws:13 immediate grade improvements, six unchanged, zero losses. All enumerate positive expected benefit; the no-benefit skip branch is not reached in this cohort. Four full Briefs appear, one in each conservative route; those12 Briefs have no zero grade. Across all30 take-route Briefs there are four full,19 positive partial and seven zero results. Repeated policy routes on common seeds are paired comparisons, not30 independent campaign samples.

Actual first-hand computation is238–264ms, median242.5ms across12 decisions (2.949s total). Executed control/candidate game processes take54.062s/61.672s; import/copy overhead is additional. These are observations on this host, not production CPU or population limits.

### Cash, timing, resources and failed access

All take policies finish six games at cycle48; skip finishes at42. Cash at release6 is unchanged by planner/redraw choice:4417 `$7,428.60` against skip `$8,837.69`,4418 `$12,200.26` against `$13,434.53`. Same-release deltas are `-$1,409.09`/`-$1,234.27`, including the extra six productive cycles. Last common cycle42 deltas are `-$20.21`/`-$1,995.17` with different release progress. Briefs still award no cash/Promotion/Investment. All routes end with4 redraw tokens after ordinary regeneration; this does not erase the recorded4–6 token spend.

All six4419 policies fail before Crown on the same game3 Design affordability action:53 recorded/52 accepted commands, two releases, cycle25, `$116.68`, zero overdue, no Brief accepted. The prior2.4/6.0 Reviews fail discovery. Complete initial state/RNG and failed-prefix state match; preserve this intake limitation. No extra failure reduction is needed for an unchanged pre-intervention rejection.

## Verification, failures and limits

- **PASS:**2,392 independent analysis checks: full initial state/RNG and first-Brief boundaries across batches, all9 prior control outcomes/RNG and six complete durable Studio payloads, exact grades/P1 awards, sampled pool legality/ranks, every enumerated conservative replacement probability/grade, actual monotonic redraw, finite reuse, saved counters, zero currency/Investment and release-paced offers.
- **PASS:**130-step `lookahead-4417` and134-step `lookahead_safe-4418` fresh-process replays with exact states at every step/final boundary.
- **PASS:**15-command cold Studio Continue to release7/cycle52, exact initial entire state/RNG, unchanged completed Briefs/redraw counters/standing ledger and pending offer.
- **PASS:**876 integrity/closeout checks, mostly source/archive hashes plus replay/save assertions. Immutable baseline/ancestry and parent bytes preserved; sole parent-relative code delta is observation. Plan, policy, cases and candidate remained frozen. No legacy Starwave-count leak or unintended commission/support.
- **RETAINED FAILURES:** initial control capture aborted before import/gameplay because canonical source changed while recording drift; unchanged retry in a new directory succeeded in capture. Both executed batches exit1 for three known pre-Crown rejections each.18 cases retained,12 completed/six rejected;1,879 recorded/1,873 accepted commands. No gameplay rerun, timeout, import or script error. Five process logs each retain the existing six-ObjectDB-instance exit warning.
- **NOT RUN / OPEN:** wider/no-trait specialties, current-source regeneration, longer horizons, worst-case draw distributions, human comprehension, no-benefit redraw branch, actual Crown commission/support, prospective migration/populated ownership/disk/native/exported acceptance and maintained full-suite gates. No final balance/production AI approval.

An ancillary one-line statistics inspection had a Python bracket typo; corrected in the recorded `summarize.py` without changing any run/policy/results. All evidence-analysis scripts, replay and continuation commands pass. [Analysis](studies/crown-lookahead-20261024-v1/analysis-v1.json) · [compact metrics](studies/crown-lookahead-20261024-v1/summary-v1.json) · [integrity and warnings](studies/crown-lookahead-20261024-v1/closeout.json).

Raw frozen source, all cases/failures, logs, commands, tapes and saves: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-lookahead-20261024-v1/`. Selected exact hashes are retained locally. No canonical gameplay, player saves, shared design authority, `.codex-godot-temp`, commits, pushes or GUI controls were touched. TODO review status is reconciled separately under existing user authorization.
