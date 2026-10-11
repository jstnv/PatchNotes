# Paid-Feature education and Bank finding — 2026-10-11

**Status: bounded evidence; no balance ruling or gameplay change.** The [predeclared plan](2026-10-11-spending-bank-study-plan-v1.md) tested current Store, education and Bank rules. A private [Banking simulator variant](simulators/education-bank-quote-v1/variant.json) added only a read-only Studio observation of the existing `$500/12-month` quote after two releases. Its baseline identity is `4162c70c12bf3d6af7587e5879759b54b127280c4ff224f4970ed7f8c2b895df`; candidate identity is `30ad2ea73e5fb0986f04cddfd39f28bee80dc762260a96e033e0d4c5c4f4876f`. The sole delta is `scripts/simulation/campaign_session.gd`; canonical gameplay was not edited.

## Inputs, source and exact runs

- Dirty `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python 3.12.14; runner SHA-256 `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`. Policy v3 SHA-256 `f7d51ef9705f2b50249ff51c2d34cead09b5edb4271be5e615c2071f1a0a7673`.
- [Canonical six-case run](simulations/spending-bank-canonical-prefix-v3r2/run-report.json), frozen source `dcaafa5d97e1b12dbc5e8abcbf5f8e433d288deb708a161048518beca6da424f`; [variant six-case run](simulations/spending-bank-variant-prefix-v1/run-report.json), frozen source `3fed02fde17bbff091a7444dcc57053b05bae9fca4f7da67a4485634b53f529b`; [four-case continuation](simulations/spending-bank-variant-continuation-v1/run-report.json) from the variant's exact Graduate Studio envelopes. Source identities differ by the observation-only delta and copied policy; all six canonical/variant final state digests, cash and command counts match.
- Exact commands from repository root, with `python` meaning `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe` and `<godot>` meaning `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`:

```text
python tools/simulate.py run --config docs/codex/threads/banking-system/simulations/spending-bank-prefix-v3.json --output docs/codex/threads/banking-system/simulations/spending-bank-canonical-prefix-v3r2 --godot <godot> --timeout 240
python tools/simulator_variant.py create --id education-bank-quote-v1 --owner banking-system --output docs/codex/threads/banking-system/simulators/education-bank-quote-v1
python tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v1 --config docs/codex/threads/banking-system/simulations/spending-bank-prefix-v3.json --output docs/codex/threads/banking-system/simulations/spending-bank-variant-prefix-v1 --godot <godot> --timeout 240
python tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v1 --config docs/codex/threads/banking-system/simulations/spending-bank-continuation-v1.json --output docs/codex/threads/banking-system/simulations/spending-bank-variant-continuation-v1 --godot <godot> --timeout 240
python tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/spending-bank-variant-prefix-v1 --case <control-4417 | dropout-4417 | graduate-4417> --output docs/codex/threads/banking-system/simulations/spending-bank-replay-<case>-v1 --godot <godot> --timeout 240
python tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/spending-bank-variant-continuation-v1 --case <graduate-4417-borrow-500-12 | graduate-90210-borrow-500-12> --output docs/codex/threads/banking-system/simulations/spending-bank-replay-<case>-v1 --godot <godot> --timeout 240
python tools/compare_simulations.py --bundle docs/codex/threads/banking-system/simulations/spending-bank-variant-continuation-v1 --left graduate-<seed>-no-loan --right graduate-<seed>-borrow-500-12 --output docs/codex/threads/banking-system/simulations/spending-bank-comparison-<seed>-v1
```

The [first policy](simulations/spending_bank_policy_v1.gd) failed GDScript type inference; the [v2 policy](simulations/spending_bank_policy_v2.gd) used an incorrect copied-policy self-path. Their [failed run](simulations/spending-bank-canonical-prefix-v1/run-report.json), [snapshot race](simulations/spending-bank-canonical-prefix-v2/run-report.json), [v2 run](simulations/spending-bank-canonical-prefix-v2r2/run-report.json) and [v3 snapshot race](simulations/spending-bank-canonical-prefix-v3/run-report.json) are retained. They produced no successful cases and were not treated as favorable evidence. Version 3 fixed only the policy path. All five selected fresh-process replays passed, including both deliberately rejected Bank requests; all telemetry samples and final states reproduced. The two [paired reports](simulations/spending-bank-comparison-4417-v1/comparison.md) and [90210](simulations/spending-bank-comparison-90210-v1/comparison.md) validate equal initial Studio state/RNG and report `both_cases_completed=false` because borrowing was rejected.

Focused verifiers on the private variant project used a separate [profile and logs](simulations/spending-bank-variant-verifiers-v1/result.json): Godot `--headless --path <variant project> --import`, then `--script res://scripts/debug/verify_campaign_session.gd` and `--script res://scripts/debug/verify_finance_observation.gd`. All three exited 0. Campaign session reported **81 steps, 55 reentrant checks, 0 failures**; finance observation reported **108 checks, 21 comparisons, 0 failures**. Logs retain the environment certificate-store message and the finance verifier's ObjectDB exit warning; neither was a test failure.

