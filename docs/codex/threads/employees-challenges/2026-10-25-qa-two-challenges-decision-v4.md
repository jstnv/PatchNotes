# QA's two challenges — 2026-10-25, version 4

**Later interaction ruling:** The [version-5 note](2026-10-25-qa-swap-redraw-control-v5.md) selects the existing Beta Redraw button as the Swap control for one selected eligible QA card. Swap turns that card into the opposite card without spending a redraw or drawing from the pool. The opposite card governs subsequent Beta resolution and pure-hand classification. Its use limit and training/arming rules below remain in force; the earlier candidate card-operation wording below is superseded where it conflicts.

## Selected rules

**LOCKED qualitative design; NOT IMPLEMENTED:** QA has **two separate employee challenge tracks** and two separate permanent employee-owned benefits:

1. The earlier mixed-hand challenge remains: one successfully committed Beta hand must actually discover at least one Hidden Bug with Search and fix at least one Known Bug with Debug. Its benefit is the chance to discover Bugs only when a Feature re-triggers during a Design or Alpha specialization. [Challenge](2026-10-25-qa-challenge-buff-design-v1.md); [benefit](2026-10-25-qa-synergy-search-design-v2.md).
2. The pure-hand challenge unlocks a Search/Debug operation swap. A pure hand is four selected Search cards or four selected Debug cards in one successfully committed Beta hand. **The commit counts even when no Bug is discovered or fixed.** Training requires **three pure Search hands and three pure Debug hands** by the same employee, a minimum of six hands. Both counters **carry across projects**. [Earlier feasibility and swap draft](2026-10-25-qa-pure-hands-swap-design-v3.md).

Challenge progress belongs to the employed QA Specialist and starts with legal committed hands after hiring. It is not awarded retroactively from earlier releases, from a preview, a canceled/failed action, or a duplicate callback. Each benefit has its own trained flag; earning one does not automatically award the other. This follows the established employee-owned reward architecture. Exact save/UI fields remain implementation design.

## Selected arming and use rule; open card details

The user selected the **ability to swap Search and Debug** as the pure-hand reward. After training, **one new successfully committed pure Search or pure Debug hand in each project arms one swap for one later Beta hand in that project**. The sixth training hand **cannot** also arm the swap; a new pure hand is required after training completes. Project arming does not carry into another project, and further pure hands do not grant extra uses in that project. The arming hand may have zero Bug discovery/fix. The later [control ruling](2026-10-25-qa-swap-redraw-control-v5.md) selects one chosen QA card, the existing Beta button and a same-value change to the opposite card without a new draw or redraw cost. The opposite card counts for subsequent hand qualification. No free Bug discovery/fix, Core score, card slot or productive cycle is added. Multiple-employee stacking remains **OPEN**.

**Later resolved interaction:** Pure-hand classification uses the effective opposite card after Swap, as recorded in [version 5](2026-10-25-qa-swap-redraw-control-v5.md). The mixed challenge must still require real discovery and fixing; a changed card alone does not satisfy it.

## Reachability and evidence boundary

The current Beta pool has seven candidate instances and four selected cards. Search and Debug are each renewable, so four of one operation can legally appear. At the maximum current QA priority of 50%, Debug's 2:1 definition weight makes a fresh ordinary pool with all categories available contain four or more Searches about **1.76%** of the time and four or more Debug cards about **17.33%** of the time. This is source-derived initial-pool arithmetic, not a measured full-project training rate. Retained cards, redraws, changed priorities, exhausted finite definitions and total hand count change the actual opportunity. The user's both-operation requirement supersedes the version-3 recommendation to use either hand; measure reachability before implementation review, especially for the three Search-only hands.

No chance value for the synergy-search benefit or employee economy is approved by this note. The Employees button and implementation hold remain in place. The shared To Do List is unchanged.

## Local session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE and TODO first, then the QA design records and current Beta card/draw rules; inspected status and targeted diff before edits. Existing shared worktree changes were preserved. This decision note and the historical v3 banner, thread README/working notes, system design, DECISIONS and CURRENT_STATE were updated for the user's successive clarifications. Targeted `git diff --check` and active-summary term checks passed; no gameplay test or simulation was run for documentation-only work. No Drive, gameplay/test edit, TODO edit, commit or push.
