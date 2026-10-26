# Current-source two-hand exit replacement study — 2026-10-24

**Pre-run DESIGN plan.** The user's 2026-10-24 direction to ditch the two-hand exit confirms the [LOCKED visible-Feature rule](2026-10-24-feature-exhaustion-exit-decision-v1.md). Canonical gameplay is not edited in this thread. The goal is a current-source, minimal handoff for Design/Alpha stopping, separate from QA, entrant and affordability proposals.

## Hypothesis and policies

Removing the fixed Design/Alpha hand-count exit should prevent a rival from leaving a visible legal affordable Feature, improve Scope and Review, and keep each real Feature hand legal. It may reduce publication frequency and player market pressure; those outcomes are measured, not tuned away.

- **A, current policy:** the current two-hand exit, otherwise unchanged.
- **B, candidate:** in Design/Alpha, enumerate only four-card subsets of the seven currently visible candidate instances. Ask the actual phase hand for legality and RunState for exact current-hand Feature cost. Choose the legal affordable hand with the most Features, then use the existing synergy/Core/Scope proxy and stable token order. Re-evaluate after every productive refill. If no Feature hand is legal and affordable, request ordinary exit when allowed. If exit is not yet legal, return an explicit blocked choice: a Pass-only hand cannot establish the missing Alpha launch-Feature history and must not loop for its own sake. Beta remains its existing two-hand policy, with no redraw or new QA. No hidden-pool search, Store purchase, Core/Review bonus, cycle cap or hard future-income admission gate.

The candidate is a new thread-owned simulator variant from the **current canonical project**. It changes only its private `project/scripts/market/rival_trial.gd`; a diagnostic A arm preserves the original policy for equal-source comparison. The older v13 experiment informs the design but is not source-compatible proof for the current gameplay revision.

## Legal starts, limits and stop

Use the existing isolated interleaved world runner with two actual incumbent Studio sessions and the Action/Fantasy player route. Declared seeds: **4417 and 4418**. A and B for each seed must share the full founding state and typed RNG; both run on the same frozen candidate source. Target eight legal player releases, with at most 210 commands, player cycle64, twelve zero-cycle rival steps per player cycle and 480 seconds per world process. These are runner limits, **not** rival project-cycle limits. First run an isolated one-release smoke through `tools/simulate.py run --variant`. Retain every rejected, incomplete or timed-out attempt. Stop the candidate if it makes an illegal command, breaks import/source identity or cannot pass the first matched world; do not change seeds or bounds to obtain a favorable outcome.

## Measurements and acceptance question

Record every Design/Alpha selected hand and exit, actual four-card legality and current cash, Scope/Core/Bugs/Review for first and later releases, release cycles/counts, player earned/paid sales/cash/Fans, process CPU and saved-world bytes. Check exact full starting state and RNG equality per A/B pair, exact fresh-process replay and Studio-only Continue of a representative B world. Include a cash-blocked/short-pool route if naturally observed; otherwise mark it NOT TESTED and require a focused legal fixture before adoption.

The adoption question is narrow: can the LOCKED stopping rule replace the two-hand Design/Alpha exit on current source, with a legal finite fallback and no unapproved QA/cohort/cash changes? Passing worlds do not approve the candidate's tie ranking, rival quality, market balance or CPU budget. A handoff and TODO entry must distinguish this approved qualitative rule from OPEN implementation details.

## Retained execution amendment

The first 4417 A/B pair ran concurrently. A completed, while B reached cycle56/step143 and hit the declared 480-second **process** timeout before writing a completed report. Preserve that incomplete folder. Repeat B into a new output folder **alone**, with the identical seed, source, policy, command/release/cycle limits and 480-second process limit, to distinguish shared-host contention from a reproducible candidate failure. Do not count the timed-out prefix as a completed world or increase its budget.

The solo v18 B world completed, but its added `can_complete_productive_cycle(-cost)` preflight screened out every opening Design Feature hand, leaving Design after zero hands and yielding 28 weak titles. This violates the candidate's intended Feature-maximal behavior; the completed world is a **rejected policy revision**, not favorable evidence. Preserve v18 and its A/B outputs. Fork a new v19 from v18, remove only that additional preflight, and use the already verified actual hand legality plus exact printed current-hand cost check from the older v13 study. Re-run the same declared seed/horizon/bounds on v19; because the source revision changes, regenerate both A and B legal starting worlds. If v19 does not play opening legal Features, stop and report a design blocker.
