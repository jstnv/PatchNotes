# Market trial migration — 2026-10-19

## Result and source boundary

**PASS: 260 assertions in 16 fresh Godot processes**, eight original-save cases followed by separate cold Continue processes. All returned exit 0 with empty error lists. `migration-pinned-v1-runs.json` records the completed sequence; each `migration-pinned-v1-<case>[-cold].json`, `-run.json`, and `.log` retains assertions, source markers, process CPU and exact command.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty checkout preserved. The tested source includes the implementation thread's compiled-script/query fingerprint fix and current-revision decode fast path. All 16 processes assert equal source identity at start and end. Final cross-file readback confirms every start/end marker is `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`; all eight original file hashes remain unchanged. [Aggregate evidence](migration-pinned-v1-summary.json) records exact counts, source pairs, original hashes and timings. Disk exhaustion temporarily blocked this aggregation; it was completed after command access recovered on 2026-10-19.

No Bank rule, TODO, existing design record, commit, push, or release-readiness claim was changed by this migration subtask. The root implementation task owns integration and overall status.

## Exact matrix

| Original case | Migration / Store | Cold Continue | Hot wall / CPU seconds | Cold wall / CPU seconds |
| --- | ---: | ---: | ---: | ---: |
| prior-world | 33/33 | 7/7 | 17.831 / 15.125 | 5.399 / 5.016 |
| current-world | 26/26 | 7/7 | 10.781 / 9.859 | 5.623 / 5.000 |
| synergy-world | 27/27 | 7/7 | 15.854 / 14.328 | 5.593 / 5.328 |
| bank-recovered | 20/20 | 6/6 | 8.558 / 8.156 | 4.811 / 4.516 |
| bank-only | 20/20 | 6/6 | 9.472 / 8.656 | 6.252 / 5.438 |
| founder-v1 | 26/26 | 7/7 | 10.747 / 9.547 | 5.783 / 5.156 |
| world-v1 | 28/28 | 7/7 | 14.642 / 12.828 | 6.965 / 5.781 |
| founder-v2 | 26/26 | 7/7 | 13.091 / 11.375 | 7.702 / 6.891 |

Total wall time is 149.103 seconds; total Godot process CPU is 133.000 seconds. CPU is Windows `GetProcessTimes` user+kernel time for the Godot child; wall time covers its process lifetime. These are repeated migration/storage verification workloads, not representative campaign/population budgets. Several exits retain the existing six-ObjectDB-instance leak warning; no script/parser/runtime error was reported by this matrix.

### Inputs

All paths below are repository-relative. Each hot result records the absolute original path and SHA-256 and asserts it is unchanged at completion.

- `prior-world`: `docs/codex/findings/queue-20261018-v2/prior-v2.json`; original source `9f321103092057b23ced7fc43ebefdffc1aa56e620b237dc734e17a451a1cbf7`.
- `current-world`: `docs/codex/findings/queue-20261018-v2/roster-closeout.json`; original source `1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82`.
- `synergy-world`: `docs/codex/findings/queue-20261018-v2/profile-ai-world-before/APPDATA/Godot/app_userdata/Patch Notes/saves/studio/checkpoint.21.json`; original source `bf8d5157c91dd608456d66470d61e4927edb283401ef001c93b3a62d34b9aa6f`. This case copies the actual old Store envelope bytes.
- `bank-recovered`: `docs/codex/findings/bank-age2-20261018-v1/route-v1.json.studio.json`; source `1e7e9c1f1c5766d209a5d0826cf07982c528b6e4b132087e08130dcb0c30cb82`. Existing recovered Studio finance remains exact.
- `bank-only`: `docs/codex/findings/bank-age2-20261018-v1/bank-only-v1.json.initial.json`; same original source. This is the actual preceding Studio snapshot with accepted sequence zero, not the unsaved 42-cent partial-payment development state and not an age2 test.
- `founder-v1`: `docs/codex/threads/ai-competitors/sims/market-density-v31-historical-input-20261018-v1/profile/APPDATA/Godot/app_userdata/Patch Notes/market-founder1-original.json`; source `0679720d9518de5ce8eb7f94ba7cd2970d001afad945b3a0e4156e5396de7040`.
- `world-v1`: the same historical-input directory's `market-world1-original.json`; source `3e0d3958740f71149b3bb5b3e9f0b15b70cc6d71c96c6c03dd1f594d56a71c8f`.
- `founder-v2`: `docs/codex/findings/title-studio-audio-20261018-v1/before/verify_legacy_world.json`; source `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`.

