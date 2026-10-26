# Employees economic readiness clarification — 2026-10-25

## User ruling and status

**LOCKED direction:** Employee implementation becomes ready for review when the game's economy can support a base wage of **at least $1,000 per employee per in-game month**. The user's reference is $12,000 for a junior game developer in the 1980s; $1,000 × 12 = $12,000. The dollar floor is the selected game-design direction. The historical *industry average* claim is not verified here; a 1985 contemporary report instead describes one Atari programmer starting at $24,000/year, which is an example rather than an average ([Washington Post, 1985](https://www.washingtonpost.com/archive/politics/1985/12/23/video-game-pros-zapped/651a4ea6-fd30-4e01-9edd-347280388cdc/)).

**Interpretation:** This is a criterion for when to implement the employee system in the game's evolving economy. It does not by itself authorize a runtime rebalance, reopen hiring or define a dynamic player unlock. “Beginning of the mid game” is a description of the expected stage, not an independent release-count or calendar gate. The exact player-facing availability rule is **OPEN**.

## Current evidence and proof still needed

- **IMPLEMENTED local trial:** One Production Specialist's after-Game-1, $100 hire and $10/month payroll package remains in source. The visible Employees button is disabled under the user's 2026-10-24 hold. The future $1,000+ base has not been implemented.
- **COMPLETED but not decisive:** The earlier matched wage study covered $10/$25/$50/$75, not $1,000. Current late-campaign cash snapshots and one-time Contract or loan receipts do not prove that ordinary recurring operations can carry the proposed wage.
- **OPEN affordability proof:** Compare matched no-hire and hire/training continuations at the same calendar boundaries using actual monthly **earned and settled** sales across overlapping releases; include rent, Bank/education/current payroll dues, unpaid bills, cash low points and whether the next game remains affordable. Include shorter and longer first games and distinguish temporary cash from repeatable income. Record how many employees each path can support at **$1,000 minimum base per person**. This describes evidence to collect, not an approved pass threshold or in-game hiring algorithm.
- **OPEN implementation choices:** actual first-payday timing at the new wage, hiring fee, course tuition/raises and effects, specialist value, save transition from the $10 trial, and the player-facing hire rule. Previously approved first-slice timing/recovery remains historical trial authority, but its suitability for the later package needs review.

**Disposition:** Keep the implementation hold and button block. Do not use a fixed mid-game milestone as an additional prerequisite for declaring the system economically ready. Do not update the shared TODO from this clarification alone.

## Session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE and TODO first, then the relevant design, decision, thread notes, README, hold log and prior readiness review. Inspected branch, HEAD, status and targeted diff; the shared worktree was already heavily modified. Changed this dated thread note, the earlier same-day review pointer, the thread README, Employees design, DECISIONS and CURRENT_STATE only. Confirmed the visible button is disabled and the retained hire quote still has a $100 fee/$10 wage. Targeted `git diff --check` passed for the four changed tracked docs; both dated untracked notes have zero trailing-whitespace lines. All 331 local links in the six touched documents resolve. No gameplay or test file edits, simulations, shared TODO, Drive, commit or push.
