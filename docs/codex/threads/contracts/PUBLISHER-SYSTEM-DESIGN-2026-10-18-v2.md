# Publisher system — recommended design v2

**SUPERSEDED by [v3](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md).** Preserve this draft as a historical input; its proportional commission standing and cash-only Ironclad support recommendation are not current.

2026-10-18 (America/Los_Angeles). **USER-DIRECTED GOAL / DESIGNER-SELECTED PROPOSAL / NUMERIC PRIVATE-PILOT CANDIDATE.** The user delegated further design without requiring more input. This document chooses a coherent proposed model and formulas for review. It does not approve values, implement gameplay or lock a release. [Direction v1](PUBLISHER-SYSTEM-DIRECTION-2026-10-18-v1.md) records the user's goals; [economic screen](PUBLISHER-SYSTEM-ARITHMETIC-FINDINGS-2026-10-18-v1.md) and [relationship formula screen](PUBLISHER-RELATIONSHIP-ARITHMETIC-FINDINGS-2026-10-18-v1.md) test bounded arithmetic only.

## Core relationship model

Each **Studio–publisher pair** owns two separate, monotone integers in `[0,10000]`, displayed as 0.00–100.00. A founder changing Studios does not carry either relationship to the new Studio. All events carry a publisher ID, Studio ID, source deal ID, terms version and immutable commit ID; an event applies once. Existing five publisher unlocks and current work-Contract cash/Promotion/challenge rewards remain unchanged.

| Track | Meaning | Gained by | First effect | Candidate status |
| --- | --- | --- | --- | --- |
| **Reputation `R_p`** | This publisher's trust in this Studio as a contractor. | Explicit reputation-bearing work Briefs and delivery of commissioned games. | Opens game commissions at gates 20/50/80. | Shape recommended; scale/gates PROPOSED. |
| **Investment capacity `I_p`** | This publisher's willingness to commit resources to the Studio's future games. It is a rating, not cash or a spendable pool. | Delivery of commissioned games and a supported Studio game meeting both frozen Review and Month3 sales criteria. | Allows support at 15 and determines its committed budget. | Shape recommended; amounts PROPOSED. |

The older Bible term **Publisher Investment** meant one work Contract's reward budget. Retain that historical offer-budget meaning in old records. Name the new stored field `publisher_investment_capacity_bp` and each support deal's fixed amount `support_budget_cents`; do not reuse the old payout field or retroactively turn it into a relationship ledger. Reputation and investment capacity do not decay or decrease in the first pilot. Missed promises award zero new capacity; cash already committed is not clawed back.

## Three offer families and progression

1. **Work Contracts and Relationship Briefs.** Existing cash-first offers are preserved and grant no automatic or retroactive `R_p`/`I_p`. A new, explicitly reputation-bearing Brief can use a publisher's signature challenge and the existing two-hand Contract framework. The first candidate is the [SideStreet two-hand Brief](SIDESTREET-RELATIONSHIP-BRIEF-PROPOSAL-2026-10-18-v3.md), whose exact targets remain PROPOSED. The prior [release-paced cadence](PUBLISHER-REPUTATION-CADENCE-PROPOSAL-2026-10-18-v1.md) becomes this design's candidate schedule: at most one pending/active Brief per eligible publisher; a later successful Studio-developed game release is the next issuance chance; no instant refill or missed-release backlog. Ironclad's initial Contract stays challenge-free; a later Ironclad Brief may teach Reputation separately. Other publishers need legal promise definitions before activation.
2. **Commissioned game Contracts.** Once `R_p` reaches a tier gate, the Studio can quote a publisher-owned game at project planning. The publisher pays a fixed quoted full fee for full delivery, owns that title's IP and distribution revenue, and the Studio receives no sales royalties on it. The Studio retains its reusable Feature technology and receives developer credit/Fanbase from people playing the game. An accepted deal is bound to one project and its later release ID. It cannot be assigned retrospectively after seeing Review.
3. **Support for a Studio-owned game.** Once `I_p≥1500`, the Studio can quote a different deal at project planning. The Studio owns the title and its ongoing sales; the publisher commits upfront cash and targeted launch marketing, then recoups from a limited share of **that title's** post-platform sales. Meeting both frozen Review and cumulative unit targets by release-age Month3 increases `I_p` for *future* deals. It never changes the accepted game's budget or reopens its result.

Only one game deal can be bound to a project. A work Contract still follows the existing one-active-work-Contract guard; game-deal confirmation and `BeginProject` should be one atomic transaction in Studio. No mid-project deal acceptance, stacking multiple publishers on one title, ordinary game-deal expiration or retroactive support. The game-deal browser can recompute a fresh quote from current ledgers, while confirmation freezes all terms.

## Reputation formula and commission tiers — PROPOSED

