# Crown Brief hand preview — proposed presentation specification

2026-10-25. **PROPOSED / OPEN.** The user delegated this design pass with “Do your thing” after the recommendation to define Core-balance and reward previews. This authorizes specification and evidence work, not canonical UI implementation or Crown activation. Rewards stay unchanged; redraw research remains parked. [Source and evidence](CROWN-PREVIEW-FINDINGS-2026-10-25-v1.md) · [implementation review handoff](CROWN-PREVIEW-HANDOFF-2026-10-25-v1.md).

## Recommendation

Use an **exact preview of the four selected cards**, next to the existing score area. Distinguish first-hand score value from the final-hand award. Give the player a concise reason for the limiting score. Keep future-draw forecasting in research tools.

| Approach | Benefit | Cost / disposition |
|---|---|---|
| Committed scores and challenge text only | Smallest presentation footprint | Current behavior gives little help with the effect of a selection; insufficient for this proposal |
| Selected-hand projection with a limiting-factor explanation | Exact, inspectable feedback for a choice the player controls | Requires a pure shared evaluator and clear provisional wording; **recommended** |
| Expected final award, probabilities or suggested best cards | Could help two-hand planning | Adds model uncertainty, information and CPU requirements; the 256-point research model is not a player guarantee. **Deferred** |

This is a focused addition to the existing Contract view, not a visual-system overhaul. Do not relocate the card stage, replace the shared HUD, or introduce a compulsory confirmation dialogue.

## Authority and scope

- Preserve the existing approved/ACTIVE-TRIAL Contracts and SideStreet behavior. Crown cash work and the proposed Reputation Brief are distinct products; this specification applies only to the Crown Brief.
- Crown Brief numerical terms remain OPEN: two successful hands, at most 10 Reputation, no cash/Promotion/Investment, completion and balance scored by the existing private CB2 evaluator. This design illustrates those candidate terms without approving them.
- Do not remove, alter or add redraws, priority actions, hand counts, reward amounts or eligibility. Parked redraw **research** does not mean disabling ordinary legal controls. Refresh the preview if an existing action changes its inputs.
- No “two Briefs unlock commissions,” “guaranteed R20,” new commission/support button or future-deal entitlement. Later Crown progression remains separately gated.

## Information at each stage

| Stage | Visible content | Award meaning / action |
|---|---|---|
| Offer, before acceptance | Brief identity, current Crown Reputation, frozen terms, two productive hands, up to 10 Reputation, no cash/Promotion/Investment; normal bills and sales continue | No award is committed by acceptance; no invented net-cash forecast |
| No or fewer than four selected cards | Committed scores and “Select four cards to preview this hand” | No selected-hand award or hypothetical four-card synergy; Play follows existing legality |
| Four legal cards, hand 1 | Current → after-selection Scope and four Cores; work completion, Core balance, limiting factor; “At these scores: +X.XX Reputation” | “Provisional — one more hand can raise or lower this value. No Reputation is awarded yet.” |
| Hand 1 committed | New committed scores; “1 hand remaining”; current Crown standing unchanged | Retain provisional wording. Never add the displayed estimate to standing |
| Four legal cards, hand 2 | Same score projection; “Award on completion: +X.XX Reputation”; current → resulting standing | Exact for this selection and current valid state, conditional on successful commitment; no future draw is involved |
| Resolving/animation | Preserve existing score animation and input lock; hide the selectable projection until the new presented state is coherent | No early result overlay, duplicate credit, stale prediction or new input window |
| Completed Brief | Frozen final scores, completion, balance, earned grade, requested/credited standing when clipped, actual new standing, zero currency rewards | Read the committed result and trusted standing event; do not recompute or issue settlement from UI |

Suggested action labels: **Play hand — 1 cycle** on hand 1 and **Complete Brief — 1 cycle** on hand 2. These remain presentation proposals. A valid score preview does not prove affordability. If productive-cycle legality blocks play, retain the scores but show “Cannot play: [existing financial reason]” beside the disabled action; do not describe its award as secured. Do not use Reputation to fund bills.

## Score and explanation rules

1. Show Scope and all four named Cores in a stable order: Graphics, Sound, Technology, Design. Current → selected values include primary, secondary and legal four-card specialization effects. Core values use whole or half points; never show internal half-units.
2. Show raw over-target scores. For example, Core 10 remains visible as 10 even though its completion contribution caps at 4. Scope 12 remains visible against the target of 9. Bars may fill to their goal, but numbers must not conceal excess. No Scope-overage penalty is introduced.
3. Show **Work completion** and **Core balance** as separate percentages. Help text: “The lower value sets the Reputation award.” They are not multiplied. Neither is the separate cash Contract challenge bonus.
4. Explain **Core spread** as “highest Core − lowest Core,” with the actual range and spread. Candidate tolerance is 2.0 points; above it, balance falls by 12.5 percentage points per extra 0.5 Core point, reaching zero at spread 6.0. At spread above 6.0 keep showing the raw spread and clamp balance at zero. Avoid blaming a single category when several tie for highest/lowest.
5. If balance is lower: “Core spread limits this award.” Include the spread and tolerance. If completion is lower: “More work is needed.” Name remaining Scope/Core goals from the actual projection, without prescribing a card or implying equal weight per deficit. If both are equal below 100%, show both limiting factors; if both are 100%, show “Full score at these values.” Hand 1 remains provisional even then.
6. Show negative as well as positive award changes relative to committed scores when four cards are selected, labelled **change in score value**, not Reputation already won/lost. A zero final award completes the Brief; it does not subtract existing Reputation.
7. Show the three unplayed cards as staying for the next hand, consistent with existing rules. Explain once in accessible Details: “Unplayed cards stay. Played Features are exhausted for this Brief; Passes can appear again.” Do not reveal the next four cards, odds, estimated zero-risk percentage or model-selected best quartet.
8. Percentages display the evaluator's integer basis-point result to two decimals; award/standing display two decimals. Compute with integers, including the existing floors, before formatting. Never round a displayed percentage back into an award.

