# Authorized generated-cache cleanup — 2026-10-27

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, shared dirty tree preserved. Read CURRENT_STATE/TODO/README and the prior inventory, inspected branch/HEAD/status/diff before deletion. User explicitly authorized deleting unnecessary files after the concrete inventory proposal.

## Scope and results

**COMPLETE at the safe generated-cache scope.** Removed 984 old ignored `.godot` directories and 30 byte-identical private Godot export-template copies: **9,402,922,398 logical bytes /8.76 GiB, 35,198 files**. One unmatched template folder preserved; inaccessible paths and all actual experiment evidence/source/archive/save payloads preserved. No blanket folder purge or source deduplication.

Deletion boundaries: beneath repository `docs/` only, absolute resolved path verified before every recursive native PowerShell `Remove-Item -LiteralPath`, no tracked descendants, no links/junctions, file sizes/timestamps and complete preflight inventory matched. Local projects/import originals checked. Godot/game processes checked before cleanup and periodically during it; no game closed. Canonical cache, installed templates, `.git`, `.codex-godot-temp`, player saves and deliverables excluded.

## Exact checks

- Bundled Python `-X utf8 docs/codex/findings/storage-cleanup-20261026-v1/preflight_cleanup.py`: PASS, 984 accepted /0 skipped, original source availability and unchanged proposed cache metadata.
- Targeted template discovery: 31 old private-profile folders considered, 1,554 inaccessible paths retained in discovery report. Installed 4.7.1 templates identified independently; no change to their location or bytes.
- Bundled Python `-X utf8 .../preflight_templates.py`: PASS, 30 exact SHA-256-matched duplicate folders /1 unmatched folder preserved. Retained originals: debug `5bf89f938102f0e3119a5fdaafac4f55884c877681667d0dce844509c8bd8752`, release `76269a403bb832599edeee4432a5b7a7e88c018eb5c9c798dfd8289359b0ec07`.
- PowerShell `& 'docs/codex/findings/storage-cleanup-20261026-v1/remove-approved-generated.ps1'`: final exit0, 1,014 removed directories /0 skipped. Initial run interrupted after its durable 100-target journal to optimize the repeated 110,444-path tracked inventory scan. Resumed with a directory hash set; 19 completed removals after the journal reconciled from preflight/absence. Final receipt records both phases.
- Bundled Python `-X utf8 .../verify_cleanup.py`: exit0, PASS; all removed paths absent, 971 canonical source-file bytes/inventory identical, tracked status identical, both installed template hashes identical, protected roots present. No gameplay verification applicable.
- HEAD unchanged after cleanup. No commit, push, export or TODO update.

Observed C: free space 53,298,098,176 →62,230,003,712 bytes, +8,931,905,536 /8.32 GiB during the operation. Other processes can change drive free space; no exact whole-folder post-cleanup size or causal attribution beyond the recorded file removals is claimed.

## Files and follow-up

Audit files added/updated only under `docs/codex/findings/storage-cleanup-20261026-v1/`, plus this log. [Report and full receipts](../findings/storage-cleanup-20261026-v1/README.md).

Substantial remaining storage belongs to independent source snapshots, raw assets, replay/outcome evidence and original exports. Removing those needs an archive/restore contract and reference reconciliation; they were not assumed expendable. Future compact provenance should avoid repeated 100+MiB full-untracked Git-status dumps. No simulator behavior or retention policy was changed in this cleanup.