The runtime names 17 supported source/revision pairs. This matrix exercises six actual world source identities plus two player-only snapshots from one of those source identities; it does not individually exercise every named historical source.

## Implementation

Six new files under `patch-notes/scripts/market/`:

- `legacy_pre_market_studio_validator.gd`
- `legacy_pre_market_schema.gd`
- `legacy_pre_market_sales.gd`
- `legacy_pre_market_fanbase.gd`
- `legacy_pre_market_world.gd`
- `market_save_migration_trial.gd`

The five frozen validators originate from `before-source.zip`, captured before market edits. Their headers retain original file hashes. Local class references are remapped; runtime loading breaks the frozen schema/Fanbase preload cycle. The exact rules-revision calculations are cached within each process. These helpers preserve the current pre-market Contracts, Store branch, founding-roster and AI save shapes rather than copying the candidate's older baseline.

Migration checks exact named source/content pairs, raw old player and rival schemas/accounting, and restores the old whole world before adding fields. Existing sales receive historical neutral factors only for already-earned age months. Fanbase's neutral counterfactual stays neutral with `historical=false`. Existing active projects retain base Genre standards. A saved `market_origin` records original source, content revision, cutoff cycle and active-project identities; it constrains historical exceptions. Old release Review metadata remains unchanged. The transformed world receives current runtime provenance only after original validation. Current-schema validation and whole-world restoration run before returning it.

The root task integrated these methods into direct Studio validation/hydration, normal checkpoint coordination and world decoding. Original on-disk bytes are preserved until an ordinary subsequent Studio commit publishes a new generation.

## What the checks establish

- Exact preexisting player fields, RNG, finance/Bank/payroll/education, frozen Reviews and founding provenance are preserved.
- Exact rival hands, Core state, ownership, release history, Founder state and RNG are preserved, excluding only the new market fields and validated current source marker.
- Old active projects keep their original base standards.
- Unknown source, mixed rival revision, mixed world/project/sales shapes, changed cash and changed earned-units accounting are rejected.
- The normal Store inspect/Continue path accepts the migrated originals without rewriting their bytes or publishing a generation.
- A subsequent pending Studio flush publishes current content at the next generation; this harness explicitly marks the boundary pending to verify storage. It is not represented as a new legal player gameplay command.
- Separate cold processes inspect the exact committed payload, restore all player/world fields, and do not publish another generation.
- The prior-world case injects a pre-rename write failure, confirms unchanged committed generations/state, preserves a deliberately damaged newest generation, offers a validated backup without automatic restoration, and explicitly recovers that backup into a new generation.

## Retained attempts and limits

### Focused fixture follow-up, 2026-10-19

After final migration aggregation, the implementation thread's repaired fixtures and runner input path were exercised sequentially with the same `run.py`: `verify_contract_challenge_publishers.gd` passes 52/52 (6.040 seconds wall, 5.500 CPU; `pinned-contracts.log` and `pinned-contracts-run.json`), and `verify_studio_roster_versions.gd` passes 239/239 (6.887 seconds wall, 6.250 CPU; `pinned-roster.log` and `pinned-roster-run.json`). Both exit 0 with empty error lists. These additional 291 assertions are separate from the 260-assertion migration matrix. No further runtime edits were made by this subtask.

Earlier outputs remain evidence at their own source. A first harness parse error was corrected; a concurrent-source migration failure prompted freezing runtime edits. The accepted-sequence-zero Bank-only failure exposed and corrected the migration guard. Origin-era `final-v1` passed 132 assertions in eight processes before the driver was stopped for the final source/fast-path fixes and disk exhaustion. The complete `pinned-v1` matrix supersedes those checks for its tested source.

This is headless actual-save and ordinary storage API acceptance. It does not claim graphical input, old executable rejection, exported/native Gameplay acceptance, a full new campaign, market balance, representative population CPU, or all historical source permutations. Those remain separately scoped in the implementation task. Original shared edits and `.codex-godot-temp` are preserved.

Reproduce into a fresh tag with `python docs/codex/findings/market-adoption-20261018-v1/run_migrations.py <new-tag>`. It runs one Godot child at a time, each bounded to 300 seconds and isolated output/profile directories. Creating `migration-<new-tag>.pause` beside the runner stops between children. Never reuse an existing output tag.
