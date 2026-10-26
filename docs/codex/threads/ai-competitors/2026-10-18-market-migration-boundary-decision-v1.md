# Pre-market Studio/world migration boundary — design review, 2026-10-18

## Status

**SELECTED qualitative migration rule under the user's delegated design review.** The [private finding](2026-10-18-market-migration-finding-v1.md) supports one named old-source Studio/world route; it does not approve trial market numbers or canonical adoption. Exact source allowlists, player-only old sales, Founder/former-Studio migration, CheckpointCoordinator integration and exported acceptance remain **OPEN**. The older [trial activation decision](2026-10-17-trial-activation-decision-v1.md) remains authoritative for old player-only saves: Continue keeps them worldless and does not invent January rivals.

For a validated, named pre-market world save, migrate the **whole committed Studio/world pair in memory** before ordinary new-schema validation. Keep original bytes/generation and old world source identity as input evidence. Extend each real sales record with 10000-bp factors for exactly the release-age months that have already earned at least one half; tag those historical factors to the named old source. An old half-earned month must finish with its neutral factor. The Fanbase's synthetic neutral shadow also gains 10000-bp history, with its existing `market-0-neutral` source so the Fanbase can replay it exactly. Never recalculate earned units, entitlement/settled cents, Fans, cash or frozen release Reviews.

An active old rival project retains the pre-market Genre targets as its frozen four-Core standards with a named legacy source; future projects use their begin-development market snapshot. Construct the current committed month snapshot once from actual owner release metadata and sales, applying `release_cycle < cycle_start` and the selected recency rule. Thus a cycle-7 release is absent from snapshot6 and enters snapshot8 on a cycle-8 old save. The migrated snapshot is saved, not repeatedly derived from the changing live set. Validate the upgraded player, every rival, whole world, release ownership, finance/Fanbase provenance and RNG before writing a new generation. Rejection leaves the original generation untouched.

## Alternatives logged

| Alternative | Disposition |
|---|---|
| Recalculate past sales or Review under the new market | Rejected: changes already settled results and Fanbase provenance. |
| Give a half-earned age month the new market factor on its second half | Rejected: changes the frozen month-one or later-month total mid-age. |
| Mark Fanbase neutral shadows with the real title's legacy source | Rejected by private replay: the neutral shadow is reconstructed with `market-0-neutral`. |
| Recreate January rivals for an old player-only save | Rejected by the prior activation decision; the save remains worldless. |
| Include all current live releases in an old snapshot | Rejected: same-month launches would enter before the next month boundary. |
| Relabel an old checkpoint as current source to pass a validator | Rejected: bypasses the named-source fence and hides compatibility work. |

## Adoption boundary

The [v18 adapter](simulators/market-migration-pair-20261018-v18/project/scripts/market/market_save_migration_trial.gd) is a private proof for exact old gameplay source `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`, not a production migrator. Complete current canonical/presentation and Founder source fixtures, old player-only sales, Coordinator atomic generation/recovery and post-migration accounting before a handoff. New coefficients and saturation strength stay **OPEN/TRIAL**.
