# Banking reserve route finding — 2026-10-11

**Finding:** The Bank can fund one queued $855 Scripted AI Research action from a legal $833.77 Studio balance. A $1,000/12 loan then completes a deliberately small second game in the two-hand test, but that game launches one cycle later with Review 1.9 versus the no-loan control's 2.1, and ends with $666.64 principal outstanding. The $500/12 arm is blocked before launch at cycle 22 with $176.92 in newly due rent/Bank arrears. These routes do not establish a beneficial loan balance or authorize a rule change.

## Authority, source and setup

- [Predeclared v1 plan](2026-10-11-reserve-route-plan-v1.md) fixed two legal seed90210 cohorts, admission lists, selected loans, one Research cap, one-hand fixture and limits. [Predeclared v2 plan](2026-10-11-reserve-route-plan-v2.md) changed only the fixture to two hands per phase, keeping the same fork, loans, Research rule, seed and bounds.
- `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree at planning. Private `education-bank-quote-v3` canonical base `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`, v2 ancestor `ead6f694065a8922d7e8269bb87b37513b14292ea7bd9f9738e46b81411b4ff2`, candidate `890781bc0c39c8a2e89c7440747d4724b8dcb99f3527e7a32c26e355b6058c32`. Only read-only Bank quote observation differs from its parent; no canonical gameplay edit. Admission frozen source `f251c09d0895dfe4bd00918fd19e59e375969a913fe70f01543ed330d8340454`; both pair runs frozen source `a620a3cb6abe78f64ab23d8d0ef8b41febba9208875029fb5cc36747ed0e1b6d`, with identical policy SHA `23f9ec13289a74b1383807b949cca3627d7ba730e800954db90e6bdbe515eece`. The policies differ only by their declared hand configs. Runner SHA `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`.
- Python 3.12.14 at `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`; Godot 4.7.1 at `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`, SHA `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- The two c16 Studio checkpoints came from the earlier legal first-game/c16 run. First game released at c13; actual settled sales at c14/c16 were $2,265.73/$2,958.04. No trait started with $5,700 and Graduate with $6,000 because each had a separate unused-point receipt; bare $5,500 is untested here. The two new five-admission cases were accepted and intentionally stopped at `command_bound`, with $833.77 cash and no overdue bills. Graduate's new Multi-Directional Scrolling admission had its owned Scrolling prerequisite; the earlier rejected 16-Bit Music case remains retained in the previous study. The two cohorts differ in queued fifth Feature, but their outcomes through c24 happened to match because Graduate education dues begin at c26.

## Exact runs and checks

From repository root, `$py` and `$godot` denote the exact executables above. All folders below were new. Each simulation used the isolated runner and `--timeout 240`:

```powershell
& $py docs/codex/threads/banking-system/simulations/build_reserve_route_v1.py admit
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/reserve-admit-v1.json --output docs/codex/threads/banking-system/simulations/reserve-admit-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_reserve_route_v1.py pairs
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/reserve-pairs-v1.json --output docs/codex/threads/banking-system/simulations/reserve-pairs-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_reserve_two_hand_v2.py
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --config docs/codex/threads/banking-system/simulations/reserve-two-hand-v2.json --output docs/codex/threads/banking-system/simulations/reserve-two-hand-run-v2 --godot $godot --timeout 240
```

The [admission batch](simulations/reserve-admit-run-v1/run-report.json) returned overall `ok=false` because both valid Studio prefixes intentionally stopped at five commands, short of two releases. The [one-hand batch](simulations/reserve-pairs-run-v1/run-report.json) returned `ok=true` with all six second releases. The [two-hand batch](simulations/reserve-two-hand-run-v2/run-report.json) returned `ok=false`: four completed, two retained `rejected_policy_action` cases. No case timed out. All four one-hand and four two-hand [paired reports](simulations/reserve-two-hand-compare-control-1000-v2/comparison.md) passed exact same-source/initial-state/RNG and telemetry consistency; each report is named `reserve[-two-hand]-compare-<control|graduate>-<500|1000>-v<1|2>` under `simulations/`. The $500 two-hand reports correctly mark `both_cases_completed=false`.

Representative fresh-process exact replays succeeded with telemetry verification for one-hand control no-loan, control $1,000 and Graduate $500, and two-hand control no-loan, control $1,000 and control $500 accepted/rejected tape. The latter replay verifies its recorded rejected command and unchanged state, not an independent policy explanation. [Fresh-confirmed reduction](simulations/reserve-two-hand-reduced-control-500-v2/reduction-run.json) reproduced the $500 cycle22 development rejection with the same request/result/state signature from the shortest preceding Studio checkpoint suffix. The unchanged v3 private project had six relevant focused verifier runs in the preceding [liquidity finding](2026-10-11-liquidity-finding-v1.md); none were rerun for these policy-only changes.

