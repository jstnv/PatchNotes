# Starwave bounded-pilot implementation evidence

2026-10-09 (America/Los_Angeles). **S1–S4 implemented locally; S5 native acceptance passes, combined maintained gate pending, actual exported interaction and rendered visual review deferred to the authorized overnight work.** The [approved trial](../../threads/contracts/APPROVAL-v4-starwave-bounded-pilot.md) remains ACTIVE/TRIAL, not final balance.

## Current source and behavior

Main `41c87c76fb4d3c06a5332d93f0e7b0997007475d` plus the current Fanbase integration and this Starwave implementation. [Final native source manifest](source-manifest-v3.json) pins1190 project files before the final native run; the independent audit verifies those hashes afterward. [Dated implementation log](../../logs/2026-10-09-starwave-implementation-v1.md) records changed files, repairs and historical failures. Main scripts/scenes/data were frozen before the parent began its integrated gate.

One non-expiring Starwave offer requires two distinct releases and three distinct prior completed Contracts. Three four-card hands share the existing finite Feature, renewable Pass, retention, priority and redraw rules. Frozen targets are Scope14 and each Core7; exact numerator is `4*min(Scope,14)+sum(min(CoreHalfUnits,14))`, denominator112. Zero advance; hands1–2 pay nothing; only committed hand3 pays `floor(224000*n/112)` cents. Starwave grants no Promotion entry. Existing Crown/Neon awards remain intact until the next successful release.

Current checkpoint revision adds `starwave1`; unsupported older saved bytes remain preserved and incompatible, without inventing a newly earned offer. Existing publisher terms and two-hand behavior are retained. Completed states validate exact hand/payment count independently of productive priority changes.

## Focused checks

- [Initial13-suite results](focused-results.json): all native process exits0 and no runtime errors. The stored false values mean zero failure flags. Suites cover Starwave, old publisher offers/cash/Promotion/liquidity/browser, Publisher Connections, Ironclad, SideStreet, Studio checkpoint/RNG, Fanbase checkpoint and Feature Research.
- [Final Starwave verifier](verify_starwave-v3.command.json): exact zero/half/full/capped scoring; zero-payout RunState completion count and checkpoint; immutable offer terms; malformed initial/partial deal and redraw RNG rollback; native third-hand draw/retention; productive priority change; atomic receipt; no Starwave Promotion; unchanged earlier awards; duplicate actions; corrupt hand count, all frozen terms, identity and receipt rejection.
- [Headless UI/input verifier](verify_starwave_ui.command.json):1152×648 and1280×720. Native mouse events open chooser, keyboard confirms, mouse plays all three animated hands, result fits and mouse returns to Studio. This is native layout/input evidence, not a rendered-image or exported-app acceptance claim.
- [Adverse-liquidity fixture](adverse-liquidity.command.json): explicit accounting fixtures prove hands1–2 cannot use the future completion receipt to clear existing rent debt, blocked actions preserve state, and actual hand3 income can recover the original overdue bill once. This is a constructed boundary test, not a naturally cash-constrained Starwave playthrough.

The independent source review found a failed-initial-deal RNG gap. Setup now validates supplied rolls before binding, all failed partial draws restore RNG, and ready-node setup propagates failed preparation. The new focused cases pass; the reviewer confirmed the fix.

## Genuine native route

[Final route](native-v3/native-route.json), [command/log metadata](native-route-v3.command.json), [runner](run.py), runtime harness `patch-notes/scripts/debug/starwave_native_route.gd`.

Declared seed1104, Action specialty, Lean/Buzz/Lease traits, synergy policy, contract deal seed31104, no injected cash or unlocks. Initial cash is$5,650. The route earns three releases with Reviews5.8,7.3,7.8 and completes Ironclad, Crown and Neon. At cycle54 the earned Starwave offer is available with18 eligible Primitive Features and Neon's18 Promotion pending. An early Bank quote is honestly recorded as ineligible; a later actual$500/12-month quote at54 succeeds. Production Specialist hire succeeds.

Starwave's native three hands reach Scope20, numerator111/112 and **$2,220**. The first Bank installment falls at56, during hand2 before Starwave pays. Hand3 pays at57. The next actual release at75 has Review8.1 and consumes Neon's18 Promotion once. Productive next-project actions continue to78. All12 Bank installments close$500 principal plus$32.50 interest; rent and payroll remain in the same journal.

