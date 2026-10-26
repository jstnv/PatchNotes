# Crown & Quill — proposed publisher progression v1

2026-10-24. **Designer recommendation / CANDIDATE. No new Crown rule is approved, queued or implemented.** User delegated this design pass while SideStreet P4 implements. [Plan](CROWN-PROGRESSION-PLAN-2026-10-24-v1.md), [findings](CROWN-PROGRESSION-FINDINGS-2026-10-24-v1.md), [proposed work](CROWN-PROGRESSION-HANDOFF-2026-10-24-v1.md).

## Identity and intended player choice

Crown is the quality-focused boutique: prove you can produce a well-reviewed game, demonstrate balanced craft in small Briefs, then earn better-paid commissioned work and marketing support for your own titles. The player can pursue Crown directly after meeting its existing unlock, without first completing SideStreet's relationship progression. Reputation and Investment remain separate per Studio and publisher; neither is spent on accepting work.

Use balanced Cores to judge the short Brief. Use frozen Review and required Scope to judge a commissioned **game**. Genre weights make equal game Cores an inappropriate universal requirement: the current legal Action7.1 release had unequal half-unit Cores38/26/36/24. Adding the Brief's absolute-gap test to commissioned games would impose another untested restriction. A supported game adds actual sales expectations because the publisher is investing in distribution success.

## What is current versus proposed

| Layer | Current authority | Crown progression recommendation |
| --- | --- | --- |
| Publisher discovery | Any committed release with frozen Final Review >=7.0 unlocks Crown permanently. | Retain; no renewed7.0 requirement before every Brief and no added Ironclad/SideStreet prerequisite. |
| Existing cash Contract | One persistent two-hand Crown offer; maximum$1,920 including$150 advance, up to12 base Promotion; separately graded challenge bonus up to$100/+4. | Preserve all existing terms, counts, saves and guarantees; no Reputation backfill or conversion. |
| Reputation Brief | SideStreet has an approved separate two-hand relationship type. No Crown relationship producer exists in the inspected source. | Separate optional two-hand Crown Brief; useful graded standing, up to10R, no immediate cash/Promotion/Investment. |
| Commission | SideStreet R20/Review6/$6,000 pilot is approved and implemented. | Crown R20, frozen positive required Scope, Review7.0 full delivery, maximum$8,000, full-only +15R/+15I. All these Crown values are candidates. |
| Support | SideStreet P4 is approved and in implementation; no accepted Crown rollout. | Crown I15, same budget schedule, nominal60% funding/40% marketing, Review7.5 and1,100 units at earning age6. Reuse accepted P4 structural rules after its acceptance. |
| Expansion | Other publishers/tiers and final balance are OPEN. | One Crown tier first; no automatic tier2/3, era-specific prerequisites, exclusivity, deadlines or standing losses. |

The older [system proposal](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md) supplies Crown's support profile. Its obsolete capacity-step renewal guard is replaced in this recommendation by the [approved SideStreet earned-result structure](PUBLISHER-P4-ADOPTION-2026-10-24-v1.md), applied independently to Crown only if Crown is later approved. This document does not expand SideStreet approval to Crown.

## Approaches considered

1. **Copy SideStreet progression and change the name.** Small implementation delta, but the no-redraw/Scope-ceiling Brief loses Crown's existing craft identity. Not recommended.
2. **Shared relationship framework with authored publisher terms. Recommended by the designer.** Keep the same opportunity, ownership, save and renewal semantics; distinguish the Brief's promise, commission quality/fee and support mix. This keeps player explanations consistent and gives the differences a concrete purpose.
3. **Require all-around balance on every Crown game, bespoke genre licenses and special royalty rules.** Strong restrictions but a much larger interaction surface; risks fighting normal genre ratios and adding unverified content prerequisites. Defer.

The user delegated preparation; they have not selected or approved these numerical terms.

## Reputation Brief

### Opportunity and lifecycle

