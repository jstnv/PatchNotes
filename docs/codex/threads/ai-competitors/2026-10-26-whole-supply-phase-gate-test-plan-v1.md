# Whole-supply Feature and full-Scope gate test plan — 2026-10-26

**Status: predeclared DESIGN experiment; no gameplay adoption.** Question: When rivals must exhaust every legally drawable, affordable Design/Alpha Feature and meet full played Scope before Alpha/Beta exit, can the existing legal opening cohort complete and publish, and what happens to first Reviews and publication density?

## Hypothesis and comparison

- **A:** Frozen [opening-35-scope-roster-20261026-v1](simulators/opening-35-scope-roster-20261026-v1/variant.json), with its unchanged current visible-deal Feature-maximal policy and two-hand Beta. This is an **OPEN** opening-roster trial, not approved cohort balance.
- **B:** New child variant of A. Edit only private `project/scripts/market/rival_trial.gd` to keep A's visible legal/affordable four-card Feature maximization, then search the ordinary finite undrawn current-phase supply before exit. Use legal redraws when available, then an affordable legal four-Pass hand when available; if neither route can progress, return an explicit blocked choice. Require actual played Scope ≥ required before Alpha completion and Beta launch. Beta's two-hand choice, formulas, roster, starting cash/Fans, market, player policy and monthly rules stay as A. This search sequence is an **experimental OPEN policy**, not an approved termination or funding rule.
- Same numeric seeds **4417 and 4423**, fresh January starts regenerated in each frozen version. Seed4423 previously exposed a 29/30 release in A. Equal seeds alone are not an equality claim: compare creation source/rule differences and actual initial Studio/RNG/world snapshots before reading outcome differences. No checkpoint transfer across different source revisions.

## Legal starts, measurements and limits

- Use the preserved opening roster: two legal AI incumbents, 35 printed owned Scope each, unchanged frozen historical archive, player Action Studio from fresh recipe, January 1980, no mid-phase injected state, loan or cash grant. A's roster was authored only at Studio creation within its private candidate.
- Run the documented `tools/simulate.py run --variant` into unique thread-owned bundles using the existing 18-command/one-release smoke config, then the isolated 24-shared-cycle world probe copied with that variant. Keep A and B output folders separate. Do not use player saves or computer control.
- For each seed and rival: starting Studio/cash/RNG digest, every first live release cycle, Review, played/required Scope, final Core/Bugs, total rival releases by cycle24, blocked reason/cycle, end-phase, cash and completed work; runner source identities, Godot hash and elapsed time. Replay one representative completed bundle in a fresh process. Where the probe lacks a measure, record it as unavailable instead of inferring it.
- Each `simulate.py run` and probe has a **240-second process timeout**. The probe has **24 player/shared cycles** and `RivalTrial.ZERO_STEPS=12` zero-cycle rival steps per cycle. No rival project-cycle limit is added. Stop after the two declared seeds; retain rejects, blocked states and timeouts. If the first smoke or seed cannot run, diagnose and make a new named candidate revision before retrying; do not silently change the seeds, horizon or policy.

## Interpretation gates

- A B release below required Scope is a failure of the candidate gate. A B phase exit leaving a legally drawable, affordable Feature is a failure when the probe can establish it; absence of that inventory audit is an explicit coverage gap.
- A block or loss of publication is a real result, not a reason to synthesize Scope, money or a release. More Scope alone is not evidence of better Review; record Bugs, Core and market timing.
- Two seeds and an OPEN 35-Scope roster cannot approve a balance rule, final feature roster, search bound or implementation handoff. Legal search, stranded save recovery, publication capacity and CPU limits remain OPEN until source-pinned tests establish them.

## Declared diagnostic extension before further execution

The first two paired seeds completed, but the original world probe records outcomes rather than individual AI choices. Fork B as a **new v2 diagnostic-only variant** and add a trace to its private probe script, without changing the v1 policy or gameplay. Re-run seed **4423** through the same 18-command smoke and 24-cycle isolated world bounds; record every phase exit's visible/undrawn Feature counts and played/required Scope, plus legal redraw and Pass-search choices. Require the v2 release projection to match v1 exactly. This is an audit of actual exercised decisions, not a new search policy or extra favorable seed. Retain v1 evidence and any v2 failure.

**v2 diagnostic failure and fixed retry:** The v2 trace used `card.id` on a detached candidate Dictionary whose actual field is `definition`. Godot logged repeated SCRIPT ERRORs and the trace wrapper incorrectly marked its 0-release run as successful because it did not scan the log. Retain v2 as **FAILED**, fork a v3 diagnostic-only child, correct that field, and rerun the same seed, 24-cycle horizon and command/time bounds. Require no SCRIPT ERROR in the log and an exact v1/v3 release projection before using the trace.
