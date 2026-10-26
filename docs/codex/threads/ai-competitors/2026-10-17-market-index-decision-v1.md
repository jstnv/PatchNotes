# AI Competitors market index foundation — decision, 2026-10-17

## Authority and status

**SELECTED structural scope for implementation review.** The user requested that real rival releases challenge the player through later Core standards and Genre/Theme sales crowding, with eventual Review and sales rankings. The user delegated design-review choices to this thread's recommendation and asked whether the list is ready for implementation. This decision selects the first neutral, read-only release index described in the [market direction](2026-10-17-market-pressure-direction-v1.md). It approves no pressure magnitude or leaderboard presentation.

The current two-rival foundation remains **ACTIVE/TRIAL**. The month-start pressure snapshot, Review target lift, sales factor, AI choice improvements, and visible leaderboard are still **OPEN/CANDIDATE**, not part of this implementation slice. A passing index test will not approve any balance value.

## Selected boundary

- Derive rows only from each current owner's authoritative `RunState` released-game IDs, metadata and sales. Include the player, rivals, and any continuing former player Studio. Use `(studio_id, release_id)` as the stable composite identity. Exclude the frozen pre-1980 historical archive, projected titles and failed launches.
- Include owner/name, release cycle/year/title, Genre, Theme, frozen Review tenths, frozen actual four-Core output when present, and current cumulative **earned** units and entitlement/settled cents. Do not substitute projected units or gross forecast for sales. Return rows in deterministic cycle, studio ID, release ID order.
- Treat missing or malformed old optional Core output as explicitly unavailable in the read view. Do not invent it, reject an otherwise valid old Continue solely for this new view, or silently use it later to lift standards. Other missing eligibility fields remain visible as unavailable rather than guessed.
- The index is a pure query over current owner records. It does not add checkpoint fields, hold a mutable second sales ledger, change RNG, alter launch/Review/sales/Fans/AI, or compute pressure. A later committed monthly snapshot will use this index as input and needs its own schema/version and migration decision.
- A future all-time Review/earned-unit ranking can consume these rows. Board size, placement, tie policy and UI remain **OPEN**; this slice need not expose ranking UI.

## Alternatives retained

| Option | Disposition |
|---|---|
| Copy release Core and sales into `RivalWorld.live_releases` | Deferred: owner `RunState` already freezes real release Review/Core and settles sales; duplicate mutable accounting can drift. |
| Activate saturation and Review lift with the index | Deferred: window, qualification, weights, caps, saved month factors and old-save migration remain OPEN. |
| Include the historical incumbent archive in live rankings/pressure | Rejected for this slice: those titles have no post-start earned-sales history and are frozen background. |

## Evidence and next gate

The [one-seed baseline finding](2026-10-17-market-baseline-finding-v1.md) confirms four legal rival releases and a working owner metadata route, but observes only one fixed-Fantasy, low-Review policy. The [versioned handoff](handoffs/market-index-foundation-v1/HANDOFF.md) pins the exact implementation boundary and acceptance. After that read-only foundation, improve legal AI Genre/Theme/card decisions and trial the market rules in private simulator versions before any pressure adoption.
