# AI market transaction boundary — design review, 2026-10-17

## Status and authority

**SELECTED qualitative timing rule under the user's delegated design review; implementation and numbers remain OPEN.** Actual post-start releases will enter a shared market snapshot at the start of the following calendar month. Every player and rival action in that month must read the same committed release set. A project's market-adjusted four-Core standards, once implemented, freeze when its legal development begins. Each release-age month's sales factor, once implemented, freezes for both earning cycles of that age month. Existing Reviews, earned units and settled cents are immutable.

The [shadow finding](2026-10-17-market-shadow-finding-v1.md) tests deterministic inclusion/counting and retains a failed parse version and timed-out Theme variation. It does **not** validate an active-game transaction or any trial coefficient. The exact 12-cycle window, Review >=7.0 quality gate, lift divisor/cap and sales weights/floor in that prototype remain **OPEN/TRIAL**.

## Source-compatible boundary

`RunState._plan_productive_cycle` computes the player's sales **before** it commits the cycle or emits `calendar_changed`. `Gameplay._advance_rival_calendar` advances rivals on that later signal. A snapshot first created by the signal would arrive too late for the player's earning cycle and could give rivals a different market. The market input for target cycle `s` must therefore be a pure, tentative read during player preflight, before any direct effect or sales mutation. If the player action rejects, no world snapshot or per-title factor is committed. After player success, commit that same versioned snapshot before rival sales for cycle `s`; the rival step uses it unchanged. An inactive player-only game gets a neutral input.

At the first half of a month (even target cycle `s`), derive snapshot eligibility from actual owner records with `release_cycle < s`. A zero-cycle launch after the preceding month's final productive cycle is included; a release registered during the new month is excluded until the next boundary. A stable snapshot ID should cover the boundary, formula/source version and ordered immutable `(studio_id, release_id, release_cycle, Genre, Theme, Review, four-Core availability/output)` facts. Do not hash changing earned units into the identity. On a non-boundary half-cycle, use the saved current-month snapshot. Reject/rollback leaves the prior committed snapshot untouched. Save and validate the committed input with the whole world; never reconstruct a current month from all live titles without the boundary filter.

For a title's first earning cycle of a new release-age month, commit its factor and source snapshot ID atomically with earned units. Reuse the same factor on the second earning cycle even if a new calendar-month snapshot appears between them. `ReleasedGameSales.is_valid` currently recalculates the ledger from frozen inputs, so active saturation requires versioned per-age-month factor history and exact integer replay. A previous-version title may retain neutral factors for already completed and currently partial age months; no past unit or cent rewrite. Exact named-source migration, schema codec, integer rounding and fallback validation still need a private active prototype and are **OPEN**.

For Review, freeze base Genre targets plus market lift in the project at the successful begin-development transaction. Pre-Development may preview the tentative target; failed starts do not store it. Existing active projects from an older source retain their original Genre standards. Exact project field/schema, cross-revision restoration and visible explanation remain **OPEN**.

## Alternatives logged

| Alternative | Reason deferred |
|---|---|
| Build the snapshot only in `calendar_changed` | Player sales were already planned and committed before that signal. |
| Recompute the live set for every action | Same-month launches would change a rival's target or a title's second earning cycle based on action order. |
| Store only a final sales multiplier in `RivalWorld.live_releases` | It lacks player ownership and the per-title sales ledger needs its own replayable age-month factor history. |
| Backfill old earned sales/active project targets | Breaks frozen Reviews/settlements and old-save provenance. |

## Next test gate

Use a **new** private simulator version to integrate tentative player preflight, one committed world snapshot, project-frozen standards and per-age-month factor history with a named-source checkpoint migration. Test rejected actions, prior-cycle zero-cycle launches, same-month player/rival release ordering, boundary-crossing second earning cycle, Studio-only rollback/Continue and exact cents/RNG. The current shadow prototype is useful input but is not an adoption packet for active market effects.
