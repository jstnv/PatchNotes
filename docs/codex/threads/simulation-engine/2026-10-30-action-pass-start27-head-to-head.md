# Action Pass Budget with a 27-Scope Action start — 2026-10-30

**Status: RESEARCH / candidate comparison.** The 27 Scope is the **starting owned Feature supply**, using the exact active, parent-connected Action incumbent roster `incumbent-active-27-v1`. It is not an engine capacity cap or a new project requirement. The project still requires 30 Scope, and normal Store acquisition can raise available Scope above 27. No player-start or Pass Budget formula is approved for production.

## Controlled setup

- New isolated version: `simulators/action-pass-budget-start27-20261030-v5`, forked from the earlier career trial. Only its `project/` copy grants the 27-Scope roster to a fresh Action Studio. The common policy skips opening starter purchases for this experimental grant; later Bank, contract, research, ordinary seven-candidate Feature/Pass hands, Beta, cash, calendar, sales and review paths are shared across arms.
- Three arms: 1/K6, 2/K8, 1/K5 generous reference. The budget rule is independent per Design/Alpha phase, starts fresh at phase transition, generates on Feature activation and spends on Pass activation.
- Five matched seeds: 4417, 1104, 90210, 7, 20261030; eight releases per arm; 500-command cap. Same Studio recipe and policy apart from the formula. The 27-Scope grant is common to every arm. This is a subsidized starting-roster counterfactual, not a normally purchased fresh player roster.
- Canonical baseline identity `b92167043abdfedb734455656510bdad5a0211b98ac14331294b2a27715eb396`; candidate identity `0e412e94efa4567523a3647543b8ebd234248d34deb751c51083fb9480d09586`; no baseline drift. The source snapshot uses the previously hash-matched baseline mirror for faster capture, with exact provenance retained.
- Run bundle: `sims/action-pass-start27-matched-v5-20261030-b`. All 15 cases completed, with telemetry and replay tapes. Numerical summary: `action-pass-career-combined.json` in that bundle. A 1/K6 smoke case completed three releases before the matched run.

## Results

Early means releases 1–2; middle 3–5; later 6–8. Later is **not** the exact optimized 24-Primitive-Feature build.

| Formula | 8-release careers | Mean Review early / middle / later | Mean Review all 40 releases | Peak Review | Careers reaching 30 Scope | Mean final cash | Mean cycles to 8 releases | Review ≥8.0 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1/K6 | 5/5 | 4.02 / 4.11 / 4.63 | 4.29 | 7.4 | 5/5 | $7,405 | 86.4 | 0/5 |
| 2/K8 | 5/5 | 3.47 / 3.57 / 4.04 | 3.72 | 5.4 | 4/5 | $6,702 | 79.0 | 0/5 |
| 1/K5 | 5/5 | 3.95 / 4.04 / 4.61 | 4.23 | 6.0 | 4/5 | $6,116 | 90.2 | 0/5 |

| Seed | 1/K6 mean Review | 2/K8 mean Review | 1/K5 mean Review | First 30-Scope release: 1/K6 / 2/K8 / 1/K5 |
|---|---:|---:|---:|---|
| 4417 | 3.92 | 3.38 | 4.01 | 7 / none / 7 |
| 1104 | 3.79 | 4.00 | 4.63 | 6 / 6 / 6 |
| 90210 | 4.99 | 3.67 | 4.50 | 2 / 7 / 6 |
| 7 | 4.26 | 3.86 | 3.74 | 5 / 6 / none |
| 20261030 | 4.46 | 3.70 | 4.28 | 2 / 8 / 4 |

All arms now sustain the eight-release target, unlike the prior normal 12-Scope-start policy screen, where all 15 careers stalled at 4–6 releases with at most 18 played Scope. That comparison changes the starting roster, so it measures the effect of the **whole 27-Scope grant plus subsequent career paths**; it does not isolate a pure Scope multiplier.

**1/K6 is the strongest provisional candidate under this declared 27-Scope start and policy.** It beats 2/K8 on eight-release mean Review in four of five matched seeds, reaches 30 Scope in every seed, and has the highest final cash despite taking 7.4 more cycles on average to finish eight releases. The 1/K5 generous reference adds opportunities but does not improve the pooled Review or cash over 1/K6 here; it takes 3.8 more cycles than 1/K6. The sample is small, and formula-dependent draws alter later research and market histories, so this is not an isolated per-card treatment effect.

The result still does **not** validate an 8.0 target: no career reached 8.0. Later runs owned 19–28 Features but did not replay the exact ordered 24-Primitive optimal build. The earlier forced 24-Feature draw screen favored 1/K6 but was conditional on that ideal build; this fresh-career result supplies stronger progression evidence, not a guarantee of optimized play.

## Reproduce and next checks

- Config: `action-pass-start27-matched-2026-10-30.json`.
- Summary: `node docs/codex/threads/simulation-engine/combine_action_pass_careers.mjs docs/codex/threads/simulation-engine/sims/action-pass-start27-matched-v5-20261030-b`.
- Future decision work: more paired seeds, review of paid versus free 27-Scope access, per-phase actual Pass activation telemetry, and a longer legal career capable of the exact optimized build. Do not adopt a 27-Scope player start or Pass formula from this five-seed experiment alone.
