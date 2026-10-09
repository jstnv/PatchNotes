# Card tempo — 2026-10-07

Branch `main`, HEAD `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`. Shared worktree already contained pending implementations; preserved those changes and `.codex-godot-temp`. No commit or push.

## Request and implementation

User requested left-to-right played-card bounces at 140 BPM and explicitly confirmed four bounces per specialization cycle. One beat is 60/140 seconds; one specialization bar is four beats (12/7 seconds).

- `patch-notes/scripts/ui/hand_presentation.gd`: shared beat constants; sequential base, bonus and exit bounces; score callbacks at peaks; beat-derived transitions and label animation. Specialization header begins with the four-bounce bonus bar.
- `patch-notes/scripts/ui/synergy_notification.gd`: four-beat lifetime and half-beat entrance.
- `patch-notes/scripts/debug/verify_card_motion.gd`: beat-derived sample times and measured bounce/bar timing assertions. Preserved the existing unrelated background-line removal.
- Updated core design, TODO and CURRENT_STATE; retained commands/logs under `docs/codex/findings/card-tempo-v1/`.

Authoritative gameplay commit ordering, scores, specialization bonuses and productive-cycle rules remain unchanged.

## Checks

Runner: `docs/codex/findings/card-tempo-v1/run_checks.py`, with fresh APPDATA/LOCALAPPDATA profiles per invocation. Exact Godot commands, exits and detected errors are retained in each `.command.json` beside the logs.

- `import`: exit 0, no detected script errors.
- `verify_beta_marketing_specialization`: exit 0, no detected script errors.
- `verify_beta_qa_specialization`: exit 0, no detected script errors.
- `verify_card_motion`: final exit 0, **0 failures**, at 1152×648 and 900×600. Covers Design/Alpha/Beta/Contract motion, redraws, left-to-right timing, four-bounce specialization duration, input guards, score ordering and retained candidates.

Initial verification exposed a duplicate test-local name and two outdated redraw timing samples. Corrected these and reran the complete motion verifier successfully. The runner filters the environment's known root-certificate-store message; final command records contain no other detected errors. These are native headless behavior checks, not a claim of manual visual approval or release readiness.

No remaining blocker for this scoped request.
