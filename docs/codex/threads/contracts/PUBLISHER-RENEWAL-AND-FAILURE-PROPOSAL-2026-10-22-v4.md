# Publisher progression, renewal and failure proposal v4

2026-10-22. **PROPOSED design; pending review.** The user authorized autonomous design and bounded simulations. This proposal refines [design v3](PUBLISHER-SYSTEM-DESIGN-2026-10-18-v3.md); it does not approve any new numerical values or canonical implementation. V3 remains the source for the retained fee, grade, package and rights formulas. This document supersedes the designer recommendation for support renewal and the stop-at-100 rule only. The independent-client cash Brief remains the selected first new Contract type; publisher Relationship Briefs remain a separate proposal.

## Recommended progression

Keep separate per-Studio/per-publisher Reputation and Investment capacity. Reputation opens commissioned game work. Investment sets the size of support for Studio-owned games. Neither is a currency to spend, and neither transfers automatically when a founder changes Studios. Preserve current five work Contracts and their approved challenge rewards; do not backfill relationships from old results.

Retain the existing candidate progression for the first SideStreet pilot: full two-hand Relationship Brief +10 Reputation; commissioned game access at20; full tier1 delivery +15 Reputation/+15 Investment; support access at15; a supported game meeting both frozen targets +10 Investment. All ratings cap at100. Partial commission delivery earns the prequoted cash salvage and zero relationship points. A missed support target awards zero new Investment. Do not add rating losses, debt, interest or a funding clawback in this pilot.

The two tracks now have a clear decision: a commission exchanges a game's future sales for a quoted launch fee and standing; support preserves Studio ownership while trading a limited share of that game's sales for earlier funding and launch marketing. Reputation Briefs do not directly grant Investment. Ordinary self-published success does not automatically grant publisher standing.

## Renewal alternatives

| Alternative | Benefit | Cost or failure |
| --- | --- | --- |
| V3: require10 more Investment since acceptance; stop at100 | Simple numeric gate; prevents repeated packages after a miss | Removes access at the cap, hides the recovery action behind a number, and can permit renewal while the previous supported result is still unresolved |
| Clamp the numeric gate at100 | Small change, preserves existing progression below the cap | A naive clamp lets unchanged100 qualify after a miss and repeat funding without a new qualifying result |
| **Recommended: require a new qualifying result** | Same intended early success/recovery path, works at the cap, explains why another offer is available | Requires chronological event identities and validation instead of reconstructing eligibility from only the current rating |

The deterministic [comparison](studies/publisher-overnight-20261022-v1/renewal-model.json) is a synthetic state model, not a campaign. It exposes the cap discontinuity and naive-clamp retry. Legal evidence and limitations are recorded separately in the overnight finding.

## Exact proposed renewal rule

First support: the publisher is unlocked, Investment is at least15, the Studio is at the ordinary project-planning boundary, the selected project is legally preparable, and all normal funded transaction checks pass. No prior-support requirement exists.

Later support from that publisher requires all of the following:

1. The previous supported project has launched and its sixth-earning-cycle assessment has committed. Only one unresolved supported assessment per Studio–publisher pair; continuing recoup on older titles may overlap.
2. A qualifying event committed after the previous support acceptance: **either** that latest supported game passed both targets **or** a later fully delivered commission for the same publisher qualified. A partial commission, ordinary release, old success, other publisher's success or Relationship Brief does not qualify.
3. At least one later Studio-developed release exists after the previous acceptance, using the same issuance cadence as v3. No immediate pending-offer backlog is created. The supported game's launch itself satisfies the later-release condition; its assessment still takes six productive cycles.
4. Current Investment remains at least15. Investment100 qualifies; success at the cap must retain an explicit qualifying event even when the actual numerical award is zero.

Represent the reason as a reference to an already committed event, not an inventory of stackable tokens. A quote selects the earliest qualifying committed event after the previous acceptance, using a stable commit ordinal to break simultaneous events. Confirmation freezes this event ID and all terms, then consumes that eligibility by advancing the previous-acceptance boundary. Extra pre-acceptance successes cannot buy multiple future support offers. If a qualifying commission commits while the prior support assessment is unresolved, it can qualify later once the assessment resolves; the quote stays unavailable until then. An unknown result can never be treated as a miss or a pass.

