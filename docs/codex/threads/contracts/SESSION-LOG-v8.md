# Contracts design session v8 — integrated Promotion settlements

2026-10-07 (America/Los_Angeles). User authorized a read-only simulation follow-up. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`; the project had 57 dirty paths at source-copy time. [Manifest](sim-v5/source-manifest.json) pins them and all other copied project files. Earlier branch/status/diff inspection preceded edits. No commit, push, lock, release claim, shared TODO, design authority, gameplay, test, asset or configuration edit was made by this design session. Preexisting overlapping worktree changes were preserved.

## Files changed in this session

- New: [v5 findings](FINDINGS-v5-integrated-promotion-settlement.md), [v5 simulation folder](sim-v5/), this log.
- Updated: [Contracts README](README.md), [HANDOFF](HANDOFF.md) only. Earlier v3 review and v7 log remain untouched.
- An isolated disposable project copy and user profiles were created under `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-promotion-v5-*`; both were removed after exact source overlay, traces and audit were archived in this thread folder.

## Exact checks and results

1. Python `run.py prepare`: copied 1,122 project files; source and copy SHA-256 matched; recorded `main` HEAD and 57 dirty paths. Installed only the analysis script in the disposable copy.
2. Godot 4.7.1 `--headless --editor --import --quit`: exit 0. The runner classified a known Windows root certificate-store diagnostic as environmental; no other import error.
3. Godot headless `promotion_balance_v5.gd` with `--cohort=neon-current`, `neon-lease`, `crown-lease` and absolute output paths: all three exited 0, each produced three declared arms, and each reported `valid=true`. Exact command JSON and logs are in `sim-v5/`.
4. `audit.py` before packaging: all copied source hashes unchanged; analysis script hash matched; every route/arm, pre-branch parity, trial/cash-only Contract result/hands, later card choices, launch-cycle parity, consumed/suppressed award, `L+2`/`L+4` capture, finance validity and nonnegative cash check passed. [At-run summary](sim-v5/audit-summary-at-run.json) preserves this state.
5. `pack.py`: all three raw native JSON traces archived with byte-for-byte SHA-256 verification into [native-traces.zip](sim-v5/native-traces.zip); original large JSON files were removed after verification. `archive_source_overlay.py`: 57 dirty files archived and checked against the manifest in [dirty-source-overlay.zip](sim-v5/dirty-source-overlay.zip).
6. After disposable-copy removal, `audit.py` reran from archived traces and overlay: exit 0; all applicable checks passed. `copy_hashes_unchanged` is now `null` because the temporary copy was removed, with the earlier `true` retained in the at-run summary. Python AST parse passed for four `sim-v5` scripts; both ZIP integrity checks passed; `git diff --check -- docs/codex/threads/contracts` passed. Godot logs include nonfatal Windows path-case and phase-refresh warnings.

## Result and follow-up

The isolated Promotion contribution to target-title **settled** sales at `L+4` was $258.74 (current Neon, 18 points), $328.67 (Lease Neon, 18 points), and $202.80 (Lease Crown, 12 points). The legal no-offer arms launched two cycles earlier and are opportunity-cost context only. Trial end cash exceeded no-offer in all three, including Contract receipts and other changed timing. The existing bounded trial stays the recommendation; no final balance lock or new numerical approval follows. Details and limits are in [v5 findings](FINDINGS-v5-integrated-promotion-settlement.md).

Next design question: a Crown-before-Neon legal route could test whether Crown Promotion affects Neon availability. A cash-constrained or active-Bank-loan route would better probe value under pressure. The shared TODO and implementing-thread queue were not edited; the [handoff](HANDOFF.md) marks the follow-up **proposed**.
