# Historical Market visibility — implementation acceptance, 2026-10-30

**IMPLEMENTED locally; scoped functional/native/export-fixture acceptance COMPLETE.** Executes the [queued presentation handoff](handoffs/cycle-zero-historical-market-visibility-20261030-v1/HANDOFF.md). The larger [challenge-recovery plan](2026-10-30-challenge-recovery-workplan-v1.md) remains DESIGN/HELD after this slice. Normal-entrypoint EXE manual interaction is NOT RUN: Computer Use app approval timed out before capture. No physical-controller, final balance or distributed release acceptance is claimed.

Dirty main, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`; baseline editor runtime `c4436b020d6580b0ddc79f40e18f085e43c742965e2bcfdce75104fe386255d1`, final `673d2891707ec1092aff6d929a92c96ff38f3f8a620754f5de3d0d3ffc9325d1`. Final exported fixture runtime `d8df2fc0f23e2f23ccb41ff35cdd52e4281cb4ac296293f4d1cd113b71f5ed1d` is a separate compiled identity, never relabelled as editor parity. Exact source/delta/results are indexed in [closeout verification](sims/history-market-closeout-20261030-v1/verification.json).

## Behavior and source

`market_browser_model.gd` retains actual live rows and adds detached `historical_rows`. It validates known owners/nonblank IDs, title/Genre/Theme, positive pre-1980 year and Review0–100, deduplicates owner/ID and sorts year descending, owner/ID ascending. Optional projected archive fields do not become active facts. No archive rows enter MarketReleaseIndex, live sales, release ownership, Fans or saturation.

`market_browser.gd` shows live rows first, then rows prefixed Historical/year, with saved Reviews and `—` units. Selection explains the frozen record and unavailable sales; All/AI include it, Your Studio excludes it. Typed selection keys separate historical/live identities. Existing theme, shared header/chart/footer and actual live sales/support/commission details remain. Keyboard Escape, synthetic controller B and the Back button return focus through the existing close path. B is handled locally because the actual native test found it was not mapped to ui_cancel; no global input map changes.

`rival_world_checkpoint.gd` admits only the exact preceding c443 source with unchanged current player/rival content revisions and ordinary validation. It never regrants Features, adds rivals, edits archives or changes saved active projects. Current live27-Scope pools/player12 remain intact. Existing authored 1976–79 archive facts are displayed exactly; this does not generate eight1977-founded rivals or new8+ Reviews.

## Final evidence

| Check | Actual result |
|---|---|
| New source RED | Both4417/5607 had zero visible historical rows;8 assertions failed as intended |
| Final headless history |62 checks, zero failures; exact four Reviews7.1/7.2/7.6/7.8, filters, order, malformed/duplicate/unknown-owner handling, detached output and cold row identity |
| Final native history |62 checks, zero failures; actual1152×648/1280×720 captures, HUD clearance, Escape/controller-B/Back focus and complete passive-world equality |
| Actual live browser |107 headless and107 native checks, zero failures; legal release fixture, actual sales/order, support semantics, filters, refresh, tooltip and layout |
| Active release index |151 checks, zero failures; six genuine actual-release rows |
| Atomic world/Continue |120 checks through20 productive cycles, zero failures; real Design/Alpha/Beta, four live releases and persisted RNG/finance/history |
| Genuine c443 active save |7 fresh-process checks, zero failures; complete player/rival fields unchanged, unknown source and wrong content pairs reject |
| Compiled exported UI fixture |62 checks, zero failures; same two seeds, actual62-check UI and both-size captures, compiled source separately pinned |

The ordinary project exports successfully into a private acceptance folder. Its template ignores the external `--script` test argument, so a bounded attempted run timed out rather than passing. Direct Computer Use capture then timed out awaiting app approval; no game interaction was performed and no user data/profile was used. A separate private project preserves every canonical gameplay byte and changes only its main entrypoint to a Node adapter for the same verifier; exact export preset and explicit adapter hashes are retained. This instrumented export tests the actual ordinary gameplay scene/UI in compiled form. It does not stand in for manual interaction with the normal entrypoint or editor/export save compatibility.

[Editor native capture1152](sims/history-market-final-native-20261030-v3/history-1152x648.png) · [editor native1280](sims/history-market-final-native-20261030-v3/history-1280x720.png) · [exported fixture1152](sims/history-market-instrumented-export-native-20261030-v3/history-1152x648.png) · [live/historical1280](sims/history-market-live-final-native-20261030-v2/market-1280x720.png).

## Retained failures and limits

Initial RED/green, intermediate7e67 source, mislabeled first native1152 capture (actual1280 after normal window-setting initialization), absent controller-B cancellation, ignored exported script timeout, app-approval timeout and normal-entrypoint600-second bound are retained. The private simulator snapshot omits export config/acceptance roots; explicit preset copy and adapter hashes correct those harness assumptions. The first adapter read UTF-8 as the Windows locale, making its expected dash codepoints226/8364/8221 instead of8212; canonical game glyph/data were correct. A new UTF-8 fixture revision passes; the failed one is not rewritten. Existing ObjectDB warnings remain. No timing/no-lag or hardware-controller claim.

Only the queued historical UI is complete. Legal35+ supply/full-Scope/Core-targeting/QA/recovery quality work, ordinary finance, first-release/later8+ quality, eight-studio1977 activation, population/native late-save performance and player-owned Review/challenge judgment remain separate open gates. [Dated session log](../../logs/2026-10-30-historical-market-v1.md).
