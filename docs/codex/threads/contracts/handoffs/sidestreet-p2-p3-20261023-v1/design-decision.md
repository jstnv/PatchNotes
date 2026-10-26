# SideStreet P2/P3 adoption specification

2026-10-23. **APPROVED bounded pilot; gated implementation handoff.** Private gate/quote and focused checks pass. P3 delivery verification is **BLOCKED by two canonical source-capture races**, before any delivery case ran. See [finding and exact evidence boundary](SIDESTREET-P2-P3-FINDINGS-2026-10-23-v1.md). Canonical adoption/activation remains PN Implementation's responsibility after Gate0 below.

Authority: [user approval](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md). The [earlier proposal](SIDESTREET-P2-AND-FIRST-COMMISSION-PROPOSAL-2026-10-23-v1.md) is preserved as its original proposed snapshot; the approval supersedes that status for this bounded scope. P4 and broader publisher tiers remain OPEN.

## Approved slice

1. **Separate SideStreet Reputation Brief.** Two successful hands; Scope10 and Core3 in each category; completion fraction uses the existing proposal's64-unit denominator. No successful redraws; Scope11 halves the promise grade and Scope12+ zeros it. Award is `floor(1000 × min(completion_bp, promise_bp) / 10000)` Reputation basis points, at most10 Reputation; no immediate cash, Promotion or Investment. One release-paced opportunity, no missed-offer backlog. Keep existing cash Contracts and legacy unlock counts intact.
2. **First commissioned game.** At SideStreet R20, show an optional quote for an explicitly chosen name/Genre/Theme. Preparing it must be legal. Freeze Studio/publisher/project/source IDs, selected setup, current cycle, positive actual project-required Scope, fee, Review target and rights. R20 is access, not a guarantee of successful delivery; no standing is spent. Only one active commission; no invented cancellation penalty.
3. **Exact launch settlement.** Full fee `$6,000`; target Review6.0 and full required Scope. Let `scope_bp=min(10000,floor(10000×delivered_scope/required_scope))`; `review_bp=clamp(500×(review_tenths−40),0,10000)`; `delivery_bp=min(scope_bp,review_bp)`. Pay `floor(600000×delivery_bp/10000)` cents. Thus full-Scope Review5.0 pays$3,000,5.9 pays$5,700,4.0 pays$0. Only delivery10000 requests +1500 Reputation and +1500 Investment basis points through P1; existing caps apply to credits. A partial or zero result still has an idempotent completion record.
4. **Sales rights.** Publisher owns the commissioned title's sales. Raw market units, title history and normal Fanbase evidence continue. Studio earned revenue, settled sales, Bank sales inputs and post-launch campaign spending exclude that title. The commission fee is a distinct publisher receipt. Retain ordinary rent/arrears handling; fee is not guaranteed spendable cash after obligations.
5. **Prospective repeatability.** A later legally prepared project may receive a fresh quote once the previous commission completes. This does not invent a backlog, add support eligibility or spend standing. Current tests must be read for their actual repeat-delivery coverage.

## Implementation tasks and acceptance

All tasks below are **APPROVED** scope and **HANDED OFF** for gated implementation; none is canonically implemented by this study. Treat values as a bounded trial, not LOCKED balance.

### Gate0. Complete the blocked commission evidence before adoption

After current shared-source work stabilizes, reconcile source drift and run the frozen four-case delivery configuration under the recorded v3 mechanics, in a new output folder. Preserve the two failed captures. Then complete the long-arm later-sales continuations, focused completed-save/observer checks and three intended delivery replays. The study folder contains exact policies, configs and commands; only the first delivery capture was attempted, not its gameplay cases. If mechanics change during reconciliation, generate legal prefixes for that new revision; do not relabel these checkpoints. Report actual misses/blocks and retain fixed budgets. A candidate source archive and the passing gate/quote checks do not waive this gate.

### A. Reconcile the P1-backed P2/P3 mechanics

Adopt the exact reviewed delta into current source, not the archived project wholesale. Keep P1 as the sole R/I authority; no historical parallel dictionaries. Preserve existing cash Contract rewards, Starwave distinct-Contract counting, RNG streams and Studio-only Continue. Replace prototype assert-only P2 post-commit award assumptions with explicit preplanned transaction/commit invariants before production adoption. Bind commission terms before Begin notifications; settle fee, release metadata, rights, Fans, Promotion, finance and standing before observers. Reject altered/stale quotes and callback-mutated prepared setup without accepting a deal. Completion retries must not duplicate money, standing or Fans.

### B. Make the offer understandable and playable

Provide native selection, quote, confirmation and result flows. Distinguish Reputation Briefs from cash Contracts, and Reputation from Investment. State two-hand promise, partial grade, calendar/rent cost, R20 access, Scope/Review targets, proportional fee, full-only standing and publisher-owned sales. Show the actual prepared Scope; do not hardcode30 in UI or acceptance. Warn before consuming banked Promotion on a commissioned title; do not invent a refund or exempt it from existing consumption rules. Display raw title sales and Studio entitlement separately in Finance/title views; `net_cents` in the raw monthly report is not Studio income.

Acceptance: supported sizes, keyboard/mouse navigation, cancellation before Begin, exact result breakdown, back-to-Studio behavior, clear$0/partial/full result. Human comprehension remains separate from automated layout checks.

### C. Strict persistence and migration

Implement a named current-P1 predecessor migration for ordinary Studio and active-rival/world saves. Add empty sources prospectively; no retrospective Reputation, Investment, fees or historical Brief backlog. Preserve legacy rewards, RNG, ownership, employees, debt and last valid save generation. Completed commission saves reconstruct frozen terms, grade, one fee receipt, one P1 event and every Studio earned/settled slice from title rights. Reject unknown/renamed receipts, orphan rights, missing/duplicate awards, altered terms and finance-rights mismatches. Active commissioned production is not a new player Continue boundary.

Acceptance: actual disk save and fresh-process Continue before quote, with quote presentation, after full/partial/zero settlement and after later sales; unknown sources reject; no invented old-save equivalence. If active-rival persistence needs an active commission DTO, design and validate that internal representation explicitly rather than bypassing Studio capture rules.

### D. Preserve multi-Studio ownership and world behavior

Reputation, Investment, offers, pending deal, rights and fee belong to the Studio. Verify populated Founder ownership transitions, player/rival/world serialization and no cross-Studio award or sales transfer. Market sales and Fans keep raw title history. A publisher-owned title cannot be relabeled into Studio/Bank income. Publisher support (P4), personal wallets, new IP markets and other publisher tiers are excluded from this adoption.

### E. Verify and activate the complete bounded loop

Run affected headless suites, representative fresh replay, a current-source legal full delivery and an underdelivery, fee/standing cap and duplicate cases, corrupted-save rejection, launch rollback and cold restore. Include a second legal commissioned completion to validate repeat-history persistence beyond a second quote. Verify actual exported/native Brief→R20→quote→launch→result→later sales/Continue at supported sizes. Reconcile remaining prototype coverage limits from the final finding. Activate Reputation-only play with its actual commission benefit. Report IMPLEMENTED and ACTIVE/TRIAL only after the respective evidence exists; no commit, push or release-ready claim is implicit.

## Next design work

P4 support should use Investment to determine funding/marketing available for a Studio-owned title, with clearly quoted Review/sales obligations. Its formulas, renewal, recoup and activation remain OPEN; neither reaching I15 in a commission nor this approval authorizes support rewards.
