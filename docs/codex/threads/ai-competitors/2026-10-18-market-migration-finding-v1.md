# Named pre-market save migration — private simulator finding, 2026-10-18

## Disposition

**CANDIDATE proof for one exact old Studio/world source; no canonical adoption handoff.** The [predeclared study](2026-10-18-market-migration-study-plan-v1.md) generated legal old-source committed pairs at cycles 7, 8 and 10, then imported copies into a [v18 private adapter](simulators/market-migration-pair-20261018-v18/project/scripts/market/market_save_migration_trial.gd). Two focused migration processes pass 58/0 checks each; a fresh Studio-only cold process restores all three pairs at 15/0, and an independent 18-command player recipe replays exactly. Unknown source, missing old sale field and changed historical earned units reject. The [qualitative boundary decision](2026-10-18-market-migration-boundary-decision-v1.md) is selected, while numerical market terms and other source families remain **OPEN**.

## Sources, fixtures and bounds

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared checkout. Old audit-only fixture variant [metadata](simulators/market-migration-old-fixture-20261018-v1/variant.json) has candidate identity `9ef3fac33436f3ba8ce8df5e8cc979e777e02188608321bb3885b162b2cfbd68` and non-debug gameplay source `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`. The final v18 migration variant [metadata](simulators/market-migration-pair-20261018-v18/variant.json) retains original base `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`, candidate identity `dac892ef6487ec911ba6fd47ecfcbe434a861add29b99c4b7febe80b7dd2601d`, and gameplay source `8bc51c9cc78ca18e70adaf0160ccda1983b152d7fd39fbafa8fc1a764300c0f2`. Both run reports mark `baseline_drift=true` against concurrently changed canonical source. Godot 4.7.1 SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

All three old pairs came from a fresh seed-4417 player, no Traits, the same two legal trial rivals and policies, actual zero-work player cycles, with no edited checkpoint fields or player saves. The old audit [run](sims/market-migration-old-player-20261018-v2/run-report.json) completed one legal Action/Fantasy 2/2/2 player release in 18/50 commands, while the old [world verifier](sims/market-migration-old-fixtures-20261018-v1/rival-verifier.log) completed ten cycles, two rival releases and 31/0 checks. It used the old codec to capture/validate committed Studio/world pairs. The [retained fixture profile](sims/market-migration-old-fixtures-20261018-v1/profile/) contains `market-legacy-cycle-7.json` SHA-256 `47C6000D8D8850DEBBC62AFEF799B28AD48CBE8CD0E5D42E9CF69519D8233715`, cycle 8 `D473454365CE6D83DB461654FF65751DA0286C7C95B901BBDC854CB81032FE54`, and cycle 10 `06B918D993FE12B26CD6FCE931B710A2EA9B7008F303C04CD24719CCD9CB811B`. The separate old player-only cycle-8 fixture was retained but its no-world sales migration is **NOT RUN**.

The predeclared caps were ten old world cycles, at most two post-migration cycles per pair, 50 player commands, two rival releases and 240 seconds per process. Same seed, old policy, trial market terms and legal routes were retained across repairs. The exact native Godot argv, timeout, exits and frozen-source hashes are in each `rival-verifier.command.json` and run report. Reproduction commands from repo root, with fresh output directories and free ports, are:

```powershell
$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/market-migration-old-fixture-20261018-v1 --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/market-migration-old-player-20261018-v2 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-migration-old-player-20261018-v2 --output docs/codex/threads/ai-competitors/sims/market-migration-old-fixtures-20261018-v1 --godot $godot --script verify_rival_world_foundation.gd --test-port 47850 --timeout 240
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/market-migration-pair-20261018-v18 --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/market-migration-pair-player-20261018-v18 --godot $godot --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-migration-pair-player-20261018-v18 --output docs/codex/threads/ai-competitors/sims/market-migration-pair-focused-20261018-v18 --godot $godot --script verify_rival_world_foundation.gd --profile docs/codex/threads/ai-competitors/sims/market-migration-pair-input-20261018-v18/profile --test-port 47859 --timeout 240
& $py docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/market-migration-pair-player-20261018-v18 --output docs/codex/threads/ai-competitors/sims/market-migration-pair-cold-20261018-v18 --godot $godot --script verify_rival_world_foundation.gd --profile docs/codex/threads/ai-competitors/sims/market-migration-pair-input-20261018-v18/profile --test-port 47860 --timeout 240
& $py tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/market-migration-pair-player-20261018-v18 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/market-migration-pair-player-replay-20261018-v18 --godot $godot --timeout 240
```

