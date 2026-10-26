# Publisher system economic formula screen — findings v1

**Current disposition:** the [v3 design](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md) rejects this screen's cash-only Ironclad support row as a playable profile and adds a candidate support issuance guard. The original cases and numbers below remain unaltered formula evidence; they do not test issuance or legal gameplay.

2026-10-18 (America/Los_Angeles). **Formula-only design evidence; values PROPOSED.** [Pre-run plan](PUBLISHER-SYSTEM-ARITHMETIC-PLAN-2026-10-18-v1.md) fixes the input grid, source hashes, assumptions, measurements and stop. The calculator [source](publisher_system_arithmetic_v1.py) used the same current-source Primitive unit, release-age sales and cumulative post-platform net formulas; it did not run gameplay or create a legal Studio checkpoint.

## Execution and retained outputs

- Source: dirty working `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Five exact source SHA-256 values are in the plan and output JSON. The calculator refuses drift.
- Planned `python docs/codex/threads/contracts/publisher_system_arithmetic_v1.py --output docs/codex/threads/contracts/sims/publisher-system-arithmetic-20261018-v1.json` failed before execution because `python.exe` resolved to an inaccessible WindowsApps alias. No result was produced by that attempt.
- Retried with the configured bundled Python: `& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/publisher_system_arithmetic_v1.py --output docs/codex/threads/contracts/sims/publisher-system-arithmetic-20261018-v1.json`. PASS: [36 base cases and 540 support cases](sims/publisher-system-arithmetic-20261018-v1.json); source guard and arithmetic invariants passed.
- Ran the same command into a distinct [replay output](sims/publisher-system-arithmetic-20261018-v1-replay.json). PASS: both JSON files have SHA-256 `ACD4E64E1C4F2B7E7F905B5AA7BB8FA20A3FB9061E34B71DCB6A813FF03B0019`.

## Results

Neutral demand, Review 7.0, base Awareness 100, no Fans/campaigns: an ordinary self-published title earns 750 units / $5,244.75 after Month1, 1,077 / $7,531.46 after Month3, and 1,291 / $9,027.96 after Month12. A proposed **$6,000 fixed qualifying commission fee at launch** exceeds this title's first-month Studio sales by $755.25 and trails its Month12 sales by $3,027.96. The same $6,000 fee trails Month12 self-publishing by $1,300.69 at Review6.0 and $7,482.50 at Review9.0. The fee therefore offers earlier certainty at the cost of later upside in this reference; it does not prove the player's development financing or expected return.

At proposed Investment 15, the support budget is $875. The proposed 20% post-platform share is capped cumulatively at that $875 budget through release-age Month12. For the same Review7.0 reference:

| Publisher | Upfront cash | Targeted Awareness | Month3 units | Both criteria met? | Studio receipts vs self-publish, Month3 | Studio receipts vs self-publish, Month12 |
| --- | ---: | ---: | ---: | --- | ---: | ---: |
| Ironclad | $875 | 0 | 1,077 | Yes | $0.00 | $0.00 |
| SideStreet | $700 | 5 | 1,098 | Yes | −$28.15 | +$13.81 |
| Crown | $525 | 10 | 1,121 | No: Review below 7.5 | −$42.31 | +$34.61 |
| Neon | $350 | 15 | 1,143 | No: below 1,200 units | −$63.47 | +$76.40 |
| Starwave | $455 | 12 | 1,131 | No: both thresholds | −$42.38 | +$62.52 |

These net comparisons include the upfront cash, title sales after the candidate recoup share, and the marketing effect. They omit production spending, rent after launch, Fanbase, other titles and time value. Upfront cash is available during development; Month3/12 rows are cumulative receipts, not spendable cash at signing. The $35 per Awareness point conversion produces roughly comparable nominal packages in the neutral case; it is an accounting assumption for these offers, not a market price or a gameplay conversion action.

Across the declared **input grid**, the numbers of cases meeting each publisher's paired Month3 targets were Ironclad 81/108, SideStreet 63/108, Crown 47/108, Neon 66/108 and Starwave 24/108. These are counts over intentionally chosen inputs, **not offer success probabilities**. At Investment15, Month12 support effects ranged from −$140.38 (Neon, Review6.0/Awareness100/market0.8, criteria missed) to +$642.83 (Neon, Review9.0/Awareness120/market1.2, criteria met). High Investment100 cases gained as much as +$2,194.02 in the screened grid because the support budget can exceed the 20% twelve-month recoup; this needs legal-route and cashflow testing before any trial amount is adopted.

## Recommendation and limits

Retain the **separate Reputation and Investment capacity tracks**, a frozen flat commission quote, and support as a targeted cash/marketing package with publisher risk borne through title-only capped recoupment. Use the $6,000 fee, $500+$25×Investment budget, $35/point conversion, 20% capped share and publisher thresholds as a **private pilot candidate**, not approved gameplay values. Before adoption, validate actual legal early/midgame routes, first-month liquidity, support accepted before project creation, real Fanbase/trait/Promotion/market input, low-review misses and exact finance/Studio Continue. The current calculator cannot validate deliverability, ownership/rights, fairness, human comprehension, wider specialties or replayable engine state. No canonical code, shared TODO or implementation authority was changed by this screen.
