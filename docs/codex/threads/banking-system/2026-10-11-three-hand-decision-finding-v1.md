# Banking three-hand decision finding — 2026-10-11

**Bounded result:** Under the current player-selected loan rules, an eligible $2,500/12-month loan did enable a real second release that the matched no-loan and $1,000 arms could not afford. The financed Scripted AI Feature was **resolved in committed Game2 production**, not merely owned. Both $2,500 arms released at c27 with Review 3.8, below the predeclared 4.0 adequacy screen. A legal one-cycle continuation recorded $1,356.64 actual Game2 sales settlement at c28 and no arrears. Debt-adjusted cash remained only $215.40 without a trait and **negative $350.06** for Graduate. This supports retaining selectable loans as an option, not a $2,500 default or a balance increase.

## Predeclared scope and provenance

- [Three-hand plan](2026-10-11-three-hand-decision-plan-v1.md) fixed two seed90210 legal c16 Studio forks, no-loan/$1,000/$2,500 selected 12-month terms, one affordable FIFO Research maximum, three visible-order Action/Fantasy hands per phase, six arms, 50-command/240-second limits and a 4.0 experimental Review screen. [Settlement continuation plan](2026-10-11-three-hand-settlement-plan-v1.md) separately fixed exactly one Game3 setup action from each completed c27 Studio checkpoint to observe c28 actual sales and due bills.
- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. The unchanged Banking private `education-bank-quote-v4` candidate has original canonical base `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`, v3 parent `890781bc0c39c8a2e89c7440747d4724b8dcb99f3527e7a32c26e355b6058c32`, current candidate `c548531452bd2990792226213aee7b3485be588b59874c4ec0c6983bb1449b1d`. Its only project difference is read-only Bank quote observation. The two new runs froze source identities `180696e355cca1d8a61b8c0fb72bdd3726cda182fa37d72a36b5d992392d31cc` with injected pair policy SHA `bb0ff08d17259242a2e6ac88f81bcc6c4410da9556755e2632f36e674330d321`, and `c5485314…` with the existing finite fixture. Runner SHA `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`.
- The [prior v4 prefix finding](2026-10-11-larger-offer-finding-v1.md) regenerated legal first releases at c13, c16 two-positive-actual-settlement Studio checkpoints and five legal Store admissions. V3/v4 state, RNG, cash and command counts matched at c13/c16/after admissions. Both current exact fork balances were $833.77, with no overdue bills, actual settled sales $2,265.73/$2,958.04 at c14/c16, and eligible selected $1,000/$2,500 quotes. The first game Review was 5.8. Starting ledgers were $5,700 no-trait and $6,000 Graduate because of separate unused-point receipts; the bare $5,500 case was not tested. Quote monthly capacity was $527.97 no-trait and $457.28 Graduate after its $282.73 education overlap reserve. The $2,500 schedule had a $233.34 maximum installment and $162.50 total scheduled interest, first due c18.
- Python 3.12.14: `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`. Godot 4.7.1: `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`, SHA `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

## Exact runs and validation

From repository root, with `$py` and `$godot` set to the executables above:

```powershell
& $py docs/codex/threads/banking-system/simulations/build_three_hand_decision_v1.py
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/three-hand-decision-v1.json --output docs/codex/threads/banking-system/simulations/three-hand-decision-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_three_hand_settlement_v1.py
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/three-hand-settlement-v1.json --output docs/codex/threads/banking-system/simulations/three-hand-settlement-run-v1 --godot $godot --timeout 240
```

The [three-hand bundle](simulations/three-hand-decision-run-v1/run-report.json) retained **two completed $2,500 releases and four rejected unaffordable-hand arms**; its overall exit was 1, correctly reflecting the failures. Four [paired reporters](simulations/three-hand-compare-control-2500-v1/comparison.md) passed source/fork-state/RNG and telemetry checks, each marking `both_cases_completed=false`; names are `three-hand-compare-<control|graduate>-<1000|2500>-v1`. Four representative fresh-process pair replays (control no-loan/$1,000/$2,500 and Graduate $2,500) exited 0 with telemetry verified. The control no-loan and $1,000 [failure reductions](simulations/three-hand-reduced-control-90210-no-loan-v1/reduction-run.json) (second named `three-hand-reduced-control-90210-borrow-1000-12-v1`) reproduced the exact rejected command from a Studio restore and fresh process. No timeouts.

The [c28 continuation bundle](simulations/three-hand-settlement-run-v1/run-report.json) retained two accepted one-command `begin_development` paths from exact c27 Studio checkpoints, each intentionally `command_bound` because the target was three releases; overall exit 1 is expected. Both fresh-process one-command replays passed `telemetry_verified=true`. This is a Game3 setup cycle used to trigger actual monthly settlement; it does not establish Game3 quality or its future cost.

Representative exact comparison, replay and reduction commands:

```powershell
& $py tools/compare_simulations.py --bundle docs/codex/threads/banking-system/simulations/three-hand-decision-run-v1 --left control-90210-no-loan --right control-90210-borrow-2500-12 --output docs/codex/threads/banking-system/simulations/three-hand-compare-control-2500-v1
& $py tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/three-hand-decision-run-v1 --case control-90210-borrow-2500-12 --output docs/codex/threads/banking-system/simulations/three-hand-replay-control-90210-borrow-2500-12-v1 --godot $godot --timeout 240
& $py tools/reduce_simulation.py --bundle docs/codex/threads/banking-system/simulations/three-hand-decision-run-v1 --case control-90210-no-loan --kind rejection --output docs/codex/threads/banking-system/simulations/three-hand-reduced-control-90210-no-loan-v1 --godot $godot --timeout 240 --max-commands 50
& $py tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/three-hand-settlement-run-v1 --case control-90210-borrow-2500-12 --output docs/codex/threads/banking-system/simulations/three-hand-settlement-replay-control-90210-borrow-2500-12-v1 --godot $godot --timeout 240
```

## Outcomes and attribution limits

| Arm, same seed in both cohorts | First blocker or second release | Endpoint cash | Arrears | Remaining Bank principal |
|---|---|---:|---:|---:|
| No loan | c22 unaffordable hand; no second release | $126.84 | $0 | $0 |
| $1,000/12 | c23 unaffordable hand; no second release | $44.32 | $0 | $749.98 |
| $2,500/12, no trait | c27 release, Review 3.8 | $775.70 | $0 | $1,458.31 |
| $2,500/12, Graduate | c27 release, Review 3.8 | $492.97 | $0 | $1,458.31 |

The $2,500 arm's sampled cash low through launch was $402.80; the no-loan arm's was $126.84. The no-loan/$1,000 endpoints are earlier and cannot be assigned an unobserved game-two Review or future sales. Scripted AI Research cost $855, was unaffordable without a loan, and was owned in both borrowing arms. At both $2,500 c27 Studio checkpoints, the saved `credited_projects` record includes `scripted_ai` for **project 2**. In [RunState.record_resolved_feature](../../../../patch-notes/scripts/run_state.gd), this credit is written only after committed Design/Alpha production, never on draw or selection. Thus financed Scripted AI was actually resolved in Game2. The evidence does not isolate that card's Review contribution from the extra production, interest, timing and different cash path.

At c28, the one-command continuation recorded Game2's **$1,356.64 settled sales** in both cohorts; total portfolio settled sales were $1,412.59, including the older title. All due bills were paid, no arrears remained, and credit was 615. No-trait cash was $1,465.38 with $1,249.98 Bank principal remaining, or **$215.40 after subtracting principal**. Graduate cash was $899.92 with the same principal, or **negative $350.06** on that simple debt-adjusted measure; Graduate's scheduled education payment continued. This is a cash snapshot, not a full valuation or proof the loan pays for itself. The c28 continuation has no matched no-loan or $1,000 Game2 settlement because neither arm launched.

**Interpretation:** The accepted amount-selection rule already permits a materially useful larger loan in one legal route, and its recurring debt can still leave the Studio thin. Review 3.8 missed the planned 4.0 adequacy screen; the harsher four-hand route previously failed even with $2,500. No fixed/default principal, expanded capacity, price/rate/term change, forced reserve, or guaranteed-benefit claim follows. Exported player understanding and the delayed-first-game 6.2/bankruptcy target remain separate.
