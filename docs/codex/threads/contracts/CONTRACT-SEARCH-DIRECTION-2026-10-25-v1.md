# Contract search — user direction and proposed first slice

2026-10-25. **Approved direction; detailed catalog and rollout proposed.** This Contracts design thread prepares the feature for PN Implementation. No canonical gameplay changes in this record. Crown preview work remains a separate proposal; search does not approve Crown numerical terms.

## User decisions

1. “We should have an action to search for contracts. It should cost a cycle to do so. You can generate contracts based on publisher reputation.” **Approved feature direction:** an explicit one-cycle search action, with publisher-specific Reputation influencing available work.
2. On acquisition policy, the user selected: **“Replace repeatable automatic offers; preserve introductory and already-pending offers.”** This supersedes the release-only acquisition cadence for future repeatable work. Existing entitlements, history, tutorial/first-unlock offers and accepted work must survive unchanged.
3. On generated work types, the user selected: **“Include commissioned games at their existing Reputation gates.”** Search covers short cash work, Reputation Briefs and eligible commissioned games. SideStreet's existing R20 gate and other legal preparation requirements remain intact; support remains separate.

This permits a Contract-led Reputation path without releasing a game between every Brief. It does not make existing commission/support prerequisites, rewards or publisher unlocks disappear. Investment remains distinct from trust/Reputation.

## Proposed interaction

From Studio, choose **Contracts → Search for work**, an unlocked publisher and an eligible work type. Browsing eligible types and existing offers is free. A successful **Search — 1 cycle** generates one durable offer, not automatic acceptance. Use publisher Reputation to filter code-owned, versioned templates; keep lower-tier work available at higher standing.

Proposed first implementation choices:

- One offer per successful search, with no extra direct cash fee. Normal productive-cycle finance, sales, calendar and world processing still occur. Searching itself grants no Reputation, Investment, challenge payout or advance.
- Exactly one cycle for successful generation; zero on rejected/invalid/stale/unaffordable searches. Preflight eligibility and pending limits before advancing time. Do not spend a cycle on a known empty pool or silently return “nothing found.”
- One pending/active search-sourced offer per publisher and work type. Existing pending legacy work of that type is presented before enabling replacement search; do not delete it or silently convert its source. No expiration, free reroll or automatic replacement in the first slice. Completing work permits another search; it does not generate the next offer.
- The initial catalog can be deterministic where only one eligible template exists. A reusable generation interface should support future templates, but no randomized rewards, hidden search-success odds or Reputation multiplier are approved here.
- Preserve global active-Contract and Studio/departure/commission/support guards. Search is unavailable during an active project/Contract or incompatible deal; ordinary preview/browsing remains free.

## Reputation and initial catalog

Recommended first executable catalog uses **SideStreet**, whose short work, Brief and R20 commission terms already exist. This is a proposed rollout choice, not approval of new publisher tiers.

| Publisher / work | Existing authority | Search proposal |
|---|---|---|
| Ironclad introductory Contract | One-shot teaching offer | Preserve automatic introduction; never regenerate the $400 guarantee through search |
| SideStreet cash work | Publisher unlocked after Ironclad; existing cash/challenge terms | Repeatable searchable type, no new Reputation floor; remove future release-linked cash issuance once this source is active |
| SideStreet Reputation Brief | Two hands; existing completion/promise and up-to-10R rules | Repeatable searchable type, no new Reputation floor; replace future release-paced Brief issuance, preserve pending offers and old results |
| SideStreet commissioned game | R20 plus existing legal preparation and at least one released game | Searchable at the existing gate; a new commission requires its paid search offer. Preserve already accepted/prepared legacy work through explicit migration. |
| SideStreet support | Investment and earned-renewal rules | Preserve existing support flow; it is not work generated from a Reputation search |
| Crown/Neon/Starwave | Current first-unlock cash offers; Crown Brief private proposal | Preserve introductory/pending offers. Do not turn one-shot advances into a repeatable income source or activate unapproved Brief/commission tiers |

Rep-based generation means choosing among approved work types/tiers for the **selected publisher's** standing. It does not pool other publishers' trust, spend Reputation, substitute Investment or scale all payouts automatically. Future higher tiers require their own templates, terms and acceptance; no invented R40/R60 ladder.

## Source boundary and required foundation