For a pair reporter and representative replay/reduction, the exact command forms were:

```powershell
& $py tools/compare_simulations.py --bundle docs/codex/threads/banking-system/simulations/reserve-two-hand-run-v2 --left control-90210-no-loan --right control-90210-borrow-1000-12 --output docs/codex/threads/banking-system/simulations/reserve-two-hand-compare-control-1000-v2
& $py tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/reserve-two-hand-run-v2 --case control-90210-borrow-1000-12 --output docs/codex/threads/banking-system/simulations/reserve-two-hand-replay-control-90210-borrow-1000-12-v2 --godot $godot --timeout 240
& $py tools/reduce_simulation.py --bundle docs/codex/threads/banking-system/simulations/reserve-two-hand-run-v2 --case control-90210-borrow-500-12 --kind rejection --output docs/codex/threads/banking-system/simulations/reserve-two-hand-reduced-control-500-v2 --godot $godot --timeout 240 --max-commands 35
```

## Measured outcomes

Both $500/12 and $1,000/12 quotes were eligible at c16, with first due c18; no overdue bill or active loan at the fork. Monthly capacity was $527.97 without a trait and $457.28 for Graduate after its $282.73 education overlap reserve. The Bank's capacity test uses actual recurring settled sales less rent and live obligations; it does not include optional queued Research. One FIFO Research payment cost $855 and one productive cycle. The no-loan arm could not afford it at $833.77, while both borrowed arms paid it and owned Scripted AI before game two. The fixed visible-order fixture did not establish that this owned card was drawn or played in the second game; do not attribute a Review difference to Scripted AI alone.

| Policy and arm | Second release | Launch | Review | Final cash | Outstanding principal | Arrears / credit |
|---|---|---:|---:|---:|---:|---|
| One hand, no loan | yes | c20 | 0.5 | $862.16 | $0 | $0 / 609 |
| One hand, $500/12 | yes | c21 | 0.0 | $614.24 | approx. $416.66 | $0 / 609 |
| One hand, $1,000/12 | yes | c21 | 0.0 | $1,021.31 | approx. $833.32 | $0 / 609 |
| Two hands, no loan | yes | c23 | 2.1 | $1,126.84 | $0 | $0 / 609 |
| Two hands, $500/12 | **no** | stopped c22 | unavailable | $0 | $416.66 | $176.92 / 594 |
| Two hands, $1,000/12 | yes | c24 | 1.9 | $775.30 | $666.64 | $0 / 612 |

Each row held for both no-trait and Graduate seed90210 cohorts through its endpoint; education grace explains the identical early obligations. The $500 two-hand endpoint had $131.08 c22 rent and $45.84 c22 Bank installment unpaid; the rejected development action cannot advance the calendar safely. Its historical first game's 5.8 Review must not be mislabeled as game-two Review. The $1,000 two-hand arm had paid $35.00 interest and ended with **$108.66 debt-adjusted cash** ($775.30 less $666.64 principal), compared with no-loan $1,126.84 at c23; endpoint calendars differ. At the common c23 boundary, the no-loan arm had $1,126.84 after release and the loan arm had $184.32 before its c24 release. The loan arm's sampled cash low was $184.32 versus $126.84 for no loan, but its c24 debt position and lower Review show no demonstrated advantage. One-hand Reviews were too low to be useful balance evidence. No tested two-hand game approached the first game's 5.8 or the delayed 6.2 pressure target.

## UI and design interpretation

Current [Bank quote text](../../../../patch-notes/scripts/ui/studio_finances.gd) shows settled-sales basis, rent/required recurring obligations, capacity, full installment schedule, first-due confirmation and early-payoff math. Current [Feature Store](../../../../patch-notes/scripts/ui/feature_store.gd) shows FIFO Research due, down payment, and [spending guidance](../../../../patch-notes/scripts/finance/feature_spending_guidance.gd) including known Feature play, projected rent, scheduled Bank and education dues. The optional Research queue is not a recurring Bank obligation; this source review found no missing Bank payment disclosure requiring immediate implementation. Human comprehension of moving between those screens remains untested.

**Recommendation:** keep Bank and Store rules unchanged. The loan creates an immediate legal Research option, yet this fixed route has no measured quality/cash benefit and exposes a real $500 debt/rent failure. A future design study needs a production policy with meaningful Review, actual card draw/play trace, and matched cash at a common post-release month before any Bank amount, capacity or warning change is proposed. Source-pinned headless success is not balance approval or exported/human acceptance.
