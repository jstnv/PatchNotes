# Crown grade feedback and zero-award streaks — design v1

2026-10-25. **PROPOSED presentation; rewards remain APPROVED pilot terms.** User delegated this work with “Ill let you cook for the grade feedback and zero-award streaks. Keep rewards unchanged.” [Findings](CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md) · [review handoff v3](CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md).

## Recommendation and scope

Keep the selected-card preview from [v1](CROWN-PREVIEW-DESIGN-2026-10-25-v1.md) and the paid-Search distinctions from [v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md). Add a concise explanation of the limiting score, a final-hand warning when all choices from the current cards earn zero, and a quiet reminder after two consecutive zero-earned Crown Briefs.

The user authorized investigation and unchanged rewards. The exact copy, reminder threshold of two and current-card warning are recommendations from this design pass, not separately approved gameplay or presentation rules. Canonical Crown activation remains gated.

| Approach | Assessment |
|---|---|
| Selected-hand preview alone | Smallest change; explains the selected outcome but can leave a player searching for a positive final choice that does not exist. Retain as the foundation. |
| Selected preview, current-card warning and earned-result history | Recommended. Uses visible scores/cards and trusted completed results; directly covers the eight recorded zero results without predicting future draws. |
| Predicted win probability, recommended cards, consolation rewards or adjusted draws | Outside this proposal. The research model is not a calibrated player forecast, and rewards must remain unchanged. |

This applies only to the exact Crown Reputation Brief definition and frozen terms. Existing Crown cash Contracts and their separate challenge bonuses, SideStreet Briefs, other publishers, normal legal redraws, Search/hand costs and acceptance rights retain their current rules. No automatic play, completion, retry, dismissal, abandonment or selection is added.

## Information hierarchy

Use the existing Contract score/status area and expandable Details. Keep cards, normal financial blockers and the action row visible. The primary summary contains Work completion, Core balance and the appropriate provisional/final award label. Details contain the four named Core scores, Scope, spread, thresholds and cap breakdown. Use numbers and text alongside color.

| State | Suggested presentation | Meaning |
|---|---|---|
| Search / offer | “Search: 1 cycle”; “Brief: 2 hands”; “Up to 10.00 Crown Reputation”; no cash, Promotion or Investment reward | Fresh search through completion uses three productive cycles. A pending offer needs no repeat Search. Normal sales and bills continue. |
| Fewer than four selected cards | “Select four cards to preview this hand.” | Show committed scores; hide any previous selected-hand quote. |
| Four valid cards, hand 1 | “After these cards”; “Current score value: +X.XX Reputation”; “One hand remains. This value can rise or fall. No award yet.” | Show projected scores. Do not animate or display an increase to actual standing. A full or zero current score is provisional. |
| Four valid cards, final hand | “On completion: +X.XX Crown Reputation”; actual standing before → after | Exact for this selection, frozen terms and current standing, subject to the ordinary legal commit. |
| Resolution / incoherent animation | Existing score animation and input lock | Hide transient selectable quotes and warnings until the presented state is coherent. Never reveal a completing result early. |
| Completed result | “Brief complete”; “Crown Reputation added: +X.XX” plus actual standing and grade reasons | Read the committed result and trusted relationship event. The panel never settles rewards. |

**Wording correction:** use “Brief complete” for two committed hands. The older recommended phrase “Work complete” can imply 100% Work completion; Puzzle4522 actually completed its Brief at 57.57%, 81.81% and 72.72% Work completion. This recommendation supersedes that wording in v2, without changing the completion rule.

## Explain the grade precisely

Show raw Graphics / Sound / Technology / Design values, including over-target values and half points. Core 10 must remain visible as 10 even though its contribution toward the Core-4 completion goal is capped. Show raw Scope against 9; Scope over 9 has no penalty here.

“The lower of Work completion and Core balance sets the grade.” Preserve minimum(completion, balance), exact integer floors and the existing Reputation cap. The two percentages are not multiplied.

| Limiting result | Suggested explanation |
|---|---|
| Balance below completion | “Core spread limits the grade.” Show highest and lowest categories/values and their difference. List ties in stable category order. |
| Completion below balance | “Work completion limits the grade.” Details list actual remaining Scope/Core targets; do not imply every deficit has equal weight or prescribe a card. |
| Equal below 100% | “Work completion and Core balance both limit the grade.” |
| Both 100% | “Full grade at these scores.” Hand 1 still has no committed award. |
| Balance zero | “Core balance is 0% at this spread.” Show the actual spread, full balance at ≤2.0 and zero balance at ≥6.0. |

Above spread 2.0, balance falls by 12.5 percentage points for each extra 0.5 Core point, reaching zero at spread 6.0. Keep the raw spread visible beyond that endpoint. A selected-hand decrease is a **change in score value**, not a deduction from already earned Reputation.

At the standing cap, distinguish grade value from credited Reputation. Example: “Grade value: +10.00; Added: +0.00 — Crown Reputation is at 100.” At 99.50 standing, the same grade adds 0.50. A cap-clipped positive earned result is not a zero-earned challenge result.

## Final-hand current-card warning

On the final hand only, examine every legal four-card selection from the current seven visible candidates using the trusted pure hand planner and frozen evaluator. In this pilot that is at most 35 selections. If every valid selection has requested Reputation zero, show:

> With these cards, every four-card selection earns 0.00 Reputation.

Place it near the final-hand grade summary; keep the specific selected-score explanation available. The wording is limited to the current visible cards. Existing legal redraw controls remain available under their current rules; refreshing the candidates invalidates this result. This study adds no redraw policy or experiment.