Current `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree. Existing source ties SideStreet cash entitlements and Briefs to released game IDs. `run_state.gd` release registration creates both; `_issue_sidestreet_brief` requires a real release. `publisher_relationship_rules.gd` validates offer IDs and owner/release history before crediting standing. These checks must remain valid for legacy offers.

Introduce an explicit trusted **search source** with Studio ownership, unique monotonic action/offer identity, frozen template/terms, selected publisher/work type, pre-search Reputation snapshot, generation cycle and a matching productive finance action. Do not invent a release ID or weaken validation to accept arbitrary sources. New source validation must establish that search was legal, paid exactly one cycle once and produced the settled offer. Preserve the accepted Feature-pool freeze at acceptance and existing per-hand costs/rewards.

Commit the search's cycle effects and new offer atomically through the ordinary productive transaction. Quote eligibility at the pre-search boundary; reject stale state, rather than using standing gained during the same cycle to silently upgrade the quoted work. Any future generation RNG must be isolated, persisted/replayable, and unchanged on rejection. A single-template implementation needs no draw.

Named save migration must preserve old pending/active/completed offer histories and add empty search history prospectively. No retroactive search charges, awards or offers. Player Continue remains Studio-only; active-rival serialization needs explicit coverage even if rival search policy stays unchanged. Release validation and UI copy must follow the new cadence only after the approved source transition; release events no longer replenish active search-enabled repeatable types.

## Pacing consequence to test

For a newly searched two-hand Brief, the shortest successful cycle cost becomes **one search + two hands = three productive cycles**. Two perfect up-to-10R Briefs would therefore require at least six cycles after eligibility, before considering other prerequisites, bills or imperfect grades. This is arithmetic, not evidence that real hands earn 20R in six cycles. Existing pending offers do not incur a retroactive search cycle. Lower awards require more searches/Briefs.

Prior release-paced Crown/SideStreet accessibility findings remain historical; they cannot establish the new career pace. After the catalog/scope is fixed, predeclare a private legal-start comparison for Contract-led progression, cash lows/arrears, standing per cycle, pending-offer behavior and existing-release/commission prerequisites. Retain zero/partial outcomes and save/replay failures. Keep reward values and redraw policy unchanged.

## Open before activation

- The inclusion of commissioned games is now approved by the user. The current free direct preparation path must route through a search-sourced invitation for new work, rather than bypassing the cycle cost. Browsing/preparing an already found offer remains free; ordinary productive Begin is unchanged.
- One-offer/publisher-and-type interaction, pending policy and SideStreet-first catalog are explicit implementation recommendations. They add no new Reputation thresholds or reward values. PN Implementation should implement the authorized feature against current source and report any irreconcilable conflict before adopting a different acquisition rule.
- Legal route evidence and source/migration/atomicity/native/export acceptance. A design packet or successful arithmetic check is not implementation or balance acceptance.

## Commission offer lifecycle

Search generates a persistent invitation referencing the approved publisher commission template, frozen reward/Review/ownership terms and search receipt. It does not create a game, advance a project serial, pay its fee or bind sales rights. On selecting the invitation, normal name/Genre/Theme preparation derives the real required Scope and project identity; do not invent fixed Scope in the search template. Bind the invitation to that exact prepared quote when productive Begin succeeds, consuming it once. No second search fee is charged at preparation or Begin.

Canceling preparation returns to the same unconsumed offer. Stale/invalid/unaffordable Begin cannot consume it. Leaving to develop another game does not retarget a frozen project quote; prepare a fresh legal quote against the same unused invitation. Existing one-exclusive-deal/active-project guards still apply, and support cannot silently replace a bound commission. Searching again for that publisher/work type is unavailable while an invitation or its accepted commission remains pending/active. No new abandonment or decline mechanic in this slice.

Preserve every already-accepted commission and any actually persisted pre-migration reservation through named compatibility handling. Existing ephemeral UI quotes are not saved entitlements: on a source reload invalidate them and show the new route, without inventing a retroactive search receipt or claiming a lost committed deal. Explicitly test that old commissioned titles retain their owner, fee, Review/Scope calculation, sales history and standing receipts.

## First-unlock versus repeatable generation

Retain Ironclad and existing one-time publisher unlock offer behavior, including a currently qualifying SideStreet unlock Brief. Keep their original trigger requirements and identity guards. Remove the repeatable cash/Brief issuance from later release registration for search-enabled types. Do not grant a new free introductory Brief merely because an already-unlocked migrated Studio has no pending work, and do not backfill an unlock that originally lacked its release prerequisite. Preserve all previously earned SideStreet cash entitlements, including old backlogs, before allowing new same-type search.
