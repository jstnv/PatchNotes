# Cycle-0 Market Browser is empty despite frozen rival history — 2026-10-30

## Finding and status

**PASS, reproduced source behavior; player-visible acceptance NOT RUN.** A current new Studio activates two trial rivals and stores four pre-1980 historical games, yet the Market Browser model has zero rows at cycle 0. The browser explicitly excludes pre-1980 archives. This is a missing historical presentation path, not missing generated archive data and not a failure of active sales/saturation. The requested legal eight-rival opening is still a held private candidate and does not run in normal new saves.

The [predeclared probe](2026-10-30-cycle-zero-market-visibility-probe-plan-v1.md) used private variant [`cycle-zero-market-visibility-20261030-v1`](simulators/cycle-zero-market-visibility-20261030-v1/variant.json) with only one added diagnostic script; original canonical baseline identity `05eb34e6701f42a8f7a5645dddb47706b146a3f9bfba6638dfddef15f4932dc6`, variant identity `4c52b17c54292876e22ab943afb6c64dab328451971e21333b43ffd24334b779`, canonical mechanics identity `33f44f0c61446daf6f464bee3c04f689a437d4b08704d2c3dbc65874778a1f27`. Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`; shared docs/UI/checkpoint edits were dirty and preserved. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`.

## Exact commands and outcomes

From repo root, `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulator_variant.py create --id cycle-zero-market-visibility-v1 --owner ai-competitors --output "$t/simulators/cycle-zero-market-visibility-20261030-v1"
& $py tools/simulate.py run --variant "$t/simulators/cycle-zero-market-visibility-20261030-v1" --config "$t/2026-10-30-cycle-zero-market-visibility-freeze-v1.json" --output "$t/sims/cycle-zero-market-visibility-freeze-20261030-v1" --timeout 240 --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/cycle-zero-market-visibility-freeze-20261030-v1" --output "$t/sims/cycle-zero-market-visibility-probe-20261030-v1" --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/cycle-zero-market-visibility-freeze-20261030-v1" --output "$t/sims/cycle-zero-market-visibility-probe-repeat-20261030-v1" --godot $godot
```

The [source-freeze runner](sims/cycle-zero-market-visibility-freeze-20261030-v1/run-report.json) exited 1 as **expected INCOMPLETE**: each case was stopped by its predeclared one-command bound before any release. Both isolated [first](sims/cycle-zero-market-visibility-probe-20261030-v1/opening-rival-reviews-run.json) and [repeat](sims/cycle-zero-market-visibility-probe-repeat-20261030-v1/opening-rival-reviews-run.json) probes exited 0, had no script errors and produced identical result SHA-256 `117ff623fb33dc4cb46a6e9759b6bdbc6b0529855fc931bfcedf93b2a29d4420`. [Raw results](sims/cycle-zero-market-visibility-probe-20261030-v1/opening-rival-reviews.json) retain both seeds and all c0 measures.

| Measure at cycle 0 | Seed 4417 | Seed 5607 |
| --- | ---: | ---: |
| Active rivals | 2 | 2 |
| Frozen historical records | 4 | 4 |
| Historical Reviews at or above 8.0 | 0 | 0 |
| Live rival releases / active Market facts | 0 / 0 | 0 / 0 |
| `MarketReleaseIndex.query` rows | 0 | 0 |
| `MarketBrowserModel.query` rows | 0 | 0 |
| Fresh player/world checkpoint valid | yes | yes |

The four frozen records are *Circuit Clash* (1977, 7.2), *Skyline Siege* (1979, 7.8), *The Lantern Road* (1976, 7.1), and *Atlas of Ash* (1979, 7.6). Current `rival_trial.gd` writes them to `world.historical_archive`; `market_release_index.gd` reads actual released-game ledgers only; `market_browser_model.gd` projects only the index; and `market_browser.gd` explicitly says the archives are excluded. The [current founder assessment](2026-10-30-current-founder-candidate-findings-v1.md) confirms eight-rival adoption is HELD. Even its private projected archives are excluded by its active release index.

## Recommendation and limits

Add a separate historical read projection in the Market Browser and label its rows **Historical**. Preserve the existing active release index and Market snapshot as live-only. Historical rows must not earn post-start sales/Fans, seed active saturation, or masquerade as 1980 releases. The [scoped handoff](handoffs/cycle-zero-historical-market-visibility-20261030-v1/HANDOFF.md) defines the UI acceptance. This change would reveal four existing 7.1–7.8 records in the current two-rival game; it cannot deliver the selected eight-rival 8.0+ opening by itself. Founder quality/funding/CPU and migration gates remain **OPEN**. No graphical or exported game was tested; the headless probe tested the browser model and saved world, not rendered interaction.
