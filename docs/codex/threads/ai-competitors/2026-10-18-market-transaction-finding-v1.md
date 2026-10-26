# Active AI market transaction — private simulator finding, 2026-10-18

## Disposition

**CANDIDATE evidence; DESIGN review needed. No active market implementation handoff or TODO queue entry.** The [selected qualitative transaction rule](2026-10-17-market-transaction-boundary-decision-v1.md) is compatible with a ten-cycle private player/two-rival route: a pure tentative player preflight, one committed month input for rivals, project-frozen four-Core standards, and an age-month sales-factor ledger can survive checkpoint validation and a fresh Studio Continue. The numerical trial is **OPEN**, and old-save migration is **NOT RUN**. The private code is not canonical gameplay.

This finding follows the [predeclared plan and dated repair addenda](2026-10-18-market-transaction-study-plan-v1.md). The unchanged neutral-index source was captured before testing active effects. No player save or canonical `patch-notes/` file was edited.

## Source and comparison contract

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout. The unchanged control's base identity is `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`. The final private variant [market-transaction-provenance-20261018-v10](simulators/market-transaction-provenance-20261018-v10/variant.json) retains that ancestry; candidate identity `17aff46ed01f6ba63a5480e3e79d52b2b70bbcbc659e2f71f6c6686906a1d539`, gameplay source `8a148a7dea119563fa7921520d875e3d70e17d7b43ba483bb96f7fe23034f721`. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python 3.12.14. The [v10 run report](sims/market-transaction-provenance-player-20261018-v10/run-report.json) records `baseline_drift=true`: the shared canonical source changed after the baseline capture, so canonical reconciliation is required before any adoption.

The control and candidate both start fresh with seed `4417`, no Traits, legal Action/Fantasy 2/2/2 player hands, a finite 50-command cap, one player release, and the same two trial rivals. The focused world route advances ten productive cycles and has one legal release per rival on cycle 7. We compare named releases and RNG, not equal seed alone or cross-revision state hashes. The candidate changes the saved schema and actual sales, so whole-state digests cannot be expected to match the control. The private trial inputs are 12-cycle recency, Review at least 70 tenths for a Core lift, per-Core `min(8,max(0,floor((max_core-base)/2)))`, and sales `max(7000,10000-600*GenreOnly-300*ThemeOnly-1200*Pair)` basis points. All those values remain **OPEN/TRIAL**.

## Commands, limits and artifacts

The isolated runner's exact Godot commands, exit codes, timeouts, frozen-source manifests and import results are retained with each artifact. These are reproduction commands for the final route, expressed from repo root; use new output directories and free test ports when reproducing:

```powershell
$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/market-transaction-provenance-20261018-v10 --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-20261018-v10 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-20261018-v10 --output docs/codex/threads/ai-competitors/sims/market-transaction-provenance-focused-20261018-v10 --godot $godot --script verify_rival_world_foundation.gd --test-port 47840 --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-20261018-v10 --output docs/codex/threads/ai-competitors/sims/market-transaction-provenance-cold-20261018-v10 --godot $godot --script verify_rival_world_foundation.gd --profile docs/codex/threads/ai-competitors/sims/market-transaction-provenance-focused-20261018-v10/profile --test-port 47841 --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-20261018-v10 --output docs/codex/threads/ai-competitors/sims/market-transaction-provenance-focused-repeat-20261018-v10 --godot $godot --script verify_rival_world_foundation.gd --test-port 47842 --timeout 240
& $py tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-20261018-v10 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/market-transaction-provenance-player-replay-20261018-v10 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/2026-10-18-market-transaction-compare-v2.py
```

The predeclared limits were 50 player commands, one player release, at most 20 world cycles, two rival releases, and 240 seconds per process. The representative world route uses ten cycles. The [focused log](sims/market-transaction-provenance-focused-20261018-v10/rival-verifier.log), [cold log](sims/market-transaction-provenance-cold-20261018-v10/rival-verifier.log), [repeat log](sims/market-transaction-provenance-focused-repeat-20261018-v10/rival-verifier.log), [player run](sims/market-transaction-provenance-player-20261018-v10/run-report.json), [fresh replay](sims/market-transaction-provenance-player-replay-20261018-v10/run-report.json), and [cross-version audit](sims/market-transaction-cross-version-20261018-v2/comparison.json) are the primary evidence. The two focused runs have the same eleven `MARKET_TRANSACTION*` observation lines; one has exit-only ObjectDB warnings, so the complete logs are not byte-identical. Both exit zero.

## Observations

