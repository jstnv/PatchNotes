# Contracts design session v10 — legal Crown→Neon chain

2026-10-08 (America/Los_Angeles). User authorized the read-only chain continuation in this Contracts design thread. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, with **104 uncommitted project paths** at copy time. Branch/status/diff, `CURRENT_STATE`, `TODO` and Contracts authority were inspected before edits. The [manifest](sim-v7/source-manifest.json) pins 1,146 project files and the exact analysis script. No commit, push, gameplay/test/asset/config edit, shared TODO or shared design-authority edit was made by this session; overlapping worktree changes and `.codex-godot-temp` were preserved.

## Thread-local files

- New: [v7 findings](FINDINGS-v7-crown-neon-offer-chain.md), [sim-v7 predeclaration, scripts, traces and audit](sim-v7/README.md), and this log.
- Updated: this folder's [README](README.md) and [HANDOFF](HANDOFF.md) only. Earlier v5/v6 results remain untouched.
- The temporary source copy and isolated user profiles were created under `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-chain-v7-*`, then removed after resolving and verifying both absolute targets under the named Downloads directory. The source overlay and raw trace were hash-verified and archived here first.

## Exact checks and outcome

1. `run.py prepare`: copied and SHA-256 checked 1,146 project files; recorded 104 dirty paths; analysis script SHA-256 `97812b7da4af239a15ae2ec5187692f761e2a293a5d5501af7343c0017b8f718`.
2. Godot 4.7.1 headless `--editor --import --quit`: exit 0. `run.py crown-lease-chain`: exit 0, `valid=true`, four declared arms successful, with exact command JSON and native log in `sim-v7/`. Nonfatal Windows root-certificate, path-case and phase-refresh diagnostics are retained in the logs.
3. `audit.py` before packaging: all copied project hashes unchanged; pre-Crown foundation, branch equality, Crown hands/advance, Game-3 trace, newly pending Neon offer, legal Neon hands/$1,451.16 payout/18 Promotion, Game-4 card/review parity, two-cycle delay, matched cycles72/74/76, finance and Starwave profile checks passed. [At-run summary](sim-v7/audit-summary-at-run.json).
4. `archive_source_overlay.py` verified all 104 dirty-file bytes against the manifest; `pack.py` verified and archived the complete native JSON trace. After temporary-copy cleanup, `audit.py` reran from the ZIP/overlay and exited 0; the copy-hash field is now `null`, with its earlier `true` retained in the at-run summary.

At cycle76, chain versus Crown-only is **+$1,020.64 cash**, **−$475.52 cumulative settled portfolio sales**, and **two fewer Game-5 productive cycles**. At chain Game-4 launch cycle72, its cash was $3,281.68 lower; it crossed ahead after the next settlement. All arms had no arrears and valid ledgers. The precise decomposition, limits and recommendation to retain ACTIVE/TRIAL terms are in [v7 findings](FINDINGS-v7-crown-neon-offer-chain.md).

No blocker. The next **proposed**, unapproved design study is a common-calendar Game-5 launch/settlement continuation and separate real cash-pressure/Bank case before any final balance lock. The shared queue and implementing thread were not changed.