Do not show this warning on hand 1. In one recorded first hand, every current selection has a zero provisional score; future cards are still unknown. Do not infer whole-Contract impossibility from that snapshot. Do not publish the model's expected final award, hypothetical zero frequency, “best” card choices or a guaranteed recovery promise.

Use **requested** Reputation when evaluating this warning. A positive grade with no credit because standing is capped gets the cap explanation. If candidate legality cannot be established, the terms are unsupported, no valid quartet exists, or the state is stale/incoherent, mark availability information unavailable; never equate missing data or financial blockage with “all choices score zero.” Play retains its ordinary legality and user confirmation through the normal action.

## Consecutive zero-earned results

Proposed trigger: after **two** consecutive completed Crown Briefs with requested Reputation zero. Show one inline summary in the completed-result Details and the Crown Brief's existing Studio/offer information when available:

> Last 2 Crown Briefs: 0.00 Reputation earned. Check Work completion and Core balance before your next Brief.

Update 2 to the actual streak count. Keep this informational: no modal, extra confirmation, new menu, forced tutorial, changed price, altered eligibility, bonus, guarantee, draw adjustment or automatic retry. It is a conditionally visible summary, not a new notification event; repeated viewing must not replay a toast or sound. Clearing a UI view does not clear the underlying result history.

At R100, suppress the proactive improvement reminder and prioritize the cap explanation. Factual history remains available in Details. The count does not change; the presentation must not suggest that improving a grade can add Reputation beyond the cap. [Bounded display check](studies/crown-grade-feedback-20261025-v1/CAP-REVIEW-ADDENDUM.md).

Derive the count from the existing validated relationship ledger and trusted completion sources. Filter exact publisher `crown_quill` and event kind `crown_quill_brief_completion_v1`, checking the source belongs to the applicable Brief definition/terms. Preserve trusted ordinal/cycle ordering. Do not count previews, accepted/incomplete work, rejected commands, cash challenges or other publisher products.

- Requested award >0 resets the count, even if credited award is zero at R100.
- Requested award =0 increments the count. Under the exact pilot arithmetic, this is equivalent to a zero grade; positive grades cannot round to zero requested Reputation.
- Interleaved events from other publishers/products do not count or reset this Crown-Brief streak.
- Duplicate event/source identity, invalid ordering, unverified source or unavailable/incomplete history means **history unavailable**. Never fabricate a precise streak or infer one from an aggregate Reputation total.
- An empty, validated complete ledger has a count of zero. A missing history is a different condition.
- Derive on open/restore from existing authoritative records. Add no persistent streak field or migration solely for this presentation. Exact current-source restore and source validation remain implementation acceptance requirements.

The reminder is an explanation aid. It does not make three Briefs reliably reach R20 or remove unlucky outcomes. Whether this progression variability is acceptable to players remains open.

## Recorded information examples

These are data wireframes, not implemented UI or screenshots. Source: Puzzle4522, second paid Brief.

| Field | After selected hand 1 | Selected final hand / committed result |
|---|---:|---:|
| Scope | 2 / 9 | 9 / 9 |
| Graphics / Sound / Technology / Design | 0 / 0 / 5 / 4 | 10 / 2 / 11 / 6 |
| Work completion | 30.30% | 81.81% |
| Core balance | 25.00% | 0.00% |
| Spread | 5.0 | 9.0 |
| Score / award | +2.50, provisional | +0.00 on completion |
| Current-card warning | Hidden: another hand remains | All 35 current choices earn zero |
| Actual standing | 0.00, unchanged | 0.00, unchanged |

After this committed second Brief, the reminder displays a count of two. After the third zero it displays three. The Action and Simulation routes each had two zeros separated by a positive award; neither earns a consecutive-two reminder.

## Pure-query and integration contract

Obtain state from the active trusted Brief. Identity includes offer/definition/terms, hand, action sequence, current candidates and score state, standing/cap revision and coherent presented-state revision. Validate four distinct current eligible tokens. Use the existing score planner for multi-Core and specialization effects, then the same versioned completion/balance/award rules as settlement. No client-supplied projected score is authoritative at commit.

Return selected projection, limiting factors, provisional/final mode, separate finance legality, and optional current-card availability. A first-hand UI must not bind the diagnostic hypothetical standing-after values to the actual standing widget. Return history as a separate derived summary with available/count/trigger fields; unavailable is not count zero.

Repeated selection, Details, warning enumeration and history display must leave cycle, sequence, finance, standing, used Features, redraw budget, world state and RNG unchanged. Revalidate the actual hand on commit. Never reuse a cached quote after candidate/selection/score/standing/terms/sequence changes, successful redraw, restore, new offer, reset or animation transition. Cache only complete relevant inputs; do not bypass runtime validation to save UI work. Run the 35-option check on relevant input changes, not every animation frame. The offline Python timing is not a native performance budget.

Use current theme/folder components, keyboard navigation and focus restoration. Warnings must wrap without covering the cards or action row at supported sizes. Avoid repeating long announcements on every selection. Details can expand/scroll; ordinary locks and disabled-action reasons take precedence. The implementation thread owns native integration and verification against newer canonical finance/checkpoint work.

## Remaining acceptance

Offline arithmetic and history fixtures pass; no user comprehension or live UI benefit is established. Human review must check that players can explain provisional versus credited Reputation, why meeting Scope can still yield zero, what “with these cards” does and does not imply, and why positive grade at R100 is not a zero-earned streak. Current-source purity, finite-card legality, native/export behavior, Studio restoration and Crown activation remain gated in the handoff.
