# AI Competitors market index foundation — adoption handoff v1, 2026-10-17

## Status and authority

**QUEUED for PN Implementation review; not implemented by this handoff.** Adopt only the [selected read-only index decision](../../2026-10-17-market-index-decision-v1.md). The user's market challenge direction is [recorded here](../../2026-10-17-market-pressure-direction-v1.md). Numeric Review and sales pressure, monthly snapshot persistence, AI policy changes and UI leaderboards are **not queued**.

This is a structural data view. It may be reconciled in the canonical project only in the single implementation slot, with existing worktree edits preserved. Reinspect source and reconcile hashes before editing: the working tree was dirty when this handoff was authored.

## Source identity at handoff

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` on 2026-10-17; uncommitted changes exist.
- `patch-notes/scripts/market/rival_world.gd` SHA-256 `9f9ad490ba6caa07812342321f22c999cc574e33f435699f5b8ceb773a6b1986`.
- `patch-notes/scripts/market/rival_world_checkpoint.gd` SHA-256 `590814c2fded745c44f0fc0a79f10507652a69a1ae283adcd6b2abd44506a857`.
- `patch-notes/scripts/run_state.gd` SHA-256 `8352dee38ef666e7133cdb6bac94536f6b97b775146fbd200c89de278490bc30`.
- `patch-notes/scripts/sales/released_game_sales.gd` SHA-256 `4d8418b023557cffae670794c9a881d936a2dcbf0eb457d85438c8bfce014739`.
- `patch-notes/scripts/review/primitive_review_calculator.gd` SHA-256 `abc0b809d253035ea07c3133dc82c568ffd0f32a43f352ec50c479d0b3081846`.

## Exact delta

1. Add a pure read-only market release query, preferably a separate `scripts/market/` class or function called by `RivalWorld`. Enumerate `world.player` plus each session in `world.studios`, deduplicating owners by stable studio ID. A continuing former player Studio remains an ordinary owner. Do not use `RivalWorld.live_releases` as the data authority; it is a rival summary without four-Core or current earned units.
2. For each `RunState.get_released_game_ids()` ID, read `get_release_metadata(id)` and `get_released_game_sales(id)`. Return one value row keyed by `(studio_id, release_id)` with studio ID/name, release ID, release cycle/year/title, Genre, Theme, frozen Review tenths, actual frozen `review.cores` when a valid four-category vector exists, current cumulative `earned_units`, `entitlement_cents`, and `settled_cents`. Make Core availability explicit. Preserve integer types and deep-copy returned values. Use a result envelope such as `{ok: true, rows: [...]}`. On duplicate identity or missing/malformed required metadata or sales, return `{ok: false, reason, studio_id, release_id}` with no partial rows; do not silently replace an actual value with a forecast. This read-query error must not become a new checkpoint-load gate.
3. Sort by release cycle, then studio ID, then release ID. Archive rows, previews and failed launches must not enter. Expose unavailable optional older Core data without blocking otherwise valid player-only or old-world Continue. Do not guess absent Genre/Theme or any other required market eligibility field.
4. Keep this a derived query: no save schema/payload change, no stored monthly pressure snapshot, no RNG consumption, no release/Review/sales/Fan/finance/AI mutation, and no visible leaderboard or market factor. Historical and old-save compatibility for *active pressure* remains a separate handoff.

## Evidence and acceptance

The [predeclared baseline](../../2026-10-17-market-baseline-plan-v1.md) and [finding](../../2026-10-17-market-baseline-finding-v1.md) give current legal owner records: four rival titles by world cycle 20; focused verifier 118/118, one 18-step player control, one 18/18 fresh-process replay. This supports index feasibility only; it does not test the new query or approve pressure/balance.

Implementation acceptance:

- A legal new game with player and two rival releases returns each real title once, with authoritative metadata, Core availability, and earned units/cents matching the owner's `RunState`; zero earned at registration updates after settlement without rewriting the frozen release fields.
- A continuing former player Studio, if present, remains included under its own stable ID. Pre-1980 archive and projected/failed titles never appear. Reordered dictionary insertion returns the same sorted rows. Duplicate owner/identity and incomplete required fields are handled explicitly.
- In-process rollback and fresh-process Studio-only Continue reconstruct the same rows from saved owners without an index payload. An older player-only checkpoint still loads and yields player rows; missing optional frozen Core output is marked unavailable. Record any actual older-world fixture not run as **NOT RUN**.
- Focused native checks and at least one fresh-process replay report exact command, source identity, PASS/FAIL/BLOCKED/NOT RUN, runtime errors, and scope. Confirm no changed Review, sales, Fan, finance, RNG, or checkpoint bytes in a matched unchanged route.

## Remaining design work

The monthly market snapshot ID/save contract; recency window; Core quality gate, aggregation and cap; Genre/Theme sales coefficients, floor and rounding; active-project and sales-ledger migration; AI legal card/Genre/Theme policy; high-Review news threshold; CPU/history bounds; and leaderboard placement/tie rules all remain **OPEN**. Do not infer approval from this queue or the baseline. PN Implementation owns canonical adoption and reports source drift before changing scope.