For a new reputation-bearing Brief, freeze completion `C_bp` and promise grade `G_bp` in `[0,10000]`. At its one committed result:

`ΔR_p = floor(1000 × min(C_bp, G_bp) / 10000)`; `ΔI_p = 0`.

A full Brief gives 10 Reputation points, half gives 5 and a missed promise gives 0. This adopts the *shape* of the earlier [formula finding](PUBLISHER-REPUTATION-FORMULA-FINDINGS-2026-10-18-v1.md) with a new trial maximum; the finding did not approve 10 points. No Brief payout, existing challenge bonus or legacy completed result is changed by this recommendation.

| Commission tier | Minimum `R_p` | Quoted full fee | Review target | Full `R_p` and `I_p` gain |
| --- | ---: | ---: | ---: | ---: |
| 1 | 20.00 | $6,000 | 6.0 | 15.00 each |
| 2 | 50.00 | $8,000 | 7.0 | 20.00 each |
| 3 | 80.00 | $10,000 | 8.0 | 25.00 each |

The displayed fee is frozen cents, not a percentage of future sales. The accepted brief may also freeze an authored Genre, Theme, owned-Feature or era prerequisite, but an offer must be checked as legally producible before it appears. The **first SideStreet pilot** would use any currently legal Genre/Theme and no extra Store gate; later authored publisher-specific content is OPEN. The offered tier never increases mid-project when Reputation changes.

At launch, compute exact Scope completion `S_bp=clamp(floor(10000×delivered_scope/required_scope),0,10000)` and the frozen one-decimal Review in tenths `r`. For tier Review target `t`, define `V_bp=clamp(500×(r−(t−20)),0,10000)` and `D_bp=min(S_bp,V_bp)`. On a publisher-owned commissioned release:

- `fee_paid_cents = floor(full_fee_cents × D_bp / 10000)` once at launch.
- `ΔR_p = ΔI_p = floor(full_tier_award_units × D_bp / 10000)` once, capped at 100.00 per ledger.
- Full Scope and Review at/above target pay the full flat quote. A miss receives the **prequoted underdelivery salvage** on this two-point Review band; it never changes sales ownership or creates royalties. At tier1, full Scope and Review5.0 pay $3,000; Review5.9 pays $5,700; Review≤4.0 pays zero. This exception to the full flat fee must be prominent before acceptance.
- An unlaunched/abandoned project has no committed release or payment event. Mid-project cancellation, if later added, requires an explicit policy; it is outside this first pilot.

The title counts as a Studio-developed release for Review/Fanbase, release-based publisher unlocks and ordinary release history. It **does not** count as a completed legacy work Contract for Starwave's three-Contract gate; neither do Relationship Briefs. Its observed units remain in the market/fan ledger, while **Studio sales entitlement and Bank qualifying sales are zero**. The sales HUD and finance report must identify publisher-owned units separately from Studio earnings. No current source implements these rights; implementation requires a typed release ownership path.

## Support quote, recoupment and criteria — PROPOSED

At `I_p≥1500`, display `i=floor(I_p/100)` whole Investment points. Freeze the support budget `B_cents=min(300000, 50000+2500×i)`: $875 at15, $1,750 at50, $3,000 at100. `I_p` is **not spent** on acceptance. This is an amount the publisher will offer per eligible project, not Studio cash until a deal commits. Publisher personality splits that fixed budget into funding and marketing:

| Publisher | Cash share basis points | Review ≥ | Cumulative units after Month3 ≥ |
| --- | ---: | ---: | ---: |
| Ironclad | 10,000 | 6.5 | 900 |
| SideStreet | 8,000 | 7.0 | 1,000 |
| Crown & Quill | 6,000 | 7.5 | 1,100 |
| Neon Circuit | 4,000 | 6.5 | 1,200 |
| Starwave | 5,000 | 8.0 | 1,350 |

Let `raw_cash=floor(B_cents×cash_share_bp/10000)`, `marketing_points=floor((B_cents−raw_cash)/3500)` and `funding_cents=B_cents−3500×marketing_points`. The final cash includes any sub-$35 marketing remainder, so `funding_cents+3500×marketing_points=B_cents` exactly. The $35 conversion is a trial budget equivalence, **not** a player exchange rate or final economic valuation. Funding is transferred once at deal/BeginProject commit as a new, labeled **nonrecourse publisher support advance**. It is spendable then and may service ordinary due bills under the existing finance ordering, but does not count as earned sales or Bank underwriting income. Marketing points are bound to this project and added once to its launch Awareness alongside existing banked Promotion, **before trait conversion**, without consuming another publisher's Promotion or affecting an older release.

