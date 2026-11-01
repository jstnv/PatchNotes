# Calendar Market integration, 2026-10-31

Scoped source: `main` baseline `2d5c8df152cd40eb827117270f13fed20af69498`, with the existing dirty Public Action Engine work preserved. This worker changes only `market_transaction_trial.gd`, `rival_standard_book.gd`, `rival_world.gd`, `rival_opening_loader.gd`, and `rival_career_policy.gd`. `historical_standard_trial.gd` remains unchanged because its callers validate frozen prelude proofs.

## Snapshot and proof contract

- Old ordinary v2, historical v3 and Book v4 snapshots keep their exact shapes, IDs, proof encodings and two-cycle source interpretation.
- New ordinary v5 is exactly `{version,cycle_start,id,facts,calendar}`. New Book v5 adds `epoch_offset,basis`, for seven fields; `basis` distinguishes it from ordinary v5. Calendar is a nonempty valid Clock profile. New ordinary IDs start `market-v3-`; Book IDs start `market-book-v2-`.
- Sales factors retain the existing seven fields. `Market.calendar_source(id)` recognizes the two new prefixes. Their generic structural validator allows odd raw dates; authoritative sales/world replay must validate the actual Clock boundary and source facts. Old factor prefixes still reject odd boundaries.
- Review detail dictionaries retain eight fields. New Book detail IDs start `historical-book-v2:` and contain the old five-field proof plus `calendar`. `Book.is_details(value)` recognizes old and new detail prefixes; `Book.proof(id)` decodes either. Old v1 proof bytes remain unchanged.
- `Market.calendar_for(snapshot)` returns its profile or `{}`. `Market.within_window(release_cycle,month_start,calendar={})` keeps the existing six-month presence window as a positive raw date difference of at most 24 calendar quarters. `Market.is_book(snapshot)` recognizes v4/v5 Books. `Book.snapshot` accepts optional fifth `calendar`; ordinary `Market.snapshot(cycle,facts,calendar={})` is also available.
- Raw owner offsets, historical closure and basis cutoff remain 72. `RivalWorld.calendars_aligned()` verifies converted owner anchors differ from the player anchor by exactly their raw offset, or all owners remain legacy. The loader, provider and scheduler check this. Current committed snapshots remain in use until the next actual Clock month boundary.

Root owns typed world/Studio unions, source/content admission, factor provenance replay, and post-legacy-validation coordinated profile migration. New Book proof reconstruction must use `Book.is_details`, include `proof.calendar` when regenerating a snapshot, and compare it against the shared world profile. The source-pinned old historical standard proof branches remain legacy. Calendar-bearing frozen sales factors require their record's `run_calendar` shifted by raw owner offset.

## Focused verification

`pure-project/` is a minimal isolated probe, not a simulator variant or gameplay candidate. It copies the three pure Market modules, Clock and the release-index query; it supplies small empty-owner stubs. It does not read player saves, execute careers, or establish full world/finance/save acceptance.

- Initial canonical attempt crashed before test output during concurrent shared source changes; retained `red-market.txt`. No later canonical parse/test was run while the root held parsing.
- Initial isolated setup errors are retained in `red-import.txt` and `red-market-pure.txt`; corrected setup imported cleanly in `red-import-2.txt`.
- Meaningful baseline RED: `red-market-pure-2.txt`, six checks/five expected behavior failures, no script errors. Legacy Book check passed.
- Initial GREEN: `green-market-pure.txt`, nine checks/zero failures.
- Expanded reference test found converted cycle-zero ID rejection: `red-reference-zero.txt`, 15 checks/one failure. Fixed the new-prefix zero-source path.
- Final focused GREEN: `green-reference-zero.txt`, 15 checks/zero failures, no script errors. Covers four-cycle refresh, odd cutover retention/boundary, old/new proof shape, six-month window, factor shape and old-prefix rejection.
- Focused `git diff --check` passes. Canonical parse, runtime scheduler/cold saves, certified-opening migration and broad acceptance remain root integration work.

Certified inputs were read only and retain original SHA256 values: 5607 `34496db5c8c869783134710a5736342264ab38c9a81db46f099b3ef0ea989461`; 5613 `780f761e628d94da766e9e56126c79a92bb070e083785b6fdc0b299cc532298b`. No commit, push or build.