### Standing cap

Use requested award and remaining room at the Crown cap separately. With a requested +8.18 at Reputation 99.00, prominently show **+1.00 credited → 100.00**, and “Score earns 8.18; Reputation cap limits this gain to 1.00.” At cap 100, show **+0.00 credited — at cap**, with the uncapped earned result still available. A full grade at cap remains a full Brief result, not “no work completed” or failure. On hand 1 these are conditional cap illustrations at the current standing, not booked awards.

### Small wireframes using recorded legal selections

These are information hierarchies, not screenshots, pixel specifications or implemented UI. Both use the same proposed compact panel; explanatory details may expand without covering cards or moving the Play button.

**First hand, Action 4521 / first Brief — after selecting four cards:**

| Preview after this hand | Value |
|---|---:|
| Scope | 0 → 5 / 9 |
| Graphics / Sound / Technology / Design | 0/0/0/0 → 6/2/4/2 |
| Work completion | 63.63% |
| Core balance | 50.00% |
| Core spread | 4.0 (target ≤ 2.0) |
| At these scores | **+5.00 Crown Reputation — provisional** |

“Core spread limits this award. One more hand can raise or lower it. No Reputation is awarded yet.”

This exact recorded route later finished at **0**, proving why +5.00 must not be presented as a guarantee or stored credit.

**Final hand, Action 4522 / second Brief — after selecting four cards:**

| Preview on completion | Value |
|---|---:|
| Scope | 6 → 9 / 9 |
| Graphics / Sound / Technology / Design | 7/4/5/5 → 7/8/8/9 |
| Work completion / Core balance | 100.00% / 100.00% |
| Core spread | 2.0 (target ≤ 2.0) |
| Award on completion | **+10.00 Crown Reputation** |
| Crown Reputation | **2.50 → 12.50** |

“Full score at these values. Complete Brief — 1 cycle.” The normal legality check still applies. The frozen run committed this exact award; this is not a newly executed GUI test.

## Pure projection contract for PN Implementation

Use the active Brief's trusted definition/terms and ordinary hand planner. Validate four distinct current candidate tokens, finite Feature eligibility and the current offer/hand/sequence before projecting. Derive projected Scope/Cores from the planner's score additions and evaluate them through the same versioned completion/balance/standing calculation as settlement. The current generic hand plan leaves final reward fields zero on hand 1, so those fields cannot serve as its provisional score-value quote.

Proposed presentation data: offer/terms identity, source hand/sequence, selected tokens, committed and projected Scope/Cores, completion/balance/grade, spread, requested/credited award, standing before/after, provisional/final flag, limiting factors and separate legality/block reason. Method/field names are implementation choices, not approved schema. Do not persist this transient projection, add a save schema, or trust client-supplied preview values at commitment.

Viewing, selecting, deselecting and opening Details must not advance cycle/sequence, mutate finance/standing, mark Features exhausted, consume redraws or touch RNG. Cache only by all relevant inputs, including current standing and frozen terms, and invalidate on selection/state/action changes. At confirmation revalidate the actual tokens and current state; rejected/stale selection leaves every durable field/RNG unchanged and removes the stale award quote.

Committed scores may temporarily differ from visually presented scores during the existing hand animation. The preview must remain unavailable during that period. Completion must still appear only after the shared presentation finishes. Do not weaken atomic completion or overwrite current UI work to add this panel.

## Layout and access

Place the compact score-value summary within the current Contract score/status area, with Details for formula explanation and cap breakdown. Keep card selection, existing financial blockers and the action row visible. At the currently supported window sizes, long copy wraps without overlapping cards; Details scrolls if necessary. Respect current theme, UI density, motion and keyboard/focus conventions.

Use text and numbers as well as color for increases, decreases and blocked/provisional states. Details must be keyboard reachable and dismissible with focus restored. Hover or selection must not steal focus or announce the same long paragraph repeatedly. No extra mouse-only affordance, new global tutorial requirement, or automatic recommended-card selection.

## Decisions still needed

This packet recommends the exact-selected-hand presentation. User acceptance of this design, Crown numerical/activation scope and the existing migration/structural gates remain OPEN. Human comprehension is untested: can a player explain why more Core can reduce the award, why a first-hand estimate is not banked, and why cap-level zero credit is not a failed Brief? Numeric arithmetic or the planner's improvement cannot answer those questions.
