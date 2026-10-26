# Banking $2,500 larger-offer screen — 2026-10-11

**Bounded finding:** A legally eligible player-selected $2,500/12-month loan financed the first $855 FIFO Research and extended a fixed four-hand-per-phase game-two route from a c23 cash block to c26. Neither no-loan, $1,000 nor $2,500 arm launched game two. At c26 the $2,500 arms had $274.30 overdue rent/Bank bills without a trait and $557.03 including Graduate's first education bill. This study does **not** support a larger default offer, new ceiling, capacity change or final balance ruling.

## Authority, source and legal route

- [Predeclared plan](2026-10-11-larger-offer-plan-v1.md) fixed seed90210, two cohorts, fresh prefixes, admissions, no-loan/$1,000/$2,500, one Research maximum, four hands per phase, 50-command/240-second bounds and stop rules before execution. It is a current-rules quote sensitivity screen under the accepted player-selected amount/term rule; $2,500 is an OPEN experimental selection.
- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at plan time, dirty shared worktree. Banking-owned private [v4 variant](simulators/education-bank-quote-v4/variant.json) retains canonical baseline `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e` and v3 parent `890781bc0c39c8a2e89c7440747d4724b8dcb99f3527e7a32c26e355b6058c32`; its current candidate identity is `c548531452bd2990792226213aee7b3485be588b59874c4ec0c6983bb1449b1d`. Sole added project code is a read-only `bank_quote_2500_12` Studio observation. No finance, Store, RNG, save or canonical gameplay change.
- Frozen source identities are [first](simulations/larger-offer-first-run-v1/run-report.json) `c5485314…`, [c16 Studio](simulations/larger-offer-studio-run-v1/run-report.json) `ef1a7493…`, [admission](simulations/larger-offer-admit-run-v1/run-report.json) `518df0f5…`, and [pairs](simulations/larger-offer-pairs-run-v1/run-report.json) `180696e355cca1d8a61b8c0fb72bdd3726cda182fa37d72a36b5d992392d31cc`; the differences are the external injected policies. Pair policy SHA `bb0ff08d17259242a2e6ac88f81bcc6c4410da9556755e2632f36e674330d321`, runner SHA `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`. Python 3.12.14 was `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`; Godot 4.7.1 was `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`, SHA `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- Both v4 fresh first games released at c13. Both c16 Studio routes had the same strong actual c14/c16 settled sales as v3, no overdue bill, and $5,133.77 no-trait/$5,433.77 Graduate cash before admissions. Both legal five-admission sequences then left $833.77 at c16 with no overdue bill. Starting ledgers were separately $5,700 and $6,000 from unused-point receipts, not the bare $5,500 case. At c13, c16 and after admissions, v4 final state digests, RNG, cash and accepted command counts matched the corresponding v3 routes exactly (six cross-version stage/cohort checks). No old checkpoint was transplanted into the new source.

## Exact commands, checks and failures

From repository root, `$py` and `$godot` are the exact executables above; all outputs were new folders. These are the complete primary simulator commands:

```powershell
& $py tools/simulator_variant.py create --id education-bank-quote-v4 --owner banking-system --from-variant docs/codex/threads/banking-system/simulators/education-bank-quote-v3 --output docs/codex/threads/banking-system/simulators/education-bank-quote-v4
& $py docs/codex/threads/banking-system/simulations/build_larger_offer_v1.py first
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/larger-offer-first-v1.json --output docs/codex/threads/banking-system/simulations/larger-offer-first-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_larger_offer_v1.py studio
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/larger-offer-studio-v1.json --output docs/codex/threads/banking-system/simulations/larger-offer-studio-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_larger_offer_v1.py admit
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/larger-offer-admit-v1.json --output docs/codex/threads/banking-system/simulations/larger-offer-admit-run-v1 --godot $godot --timeout 240
& $py docs/codex/threads/banking-system/simulations/build_larger_offer_v1.py pairs
& $py tools/simulate.py run --variant docs/codex/threads/banking-system/simulators/education-bank-quote-v4 --config docs/codex/threads/banking-system/simulations/larger-offer-pairs-v1.json --output docs/codex/threads/banking-system/simulations/larger-offer-pairs-run-v1 --godot $godot --timeout 240
```

The first run exited 0 with two completed c13 first releases. The c16 and admission batches each exited 1 because both valid Studio cases intentionally stopped at their five-command bound short of the two-release target. The pair batch exited 1 because **all six** game-two arms had retained `rejected_policy_action` outcomes, not timeouts. Four [paired reporters](simulations/larger-offer-compare-control-2500-v1/comparison.md) exited 0, verified same-source exact starting state/RNG and telemetry integrity, and correctly marked `both_cases_completed=false`. They are named `larger-offer-compare-<control|graduate>-<1000|2500>-v1`. Six representative fresh-process replays succeeded with telemetry verification: first control, c16 Graduate, admission control, pair no-loan control, and both $2,500 pair arms. A replay of a rejected tape verifies its accepted prefix and recorded rejection, not independent policy reasoning. Both $2,500 [control](simulations/larger-offer-reduced-control-90210-borrow-2500-12-v1/reduction-run.json) and [Graduate](simulations/larger-offer-reduced-graduate-90210-borrow-2500-12-v1/reduction-run.json) calendar rejections reproduced in fresh processes from shortest prior Studio restore suffixes. The v3 focused Bank/finance checks remain prior unchanged-rule evidence; no new focused suite was claimed for the read-only observation edit.

The command form for paired reporting, replay and reduction was:

```powershell
& $py tools/compare_simulations.py --bundle docs/codex/threads/banking-system/simulations/larger-offer-pairs-run-v1 --left control-90210-no-loan --right control-90210-borrow-2500-12 --output docs/codex/threads/banking-system/simulations/larger-offer-compare-control-2500-v1
& $py tools/simulate.py replay --bundle docs/codex/threads/banking-system/simulations/larger-offer-pairs-run-v1 --case control-90210-borrow-2500-12 --output docs/codex/threads/banking-system/simulations/larger-offer-replay-larger-offer-pairs-control-90210-borrow-2500-12-v1 --godot $godot --timeout 240
& $py tools/reduce_simulation.py --bundle docs/codex/threads/banking-system/simulations/larger-offer-pairs-run-v1 --case control-90210-borrow-2500-12 --kind rejection --output docs/codex/threads/banking-system/simulations/larger-offer-reduced-control-90210-borrow-2500-12-v1 --godot $godot --timeout 240 --max-commands 50
```

## Quote and outcome

The c16 conservative settled-sales basis was $2,611.88. Actual monthly capacity was $527.97 no-trait and $457.28 Graduate after its $282.73 overlapping education reserve. The $2,500/12 quote was eligible in both, under exact maximum principals $5,656.80 and $4,899.48. Its largest scheduled monthly payment was $233.34, total scheduled interest $162.50, first due c18. This observed eligibility is specific to these sales/obligation histories.

| Arm (both cohorts) | FIFO Research | First game-two blocker | Second release | Final cash | Remaining Bank principal |
|---|---|---|---|---:|---:|
| No loan | none; $855 unaffordable | c23 unaffordable hand | none | $76.84 | $0 |
| $1,000/12 | one; Scripted AI owned | c23 unaffordable hand | none | $254.32 | $749.98 |
| $2,500/12 | one; Scripted AI owned | c26 calendar cannot advance safely | none | $0 | $1,666.64 |

The $2,500 no-trait endpoint had $49.30 rent and $225.00 Bank installment unpaid, $274.30 total and credit 594. Graduate had those same bills plus its first $282.73 education installment, $557.03 total and credit 589. Both $2,500 arms had paid earlier scheduled Bank amounts; the remaining principal is debt, not spendable benefit. The first game's historical Review 5.8 is the last stored release Review at all endpoints; **game-two Review is unavailable** because no second release occurred. The extra money bought more attempted actions and time, while recurring debt and then education overlap consumed the margin. No card draw/play benefit or future sales can be inferred from a Research admission.

**Design recommendation:** keep current Bank and Store rules, including player-selected amounts, unchanged. A larger selected principal alone did not rescue this deliberately cash-depleting queue strategy. A future useful comparison must change the *predeclared spending/production strategy* and demonstrate a meaningful second release and next actual sales settlement. Do not tune Bank capacity, rent, rate, term or score from these six censored arms. The 6.2-rated delayed-first-game bankruptcy target, latest-source exported late/partial acceptance and human quote comprehension remain separate.