The publisher's title-only recoupment uses the authoritative cumulative post-platform net entitlement `N_cents` after the existing 30% platform retention. Through the title's first 12 release-age earning months, `publisher_recoup_cumulative_cents = min(B_cents, floor(N_cents×2000/10000))`. Each cycle/settlement books only the positive delta from the prior committed cumulative share. The Studio earns `N_cents−publisher_recoup_cumulative_cents`, with cash paid at the existing month boundary. After Month12 the publisher's cumulative share freezes permanently and later sales are fully the Studio's. If sales cannot repay the budget, the shortfall is the publisher's risk: no Studio debt, arrears, interest or off-title claim. Finance shows platform retention, publisher recoup and Studio net separately; no double 30% deduction.

The accepted deal freezes Review threshold, Month3 unit threshold, share/cap and six-earning-cycle observation point. Review is the existing frozen launch Review. Units are the title's **actual cumulative earned units** after its sixth productive earning cycle (release-age Month3), not projected Month1 units, settled cents, calendar-month number, or all-Studio sales. At that once-only observation, if both thresholds pass: `I_p=min(10000,I_p+1000)`; otherwise `ΔI_p=0`. Reputation does not change. A late sales recovery does not retroactively pass the Month3 promise; a miss does not claw back funding or marketing. Existing/old releases are never enrolled after launch.

At Investment15 and neutral Review7.0/Awareness100/market1.0, the [arithmetic screen](PUBLISHER-SYSTEM-ARITHMETIC-FINDINGS-2026-10-18-v1.md) puts SideStreet at $700 upfront, +5 Awareness, 1,098 Month3 units, and only +$13.81 cumulative Studio receipts versus no support by Month12. This is a **reference sensitivity check**, not a legal campaign or proof of value. Lower demand/quality can make support worse after recoup; higher Investment can make it materially better. The first playable trial must test those branches at legal cash and calendar boundaries.

## Event, save and player-facing contract

**Identity and ordering:** one new relationship event per committed work-result, commissioned release, or support Month3 milestone. Use source offer/deal/release IDs and an event-kind key; reject previews, retries, duplicate callbacks and unsupported old states without mutation. Reconcile all new cash/entitlement/ledger fields atomically with existing finance, Fanbase, publisher unlock and checkpoint validation. Keep Studio-only Continue; no inferred mid-phase save. Version every accepted term set so later balance changes do not rewrite active or completed deals. A frozen support quote cannot be upgraded by another game's mid-development Investment gain.

**Player explanation:** each publisher page shows Reputation, Investment capacity, next commission gate and current support quote. The commission screen shows the fixed full fee, underdelivery salvage band, required Review/Scope/content and publisher ownership/no Studio sales. The support screen shows upfront funding, targeted marketing, 20% title-only recoup capped by `B`, Review and Month3 unit targets, observation timing and future Investment reward. Results show actual grade, fee/recoup, title owner and exactly why a milestone passed or missed. The Bank/Finances screens distinguish publisher advances from sales and ordinary debt.

**Current integration boundary:** the existing [code-owned Contract registry](../../../../patch-notes/scripts/contracts/contract_definitions.gd) covers five Primitive work offers only; [RunState](../../../../patch-notes/scripts/run_state.gd) records publisher offers, Promotion, releases and finance but has no relationship/deal ledger. [Launch settlement](../../../../patch-notes/scripts/simulation/launch_settlement.gd) freezes Review/units at release, and [ReleasedGameSales](../../../../patch-notes/scripts/sales/released_game_sales.gd) earns units by title age. Commission sales rights and support recoup therefore require new typed release/finance/checkpoint paths; adding IDs to the existing work scorer is insufficient.

## Adoption order and remaining uncertainty

1. **Publisher relationship foundation:** typed per-Studio/per-publisher ledgers, idempotent events, old-save zero baseline and read-only UI, with no automatic awards on old cash offers.
2. **One reputation-bearing Brief:** SideStreet two-hand terms after broader legal-route tests; keep Ironclad's first offer introductory. Test release-paced issuance, grades, exact ledger event and rollback.
3. **One commissioned-game pilot:** SideStreet tier1, project-bound quote, full/salvage fee, publisher-owned sales, Fanbase and release-gate behavior, finance and old-save migration.
4. **One supported Studio game pilot:** SideStreet funding/marketing, title-only capped recoup and six-earning-cycle criteria. Test low/neutral/high market, partial/missed criteria, support accepted before project start, actual cashflow, replay, both-size presentation and exported Studio Continue.
5. **Broader publisher profiles and tiers:** only after the pilots show legal access and understandable tradeoffs. Revenue share, exclusivity, control, multi-Studio publisher competition, premium content prerequisites and final balance remain separate future decisions.

No shared TODO entry or canonical implementation is authorized by the arithmetic screens. The [thread HANDOFF](HANDOFF.md) holds proposed tasks and acceptance criteria until an exact private runtime and adoption review are ready.
