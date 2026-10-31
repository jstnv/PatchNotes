# Action Pass Budget paired draw screen — 2026-10-30

**Status: RESEARCH / conditional simulation.** No canonical gameplay or Scope rule was changed. The three formulas are not implemented in production. This is a source-pinned, paired random-draw screen, not a fresh-Studio career simulation or a release acceptance test.

## Source and fixed inputs

- Baseline: the previously exhaustively selected 24 Primitive Features, exact six hands, 35 printed Scope played against the existing 30-Scope requirement, post-Feature G27/S10/T46/D35.
- Printed Feature Core: Design hand totals 19, 13, 18; Alpha 11, 11, 17. Each phase receives its own starting allowance and `floor(cumulative printed Feature Core / K)`.
- Four renewable Passes, each +2 printed Core in one category. Four matching Passes receive the current 1.5 specialization multiplier. Action standards are G40/S26/T40/D26. Review uses the current ratio/dispersion calculation, neutral variance, zero Bugs.
- 100,000 paired integer seeds, 25/25/25/25 draw priorities, seven candidate maximum, renewable Pass draws with replacement. Each arm uses the same seed and policy: after all fixed Features, draw up to the budget and seven-candidate limit; play the available four-Pass hand with the highest immediate displayed Review, breaking ties by remaining Core deficit; refill while budget permits. No redraw.
- Reproduce with `node docs/codex/threads/simulation-engine/action_pass_budget_draw_screen.mjs`; complete numerical output is in `action-pass-budget-draw-screen-2026-10-30.json`.

## Budget timing and complete-hand capacity

The prefixes below are generated allowances *before* any Pass spend. Early/middle/optimized here mean after the first, second, and third fixed Feature hand **in each phase**, not separate Studio careers. A four-Pass hand needs four available activations; budget below four can still permit mixed Feature/Pass hands, which this screen does not model.

| Formula | Design budgets after hands 1/2/3 | Alpha budgets after hands 1/2/3 | Full four-Pass hands fundable at early D/A | Middle D/A | Optimized D/A |
|---|---:|---:|---:|---:|---:|
| 1/K6 | 4 / 6 / 9 | 2 / 4 / 7 | 1 / 0 | 1 / 1 | 2 / 1 |
| 2/K8 | 4 / 6 / 8 | 3 / 4 / 6 | 1 / 0 | 1 / 1 | 2 / 1 |
| 1/K5 | 4 / 7 / 11 | 3 / 5 / 8 | 1 / 0 | 1 / 1 | 2 / 2 |

Thus 2/K8's extra starting Alpha activation does not fund an additional complete Pass hand at the first or second Feature checkpoint. Both head-to-head arms can fund the theoretical 8 Design / 4 Alpha Pass split at the optimized checkpoint. 1/K6 leaves one more Design and one more Alpha budget than 2/K8 at that point. 1/K5 permits a fourth complete Pass hand in Alpha.

## Conditional post-Feature draw results

| Formula | Passes played Design/Alpha | Mean Review | Median | 10th–90th percentile | Review ≥8.0 | Mean G/S/T/D |
|---|---:|---:|---:|---:|---:|---|
| 1/K6 | 8 / 4 | 7.15 | 7.1 | 6.6–7.8 | 4.963% | 34.93 / 18.42 / 50.69 / 39.04 |
| 2/K8 | 8 / 4 | 6.98 | 6.9 | 6.5–7.6 | 2.316% | 34.14 / 17.36 / 51.32 / 40.18 |
| 1/K5 | 8 / 8 | 7.48 | 7.4 | 6.9–8.2 | 16.490% | 36.93 / 20.02 / 53.23 / 41.12 |

Within this **conditional draw screen**, 1/K6 is the stronger head-to-head candidate: it grants the same complete Pass-hand capacity at early and middle checkpoints, and its one extra available candidate in each optimized phase increases G/S targeting and the 8.0 frequency. 1/K5 is a useful generous reference, but its extra four Pass activations and higher Review are not, by themselves, a healthier progression result. Even it misses 8.0 in 83.51% of these no-redraw draws; the previous 12-Pass result was an ideal sequence, not an ordinary-draw guarantee.

## Boundaries before a gameplay winner

This screen **forces all 24 Features and their exact hands**, so it does not measure legal Store acquisition, Feature candidate draws, retained mixed pools, Feature/Pass interleaving, redraw costs, project cash/calendar, Bugs/Beta, launch sales, or full early/middle/optimized careers. Pass-only candidates are drawn after Feature exhaustion. Greedy immediate-Review selection is one declared policy, not optimal play over future hands. The seed generator is in the retained script; it is not the Godot RNG. Therefore these Review figures are research-model outputs, not actual game releases.

The current `DevelopmentActions.valid_pool()` requires **exactly seven** Alpha candidates. Under a hard Pass Budget cap, the modeled optimized Alpha pool can be shorter after Pass play, so current production finalization would reject the release. A future isolated variant must reconcile this candidate-size rule and cover ordinary weighted Feature draws and fresh Studio careers before selecting a formula for adoption. No formula is approved here. The provisional 1/K6 advantage does not settle overall balance health.