| Check | Observed result |
|---|---|
| Legal fresh player route | 18/18 recorded commands, one release, cycle 7; fresh-process command replay `ok=true` with 18 accepted steps. |
| Ten-cycle player/rival transactions | 116 checks, zero failures, repeated with identical market observation lines; two real rival releases at cycle 7. Rejected stale player preflights leave player state, world snapshot, checkpoint and RNG digest unchanged. |
| Month snapshot | Two actual release facts enter at cycle 8; cycles 8–9 reuse `market-8-d219d0a0…`, cycle 10 uses `market-10-d219d0a0…`. Player commits the preflight input before rival advancement; no same-month re-addition. |
| Review standards | A second Action rival project starting in cycle 8 stores that month's source/targets; they remain frozen through cycle 10 and cold Continue. The real rivals' Reviews are 2.2 and 2.7, so they cause **no** Core lift under the trial 7.0 gate. A synthetic qualifying Review 8.0 other-studio row raises Action targets `[40,26,40,26]` to `[48,26,46,26]`; the same row without Core evidence causes no lift. |
| Sales ledger | Age month 1 factor 9700 basis points is reused for its second earning half; age month 2 gets a new 9700 factor sourced from the cycle-10 snapshot. Exact cumulative earned units, entitlement cents, settlement cents, cash and Fanbase replay validate. |
| Save provenance | Fresh Studio-only cold Continue passes 8/0, with exact checkpoint digest and frozen active-project source. A forged market fact with a recomputed internally valid hash is rejected against the actual owner release ledger. |

The [matched audit](sims/market-transaction-cross-version-20261018-v2/comparison.json) checks the same two real release IDs, dates, Genre/Theme, Reviews, launch totals and rival RNG. Only the trial sales rule changes their earned results in this route:

| Studio | Control earned / cents | Candidate earned / cents | Candidate minus control | Fans |
|---|---:|---:|---:|---:|
| Arcade Foundry | 361 / 252447 | 350 / 244755 | -11 / -7692 | 12 in both |
| Wayfinder Works | 390 / 272727 | 377 / 263636 | -13 / -9091 | 14 in both |

The candidate's settled cents equal entitlement cents for both titles in this bounded route. The 9700 basis point factor comes from one other-studio **Theme-only** Fantasy release; Genre-only and pair buckets were shadow-tested earlier, not in this active legal route. Neither the 3% trial loss nor the synthetic Core lift is a balance approval or evidence that rivals challenge the player.

## Retained rejected and incomplete cases

The [study plan addenda](2026-10-18-market-transaction-study-plan-v1.md) record each repair without silently changing seed, trial terms, or budget. The unchanged 20-cycle [control verifier](sims/market-transaction-control-rivals-20261018-v1/rival-verifier.command.json) timed out at 240 seconds after cycle 14: **INCOMPLETE**, not a passing control. A shorter audit-only control uses the same unchanged gameplay source and reaches cycle 10 with [23/0](sims/market-transaction-control-audit-rivals-20261018-v1/rival-verifier.log).

| Private version | Retained result |
|---|---|
| Snapshot v1 | Eight-cycle focused 87/0; [cold restore failed](sims/market-transaction-snapshot-cold-20261018-v1/rival-verifier.log) because dictionary-order hashing was unstable. |
| Snapshot v2 | Eight-cycle focused 87/0; [cold restore failed](sims/market-transaction-snapshot-cold-20261018-v2/rival-verifier.log) because raw JSON integers did not meet the world codec schema. |
| Snapshot v3 | [Focused failed](sims/market-transaction-snapshot-focused-20261018-v3/rival-verifier.log) at the populated snapshot: text market IDs were encoded through `StringName` ID fields. |
| Snapshot v4 | Eight-cycle focused 87/0, repeat 87/0, cold 6/0; snapshot-only milestone, no owner ledger. |
| Ledger v5 | Ordinary player route passed; [focused verifier parse error](sims/market-transaction-ledger-focused-20261018-v5/rival-verifier.log), no rival result. |
| Ledger v6 | Player route passed; [focused 88 checks / 3 failures](sims/market-transaction-ledger-focused-20261018-v6/rival-verifier.log) when Fanbase historical validation replayed neutral instead of saved factor history. |
| Ledger v7–v8 | First earning half/cold restore passed v7 90/0 and 7/0; full ten-cycle age-month route/cold passed v8 112/0 and 7/0. |
| Review v9 | Ten-cycle focused 114/0 twice, cold 8/0 and fresh player replay 18/18; market-fact owner provenance still absent. |
| Provenance v10 | Ten-cycle focused 116/0 twice, cold 8/0 and fresh player replay 18/18; forged-valid-hash market fact rejected. |

## Recommendation and remaining gates

Preserve the **SELECTED** month-start transaction/freeze boundary. Keep the v10 code and 9700-bp result as a **private CANDIDATE**. Do not place active market effects on the canonical implementation queue yet. A new private version needs a named-source migration that imports an older valid Studio/world pair, supplies neutral factor history only for already earned and partially earned age months, preserves old project targets and previous cents/RNG, and then moves forward with the new snapshot. The simulator source-identity fence must stay enabled; an old checkpoint cannot be relabeled as current source. Test no-world old saves separately.

Before an adoption handoff, also select trial numerical policy (window, quality gate, lift, buckets, floor), reconcile canonical source drift, verify a legal **player** release exposed to a rival snapshot through the actual Gameplay calendar signal, validate forecasts/quotes and more than one age month, test stronger real rival choices and Genre/pair crowding, and run rendered/exported and human-comprehension acceptance as appropriate. Existing ObjectDB exit warnings occurred on some otherwise passing native verifier runs. The isolated headless results establish only the stated route. Leaderboards remain a separate future feature.
