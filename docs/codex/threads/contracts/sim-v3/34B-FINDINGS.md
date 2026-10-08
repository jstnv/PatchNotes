# Task34B — historical Crown liquidity gate complete

2026-10-07, read-only candidate analysis on main `b84d1a5`. The two native typed Review9.0 checkpoints from [34A](34A-FINDINGS.md) feed native Contract draws/retention/redraw/hand validation and finance/sales planners. Candidate scoring and offer identity guards are a separate analysis model. Native Ironclad ContractState payout is deliberately excluded from candidate finance. Scope target9, ordinary visible-hand policy and draw seed200929000 were used for this boundary probe; broader cohorts follow.

| Startup / acceptance cycle | Advance | Both hands | End cycle | Direct publisher cash | End cash | End arrears |
|---|---:|---|---:|---:|---:|---:|
| Legacy $5,500 / 32 | $0 | No: first hand blocked | 32 | $0 | $0 | $147.65 |
| Legacy $5,500 / 32 | $150 | Yes | 34 | $1,169.09 | $8,451.50 | $0 |
| Legacy $5,500 / 32 | $200 | Yes | 34 | $1,190.30 | $8,472.71 | $0 |
| Legacy $5,500 / 32 | $300 | Yes | 34 | $1,232.72 | $8,515.13 | $0 |
| Preview $5,700 / 33 | $0 | Yes | 35 | $1,105.45 | $4,622.83 | $0 |
| Preview $5,700 / 33 | $150 | Yes | 35 | $1,169.09 | $4,686.47 | $0 |
| Preview $5,700 / 33 | $200 | Yes | 35 | $1,190.30 | $4,707.68 | $0 |
| Preview $5,700 / 33 | $300 | Yes | 35 | $1,232.72 | $4,750.10 | $0 |

$150 leaves $2.35 after servicing the old bill and allows the first hand. Actual native all-title settlement then finances the second boundary: these end balances include sales, not just the advance. The successfully completed candidate fraction is 342/594. Credits finish 601 for recovered legacy arms and 606 for preview arms; recovery does not erase historical late credit. The different end calendars require separate common-calendar analysis in the cohort, not a direct cash ranking of startup paths.

188 native/model assertions across the two runs cover pending/rejected/duplicate acceptance, duplicate completion, native third-hand rejection, pure rejection preservation, sales validity, full ledger replay, and zero/full payout endpoints for both publisher formulas and target variants. An independent Python review of all eight final transaction chains verifies nonnegative exact-cent cash, exactly one acceptance row, and `A + floor((192000-A)*n/d)` for completed Crown arms. Commands and raw JSON are `34B-legacy` and `34B-trait`; scripts are [advance.gd](advance.gd) and [run.py](run.py). The initial publisher-key harness error was corrected to the native `crown_quill` key before these successful runs; no runtime code changed.

34B is COMPLETE for the boundary gate. $150 is the smallest tested amount that resolves this historical block; it is not a selected publisher value or a broader balance recommendation. Continue 34C and the distinct legal Neon cohort before a per-publisher recommendation.
