# SideStreet Relationship Brief — design proposal v1

2026-10-18 (America/Los_Angeles). **PROPOSED / OPEN.** The [bounded feasibility finding](SIDESTREET-RELATIONSHIP-BRIEF-FINDINGS-2026-10-18-v1.md) verifies legal card choices under today's two-hand SideStreet cash Contract and projects a one-hand score. It is **not** approval of a new Contract, reputation rule or numerical reward. The [one-hand independent cash brief](NEW-TYPE-DIRECTION-2026-10-18-v1.md) remains the selected first new type direction; this publisher Relationship Brief would be a later distinct type.

## Candidate player promise

SideStreet offers an optional, one-hand **Relationship Brief** with a clear small-scope promise. It is visibly separate from SideStreet's existing two-hand cash Contract and does not replace or retune that Contract. Acceptance freezes the offer ID, publisher, type/version, eligible four-card pool, terms and grade rule. A hand uses the ordinary seven-card draw and four-card play; Passes may repeat where current rules permit. No successful redraw qualifies for the promise. The player sees the target before acceptance and the projected progress/result by category and Scope.

The following terms are **candidates for a private prototype**, not approved values:

| Component | Candidate rule |
|---|---|
| One-hand completion `C` | Let `S` be played Scope and `H_i` each final Core in half-units. `C=floor(10000*(4*min(S,5)+sum_i min(H_i,4))/36)`, clamped to `[0,10000]`. This targets Scope5 and 2 points in each Core. |
| Promise grade `G` | If any successful redraw, `G=0`. Otherwise `G=10000` for Scope<=6, `5000` for Scope7 and `0` for Scope>=8. |
| Reputation evidence | Emit `min(C,G)` basis points and the component grades on **committed completion only**, keyed by immutable offer/result ID and publisher ID. The Publishers owner chooses the actual award maximum, fixed-point precision, cap and effects. A zero grade means no new reputation by default; losses remain OPEN. |
| Existing rewards | Existing SideStreet cash payout, challenge bonus and Promotion are unchanged. Cash/Promotion for this *new* Relationship Brief remain OPEN; do not silently reuse the two-hand job's numbers. |

In the one observed legal Sports deal, five of 35 possible four-card choices reach full combined grade with this completion target, seven choices have a half Scope promise and three miss it. Four named full/partial/miss outcomes were legally committed as current-rule hands and fresh-process replayed, but the proposed Brief's one-hand settlement was **not** executed. The combination counts are not encounter probabilities.

## Lifecycle questions still OPEN

1. **Eligibility and cadence.** [Release-paced repeatability](PUBLISHER-REPUTATION-CADENCE-PROPOSAL-2026-10-18-v1.md) is the current recommendation: at most one pending/active Relationship Brief per eligible publisher, and another only after a newly committed eligible game release, never an instant retry or backlog. SideStreet's first eligibility, priority against its cash offer, coexistence with other publisher offers and whether old saves wait for the next new release require a ruling.
2. **Publisher standing.** A separate Publishers owner must decide per-publisher ledger identity, starting value, maximum award, precision, cap, display, decay/loss, unlocks and old-save migration. The [weakest-grade formula study](PUBLISHER-REPUTATION-FORMULA-FINDINGS-2026-10-18-v1.md) recommends `floor(M*min(C,G)/10000)` for an as-yet-undefined fixed-point `M`; no amount is approved. Publisher standing must stay separate from Studio Prestige and Founder reputation events.
3. **Economic interaction.** Decide whether this new type pays any cash or Promotion, any acceptance advance, and whether it counts toward Starwave's three distinct completed publisher Contracts. Recommend no automatic Starwave qualification until explicitly approved; keep current cash-first progression unchanged.
4. **Experience and compatibility.** Define the offer/result copy, coexistence in the chooser, four-card feedback, missed-promise explanation, active-phase rollback, Studio-only Continue, old completed contracts, forged/duplicate results and exact once-only settlement. The current-game simulation proves only card access and hand legality.

## Evidence needed before adoption

After a user ruling on the core promise and ownership, make a named **private Contracts simulator variant** from its recorded canonical baseline. Implement only the one-hand candidate in that private `project/` and run legal SideStreet access routes across multiple specialties, owned-card pools, seeds and Store progressions. Predeclare route policies, seeds, limits and stopping conditions. Compare equal legal starting states/RNG, grade availability, actual full/partial/miss settlement, additional cycles, rent/credit outcomes and offer backlog. Replay representative cases in fresh processes. Explicitly exercise duplicate completion, failed/rejected hand, old-save and Studio Continue boundaries. Hand the source-pinned packet to PN Implementation only after Contracts and Publishers decisions are approved; passing runs never approve numerical balance on their own.
