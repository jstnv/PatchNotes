# Balanced Craft Brief — pilot terms v1

2026-10-25. **PROPOSED pilot specification; authorized design work, no canonical activation approval.** User direction: “Ill let you cook for the Balanced Craft Brief pilot terms. Keep rewards unchanged.” This selects the Brief as the design focus and requires reward preservation; it does not explicitly approve every candidate number or activate Crown relationships. [Evidence and acceptance](BALANCED-CRAFT-PILOT-REVIEW-2026-10-25-v1.md).

## Recommendation

Retain the existing private Crown candidate's scoring, targets, hands and reward calculation. Adapt its acquisition to the approved paid Search direction. First determine whether players can access, afford and understand that version before proposing balance changes. This is the first Crown relationship slice only; compact cash work, commissions and support remain separate proposals.

| Term | Recommended pilot |
|---|---|
| Publisher / work | Crown & Quill / Reputation Brief; working title Balanced Craft Brief |
| Eligibility | Crown already unlocked through its existing frozen released Review ≥7.0 gate; no new Reputation floor, cash-Contract prerequisite or SideStreet standing requirement |
| Search | One successful paid search produces one persistent offer; one productive cycle, no extra direct fee; search earns no standing |
| Acceptance | Free, no advance or other payout; existing legality guards apply |
| Play | Two successful four-card hands; one productive cycle each; existing draw/finite Feature/Pass/synergy/priority rules |
| Full completion targets | Final Scope ≥9 and all four displayed Cores ≥4.0 |
| Full balance target | Highest minus lowest displayed Core ≤2.0; the existing fade reaches zero at spread 6.0 |
| Award | Existing candidate minimum(completion, balance), up to **10.00 Crown Reputation**; integer hundredths, credited within existing 100.00 standing cap |
| Other rewards | **$0 cash, $0 advance, 0 Promotion, 0 Investment**, including challenge reward caps; current cash Contracts retain all their own rewards |
| Failure/partial | Positive partial grade earns partial standing; zero grade earns zero; no standing loss, debt, clawback or extra penalty |
| New restrictions | None: no added Scope ceiling, no-redraw condition, perfect-Brief gate, deadline or roster restriction |

**Reward preservation includes the formula and rounding**, not just its maximum. Do not soften targets/fade, multiply completion by balance, add a minimum payout or remove existing partial routes while calling rewards unchanged. The numbers above remain the same private candidate values, proposed for this pilot rather than newly ACTIVE/TRIAL canonical rules.

## Exact retained arithmetic

Let `S` be final nonnegative integer Scope and `H[0..3]` final Core half-units (displayed 4.0 is stored 8). All divisions below floor; do not calculate using rounded UI percentages.

```text
N = 2*min(S,9) + sum(min(H_i,8)) + 2*min(min(H_i),8)
completion_bp = floor(10000*N/66)
spread_half_units = max(H_i)-min(H_i)
balance_bp = max(0,10000-1250*max(0,spread_half_units-4))
grade_bp = min(completion_bp,balance_bp)
requested_R_bp = floor(1000*grade_bp/10000)
credited_R_bp = min(requested_R_bp,10000-current_Crown_R_bp)
```

`100 R_bp = 1.00 Reputation`. Settlement uses the trusted current standing in the committed transaction and records requested versus actual credit. The event belongs to the Studio and Crown; it is once-only even if credit is clipped to zero. Search, acceptance and hand 1 grant no standing.

Constructed arithmetic examples, **not legal card-deal evidence**:

| Scope | Displayed Cores | Requested Reputation | Explanation |
|---:|---|---:|---|
| 9 | 4 / 4 / 4 / 4 | 10.00 | Full work and balance |
| 9 | 3 / 3 / 3 / 3 | 8.18 | Partial work, full balance |
| 5 | 2 / 2 / 2 / 2 | 5.15 | Partial work |
| 9 | 4 / 4 / 4 / 6.5 | 8.75 | Spread 2.5 limits award |
| 9 | 4 / 4 / 4 / 8 | 5.00 | Spread 4.0 limits award |
| 9 | 4 / 4 / 4 / 10 | 0.00 | Spread 6.0 misses balance |
| 0 | 4 / 4 / 4 / 4 | 7.27 | Existing no-Scope partial route |
| 9 | 0 / 0 / 0 / 0 | 2.72 | Existing Scope-only partial route |
| 0 | 0 / 0 / 0 / 0 | 0.00 | Empty balance alone pays nothing |