All qualification uses the **pre-start Studio snapshot**. A productive start cycle that matures an older title's assessment cannot retroactively qualify or improve the quote being accepted. The newly committed event becomes available at the next legal planning opportunity. Quote preview and Back do not consume eligibility. Failed or stale confirmation preserves it. A completed acceptance/retry produces one funding receipt and one deal.

## Failure and recovery

| Outcome | Immediate consequence | How to proceed |
| --- | --- | --- |
| Reputation Brief partially meets its frozen requirements | Proportional Reputation under the retained min(completion,promise) formula; no Investment | Earn a later release-paced Brief |
| Commission below full Review or Scope requirement | Quoted proportional cash salvage; publisher still owns sales; zero relationship gain | A later qualifying release permits another commission quote under existing cadence |
| Supported game misses Review, units, or both at age6 | No new Investment, no clawback or new debt; title-only recoup continues to its original cap/age24 limit | Complete a later full commission for that publisher to qualify for another support offer |
| Supported game meets both criteria | +10 Investment, capped at100, plus a committed success record | A later support quote can use the success once at a legal Studio planning boundary |
| Sales recover after a missed assessment | Studio receives its normal title rights; original assessment stays missed | Recovery does not backfill Investment or create a renewal event |
| Publisher cannot recover its full package by age24 | Remaining recoup is written off; all later title net belongs to the Studio | No credit bill, cross-title claim or future deduction |

Recovery is a route, not a promised easy rescue. A commission still requires legal development funding and full delivery. The legal continuation in the overnight study tests this route; broader specialties and distressed cash remain open.

## Monetary and score formulas retained for review

- Tier1: R20 gate; full fee600,000 cents; Review target60 tenths; positive required Scope frozen at quote. `S=floor(10000*delivered_scope/required_scope)` clamped0–10000; `V=clamp(500*(review_tenths-40),0,10000)`; `D=min(S,V)`. Fee=`floor(600000*D/10000)`; only D10000 grants the nominal1500bp relationship award, clipped separately to each rating's remaining headroom.
- SideStreet support: `B=min(300000,50000+2500*floor(I_bp/100))`; `raw_cash=floor(B*8000/10000)`; `marketing=floor((B-raw_cash)/3500)`; `funding=B-3500*marketing`. Acceptance freezes amounts; I is never deducted.
- Recoup through age24: `min(B,floor(cumulative_raw_post_platform_net*2000/10000))`; after24 freeze that cumulative recoup permanently. Commit positive deltas once. Studio earned net = raw post-platform net minus cumulative recoup; monthly cash settlement uses only Studio entitlement. No second platform deduction.
- Support success: frozen launch Review>=70 tenths **and** actual cumulative earned units>=1000 at exactly the sixth productive cycle after launch. Award=`min(1000,10000-I_before)` once; log nominal reward, actual clipped reward, criteria and success separately.

Do not use raw title sales as Studio/Bank income for publisher-owned commissions. Support funding is a nonoperating advance; title rights after recoup are Studio sales. Paying bills with the advance can affect ordinary payment history but must not falsely turn the advance into operating profit. The $35 marketing conversion is package accounting only, never a player conversion action.

## Chronology, save and adoption requirements

Persist versioned publisher/Studio/deal/project/release IDs, accepted terms, qualification-event ID, acceptance commit ordinal, each result's ordinal and actual clipped gains. Reconstruct ratings and support eligibility in commit order across Briefs, commissions and support assessments. Do not validate all commissions first and all support results afterward: that can invent capacity at an earlier acceptance. Verify each frozen acceptance capacity and source event against the exact preceding ledger state; a later award cannot justify an earlier offer.

Support arrays must allow validated historical deals. A size<=1 shortcut contradicts renewal. Reconcile all title rights against finance earned/settled/unsettled totals and all funding/fee receipts. Preserve old-save zero initialization only for pre-feature saves; never silently erase real relationships/deals. Corrupt or unsupported data rejects the whole restore while keeping the last valid generation. A runnable campaign without a valid ending Studio checkpoint fails adoption acceptance.

Implementation review must resolve private/canonical drift and the known quote, funded-start and signal-order gaps before adoption. Frozen private variants stay evidence, not a patch to transplant wholesale. P5 tiers2–3 and other publishers, relationship losses, exclusivity, deadlines, premium prerequisites and final balance remain deferred. The remaining substantive review decision is whether to adopt this earned-result renewal policy with the retained candidate values for a bounded pilot.
