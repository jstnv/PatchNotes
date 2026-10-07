# Feature Store findings v5 — conditional purchase timing

Date: 2026-10-06 (America/Los_Angeles). **Read-only native timing pilot.** This finding recommends further study; it does not approve a Store rule, candidate card, price, fee, or gameplay implementation.

## Question and source

After the [immediate-purchase screen](FINDINGS-v4-immediate-purchase-screen.md), can a legal cash reserve or an actual settled stronger release postpone a candidate purchase without losing all card access? The shared Task 2 handoff asks for a wider comparison; this thread ran a bounded pilot to refine that question, not to claim the full handoff complete.

Branch `main`, HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after. [Predeclaration](sim-v3/predeclaration.json) records the exact 593 tracked source-file hashes, driver hash `ada395a96711ee179411caa14486e1780bd93ac7ec82413fac4d532a2615bc5b`, source/route plan and policy thresholds. Relevant hashes: `alpha_phase.gd` `81a1d9b591d42e1863231de614c7def5d3b6443ba4bdfce612761c2558cca903`; `run_state.gd` `ddae87856f7d5bd4dbbd424a9774e6deb420390a1ce6a9ca384e98f0a9f33b84`; `main_menu.gd` `4173ab675110178ce15b3277831c6f731890950901591183b727b49f7d1250c6`; live Store ledger `547a1cbc408ac263f3cf3c3a9e96e8667f33993e211bbb492937716c7df414cf`. [Run report](sim-v3/run-report.json) gives every command, exit, isolated profile, trace hash, and source comparison. All output remains in this thread's folder.

## Predeclared simulation

- 21 paired routes: Action/ordinary, Action/synergy, Adventure/ordinary; seed 1104; no purchase plus Sub-Areas and Background Music under immediate, full-next-project reserve, and settled-stronger timing. Early Game 1 budget and three later 18-action budgets, four-release horizon or first legal block. Native Ironclad and eligible SideStreet, current finite pools, native draws/committed plays, $500 monthly rent and exact-cent sales/settlement. No loans, campaigns, free waits, fixed-action cash overlays, or invented releases.
- All starts follow the current MainMenu background/review/confirmation, with Family Funding preview, no secondary previews and the once-only $200 unused-point financing receipt: genuine **$5,700** cash. The legacy $5,500 cohort is outside this pilot.
- Process-local candidate shadows only: Sub-Areas Alpha Graphics 3 / Design 2 / Scope 2, Levels parent, $1,700 trial base; Background Music Alpha Sound 3 / Scope 1, Music parent, $950 trial base. These prices are **OPEN**. The native current later-card fee is temporarily $0; the proposed $90/$50 fees are not simulated or approved. Missing Primitive parents are bought natively and separately; no parent refund on a failed child.
- **Immediate:** attempt the complete chain after Game 1 and its normal Contract actions. **Reserve:** after each completed Game and Contract actions, buy only if settled cash covers that visit's quoted missing-parent-plus-child chain, nine $500 rent bills for the next 18-cycle game ($4,500), and a $500 play-cost allowance. This is a conservative policy threshold, not a bank reserve or guaranteed full project cost. **Settled stronger:** after Game 2 or 3, buy if any post-Game-1 release has Review at least 6.0 and at least 1.0 above Game 1, and that *same release* has positive actual settled sales. No forecast or free waiting.

## Native outcome

| Arm | Four releases | Candidate actually purchased | Interpretation |
|---|---:|---:|---|
| No purchase | 3/3 | 0/3 | Baseline. |
| Immediate candidates | 1/6 | 6/6, after Game 1 | Five routes stopped financially after Game 2. |
| Full-next-project reserve | 6/6 | 0/6 | Safe in this sample **by abstaining**; it provides no candidate benefit within four releases. |
| Settled stronger | 6/6 | 4/6, after Game 3 | Four Action routes bought, supplied, drew and played the card in Game 4 with no arrears. Both Adventure routes abstained because no release met the Review gate. |

The Action delayed purchases occurred at cycle 51 for Sub-Areas and cycle 52 for Background Music (the latter needed Music parent). At the Game 3 Store visit, Action/ordinary had $5,359.56 settled cash, a $1,190 Sub-Areas child quote or $1,400 Music-plus-Background-Music chain, and $8,412.57 of actual settled sales for its qualifying earlier release. Action/synergy had $5,264.74 cash and $8,769.22 settled for its qualifying release. The settled amount is a release ledger amount, **not** extra spendable cash beyond the reported balance. The earlier Game 2 Store visit had no settled sales for the qualifying release, so the policy did not buy there.

| Action policy / delayed card | Game 4 Review vs no purchase | Game 4 release cycle vs no purchase | Final cash vs no purchase | Final arrears |
|---|---:|---:|---:|---:|
| Ordinary / Sub-Areas | 8.4 vs 7.0 | 69 vs 68 | $6,190.67 vs $7,380.67 | $0 |
| Ordinary / Background Music | 7.5 vs 7.0 | 70 vs 68 | $5,384.66 vs $7,380.67 | $0 |
| Synergy / Sub-Areas | 7.8 vs 7.3 | 69 vs 68 | $9,067.87 vs $10,257.87 | $0 |
| Synergy / Background Music | 8.4 vs 7.3 | 70 vs 68 | $8,350.80 vs $10,257.87 | $0 |

All four delayed Action candidates entered Game 4 supply, appeared in a native hand, and were committed once. Sub-Areas' final-cash gap exactly equals its $1,190 trial quote at this horizon; its one extra Store cycle delayed Game 4 by one cycle. Background Music required two purchase cycles and left a larger cash gap. The study ends at Game 4 launch, before the full subsequent sales settlement, so these are **not** net-return estimates. Review differences include changed hand composition, cycle alignment and RNG consumption; they are not isolated card coefficients.

## Verification, revision from first pilot, and recommendation

The [audit](sim-v3/audit.py) passed: 21/21 Godot exit 0 and valid, zero unexpected errors/discrepancies, 21 raw-trace hashes, genuine startup cash, final finance cash equality, nonzero native ledger/row checks, stable HEAD and driver, and no change among 593 tracked source files. [Summary CSV](sim-v3/summary.csv) records each route's release cycles, reviews, cash low, arrears, credit, decision quotes/cash, purchase point, draw and play. Compressed raw traces and logs are in [sim-v3](sim-v3/).

An earlier [sim-v2](sim-v2/) exploratory policy screen showed that a $1,500 short-horizon reserve bought immediately in all six candidate routes, while a condition requiring the *latest* release to settle at its immediate post-release visit never bought. Those triggers were non-discriminating, so the corrected v3 thresholds above were declared before its routes. One v2 route initially hit an output-file open failure and a stale pilot path; its serial successful rerun and original failure are both retained in that folder. **V3 is the basis for the table above.**

**Candidate recommendation:** investigate a settled-stronger late purchase as the next bounded design option, especially for a single parent-owned Sub-Areas pilot. It preserved four-release access and produced a played Game 4 candidate in these Action routes. Do not implement the threshold from this seed. The conservative reserve protected cash only by declining every purchase, and immediate buying remained fragile. Next evidence should cover additional seeds, genuine $5,500 versus $5,700 starts, parent-missing specialties, representative live-node controls, Game 4's actual later settlement and at least one subsequent project, plus sensitivity to candidate play fees and stronger-release threshold. Review whether Sub-Areas intentionally duplicates Levels before any card approval. The shared Task 2 read-only handoff remains open.
