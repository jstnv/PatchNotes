# Publisher offers, results and finance specification v1

2026-10-22. **PROPOSED presentation/acceptance specification.** Uses the candidate terms in [v3](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md) and proposed [v4 renewal](PUBLISHER-RENEWAL-AND-FAILURE-PROPOSAL-2026-10-22-v4.md). Examples are exact arithmetic for those terms, not new approval or evidence of implemented UI. Keep presentation values derived from one authoritative quote/result rather than duplicating formulas in UI.

## Publisher page

Show `Reputation 35.00 / 100` and `Investment capacity 15.00 / 100` with short help: “Reputation unlocks commissioned work. Investment capacity determines support for your Studio's games.” Show the next authored commission gate only when that tier has real enabled content. Do not show tiers2/3 as available in the SideStreet tier1 pilot.

List offer families separately: Work Contracts, Reputation Briefs, Commissioned Games, Game Support. Ironclad remains the introductory work Contract. Existing challenges retain separate bonus cash/Promotion and must not be presented as Reputation/Investment rewards. Hidden/unimplemented publisher families should not look purchasable.

Derive an availability reason from the real quote service, with stable priority: active project/Contract or checkpoint gate; publisher locked; insufficient rating; previous support result pending; qualifying recovery result missing; project prerequisites; affordability. Provide exact unresolved facts instead of a generic “locked.” Example: “Support assessment pending: 4 of 6 productive cycles since launch.” After a miss: “Meet the full requirements of a new SideStreet commission to qualify for another support offer.” At the cap with a success: “Investment capacity remains100.00. Another support offer is available.”

## Commission quote

For the candidate tier1 example:

> **Develop for SideStreet**
>
> Up to **$6,000 at launch**. No upfront funding.
> Full payment requires **Review6.0** and **30 Scope**.
> SideStreet owns this game's sales. Your Studio keeps its reusable technology and earns developer Fans from people playing it.
> Full delivery earns **+15 Reputation and +15 Investment capacity**, up to each rating's100 cap.

Show the prospective project, genre/theme and all required features/era conditions above confirmation. Required Scope is the positive value from this legally prepared project, never a hardcoded30 in UI. Display actual clipped relationship gains when near the cap.

Show the underdelivery terms prominently: “A lower Review or incomplete Scope reduces your fee. Full Scope with Review5.0 pays$3,000; Review4.0 or below pays$0. A partial result earns no new Reputation or Investment. SideStreet still owns the game's sales.” A Details panel can show the grade equation. Do not hide partial payment entirely in a tooltip.

If banked Promotion exists, show its exact amount and state that it will be used by this next successful launch, including a commissioned title. Explain that Studio-paid post-launch campaigns are unavailable on this publisher-owned game. Confirm action: **Accept commission & start game**; alternate: **Start without publisher**; Back returns to planning at no cost. Start controls show actual productive-cycle and due-bill consequences through the existing quote system.

## Support quote

For I15:

> **SideStreet support for your game**
>
> **$700 funding now** and **+5 base launch Awareness** from marketing. Studio traits apply to launch Awareness normally.
> You own the game. SideStreet receives **20% of this game's sales after the platform fee**, up to **$875**, during its first **12 sales months**.
> The$875 limit includes$700 funding and$175 marketing support. Your payment may exceed the cash funding you receive.
> Earn **+10 Investment capacity** by reaching **Review7.0** and **1,000 actual copies sold** after the first **3 sales months**.

Directly underneath: “The assessment occurs after six productive cycles following launch. A miss awards no new Investment. Funding is not clawed back, and unpaid support creates no debt or claim against another game. Recoup ends after24 productive cycles following launch; all later sales after the platform fee belong to your Studio.” At a cap, show “Capacity stays100.00; a successful assessment qualifies your Studio for another support offer” under v4.

Offer a brief projected cash ledger using current cash, exact funding, known cost and due payments for the funded start. Distinguish conditional future sales from spendable cash. Obtain the funded quote before the unfunded affordability gate; if the advance covers the actual start and bills, the quote must be confirmable. If it still cannot fund the start, show the exact missing amount. Confirmation must requote changed inputs and never silently switch terms.

Confirm action: **Accept support & start game**; alternate: **Start without support**; Back returns freely. On I25 the same formula must show$915 funding, +6 base Awareness, and$1,125 total recoup limit. This is a useful rounding example: the UI must derive all three values from the frozen terms.

## Result and progress

Commission release result shows target and actual Review/Scope, completion percentage, actual once-only fee, actual clipped R/I gains and sales owner. A 5.9/30-of-30 result reads “95% delivery; $5,700 fee; no new relationship points.” A full result at a rating cap remains full delivery even when its displayed numerical increase is zero.

Supported-title progress keeps launch Review fixed, shows actual copies so far, and marks “assessment pending” until age6. At assessment, show each criterion separately and one final pass/miss. Example retained weak case: Review2.8 versus7.0;512 copies versus1,000; **targets missed, +0 Investment**. A later sales revival must not overwrite this original result. Show a recovery action alongside the miss. Final assessment may occur while developing another game; queue its notification once, display it at the next safe presentation boundary, and preserve it through Continue without repeating the award.

Recoup progress is separate from assessment progress. Display amount recovered, total limit and remaining earning cycles. Label the remainder “potential future publisher share” while active and “written off” after expiry. It must never be displayed as a Bank loan balance or overdue bill. A game can miss its support target yet fully repay recoup, or pass the target while leaving unrecovered recoup; those are independent outcomes.

## Finance and title ledger

Every title detail should distinguish these values:

| Field | Meaning |
| --- | --- |
| Copies sold | Actual cumulative earned units; includes publisher-owned titles for developer/Fanbase history |
| Gross title sales | Existing sales gross before platform retention |
| Platform fee | Existing30% platform retention, deducted once |
| Net title sales | After platform retention, before publisher rights |
| Publisher share | All net for commissioned titles; capped title-only recoup for support |
| Your Studio's earned sales | Net title sales less publisher share |
| Paid to your Studio | Studio entitlement actually settled on the game's existing calendar boundaries |
| Awaiting settlement | Studio earned less Studio settled |

The Studio sales HUD totals **your Studio's sales**, with a clearly labeled title-unit view if it includes commissioned games. Finance month details include nonoperating support funding separately from operating sales, work/commission receipts, Bank financing and debt service. Do not change the tax/credit treatment of work or commission receipts in a presentation task. Account for the support row in cash reconciliation without adding it to operating profit.

Evidence reference examples: a prior successful supported title had$12,139.84 net title sales,$875 publisher share,$11,264.84 Studio earned and$10,705.40 settled. Displaying the raw$12,139.84 as Studio earned overstates it by$875. A commissioned title with$11,202.78 raw net has$0 Studio sales; its$6,000 commission fee belongs in its separate receipt category.

## Acceptance

At1152×648 and1280×720, a player must be able to see the upfront amount, full payment conditions, ownership, recoup limit, funding-versus-marketing split and failure consequence before confirmation. Verify keyboard focus/Back, scroll access and no color-only status. Do not bury ownership or funding obligations in optional tooltips. Actual human comprehension and exported interaction require separate evidence; a text specification or headless run does not close them.

Headless integration must compare every displayed number to the same accepted quote/result and exact finance journal. Exercise partial/full/capped outcomes, duplicated notifications, concurrent milestone on project-start cycle, funded rescue, stale/rejected confirmation, two historical support deals, save/Continue and old-save migration. Every public signal/checkpoint observer must see fully committed deal, cash, project ID and publisher event state. Rendering and native/exported tests belong to the implementing thread after design approval.
