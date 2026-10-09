# Contracts design session v9 — Crown before Neon

2026-10-08 (America/Los_Angeles). User authorized the narrow read-only follow-up. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, with 61 uncommitted project paths at analysis-copy time. [Manifest](sim-v6/source-manifest.json) pins 1,125 project files and the analysis script; [overlay](sim-v6/dirty-source-overlay.zip) preserves the dirty portion. Branch, status and diff were inspected before edits. No commit, push, gameplay/test/asset/config change, shared TODO or shared design-authority edit was made by this session; existing worktree edits and `.codex-godot-temp` were preserved.

## Thread-local changes

- New [v6 findings](FINDINGS-v6-crown-before-neon-threshold.md), [sim-v6 evidence and scripts](sim-v6/), and this log.
- Updated only [Contracts README](README.md) and [HANDOFF](HANDOFF.md) to identify completed read-only evidence and a **proposed** further chain study.
- Created a temporary isolated Godot source copy/profiles under `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-threshold-v6-*`; archived exact dirty source and results in this folder, verified their hashes, then removed both temporary directories after resolving and checking their paths against the named Downloads directory.

## Exact checks/results

1. `run.py prepare`: 1,125 source files copied and SHA-256 matched; 61 dirty paths captured; analysis script SHA-256 `df339573b4dff9720bd352aeb01b6590194493879857df0e0a70b81a77d9ce28`.
2. Headless Godot 4.7.1 `--editor --import --quit`: exit 0. `run.py crown-current` and `run.py crown-lease`: exit 0 each, with all three declared arms successful; exact commands and Godot logs remain in `sim-v6/`. Nonfatal Windows root-certificate, scene-case and phase-refresh diagnostics were not treated as Contract failures.
3. `audit.py` at run: copied file hashes unchanged; script matched manifest; both legal foundations had Crown Review≥7.0, Awareness<125 and locked Neon; all arm, prebranch, hands, native card-choice, launch, award, threshold, settlement and finance checks passed. [At-run summary](sim-v6/audit-summary-at-run.json).
4. `archive_source_overlay.py`: 61 dirty paths archived and verified against manifest. `pack.py`: two full native JSON traces archived with byte-for-byte hash and ZIP integrity checks. After temporary-copy cleanup, `audit.py` reran from archives with exit 0; `copy_hashes_unchanged` is now `null` because the copy was removed, with its earlier `true` retained in the at-run summary.

The ordinary route began at Game-2 Review7.0/Awareness110 and launched Game 3 at Awareness123 with Crown's 12 Promotion, leaving Neon locked. The Lease route began at Review7.2/Awareness113 and launched at 126 versus 114 in matched cash-only/no-Crown controls; only the promoted trial unlocked Neon. Crown paid $1,920 total in both legal trials. Settled target-title Promotion gains by `L+4` were $202.79 and $258.74. All arms had nonnegative cash, zero overdue bills and valid ledgers. [Findings](FINDINGS-v6-crown-before-neon-threshold.md) explain the conditional threshold and economic limits.

No blocker. Next design question, if commissioned: play the newly available Neon offer on this legal route and compare the full Contract chain against matched-calendar alternatives. Final Crown/Neon tuning, Starwave offer terms and player-selected Neon focus remain OPEN; the shared queue was not changed.