- On a **new** qualifying release that first unlocks Crown, offer one separate Crown Brief alongside the existing first-unlock cash offer. Do not require completion of that cash offer; neither offer is consumed by accepting the other. Preserve one globally active hand-based Contract.
- Later committed Studio-developed releases may issue one Brief when Crown is unlocked and no Crown Brief is pending/active. A failed launch, preview, restore or Brief completion cannot issue one. Pending offers persist without expiry or replacement; releases skipped while a Brief is pending do not accumulate a backlog.
- Scope this first candidate to the same eligible Primitive Feature pool used by Crown cash work, frozen at acceptance. Two successful four-card hands, one productive cycle each, cumulative final grading. Redraws follow existing legal rules; Crown has no extra no-redraw or Scope-ceiling penalty.
- Store source release/offer/publisher/definition version. Migration creates no historical standing or past-release backlog; already-unlocked saves become eligible on the next new release. Previously earned cash-Contract results are untouched.
- Briefs do not increment legacy completed-cash-Contract counts or unlock Starwave by masquerading as cash work. Multiple publisher Briefs may coexist; all use the same global active-Contract guard.

### Exact candidate grading

Let `S` be final aggregate Scope and `H_i` the four nonnegative Core totals **in half-units**. Reuse Crown's existing completion geometry:

```text
N = 2*min(S,9) + sum(min(H_i,8)) + 2*min(min(H_i),8)
C = floor(10000*N/66)
d = max(H_i)-min(H_i)
G = 10000                         if d <= 4
G = max(0,10000-1250*(d-4))        otherwise
grade = min(C,G)
requested_reputation_bp = floor(1000*grade/10000)
```

One hundred standing basis points equals1.00 displayed Reputation. Clip the award against Crown's own100.00 cap through a trusted P1 event; retain the committed result when credit clips to zero. Award once on hand2; partial positive progress is not labeled failure. Zero grade records a completed zero-award Brief without cash/debt/standing penalties. No immediate replacement.

Full credit needs Scope>=9, each Core>=4.0 and highest-minus-lowest<=2.0 points. Scope beyond9 is not penalized. Core spread reaches zero promise at6.0 points. Weakest-Core weighting favors coverage, but the spread test can still reduce reward when a dominant Core increases; make this visible after hand1 and before final play.

Use `min(C,G)` for the first private candidate. A product `floor(C*G/10000)` compounds partial penalties; promise-only would award full standing to an empty balanced score. The arithmetic screen verifies those properties, not accessibility. Scope-only synthetic work can still earn up to2.72R; retain useful partial progress for this candidate and measure whether a real low-effort route abuses it before changing that rule.

| Illustrative final work | Candidate standing |
| --- | ---: |
| Scope9; all four Cores4.0 |10.00R|
| Scope9; all four Cores3.0 |8.18R|
| Scope5; all four Cores2.0 |5.15R|
| Scope9; Cores4/4/4/6.5 |8.75R|
| Scope9; Cores4/4/4/8 |5.00R|
| Scope9; Cores4/4/4/10 |0.00R|

These are constructed arithmetic examples, not guaranteed legal hands. Two perfect Briefs reach proposed R20; three8.18R results would also do so. Neither path is yet demonstrated for a real Crown Brief. The fresh legacy first-four cash route scored full completion but zero balance grade, so copying its policy is insufficient.

## First commissioned game

Candidate access is **Crown Reputation20**, independently of SideStreet. Recommend a maximum$8,000 fee and Review7.0 target for the first candidate: the existing Crown unlock already asks for a7.0 release, and the stricter7.5 promise is reserved for support. Compare$6,000 and7.5 before any numeric approval; the arithmetic alone cannot justify the premium.

Quote/freeze the actual prepared project's required Scope, Genre, Theme, title identity, publisher, standing provenance and terms from the pre-start state. Use current legal preparation; do not assume required Scope30 for every size. No invented Feature ownership, genre license or era prerequisite in this slice. Only one deal per project; no publisher stacking or mid-project acceptance/cancellation. Follow accepted P2/P3 prospective quote cadence; do not add a further mandatory release cooldown merely from older proposals.

