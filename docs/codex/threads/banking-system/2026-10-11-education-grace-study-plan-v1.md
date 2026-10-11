# Education grace-boundary simulator study — predeclared 2026-10-11

## Question and hypothesis

On current live rules, how do the first scheduled College Dropout and Graduate payments affect cash, arrears, credit and the ability to complete a third release after the 12-month grace period? B6 did not include education debt. This is a bounded balance screen, not a proposed change to approved education terms.

Hypothesis: Graduate's larger monthly due creates a distinct post-cycle-26 liquidity/credit risk under an ordinary finite development policy even when its extra unused-point receipt provides more starting cash. College Dropout should exert less pressure. Either hypothesis may fail. A loan is not scripted; the accepted two-positive-settlement gate remains in force, so no claim about Bank rescue follows from this study.

## Declared cases and limits

- Six independent legal new Action Studios: no trait, `college_dropout`, and `graduate` at each of seeds `4417` and `90210`. The same seed does **not** make the trait cohorts identical starting states; compare them as separate legal startup cases, not matched checkpoint counterfactuals. No edited balances, checkpoint injection, or player saves.
- Existing `finite-development-fixture` policy v1, `visible_order`, Action/Fantasy, four Design, four Alpha and four Beta hands per release. Three-release target; 120-command maximum per case; timeout 240 seconds for import and run. No Store purchases, Research, Contract, Bank action, hiring, redraw optimization or adaptive rescue. Every legal failure, rejection, incomplete route or timeout remains evidence. No seed/budget changes within v1.
- Record initial cash/trait provenance; release Review/cycles; cash low, settled sales, rent, education bill creation/payment/arrears, monthly credit and first block/rejection at comparable calendar boundaries. In particular inspect cycles 24, 26, 28, 30 and 36 if reached. Trace finance in exact cents; distinguish principal repayment from expenses. Telemetry requested for each case.
- Stop at three Studio releases, first rejected command, 120 commands or timeout. Cases ending before cycle 26 cannot answer the grace-boundary question and remain incomplete. A missing due is not evidence that grace terms changed.
- Replay one no-trait and one case of each debt trait in a fresh process when complete. Audit the retained source and legal state/RNG identities. If no debt case reaches a first due, reduce the conclusion to the reachability limit; any revised policy requires a new plan/config/output version.

## Commands and scope

Run `tools/simulate.py run --config docs/codex/threads/banking-system/simulations/education-grace-v1.json --output docs/codex/threads/banking-system/simulations/education-grace-run-v1 --godot <Godot 4.7.1 console> --timeout 240` with the configured bundled Python. Replay uses `tools/simulate.py replay --bundle <run folder> --case <case ID> --output <new replay folder> --godot <same Godot> --timeout 240`. No candidate rule addition is assumed, so test authoritative existing behavior first and create no variant unless a specific OPEN addition becomes necessary. This study cannot approve a balance change, user-visible presentation, or release readiness.