Scope above 9 adds no completion credit and no penalty. A very high but balanced set of Cores can still earn full credit; “4.0” is a minimum for full completion, not a precision target. Raising the dominant Core can reduce balance even though completion improves. Full grade at R99 requests 10.00 and credits 1.00; at R100 it requests 10.00 and credits zero, without turning a full result into failure.

## Acquisition and lifecycle

This supersedes the prospective release-generated Brief cadence in [the earlier Brief design](CROWN-BRIEFS-DESIGN-2026-10-25-v1.md), following the [approved Search direction](CONTRACT-SEARCH-DIRECTION-2026-10-25-v1.md). It does not rewrite historical simulator results.

1. Existing Crown first-unlock **cash** offer and pending/accepted work retain their original terms and source. Crown Briefs are still private; do not invent a historical canonical Crown Brief entitlement or an automatic free introductory Brief.
2. Once Crown is unlocked and the new Brief is activated, choose Crown → Reputation Brief and search. No repeated Review7 requirement on later releases; no compulsory game release between searches. One deterministic template is enough for this pilot.
3. One pending/active Crown Brief at a time, no expiry or replacement. A cash offer or another publisher's pending work may coexist under existing guards. No active-project/Contract/deal guard bypass. Rejected/stale/known-unavailable searches spend no cycle.
4. Freeze trusted publisher/Studio/source identity and versioned terms at offer creation. Freeze eligible owned Primitive Feature IDs at acceptance as the existing Contract foundation does. Do not include later Store acquisitions in an active frozen pool or filter out finite cards to manufacture easy balance.
5. Commit hand 2, completion and standing atomically. Duplicate completion, result dismissal, restored saves and repeated notifications cannot award again. No new abandonment or cancellation after acceptance.
6. Completion permits another paid search; it does not create another free offer. No new cooldown or arbitrary daily/season cap. Reaching R100 does not silently change the formula or add a hidden search gate; show zero remaining standing capacity before a paid search. Whether the product should later suppress capped work is separate design.

The private prototype's resolver validates a real release source. A searchable version needs a distinct trusted Search receipt and named source validation; **never put a fake release ID into the old resolver**. Preserve any explicitly supported legacy release-sourced records under their own rules. No arbitrary save-selected evaluator or widened unknown-schema acceptance.

## Player information and cost

Before spending the search cycle:

> Balanced Craft Brief — build Crown trust. Search: 1 cycle. Work: 2 hands, 1 cycle each. Up to 10 Crown Reputation. No cash, Promotion or Investment. Aim for Scope 9, every Core at least 4.0, and Core spread at most 2.0. Partial results can earn Reputation.

**Minimum three productive cycles from search to settlement**, plus any ordinary legal extra actions such as redraws. Acceptance and dismissal add none. Ordinary sales, rent, payroll, debt and world processing continue. Do not advertise a guarantee that cash at search time covers every later hand. Use existing affordability/block reasons for each productive action; no new three-cycle escrow or subsidy.

After finding the offer show the frozen terms and distinguish the already-spent search cycle from the two hands remaining. During hand selection use the [existing preview proposal](CROWN-PREVIEW-DESIGN-2026-10-25-v1.md): current → selected scores, separate completion/balance, limiting factor and requested/credited standing. Hand 1 is provisional and can fall; hand 2 is conditional on a valid successful commit. Hide stale/incomplete-selection quotes and never consume RNG for the preview.

Result: Full / Partial / Zero **grade** plus actual credited Reputation and any cap clipping. “No Reputation earned” must distinguish zero grade from full standing capacity. Do not show R20 as unlocking a playable Crown commission until that separate feature is approved and implemented.

## Pilot scope and decision boundary

Recommend one Brief template with these unchanged terms and the selected-hand explanation. Retain simpler expected-final-grade planning only as a research comparator; no automatic best-card button or redraw-policy experiment. Test current root-first founding rosters separately from valid historical Studio rosters. Do not tune around a favorable old wealthy Action seed.

If unchanged terms show poor access, report the blocker by layer: reaching Crown, paying search/hands, legal card supply, selecting balanced work, or understanding the display. A poor result does not authorize reward changes. A later separately approved term revision would get its own version and comparison.
