# Crown/Neon cash-cap sensitivity — exact-cent arithmetic only

2026-10-07, America/Los_Angeles. **Candidate analysis, no rule approval or gameplay implementation.** Source is the Task 34 isolated main revision `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`, identified by its [source manifest](../sim-v3/source-manifest.json). The current shared worktree has later uncommitted gameplay changes; this study reads only Task 34's pinned result files. See the [predeclaration](PREDECLARATION.md), [reproduction script](analyze.py), [input hashes](input-sha256.json), [machine results](results.json) and [primary paired cents](paired-payouts.csv).

## Setup and checks

Hold the Task 34 legally drawn/selected two hands, offer checkpoint, target, frozen focus, production policy, draw seed, acceptance advance and exact completion fraction `n/d` fixed. Rescore Crown caps `$1,680/$1,920/$2,160` at the proposed A=$150 and Neon caps `$1,320/$1,560/$1,800` at the proposed A=$0. The middle caps are the existing candidates. The cap-only payment is `A + floor((C-A)×n/d)` cents on a completed second hand. Acceptance still pays only A, and full completion pays exactly C. Conditional Promotion remains `floor(12×n/d)` Crown or `floor(20×n/d)` Neon; it was not re-simulated or implemented.

The script loaded 42 pinned Task 34 result files, checked all **2,880** Crown/Neon original arms against the exact baseline payout formula, and re-scored the **2,712** that completed under their original cap. No mismatches occurred. The primary paired subset is the 492/528 Crown arms completing at A=$150 and all 192/192 Neon arms completing at A=$0. These are deterministic arms from Task 34's 26 native preparation routes, with repeated target/policy/draw treatments; the arm count is not a sample size of independent players. Mean amounts below are rounded to the nearest cent after exact integer payouts.

| Primary policy | Candidate cap | Cap / Ironclad max | Mean cash on the same completed hands | Paired mean change vs middle cap | Range of paired change |
|---|---:|---:|---:|---:|---:|
| Crown A=$150 | $1,680 | 70% | $1,409.54 | −$197.58 | −$240.00 to −$138.19 |
| Crown A=$150 | **$1,920** | 80% | $1,607.12 | reference | — |
| Crown A=$150 | $2,160 | 90% | $1,804.70 | +$197.58 | +$138.18 to +$240.00 |
| Neon A=$0 | $1,320 | 55% | $1,222.79 | −$222.33 | −$240.00 to −$189.76 |
| Neon A=$0 | **$1,560** | 65% | $1,445.11 | reference | — |
| Neon A=$0 | $1,800 | 75% | $1,667.44 | +$222.32 | +$189.77 to +$240.00 |

Crown's completed hands average exact completion `163/198`; 164/492 hit the full cap. Neon's average is `239/258`; 32/192 hit the full cap. The high Neon completion fractions explain why a $240 cap step moves the mean Neon reward by roughly $222. The same-hand cash shift is about 40–45% of one current $500 rent bill. Scoring all 2,712 original completed candidate arms across the four original advance choices yields the same rounded cap-change means within one cent (full table in `results.json`); changed completion counts are **not** inferred.

## Access, hierarchy and limits

The cap has no effect on the cash paid at acceptance or before the second-hand receipt. Changing it cannot itself clear the reproduced $147.65 pre-first-hand Crown rent block; that is an advance-timing question. The lower-cap arithmetic leaves the original completed hands with a positive shifted immediate cash balance: minimum $3,135.85 Crown and $4,244.69 Neon; none of those original hands had immediate arrears. This is a ledger-margin calculation on already completed arms, **not** a native typed-finance continuation. The changed second-hand payout could alter rent payment, credit, sales timing, later spending or a rejected action. This slice does not establish alternate-cap completion or later solvency, and it does not score the 168 baseline-incomplete candidate arms as successful.

At their maximum, all tested Crown and Neon caps remain below live Ironclad's $2,400 ceiling. The low Neon cap of $1,320 sits only $120 above live SideStreet's $1,200 ceiling; the upper Crown cap reaches 90% of Ironclad. Task 34 observed 54/54 available Ironclad hand pairs completing with mean direct cash $2,191.66, and 12/18 available SideStreet pairs completing with mean $1,075. Their availability, requirement, completion formula, advance and selected hands differ, so those observed amounts are **unmatched context**, not a controlled publisher preference result. The cap sensitivity has no sales/Promotion economics or player-choice valuation.

## Recommendation for the design ruling

Keep Crown **$1,920** and Neon **$1,560** as the working cap candidates while ruling advances and targets; do not raise caps merely to solve first-hand liquidity, since that payment arrives later. A lower cap is a meaningful reward reduction on these high-completion hands, and an upper cap adds roughly $198/$222 on average without demonstrated access need. The present evidence gives no basis to approve any tested cap. If the board considers a cap change, compare the resulting second-hand typed finance and later common-calendar cash/credit/settlement on the fixed Task 34 hands before locking it, and separately choose the intended reward spacing relative to Ironclad and SideStreet.
