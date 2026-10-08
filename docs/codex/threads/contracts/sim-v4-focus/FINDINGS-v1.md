# Neon acceptance focus: fixed-hand sensitivity

2026-10-07, America/Los_Angeles. **Read-only candidate analysis. No focus rule or numerical reward was approved.** The predeclared method is [PREDECLARATION.md](PREDECLARATION.md); [audit.py](audit.py), [results.json](results.json) and [arm-rescores.csv](arm-rescores.csv) reproduce the arithmetic.

## Source, assumptions and checks

The source revision is isolated main `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`, as captured in Task 34's [source manifest](../sim-v3/source-manifest.json). The audit verified archived native Contract/score order source hashes, v3 harness hashes and all eight eligible compressed route outputs. It selected the **192 completed Neon arms with $0 advance** from the predeclared Task 34 cohort; eight ineligible routes contributed none. There are only **six distinct final Scope/four-score profiles**, so these 192 paired arms are not 192 independent player outcomes. The audit passed **1,261 assertions** and reproduced each recorded auto-focus fraction, exact-cent cash and whole Promotion amount.

The same two native hands, Scope, core scores, target and candidate cap are held fixed. Re-score each of the four possible acceptance-frozen focus slots using the candidate Neon formula, `floor($1,560 × completion)` and `floor(20 × completion)` Promotion. Automatic focus was Graphics in all 192 arms because Task 34 picked the highest owned Primitive primary total at acceptance. Best/worst are retrospective bounds on those hands, not player decisions possible with acceptance-time information. No cards, draw, finance, sales or Promotion consumption were rerun.

## Results

| Focus on the fixed hands | Mean direct completion cash | Mean conditional Promotion | Arms above / equal / below auto cash |
|---|---:|---:|---:|
| Auto / Graphics | $1,445.11 | 18.17 | 0 / 192 / 0 |
| Sound | $973.48 | 12.00 | 32 / 0 / 160 |
| Technology | $1,535.81 | 19.67 | 96 / 96 / 0 |
| Design | $1,215.35 | 15.33 | 96 / 0 / 96 |
| Hindsight best per arm | $1,535.81 | 19.67 | 96 / 96 / 0 |
| Hindsight worst per arm | $888.83 | 10.83 | 0 / 32 / 160 |

All displayed means round only for presentation; [results.json](results.json) retains exact integer totals and denominators. Technology was the best or tied best on these fixed hands and improved mean direct cash by exactly **$90.70** and mean Promotion by **1.5 points** against auto. Its maximum paired cash gain was **$326.52**. The hindsight worst focus reduced mean direct cash by about **$556.28**, up to **$906.98** on one arm, and mean Promotion by about **7.33 points**. Auto was cash-best in 96/192 arms and cash-worst in 32/192 arms. The mean hindsight-best gain over auto is $145.12 for ordinary-policy hands and $36.28 for synergy-policy hands; target 10/11 strata have identical aggregate sensitivity in this cohort.

## Recommendation and limits

**Keep the strongest-owned-primary automatic focus as the bounded pilot default.** The sampled Technology score shows that this default does not maximize every actual payout, while the large worst-choice loss makes an unassisted player selection consequential. Treat an optional player override with a clear scoring preview as a separate **candidate**, to evaluate against more owned-roster variety and native adaptive hand selection before a ruling. No claim about player preference, cross-roster balance or true post-Contract cash/settlement follows from this fixed-hand arithmetic. The candidate completion cash changes only at the second hand, so this re-score cannot alter the observed first-hand access result; downstream finance effects of altered payout were not simulated.
