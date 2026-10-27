# Storage inventory — 2026-10-26

Status: **INVENTORIED 2026-10-26; bounded generated-cache cleanup COMPLETE 2026-10-27.**

User asked whether unnecessary storage could be removed. Existing shared edits, `.codex-godot-temp`, player saves, source and Git history remain intact.

## Authorized cleanup — 2026-10-27

The user explicitly authorized deletion: "Go ahead and delete the things we wont need."

Removed **9,402,922,398 logical bytes (8.76 GiB), 35,198 files in 1,014 generated directories**:

- All 984 proposed old `.godot` caches: 3,032,868,888 bytes (2.82 GiB). Each still matched the proposal's file inventory/sizes/timestamps, had a local project and original import sources, had no tracked descendants and no symlink/junction escapes. Canonical `patch-notes/.godot` and protected temp were excluded.
- 30 private `APPDATA/Godot/export_templates/4.7.1.stable` dependency copies: 6,370,053,510 bytes (5.93 GiB). Each copied EXE matched the retained installed template's SHA-256; the tiny version markers were exactly `4.7.1.stable`. One unmatched template folder was preserved. Actual exported player EXEs/PCKs/ZIPs were preserved.

Fresh verification: **PASS**, all 1,014 removed paths absent, 971 canonical source-file hashes/inventory identical, tracked worktree status identical, two installed template hashes unchanged, protected roots present. Source snapshots, reports, original assets, baselines, replay/checkpoint data, player saves, Git and `.codex-godot-temp` were outside deletion scope. No gameplay tests or source changes were needed.

Recorded C: free space rose from 53,298,098,176 to 62,230,003,712 bytes during cleanup: **+8,931,905,536 bytes (8.32 GiB)**. This is the observed drive delta during the operation, not an exact attribution of all system activity. Folder payload deletion and physical disk-space delta are different measurements; no post-cleanup whole-tree size is claimed.

The native PowerShell runner checked absolute resolved containment before each recursive deletion. Initial repeated tracked-file scans were slow because Git tracks 110,444 paths. After a durable 100-target journal, that run was interrupted and resumed with an equivalent directory hash-set check. Nineteen completed removals beyond the journal were reconciled against the original preflight; the final receipt records the interruption. Final removal errors/skips: zero. No rollback, reset, commit or push.

Receipts: `approved-cache-preflight.json`, `approved-template-preflight.json`, `deletion-receipt.json`, `verification.json`. Runner and verifier remain alongside them. The receipt guard prevents accidentally rerunning a completed deletion. Earlier inventory access failures remain recorded; ambiguous/inaccessible evidence and source bundles were preserved.

## Measurements

Read-only Python metadata traversal visited 1,127,270 files in 121.422 seconds, totaling **86,799,065,249 logical bytes (80.84 GiB)**. This is a lower bound: 1,554 paths could not be inspected. No directory links were followed. The sandbox metadata provider returned inode zero for all files; physical allocation and hard-link deduplication therefore cannot be established. Invalid initial allocation totals were discarded. These measurements do not establish bytes reclaimable on the C: drive or OneDrive quota.

| Area | Logical GiB |
| --- | ---: |
| `docs/codex/threads` | 51.07 |
| `docs/codex/findings` | 22.86 |
| `patch-notes/design-logs` | 5.13 |
| `.codex-godot-temp` (protected) | 0.88 |
| `.git` | 0.85 |

The largest thread areas are AI Competitors (31.41 GiB) and Contracts (12.85 GiB). File-extension totals include WAV (27.81 GiB), JSON (16.28 GiB), EXE (9.88 GiB), ZIP (5.52 GiB), and generated Godot samples (3.04 GiB). These overlap the directory totals and must not be added to them. WAVs and source snapshots in independent variants are not expendable merely because they are copies.

Several captured `git-status.txt` files exceed 100 MiB. Future experiment receipts should avoid enumerating every untracked file in every retained snapshot; record compact repository status and source manifests instead.

`git count-objects -vH`: 29.97 MiB loose objects, 818.68 MiB packed, zero garbage. No Git pruning is justified.

## Narrow first cleanup proposal

`cache-candidates.json` lists **984 ignored `.godot` directories beneath `docs/`, with 3,032,868,888 logical bytes (2.82 GiB)**, whose latest scanned file modification predates the scan by more than 48 hours. These exclude canonical `patch-notes/.godot` and all `.codex-godot-temp` paths. The total of all discovered caches, including recent/protected caches and Python caches, was 3.42 GiB.

Supporting source: `tools/simulate.py` source inventory selects explicit source roots and root files, excluding project-root `.godot`; `tools/simulator_variant.py` uses that source inventory for baseline/current identities. `.gitignore` ignores all `.godot` folders. `git ls-files -- '**/.godot/*'` returned no tracked cache files. Some Python caches ARE tracked, so a blanket cache sweep is inappropriate.

Before deleting the proposed caches, revalidate resolved containment, link-free paths, inactivity, complete source assets for regeneration, and absence from sealed evidence file manifests. Older cache timestamps alone do not establish that a simulation is inactive. Re-import may be required for future native runs. Actual disk savings must be measured after an authorized cleanup; logical totals are not a savings guarantee.

## Larger cleanup proposal

Review old simulation/run bundles for lossless archival. Retain exact candidate source, baselines, manifests, ancestry, commands, outcome summaries, representative captures and failed cases. `docs/codex/threads/simulation-engine/VARIANTS.md` explicitly requires referenced run/replay folders and sealed evidence hashes; removing raw folders without a documented restore path would break that contract. Do not delete old experiments wholesale.

An archive pilot should verify byte-for-byte restoration and record a path/index migration before removing any originals. Do not hard-link editable candidate projects together: independent edits must stay independent. Keep active runs and current source accessible. Preserve existing exports until their retention is decided separately.

Future large generated runs can be directed to a dedicated local, nonsynced evidence location with compact repository manifests, but this requires an explicit path/retention convention. No simulator behavior or output path was changed in this inventory pass.

## Evidence

- `inventory.py`: read-only scanner; inode-zero physical-allocation guard corrected after first scan.
- `inventory.json`: measured logical totals, largest files, extension totals, inaccessible paths.
- `cache-candidates.json`: proposed cache paths, sizes and timestamps; no execution script or automatic deletion.

The original inventory pass performed no cleanup. The separately authorized cleanup above changed generated files only; no gameplay tests, commit, push, export, TODO or canonical source changes.