The old fixture files were copied, unchanged, from the old variant's isolated profile to each candidate's separate isolated input profile before focused runs. The copied input is not a user save or a shared mutable project. New outputs were used for every run; the first old-player capture that met concurrent canonical source drift is [retained as a failed preflight](sims/market-migration-old-player-20261018-v1/).

## What passed

| Invariant | Evidence |
|---|---|
| Exact old fields and source | [Focused 58/0](sims/market-migration-pair-focused-20261018-v18/rival-verifier.log) checks every migrated pair after stripping *only* the new fields: all old encoded player/world fields are equal, including release Review metadata, units, cents, Fans, cash, active hands and RNG. The original fixture file is unchanged. The old world source marker stays `f8f…`; it is not relabeled to pass the new guard. |
| Month boundary | At cycle 7, snapshot6 has zero release facts despite two cycle-7 launches. At cycles 8 and 10, the saved snapshots each include the two actual prior-month releases. Fact provenance is independently checked against owner metadata by the v10+ world codec. |
| Historical sales/Fanbase | Each age month already earned gets 10000 basis points with the named old source. A half-earned old age month keeps that factor on Continue. The Fanbase neutral shadow gets `market-0-neutral`, matching its existing replay. Old Fans and all recorded accounting remain equal. |
| Future effect only | From the old cycle-10 save, the age-2 second earning half remains neutral; the new age-3 factor is 9700 basis points under the **OPEN/TRIAL** saturation formula. The resumed legal two-cycle world route completes. |
| Rejection | An unknown old world source, a missing old sale field and a changed historical earned-unit field each reject; the old fixture file hash/content remains unchanged. |
| Fresh processes | [Cold 15/0](sims/market-migration-pair-cold-20261018-v18/rival-verifier.log) restores all three saved pairs and matches month IDs/fact counts/current-source recapture digests. The [18-step replay](sims/market-migration-pair-player-replay-20261018-v18/run-report.json) passes. A separate [focused repeat](sims/market-migration-pair-focused-repeat-20261018-v18/rival-verifier.log) passes 58/0 with the same result line. |

The old pair's source marker remains old in the migration input. After a successful restore, the next capture is correctly labeled with the *current candidate* source; cold digest comparison uses that recapture. This is a tested in-memory transition, not proof of CheckpointCoordinator generation writing/recovery.

## Retained failures and uncertainty

| Version/output | Finding |
|---|---|
| Old player capture v1 | Canonical source changed during drift recording; runner rejected before case execution. Same config succeeded in a new v2 output. |
| Migration v11/v12 focused | Strict old-schema decode returned `Record field count` for all three pairs. Neither version accepted a migrated pair. |
| Migration v13/v14/v15 focused | v13 localized new-world rejection; v14 exposed mixed encoded key types; v15 used text keys but still missed nested Fanbase neutral sales fields. All failed outputs retained. |
| Migration v16 focused | Cycle-7 pair reached world validation; cycles 8/10 rejected Fanbase provenance because the synthetic neutral shadow used the real title's legacy source. |
| Migration v17 cold | Same-process 58/0 passed; the cold test compared intentionally old-source input bytes and raw JSON directly with a current-source recapture/typed snapshot, producing six verifier failures despite successful restore. V18 corrected the *test expectations*, not the migration mechanics. |

The private adapter is pinned to one exact pre-market source and is **not** integrated into `CheckpointCoordinator` or `StudioCheckpointStore`; no old generation was actually loaded, atomically migrated and written by normal Gameplay. The old player-only case **with earned sales**, the historical named source `3e0d3958…` and canonical presentation-compatible sources, Founder/former-player owners, additional campaign/age histories, corrupt cents/backup recovery, and graphical/exported Continue remain **NOT RUN**. Current canonical `rival_world_checkpoint.gd` adds presentation compatibility IDs absent from v18; do not wholesale copy this candidate. The market window, Review quality gate/lift and sales weights/floor remain **OPEN/TRIAL**. The 3% trial effect is not balance approval or proof that current weak rivals challenge the player.

## Recommendation

The design thread can own further private old-source/Coordinator acceptance and finish a source-pinned handoff once those gates and numerical policy are selected. Canonical migration, current-source reconciliation and gameplay adoption belong to the implementation thread. Keep the current TODO at **DESIGN review needed**; no QUEUED implementation entry or handoff is justified by this one-source proof.
