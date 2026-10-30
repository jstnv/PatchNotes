# Rival Reviews at new-save opening — 2026-10-29

**Later supply diagnosis:** current trial rivals inherit the player's 12-Scope founder roster and only 14 future-eligible Scope after extras/retired Audio filtering. The user has since directed a separate larger rival pool. See the [dated source diagnosis and design correction](2026-10-29-rival-founder-pool-separation-decision-v1.md); the census itself did not run a matched pool-only counterfactual.

**Finding: current-source rival-only census PASSES two seeds and a fresh-process repeat; the intended opening quality is absent.** At player cycle 0, current new saves contain two active rival Studios and four authored frozen historical games with Reviews **7.1, 7.2, 7.6 and 7.8**. There is **no 8.0+ historical game**, no live release and no active Market fact. The first two legal trial rival releases score **0.9/1.4** in seed 4417 and **1.5/1.9** in seed 5607; all enter active Market facts at cycle 10. No player project was developed or reviewed.

## Authority and source

The [user's scope direction](2026-10-29-rival-opening-review-test-scope-decision-v1.md) assigns player Review testing to the user and makes rival Reviews at the new-save opening this thread's quality focus. The [pre-run plan](2026-10-29-opening-rival-review-census-plan-v1.md) fixed seeds **4417/5607**, normal current-source new-Studio recipes, player calendar-only advance through cycle 12, at most 12 rival zero-cycle steps per boundary and 240 seconds per process. The selected eight-rival 1977 opening is a separate **DESIGN** target, not current source.

Private v2 candidate `opening-rival-review-census-v2` derives from a current canonical snapshot; original baseline identity `897ad674a75dbd905c48afe821f2469365f6fb02799f2937e5d3ae7c5bc3a922`, candidate identity `37b70b2d1142370696034e73843b578c30b1106cc4b57a4f8765e97fa660eaa8`, runner snapshot identity `44b6a4d13cb0ba5181b88ed3d2eba652c6e8c885d567b8cf5072688dbdf22419`, gameplay replay identity `3b6eba994505a819eb79d14dc7ed13689ac5c9b68b830bf7a09cff23d3ec5cd5`, canonical identity at capture `bf9c12f6e032251880316ad5ef72a1880a8d7cfe30b8f10a1524f4d4333e0977`. Branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; canonical and other documentation files were dirty and changed concurrently. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. The v2 project changes only a private diagnostic script; no canonical gameplay or player save changed.

## Exact retained commands and failures

From repo root, `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulator_variant.py create --id opening-rival-review-census-v1 --owner ai-competitors --output "$t/simulators/opening-rival-review-census-20261029-v1"
& $py tools/simulate.py run --variant "$t/simulators/opening-rival-review-census-20261029-v1" --config "$t/2026-10-29-opening-rival-review-census-smoke.json" --output "$t/sims/opening-rival-review-source-freeze-20261029-v1" --timeout 240 --godot $godot
& $py "$t/run_opening_rival_review_census_v1.py" --bundle "$t/sims/opening-rival-review-source-freeze-20261029-v1" --output "$t/sims/opening-rival-review-census-20261029-v1" --godot $godot
& $py "$t/run_opening_rival_review_census_v1.py" --bundle "$t/sims/opening-rival-review-source-freeze-20261029-v1" --output "$t/sims/opening-rival-review-census-20261029-v1b" --godot $godot
& $py tools/simulator_variant.py create --id opening-rival-review-census-v2 --owner ai-competitors --from-variant "$t/simulators/opening-rival-review-census-20261029-v1" --output "$t/simulators/opening-rival-review-census-20261029-v2"
& $py tools/simulate.py run --variant "$t/simulators/opening-rival-review-census-20261029-v2" --config "$t/2026-10-29-opening-rival-review-census-smoke.json" --output "$t/sims/opening-rival-review-source-freeze-20261029-v2" --timeout 240 --godot $godot
& $py "$t/run_opening_rival_review_census_v1.py" --bundle "$t/sims/opening-rival-review-source-freeze-20261029-v2" --output "$t/sims/opening-rival-review-census-20261029-v2" --godot $godot
& $py "$t/run_opening_rival_review_census_v1.py" --bundle "$t/sims/opening-rival-review-source-freeze-20261029-v2" --output "$t/sims/opening-rival-review-census-repeat-20261029-v2" --godot $godot
```

Both `simulate.py run` source-freeze cases intentionally end **INCOMPLETE/exit 1** after one player Begin command, before any player release or Review. This is a required isolated source capture, not a gameplay pass. [v1 first wrapper output](sims/opening-rival-review-census-20261029-v1/opening-rival-reviews-run.json) failed a provenance-field check; [v1 second output](sims/opening-rival-review-census-20261029-v1b/opening-rival-reviews-run.json) had `ok=true` but the raw log contained repeated `SCRIPT ERROR` from iterating a release Dictionary as an Array. Both v1 probe summaries are **REJECTED** as Review evidence. The [revision note](2026-10-29-opening-rival-review-census-revision-v1.md) precedes v2. V2 reads Dictionary values, cross-checks every world release with its owner ledger and rejects script errors in the wrapper. [V2 run](sims/opening-rival-review-census-20261029-v2/opening-rival-reviews-run.json) and [fresh repeat](sims/opening-rival-review-census-repeat-20261029-v2/opening-rival-reviews-run.json) both PASS with empty error scans and identical result SHA-256 `84c7cba2da55e4efe9e9bf3702da96ccb1d0b3943518a13f899e6cd254cb7c08`. An ObjectDB leak warning at process exit did not change results.

## Rival-only observations

| Seed | Cycle-0 historical Reviews | First live Action | First live Adventure | First Market facts |
| --- | --- | --- | --- | --- |
| 4417 | 7.2/7.8 Arcade; 7.1/7.6 Wayfinder | c8, **0.9** | c8, **1.4** | c10, both live titles |
| 5607 | same authored four | c9, **1.5** | c8, **1.9** | c10, both live titles |

At cycle 0 and cycle 12, world checkpoints capture; owner and world release ledgers agree through cycle 12, the archive rows remain unchanged, and no archive ID enters live releases or Market facts. The current two-rival historical Reviews are authored values in `rival_trial.gd`; they are **not** receipts from a legal 1977–79 career. The source search found no UI consumer of `historical_archive` outside world/checkpoint plumbing, so this study verifies stored opening history, **not player-visible display**. The active Market contains zero facts at new-save start; these historical scores do not set active saturation.

## Interpretation and next rival-only gate

The current opening does not meet the selected design's handful of 8.0+ historical titles across multiple non-Racing Studios, eight-Genre coverage or capable early live rival Reviews. The earlier [one-Action private prelude](2026-10-29-one-action-post-release-market-finding-v1.md) supplies separate legal 1977–79 evidence that one source-pinned trial path can generate 6.9/9.2/9.7 history, but it has **trial $25,000 capital**, a different source identity and only one Genre; it is not the canonical new-save cohort.

**Recommendation:** next assemble source-matched legal prelude Review receipts for additional Genres, preserve their frozen archive and January in-progress states, and census the rival-only opening and first live releases across multiple seeds. Keep historical UI presentation, opening standards, cohort size/quality, funding and CPU **OPEN** until those receipts exist. Do not test player Reviews in this thread. No adoption handoff or TODO edit follows from this census alone.
