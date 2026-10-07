# Feature Store findings v7 — Sub-Areas play-fee sensitivity

Date: 2026-10-06 (America/Los_Angeles). **Read-only counterfactual cash overlay, not a native paid-fee replay.** The user-approved bounded-pilot Sub-Areas printed identity is unchanged. Price, fee, timing trigger and implementation remain **OPEN**.

## Exact source, inputs and method

- Branch `main`, source HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after. The [v4 predeclaration](sim-v4/predeclaration.json) fixes 593 tracked source hashes and native driver SHA-256 `9c117f1a16e5251e4d24e4eb462ba1b8427b037a65db6eb01fbd14d864b9f7b1`. The [v5 report](sim-v5/run-report.json) records all eight verified native trace hashes and overlay script SHA-256 `4d36f623f2112ed0491b78a9b63cb77c7568ecd4391b6912c57216e03c5f509a`.
- Inputs: the eight five-release native Action routes in [findings v6](FINDINGS-v6-sub-areas-payoff.md), two seeds × ordinary/synergy × no-purchase/Sub-Areas. All four trial routes bought Sub-Areas after Game 3 at the $1,190 trial discounted quote, then selected and committed it **once in Game 4 and once in Game 5**. Current runtime charged no later-card fee.
- [Predeclared overlay plan](sim-v5/README.md): charge $0, $50 or $90 per actual Sub-Areas commit, in addition to the native Primitive hand cost. Keep draws, purchases, sales, rent, release timing, credit and decisions fixed. Subtract one fee from trial cash at shared cycle 73 and two fees at respective Game 5 launches. Controls remain unchanged. This isolates the accounting effect only; it does not simulate an atomic paid-fee action or a route that adapts to the extra expense.
- [Overlay script](sim-v5/fee_overlay.py) checked source/driver hashes, all raw trace hashes, five releases, zero native arrears, purchase and two actual plays. It calculated [exact-cent output](sim-v5/summary.csv) for 12 paired fee cases. A conservative cash floor subtracts **both** fees from the lowest recorded cash after the first candidate play, even before the second fee would be due.

## Cash results

Paired differences below are trial minus no-purchase control. Game 5 launches occurred at cycle 89 in trials and 86 in controls; that column is a release-count milestone, not a matched calendar date.

| Seed / policy | Common cycle 73: $0 / $50 / $90 fee | Game 5 launch: $0 / $50 / $90 fee | Conservative post-first-play cash floor at $90 |
|---|---:|---:|---:|
| 1104 / ordinary | +$731.50 / +$681.50 / +$641.50 | +$2,447.03 / +$2,347.03 / +$2,267.03 | $6,010.67 |
| 1104 / synergy | −$113.67 / −$163.67 / −$203.67 | +$566.96 / +$466.96 / +$386.96 | $8,887.87 |
| 4417 / ordinary | −$610.17 / −$660.17 / −$700.17 | −$979.68 / −$1,079.68 / −$1,159.68 | $4,562.98 |
| 4417 / synergy | −$354.00 / −$404.00 / −$444.00 | +$339.56 / +$239.56 / +$159.56 | $7,625.40 |

Across these four fixed routes, a $90 fee does not flip any paired cash sign or create a cash-shortage signal at the recorded decision points. The small positive Game 5 margin in seed 4417/synergy falls from $339.56 to $159.56. Actual Game 4 per-title settled sales and Reviews do not change in an accounting-only overlay, so [v6's mixed quality and settlement results](FINDINGS-v6-sub-areas-payoff.md) still govern that part of the evaluation.

## Recommendation and limits

**Proposed design criterion:** for an optional bounded-pilot upgrade, require legal next-project access and no earlier arrears or financial block. Measure Review and actual settled title sales separately. Treat positive cash by Game 5 as a desirable outcome across a broader paired sample, **not a requirement that every seed must meet**; report matched-calendar deficits and worst losses before approving a price or fee. This is a recommendation for user review, not an approved rule.

The overlay supports only a narrow inference: in these four already-solvent routes, $50 or $90 accounting charges are too small to explain the large outcome spread. It cannot verify paid-play action legality, rollback, altered hand decisions, credit effects or paths near a cash boundary. Two seeds, one specialty, $5,700 genuine start, owned Levels parent, one purchase timing trigger and no native fee are insufficient for a $1,700/$90 ruling. Broader shared Task 2 work should include native fee behavior if approved for an isolated test, parent-missing routes, genuine $5,500 starts and representative current-node controls. No gameplay or shared To Do List was changed here.