```text
scope_bp = min(10000,floor(10000*delivered_scope/required_scope))
review_bp = clamp(500*(review_tenths-50),0,10000)   # full at7.0, zero at5.0
delivery_bp = min(scope_bp,review_bp)
fee_cents = floor(800000*delivery_bp/10000)
```

Full delivery alone requests +15 CrownR and +15 CrownI, independently clipped. Partial/zero results retain exact committed source/receipt with no standing loss. For sensitivity at target7.5, shift the zero floor to5.5; never accidentally retain SideStreet's4.0-to6.0 ramp while displaying a7.0 target.

Publisher owns the commissioned title's sales; Studio retains technology and normal developer/Fan history. Keep raw units/market data but zero Studio/Bank title-sales entitlement. Pay the fee once at launch; preserve ordinary bills and existing banked Promotion consumption with disclosure. No additional balanced-Core or sales target for this commissioned game.

## Support for a Studio-owned title

Candidate Crown I15 unlocks support; standing is not spent. Budget remains `min(300000,50000+2500*floor(I_bp/100))` cents. Nominal cash is60% of budget; convert the remainder to whole Awareness points at3,500 cents each and return sub-point remainder to funding, using integer floors. At I15 this is **$525 funding plus10 Awareness** against SideStreet's$700 plus5; total budget remains$875. This is a funding/marketing tradeoff, not evidence either package is better.

Freeze Review>=7.5 and actual cumulative units>=1,100 at earning age6. Both pass to request +10 CrownI; misses grant zero with no debt/clawback/standing loss. Reuse P4's title-only20% recoup up to the full budget through earning age24, expiry/write-off, nonoperating funding, pre-start terms, atomic planning and Studio ownership. Preserve prepared-Scope integrity without inventing an extra Scope assessment target.

Repeat support requires the previous assessment to resolve, a subsequent Studio-developed release and a new **same-Crown** full commission or successful supported assessment after prior acceptance. Use canonical P1 ordinals, earliest qualifying event, frozen previous/qualification IDs, no banked backlog and cap100 success semantics. SideStreet results cannot renew Crown support. Keep one unresolved assessment per Studio/publisher and one deal per project; older recoup may overlap a new deal.

## Player explanation

Show the four choices separately: **Cash Contract**, **Reputation Brief**, **Publish my game / commission**, and **Support my game** when available. Brief copy states two productive cycles, Reputation-only reward, balance targets and exact progress to CrownR20. Do not show proposed content as playable before it exists. A failed support assessment shows Review and units separately and points to full Crown commission recovery. Quotes disclose owner, funding/fee timing, required Scope, targets, recoup cap/expiry and banked Promotion use.

## Acceptance and open questions

1. **Legal Brief access is the next gate.** Test visible-card balance-aware and completion-first choices from identical initial state/RNG, finish partial outcomes, retain first-four as a naive control and compare skip at equal release and calendar boundaries. Include redraw costs and finite-pool exhaustion. Do not inject a7.0 unlock or future deals. Keep lack of Crown unlock distinct from failure after unlocking.
2. Measure chances/cycles/releases to R20 and cash lows/arrears. “Two excellent or three graded Briefs” is a design aim after Crown discovery, not a passing result. If ordinary grades repeatedly stall, compare softer targets or a different award mix in a separately declared variant; do not silently tune seeds or budgets.
3. Validate a real Crown commission and I15 support path only after the Brief producer works. Check full/partial/miss, repeat/cap, prospective migration, offer coexistence, independently isolated publishers/Studios, named source events and current-state replay.
4. P4 is still in flight. Rebase any later candidate on its accepted source, then use a named private simulator. Do not edit an existing candidate or transplant historical scalar ledgers. Canonical adoption requires a later explicit Crown trial ruling and PN Implementation handoff.
5. Current funding usefulness, Review7 versus7.5 accessibility, fee premium, marketing targets, future-era balance tolerance, broader publisher tiers and human comprehension remain OPEN. No shared TODO entry from this draft.
