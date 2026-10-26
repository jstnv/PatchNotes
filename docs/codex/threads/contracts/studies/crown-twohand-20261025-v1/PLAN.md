# Crown CB2b stronger two-hand planning — 2026-10-25

User authorizes stronger Crown Brief planning, rewards unchanged and redraws parked. Research only; no canonical gameplay, tests, assets, configuration, player saves, commits or pushes. Keep existing dirty edits and .codex-godot-temp. Prototype numeric rules and adoption remain OPEN.

## Design and hypothesis

Previous CB2 greedy play earns10R after three Briefs on each of two legal Action starts; a targeted alternative first hand earns a full10R but only12.50R total on4522. Earlier historical lookahead used32pseudo-random refill scenarios and did not improve its different bridge cohort. Test whether more complete first-hand planning improves earned standing and reduces zero results under the actual final-card balance penalty.

Compare three fixed policies: (1) retained CB2 greedy; (2) expected final grade; (3) downside-aware final grade. Both new policies enumerate all35first quartets and the best35final quartets after each of256fixed modeled refills. Model the source's priority-weighted category, uniform eligible definition, finite Feature removal and renewable Pass law. All seven currently visible finite Features are unavailable to the refill regardless of first choice (played or retained), so every first-hand option shares the same refill scenarios. No actual future draw/state/seed/RNG reads.

Model scenarios are deterministic eight-dimensional Halton points1..256, bases2/3/5/7/11/13/17/19 (category then definition for each slot). This increases coverage versus32LCG scenarios but is still an approximation, not a proof of optimality. It consumes no game RNG. Each hypothetical final result uses the exact reward floor/min(completion,balance). Expected policy ranks total grade, full count, positive count, narrower first-hand spread, then first index order. Downside ranks total grade+4*sum(lowest64grades), then total/full/positive/narrower spread/index; equivalent primary weight on mean and bottom-quarter mean. On hand2 both choose exact best visible grade, completion, narrower spread, first index. No Brief redraws or priority commands. Old development policy's unchanged ordinary redraws remain baseline behavior; no Beta tuning.

## Source and runs

- New named child `crown-twohand-planning-20261025-v1` from frozen `crown-brief-pilot-20261025-v1`; preserve original canonical baseline and ancestry. No private runtime edits are needed because public planning_pool already exists. Only a new external supplied-policy version changes decisions. Audit parent/child source equality and current canonical drift; do not silently fold unrelated UI work into this policy comparison.
- Reuse the exact previously earned same-source Studio-only Action/no-Trait4521/4522 unlock envelopes. Rules/source/RNG checks remain enforced. Historical source is pinned; if compatibility fails, retain it and explicitly regenerate legal prefixes instead of editing identities.
- Existing behavior first: two fresh greedy control continuations, original180command bounds and absolute7/6release targets. Verify exact result/tape trajectory reproduction versus CB2, then candidate execution.
- Two candidate batches, mean and downside for each seed: four cases total. Same180commands, same targets, at mostthree Briefs orR20. All six starts paired by seed have exact state/RNG. No rerolls or silent budget extension. At mosttwo concurrent host runners;600seconds each import/experiment. Hard planning bound35*256*35=313,600final evaluations per first hand. No model timing cutoff changes choices.
- No unrelated fresh start/cash-poor/other-specialty or extra-opportunity study in this pass. Candidate missing/rejected/timed-out cases remain results.

## Measurements and verification

Earned R/full/partial/zero per opportunity; R20 release/cycle if reached; actual cards, finite use, direct rewards, publisher isolation; total and productive cycles/cash/arrears; matched release/calendar effects; first-hand differences; model estimates versus actual grades and observed calculation time. Preserve exact sampled IDs and ranking summaries for independent Python replay of all modeled decisions. Audit sampler against source law, including retained/exhausted exclusions, Pass reuse, category weights, definition sort and scoring synergy. Compare lower128prefix sensitivity diagnostically only; do not select a different policy after results.

Relevant checks: independent model/policy and actual-result audit; exact frozen-source control reproduction; representative fresh-process replays for both planner types, selecting the best and worst earned totals across their two seeds (ties use4521). Exact state/RNG Studio-only cold Continue from the strongest completed candidate, at most80commands/one more release, with Briefs skipped. If a command is rejected, retain/replay/reduce its prefix (max1000reduction commands); no reduction for mere low grades. Runtime reward regression evidence from CB2 is reusable only if source equality holds; do not claim a fresh suite run.

## Stop and handoff

Stop after all six declared cases and verification; report weak or mixed effects honestly. Do not change rewards, thresholds, draw rules or bankroll to improve results. Save dated finding, review, source identities, exact commands/failures and recommendation. Update only the existing Crown DESIGN TODO paragraph after reread, with byte preservation for other entries. New canonical adoption still requires explicit scope/terms approval and structural/migration/UI/export gates. A policy result does not remove those gates.
