# 2026-10-09 decision: rival Store admission liquidity

**Status: LOCKED first-slice AI spending policy; exact accounting inputs remain OPEN.** The user selected the recommended reserve rule after the [remaining-systems review](2026-10-09-remaining-systems-design-review-v1.md). This governs whether the AI elects an otherwise legal admission. It changes no player Store transaction, quote or purchase eligibility.

## Selected rule

Before an AI-planned new admission at the [Studio boundary](2026-10-09-shopping-trigger-decision-v1.md), require the rival's **currently spendable exact-cent cash** to cover the Store's **current conditional cost to completed ownership** for that node **plus known due obligations through its planned Research completion window**. Count the down payment once within the completed-ownership quote; do not add it a second time. Count only obligations whose amount and due date are known at the decision, including already-due amounts; do not pretend unknown future income, sales, familiarity gains, optional costs or unapproved employee research will pay the difference. If the test fails, defer this admission and consider another legal action. The candidate must still pass unlock, relevance, era, quote and FIFO rules.

This is an **AI prudence screen, not an escrow or mandatory player reserve**. If later Research payment is unaffordable after actual settlement or a changed quote, the rival follows ordinary legality and may idle or choose other legal work; it receives no free progress. Requote each real installment. Current live later nodes need one Research action; any future multi-action node needs authored duration and due-window rules before it enters this policy.

The exact due snapshot, transaction ordering and cash allocation used by the G2 hypothetical project envelope remain **OPEN**. This admission screen must not silently become that envelope's development budget. It also does not resolve whether prerequisite-only cards are ever worth acquiring; the first slice still defers those under F6 pending dead-end evidence.

## Alternative logged

The other option used only the Store's legal down-payment threshold. It matches minimum transaction legality but can leave a noncancelable FIFO head waiting for cash. It is not the selected AI policy. The Store still admits a player purchase whenever the current player rule allows it.

## Source boundary

Current Store admission checks the half-base down payment, while later Research preflights its installment against actual cash (`patch-notes/scripts/run_state.gd`, Store admission and Research methods). The completed-ownership quote is conditional because familiarity and state may change before a later payment. No prospective quote grants ownership or action progress; ownership begins on completed Research.
