# One Action post-release save and next-month Market — 2026-10-29

**Finding: v28 PASSES one bounded private cold Continue and next-month Market case; DESIGN evidence only.** The first live Action rival title publishes at world c6/owner c78 with a 7.2 Review, remains the only live title, and enters the Market at c8. Its three pre-1980 games remain frozen outside active saturation and post-start sales. A c6 world checkpoint restores in a fresh Godot process and reaches c8 with an encoded player/world state identical to uninterrupted continuation. The next player Action/Fantasy **quotes** change, but an actual player project/Review/sales comparison was **NOT RUN**.

## Setup, source and controls

The [pre-run plan](2026-10-29-one-action-post-release-market-plan-v1.md) fixes legal seed **5607**, `full_pool`, midpoint first-release standard, trial $25,000 founding receipt, three frozen 1977–79 games and a full-Scope Beta project at player c2/rival c74. The path uses ordinary hands through the first 1980 release, then exactly two legal idle calendar cycles. Limits: 340 prelude commands, at most 12 post-start cycles to release, four rival zero-cycle actions per boundary and 240 seconds per fresh process. The [preflight root-cause note](2026-10-29-projected-sales-clock-trial-v1.md) and [Market-index follow-up](2026-10-29-projected-market-index-followup-v1.md) were recorded before their respective fixes.

The v28 candidate descends from v27→v26→v25→v24 and preserves original baseline identity `91e4244586bd3bf361a0cbfdb14dedcd4c4e09a14c47f1febabc9b0bba705d7b`. [Frozen v28b bundle](sims/one-action-post-release-bundle-20261029-v28b/run-report.json): candidate identity `bd7e26a6744592da76e073c3e298e960e3ba40755731366b9621930a2274fc40`, gameplay source identity `7944a7bbe7dbc324bf423c868707752b3eb9cf36d56eb15db954892ee4707a24`, branch `main` at HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`, canonical identity `5129571ab5173b88a133fb0cc7d46368e0b74405de6b9cc633bcbebc03af2ef8`. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. Concurrent canonical edits cause baseline drift; no canonical gameplay, TODO, player save or `.codex-godot-temp` was edited here.

## Retained failures and rule differences

| Private version | Observed result | Explanation |
|---|---|---|
| [v25](sims/one-action-5607-post-release-prepare-20261029-v25/post-release.json) | c6 world save captures and validates; c7 rival idle cycle rejects | Owner sales ledger validates the shared c6 factor against physical c78. |
| [v26 diagnostic](sims/one-action-5607-post-release-diagnostic-20261029-v26/post-release.json) | Market/factor/player preview and current sales record valid; `ReleasedGameSales.next_cycle`, aggregate sales and full preflight empty | The factor-cycle check has no owner/world offset. Cash $42,408.54 and the finance block reason is empty. |
| [v27](sims/one-action-5607-post-release-prepare-20261029-v27/post-release.json) | c7/c8 sales and Fan cycles succeed; c8 Market facts empty | Sales records now carry a validated +72 offset, but the Market index still emits physical c78. |
| [v28 first smoke](sims/one-action-post-release-bundle-20261029-v28/run-report.json) | Runner stopped while recording canonical drift | Concurrent source change; retained and retried in a new output. No gameplay conclusion from this attempt. |

v27 trial adds an immutable `market_clock_offset=72` only to post-start projected sales records, adjusts factor month validation and replayed Fanbase history, and requires Studio checkpoint provenance for that field. Ordinary and pre-1980 records retain the old shape. v28 changes only the private `queries/market_release_index.gd` to map a live rival release back to the player world cycle and cross-check the stored live record. A separate physical Market copy or provenance exemption was rejected in the [trial note](2026-10-29-projected-sales-clock-trial-v1.md). These are **TRIAL** mechanics, not approved integrated rules.

## Exact commands and passing observations

From repository root in PowerShell, with `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulate.py run --variant "$t/simulators/one-action-post-release-market-20261029-v28" --config "$t/sims/one-action-january-projection-bundle-20261029-v22/inputs/experiment.json" --output "$t/sims/one-action-post-release-bundle-20261029-v28" --timeout 240 --godot $godot
& $py tools/simulate.py run --variant "$t/simulators/one-action-post-release-market-20261029-v28" --config "$t/sims/one-action-january-projection-bundle-20261029-v22/inputs/experiment.json" --output "$t/sims/one-action-post-release-bundle-20261029-v28b" --timeout 240 --godot $godot
& $py "$t/run_one_action_january_projection_v1.py" --bundle "$t/sims/one-action-post-release-bundle-20261029-v28b" --output "$t/sims/one-action-5607-prefix-20261029-v28" --seed 5607 --policy full_pool --standard midpoint --godot $godot
& $py "$t/run_one_action_post_release_v1.py" --mode prepare --bundle "$t/sims/one-action-post-release-bundle-20261029-v28b" --fixture "$t/sims/one-action-5607-prefix-20261029-v28/prelude-world-fixture.json" --output "$t/sims/one-action-5607-post-release-prepare-20261029-v28" --godot $godot
& $py "$t/run_one_action_post_release_v1.py" --mode cold --bundle "$t/sims/one-action-post-release-bundle-20261029-v28b" --fixture "$t/sims/one-action-5607-post-release-prepare-20261029-v28/post-release-post-release-fixture.json" --output "$t/sims/one-action-5607-post-release-cold-20261029-v28" --godot $godot
& $py "$t/run_one_action_january_projection_v1.py" --bundle "$t/sims/one-action-post-release-bundle-20261029-v28b" --output "$t/sims/one-action-5607-prefix-replay-20261029-v28" --seed 5607 --policy full_pool --standard midpoint --replay-tape "$t/sims/one-action-5607-prefix-20261029-v28/prelude.tape.json" --godot $godot
```

The second smoke, [legal c72 prefix](sims/one-action-5607-prefix-20261029-v28/prelude-run.json), [post-release preparation](sims/one-action-5607-post-release-prepare-20261029-v28/post-release-run.json), [cold Continue](sims/one-action-5607-post-release-cold-20261029-v28/post-release-run.json) and [source-matched prelude replay](sims/one-action-5607-prefix-replay-20261029-v28/prelude-run.json) all **PASS**. The c72 prefix retains the prior physical career state digest `737b9278f5b5dc7503efd3338839517984d025242b1a5431d9246a84d0c09041` despite changed mechanics identity; its c2 world restores with exact full state.

At c6 the new rival release is the only live title; the world checkpoint captures and validates. At c7 its fact count is **0** and the player Action/Fantasy sales quote is **10,000bp**. At c8 there is exactly one c6 Action/Fantasy fact (Review **7.2**); the same quote is **8,800bp**, and player Action target Core scores rise **40/26/40/26 → 42/28/42/28**. Old historical sales records remain equal. The fresh-process c6→c8 decoded/captured state digest matches uninterrupted continuation exactly: `9d7add1ea0907fca5dd85e8e06d3c8cf722e640c81f8caa254a0d03b526207ea`.

## Recommendation and remaining gates

Retain world-relative live indexing plus an owner-verified sales-clock offset as the **TRIAL private contract**. The user's pre-existing frozen rivals and ordinary legal work remain **LOCKED**; the +72 representation, trial capital/pool, one Action title and current Market coefficients are not newly approved. **OPEN:** reject tampered offset/factor/history in a completed post-release save; run an actual player project to measure Review/sales effects rather than quotes; repeat with a Design-start rival and more than one live title; eight-Genre population/CPU; old/current save migration; and reconcile with the concurrently changing canonical source. This single case is insufficient for an adoption handoff or TODO queue.