## Measured routes

Fresh legal Action/Fantasy starts used four visible-order hands per phase and seeds 4417/90210. No trait, Dropout and Graduate started at **$5,700/$5,800/$6,000** respectively because unused trait points generated distinct startup receipts. These are not the $5,500 bare baseline. All six first releases occurred at cycle 13 (Reviews 4.0/5.8 by seed). `recorded_sounds` was admitted at cycle 13 for $850 down, then researched in one productive action for $765 after the current 10% Research discount; it was owned by the second launch. The second release occurred at cycle 27; its Graduate Reviews were 5.5/4.7. No route used a Contract, hire, loan, extra Store item or artificial cash.

| Cohort | c27 cash, seed 4417 / 90210 | Lowest command-boundary cash, 4417 / 90210 | c26 first education due | c27 arrears / financial block |
|---|---:|---:|---:|---:|
| No trait | $1,375.48 / $4,251.70 | $847.51 / $1,490.00 | none | $0 / no |
| College Dropout | $1,404.80 / $4,281.02 | $947.51 / $1,590.00 | $70.68 fully paid | $0 / no |
| Graduate | $1,392.75 / $4,268.97 | $1,147.51 / $1,790.00 | $282.73 fully paid | $0 / no |

The Graduate first due paid $133.33 interest plus $149.40 principal at c26, with credit 609/615 at c27 and no late history. Store spending reduced the weak seed's cash cushion but did not cause arrears or a blocked action in this finite route. The extra Research action moves second launch from the earlier no-Store fixture's c26 to c27; different frozen source and actions prevent treating that earlier cash as a matched counterfactual. First-game release remains within the roughly 14-cycle target; this route does not reproduce a delayed 6.2-rated first game or test bankruptcy.

## Bank gate at the matched Studio boundary

The two Graduate pairs each copied one **byte-identical** c27 Studio envelope into no-loan and request-loan arms, with identical RNG. The no-loan arms completed a third release at c40 (22 commands; cash $3,287.90/$3,800.48). Each loan arm submitted exactly one current `$500/12-month` quote and stopped on `Financial action rejected` at zero cycle, leaving its original cash/state unchanged. Rejection is an observed outcome, not a simulation infrastructure failure. The continuation bundle therefore correctly reports overall `ok=false` and no completed loan/control comparison.

| Graduate seed | Older / latest settled monthly sales | Sales basis | Monthly rent + education obligation | Capacity / eligible maximum | c27 cash |
|---|---:|---:|---:|---:|---:|
| 4417 | $55.95 / $27.97 | $27.97 | $500 + $282.73 | $0 / $0 | $1,392.75 |
| 90210 | $181.82 / $97.90 | $97.90 | $500 + $282.73 | $0 / $0 | $4,268.97 |

The quote's proposed schedule would have started at c30, with a $46.67 maximum installment and $32.50 total interest, but **no loan was issued**. Under the LOCKED capacity rule, recent settled sales must exceed live rent and obligations before any quarter-surplus capacity exists. Having cash on hand, a recent release or positive sales is insufficient. This preserves the approved lending gate; it does not show whether the $500/12 contract is useful when eligible.

## Recommendation and remaining uncertainty

**DESIGN review needed; no gameplay adoption candidate.** Keep the current locked Bank capacity and education schedule and ACTIVE/TRIAL credit weights. Before evaluating loan benefit or changing the gate, design a separate predeclared legal path that obtains two sufficiently strong consecutive settled sales months at a Studio boundary, then compare eligible borrowing with no borrowing from the exact same state/RNG. The current two seeds and policy should remain as retained ineligible controls. A future route should also test a truly delayed first release if the question is the original 14-cycle bankruptcy pressure. Any revised simulator rule needs a new Banking-owned version and its own legal starting prefix. The read-only quote observation is a study aid, not a gameplay task to adopt.