Source drift from the earlier SW1/SW2 work is explicit: this current route includes integrated Fanbase and its frozen launch Awareness, and a live Starwave third-hand RNG stream. The earlier SW2 shadow-reward economic deltas are not asserted as current route outcomes. Final balance, other specialty pools and player preference remain OPEN.

## Separate-process restore and independent audit

[Final ten-process sequence](native-v3-restart-results.json): seed genuine checkpoint → acceptance rollback → hand1 rollback → hand2 rollback → completed-before-dismissal rollback twice → dismissal/save → Continue → real next release → Continue. All10 process exits0, no runtime errors. Repeated cold timelines match actual dealt/selected cards, cash, Fans, finance and future RNG. No intermediate Contract save is published. Completed identity and Promotion consumption restore without offer reissue or payment replay. Corrupt terms/hand count/identity/receipt reject the whole restore without touching the valid disk generation.

[Independent audit](audit-summary-v3.json): **52,934 checks pass**, comprising1,850 source/card/receipt/Fan/identity checks and51,084 transaction/monthly-accounting checks. It reconstructs finite Feature use, retention, half-unit scoring, exact payout timing, every productive-cycle finance journal, neutral exposure and incremental Fan targets, the single Awareness sales conversion, full Bank closure and the ten process results. Reproduce with `python docs/codex/findings/starwave-implementation-v1/audit.py`.

### Durable native-v3 source and reproduction

The complete 1,190-file source copy is at `C:/Users/64jus/Downloads/Patch Notes Design Folder/starwave-native-v3-pinned-source`. Every copied byte matches the unchanged [original manifest](source-manifest-v3.json), including the card ledger used by the independent audit. The manifest also includes historical project evidence and cache files, so the full copy is about 1.10 GB and remains outside the repository.

Three later reporting-verifier repairs changed the current worktree after the native run: `verify_game_lifespan_trial.gd`, `verify_monthly_sales_report.gd`, and `verify_sales_earning_and_settlement.gd`. [Exact recovery provenance](source-pin-recovery-v3.json) records 1,187 matching current files, two matching Git HEAD blobs, and the monthly report verifier recovered from the earlier Fanbase source copy. All three recovered files match their original hashes without line-ending conversion or other transformation. The [initial HEAD-only mismatch](source-pin-attempt-v3.json) is preserved. Gameplay source did not drift.

The supplemental [runtime source archive](runtime-source-native-v3.zip) contains scripts, scenes, data, `project.godot` and export presets, including all three historical verifier versions. It is a **partial** archive (622,862 bytes); the complete manifest check uses the full Downloads copy. Archive SHA256: `cc600f64ce5ed9363c673eb4a47a829926c60264d7fd342e833510f5235badf2`.

`audit.py` now defaults to that complete pinned copy and uses its card ledger plus a local frozen copy of the finance auditor. `--source-root PATH` can select a relocated complete copy. The unchanged numerical audit passes again: [distinct recheck result](audit-recheck-v3.json), **52,934 checks**, exit 0. Rechecks default to `audit-recheck-v3.json`; the original `audit-summary-v3.json` and `source-manifest-v3.json` remain unchanged. The original auditor is retained as `audit-original-v3.py`. This reproduction verifies the earlier native evidence; it does not claim that the original pin contains the later reporting-only fixture fixes.

## Export continuation seed

Use only the final [native-v3 storage envelope](native-v3/before-starwave.checkpoint.1.json), copied unchanged to a clearly named isolated test profile as `saves/studio/checkpoint.1.json`. Parent authorized this transfer for later exported acceptance. This foundation was genuinely earned through native gameplay; the export test must state that it begins from a transferred native checkpoint, not from an entirely mouse-played export history.

SHA256: `01a7a395dc5c60543886a6840714d2c32de6cd83c6e28e48df579ce81010c202`.

Actual EXE Continue/Starwave three-hand/result-dismissal/restart/next-launch interaction remains deferred. No Computer Use ran in this resumed work; no commit, push or release-readiness claim.

## Preserved failures

- First import inferred an untyped integer expression; repaired before tests.
- First test fixture called unsupported `CardData.duplicate()`; repaired using explicit fixture cards.
- A standalone check-only invocation hit the known Godot signal11 compiler issue and was interrupted; no repeat. Normal import/runtime verification supplies compile evidence.
- Original native route ended with `earning priorities` after attempting an already committed initial-priority step in the optional tail. Its files remain at this directory root. Native-v2 corrected it; native-v3 reran on final frozen runtime and passed. Do not relabel the original attempt as passing.
- Placeholder-art and Windows root-certificate diagnostics remain documented; none is disguised as rendered visual acceptance.
