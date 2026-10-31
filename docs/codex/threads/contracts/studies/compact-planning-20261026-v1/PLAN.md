# Compact package two-hand planning — preregistration

2026-10-26. User authorizes continued investigation and TODO update afterward. Existing rewards unchanged; new package/gate/values remain PROPOSED. This is a **policy experiment on unchanged private Crown Brief mechanics**, not implementation or economic validation of a cash package.

## Hypothesis and comparison

Adding public-information two-hand planning will reduce avoidable loss of a joint completion/balance/size objective relative to myopic planning. A ceiling may force a useful tradeoff or may remain redundant under balance. All actual Brief awards, costs, Search behavior, draws and redraw rules remain unchanged. The proposed cash rewards are deliberately absent.

Fork named owner-contracts variant `compact-planning-20261026-v1` from `early-brief-affordability-20261025-v1`. Only a private debug policy is added. Preserve baseline and ancestry. Verify runtime/mechanics identity and source compatibility rather than rewrite checkpoint identities. Use the six previously earned Studio envelopes: Puzzle4417/4418/4521/4522 Sound+Sprites, Action4417 and Simulation4417. If unchanged mechanics cannot accept these exact envelopes, stop and report; do not inject state.

Four arms per start,24 campaigns:

1. `control`: existing two-hand public-mean256, no Scope ceiling.
2. `greedy9`: one-hand visible score, ceiling9/fade4.
3. `plan9`: public-mean256 two-hand planning, ceiling9/fade4.
4. `plan10`: same planner, ceiling10/fade4.

Each arm takes **one** paid Crown Brief then proceeds to the next release using the original route's production policy. Same120-command cap, absolute target one release beyond the checkpoint, same starting state/RNG, no redrawing or extra Research/cash work/Bank/hiring before the Brief. The original cohort/prefix recipes and seeds are unchanged; no newly selected favorable cohorts. No new player saves or native computer access.

Policy objective: maximize the projected bottleneck `min(base_completion_bp,balance_bp,size_bp)`; with no ceiling this reproduces the original Brief objective. First hand uses all35 choices and the existing256 deterministic public weighted-pool scenarios, each with35 second-hand choices. Preserve finite exclusion, retained cards, specialization and public priorities. Scenarios never consume runtime RNG or inspect future draws. Expected bottleneck is a conservative design diagnostic, **not a cash-optimal policy or a reward formula**. Preserve original deterministic tie breakers. Myopic uses current bottleneck then completion/spread. Report both base and bonus separately and the limiting reason, not just the diagnostic score.

## Measurements and controls

Before interpreting candidate arms, compare all six control first-Brief outcomes/selected tokens with their historical equivalents. Run control first. Verify variant delta is debug-only, mechanics equal to parent and all arm envelopes identical per route. Record actual selected first/final cards, scores, real awards, finance/cycles, zero/partial/full hypothetical package grades, and legal completion. For final hands enumerate every visible quartet to identify Pareto frontier and whether avoiding the cap requires a base/balance tradeoff. Compare decisions by stable card definitions, not runtime token identities alone. A two-hand planning improvement may still fail on random draws; retain all cases.

## Commands, limits and stops

Use `tools/simulate.py run --variant ...` into a unique output folder per arm, private profiles/imports. Four sequential six-case bundles; each runner receives timeout600 seconds (import and execution limits as defined by runner), every case max120 commands and one further release. Outer driver stops a bundle after1350 seconds, retaining outputs. No budget/seed extensions after failure. One same-input new-output retry allowed only for documented concurrent-source snapshot capture failure, never for unfavorable gameplay.

Representative exact fresh-process replay: one control Puzzle4417, one plan9 Puzzle4522, one plan10 Action4417, each timeout240. Failed campaign cases retain their accepted prefix; reduce reproducible command failures if applicable. A fresh-process Studio Continue check may use a completed plan9 checkpoint for one further release, same120-command bound, when baseline pair checks pass. Stop dependent research on incompatible source/invalid starting states or rule drift. If a planned case fails, report unavailable coverage instead of silently replacing it.

## Decision rule and status

Prefer the least restrictive size case with evidence of actual size-sensitive choices; do not choose a cap solely to increase failures. If9/10 both remain inactive under stronger planning, recommend holding the extra size rule until broader legal Scope supply shows a meaningful tradeoff. Stronger two-hand planning is judged on realized normalized base/bonus, joint-full/positive/zero outcomes, and finance/legal completion;6 routes are not player win-rate evidence. New cash/Promotion/advance/gate values, candidate-specific settlement/commission/activation, canonical integration, UI/human comprehension and overall affordability remain OPEN. At completion add a minimal DESIGN review entry, preserving approved feedback and concurrent TODO changes.
