# Action Pass demand for the fixed Primitive Feature build — 2026-10-30

**Status: RESEARCH / THEORETICAL DEMAND.** No Pass Budget formula, initial allowance, Scope requirement, production gameplay file, or final balance is changed or approved.

## Fixed baseline and rules

Use exactly the [previous exhaustive search's](2026-10-30-action-feature-build-finding-v1.md) three Design Feature hands followed by its three Alpha Feature hands, all 24 Features once, in their reported order. Their final hand-enhanced Core is **Graphics 27 / Sound 10 / Technology 46 / Design 35**, with 35 played Scope against a fixed **30-Scope requirement**. Neutral base Action standards are 40/26/40/26, variance is zero, and this experiment assumes zero remaining Bugs. No Feature can share an extra Pass hand without breaking the fixed four-Feature hand grouping and its synergies, so every added Pass activation occurs in a separate four-Pass hand.

The `card_ledger.json` has four renewable Primitive Pass definitions: `graphics_pass` G+2, `sound_pass` S+2, `technology_pass` T+2, and `design_pass` D+2. Each has printed Scope 0, no secondary Core, and `phase: design`. The Design hand command uses these four; Alpha explicitly accepts the same Design-phase Pass definitions (`scripts/simulation/alpha_hand_command.gd:300-307`, `scripts/simulation/development_catalog.gd`). Each committed Design/Alpha hand selects **exactly four current candidate instances**. Repeated instances of a renewable Pass definition may coexist and be played together; only finite Feature IDs are checked for duplicate selection.

`ProductionHand.calculate` applies ×1.5 specialization to four cards with the same primary Core **even if all four are Passes**. Thus four Graphics Passes yield G+12, or four Sound Passes yield S+12. Mixed four-Pass hands get only their printed 2 per card. Balanced Production requires a Feature in that hand and cannot boost a Pass-only hand. Passes add no Scope or Feature bug pressure, but each played hand is a productive cycle subject to current transaction/calendar checks.

## Exact minimum

Run `node docs/codex/threads/simulation-engine/action_pass_requirement.mjs`; the [retained result](action-pass-requirement-2026-10-30.json) pins the previous Feature result and current Pass ledger. The script enumerates all **35** four-Pass multisets (four categories, repetition allowed) and every 0-, 1-, 2-, and 3-hand combination. It maximizes the actual Review production formula at each count, including the 1.25 ratio cap, imbalance penalty, and half-up displayed rounding. With fixed Feature hands, possible Pass counts are multiples of four.

| Pass hands | Pass activations | Best added hands | Final G/S/T/D | Unrounded / displayed Review |
|---:|---:|---|---|---|
| 0 | 0 | none | 27/10/46/35 | 5.5102 / **5.5** |
| 1 | 4 | 4 Sound | 27/22/46/35 | 6.9198 / **6.9** |
| 2 | 8 | 4 Sound + 4 Graphics | 39/22/46/35 | 7.8192 / **7.8** |
| 3 | **12** | 4 Sound + 4 Sound + 4 Graphics | **39/34/46/35** | 8.8007 / **8.8** |

**Minimum: 12 Pass activations in three additional hands.** Eight is insufficient: its globally best hand combination displays only 7.8, below the 8.0 threshold (unrounded 7.95 for half-up display). Four Sound Passes are more valuable than four Graphics Passes first because Sound begins at 10/26 versus Graphics 27/40. The third hand adds another S+12; Sound's 34/26 ratio caps at 1.25 in Review. Technology and Design Passes are inferior for this fixed baseline because those categories already meet or exceed their standards.

One phase-specific maximizing sequence is:

1. Play the three original Design Feature hands, unchanged. Then play **four Graphics Passes** as one Design hand. Design Pass count: **4**.
2. Finalize Design. Play the three original Alpha Feature hands, unchanged. Then play **four Sound Passes**, followed by **four Sound Passes**, as two Alpha hands. Alpha Pass count: **8**.
3. Finalize Alpha, eliminate remaining Bugs through normal Beta work, and launch. Final Core **39/34/46/35**; capped ratios **0.975/1.25/1.15/1.25**; mean **1.15625**, population standard deviation **0.1123262547**, production/neutral zero-Bug Review **8.8007 → 8.8**.

The **4 Design / 8 Alpha split is illustrative, not mathematically required**. The same three Pass-only hands can be distributed 0/12, 8/4, or 12/0 across Design/Alpha if the necessary candidate instances appear and phase transitions occur afterward. The printed Pass definitions and specialization arithmetic are identical in both phases; the fixed Feature sequence and total score are unchanged.

## Normal draw boundary

Current Design/Alpha pools draw seven candidates, retain unplayed instances, refill four played slots, select finite Features without replacement, and draw renewable Pass definitions with replacement (`design_hand_command.gd:193-235`; `alpha_hand_command.gd:206-230`). The play validators permit four instances of one Pass ID in a hand. A constructive positive-probability draw pattern is: show each prescribed four-Feature group alongside three retained Graphics Passes in Design, then refill at least one more Graphics Pass after the last Design Feature hand. In Alpha, retain three Sound Passes alongside each prescribed Feature group, refill a fourth after the last Feature hand, then refill four Sound Passes after the first Sound hand. All four Pass definitions have positive weight under ordinary positive Core priorities. Thus the sequence is **legally possible through ordinary draws**, but unlimited budget does not guarantee it. The six exact all-Feature hands are themselves draw-sensitive. No seed-specific full campaign, acquisition/finance route, or probability estimate was produced; this is a mathematical demand measure, not evidence that an ordinary player can routinely obtain the sequence. The prior 35-Scope Primitive subset also requires extra Store ancestors in a normal owned pool, as detailed in the fixed-build finding.
