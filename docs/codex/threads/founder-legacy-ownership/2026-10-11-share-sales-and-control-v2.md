# Share sales and loss of control — selected design v2

**Date:** 2026-10-11 (America/Los_Angeles). **Authority:** the user's share-sale/valuation-offer direction followed by delegation to choose the remaining architecture. **Status:** SELECTED DESIGN; no gameplay implementation or numeric balance approval. This resolves and supersedes the two OPEN interpretation questions in [v1](2026-10-11-share-sales-and-control-v1.md). It amends the offer/transaction timing in [SPEC-v2 §§3, 7–8](SPEC-v2.md); all other v2 rules remain current.

## Decisions

1. **A competitor's bid is optional for the founder.** A competitor may initiate an unsolicited, valuation-based offer for specified founder shares. The player can accept, decline or make a priced counteroffer. Only explicit acceptance of the exact live terms can sell founder shares. No valuation, hostile label, warning, board vote, deadline or scripted event compels a founder sale. A counteroffer is a new proposal and transfers nothing until accepted. The AI may refuse it.
2. **Voluntary selling needs a real buyer.** At a safe Studio boundary the player may request offers for a specified number of their shares and a minimum total price. The request is visible to eligible corporate/passive buyers at the next six-cycle corporate evaluation. It is not a stock exchange or a guaranteed cash-out. A request can be withdrawn until a transaction commits. The player chooses whether to accept any returned bid.
3. **A paid transaction changes control, never the offer itself.** Every primary share subscription and secondary transfer uses the common validator and an immutable transaction ID. The controlling holder is recalculated from the committed cap table after settlement. A direct holder controls only if `2 × holder_units > issued_units`. The founder may lose majority without any rival obtaining majority; show this as “no majority owner,” not “competitor takeover.”
4. **Shares of other holders remain transferable with their own consent.** Passive or corporate shareholders may sell to a rival under the same priced, funded rules. A secondary sale of their existing shares leaves `issued_units` and the founder's units unchanged, so it cannot remove an existing founder majority. It can replace a controller when the founder is already a minority CEO; that can put the CEO mandate up for review at the next safe Studio boundary. The founder's equity is untouched.
5. **Primary issuance is also a sale of stock, with dilution.** A new investor pays the target Studio for newly issued equal shares. This can lower the founder's fraction and remove founder majority, but target authorization requires affirmative votes representing more than 50% of the pre-issue outstanding units. A founder who currently owns a majority can therefore block such an issue. A hostile buyer cannot create an unauthorized issue to dilute the founder.
6. **Corporate timing remains bounded.** AI buyers originate offers and autonomously buy willing non-founder shares during the six-cycle corporate evaluation. A founder's acceptance of a live offer commits at the next safe player boundary after fresh validation; it does not run another corporate search. This is the narrow exception to [SPEC-v2](SPEC-v2.md)'s quarter-only transaction sentence. Refusal or expiry changes no shares. A queued CEO-role change waits for the existing safe transition boundary.

## Valuation-based offer contract

For `q` offered equal units out of `S` issued units, use the current positive equity valuation `V_equity` as the disclosed anchor: `base_package_cents = max(1, ceil(V_equity × q / S))`. The actual bid is positive exact cents and may include a disclosed buyer premium or seller counterprice. A bid shows the valuation date/version, `q`, total and per-unit consideration, buyer funding, current and resulting ownership fractions, expiry, and whether acceptance removes founder majority or grants the buyer majority. Revalidate valuation/terms, seller units, buyer available funds after known dues and the ownership graph at commitment. An expired or stale offer requires a fresh quote; it cannot silently reprice and complete.

Secondary consideration goes to the selling holder, never the target Studio. Founder consideration uses the selected `external_owner_settlement` record without a personal wallet or automatic new-Studio capital. Primary proceeds go to the target Studio and increase issued units. Either route retains target assets, debts, employees, IP and contracts with that Studio.

## Control and role examples

All examples start with 1,000,000 issued units and apply exact integer votes.

| Committed transaction | Result |
|---|---|
| Founder 600,000; outside holder 400,000 sells all 400,000 to a rival | Founder still holds 60% and remains controller. The rival holds 40%; warning may show a significant rival stake, but there is no takeover. |
| Founder 600,000 sells 100,000 to a rival, with the other 400,000 dispersed | Founder holds exactly 50% and loses majority. The rival does not automatically control; the role/board state must show no majority owner. |
| Founder 600,000, outside holder 400,000; founder authorizes 250,000 new investor units for paid primary funding | Founder holds 600,000 / 1,250,000 = 48%. Control is lost through disclosed, authorized dilution; the target receives the subscription cash. |
| Founder 400,000 is CEO by mandate; an outside holder sells its controlling 600,000 to a rival | Rival becomes controller. Founder equity remains 40%; the new controller may review the CEO mandate at a safe boundary. |

## Player-facing sequence and acceptance

1. Show actual holdings and valuation before a voluntary sale request or competitor offer. Every accept screen shows the exact post-transaction cap table and a distinct warning if founder majority, CEO mandate or subsidiary control will change.
2. A hostile buyer may accumulate willing non-founder stakes with staged, once-only warnings. These describe actual committed shares and credible live bids; they do not claim that refusal of a founder bid can somehow transfer founder shares.
3. On founder acceptance, commit money and shares atomically, then recalculate control. Let any active development/Contract phase reach its legal safe boundary. Present CEO mandate, negotiated exit or new-venture transition only when the resulting governance actually requires it.
4. Deterministic tests must cover acceptance, rejection, counteroffer refusal, expiry, stale valuation, oversold units, buyer funding failure, exact 50%, no-controller state, authorized dilution, other-holder sale while founder retains majority, and minority-CEO controller replacement. An invalid acceptance changes no cash, shares, AI RNG, news or CEO role. A valid decline may close the offer and record that response, but changes no cash, shares or control.

**Dependencies and limits:** Buyer appetite, premiums, counteroffer acceptance bounds, valuation coefficients, warning percentages, quote expiry and financed acquisition frequency remain CANDIDATE/OPEN calibration. The AI Competitors thread still owns its rival development policy and opening cohort. No simulator, canonical gameplay, shared TODO or other thread document is changed by this ruling.
