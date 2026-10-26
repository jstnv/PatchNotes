# Publisher checks and queue reconciliation — 2026-10-17

## Scope and worktree

User: finish Neon/Starwave checks, then update TODO with completed and remaining work. `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, extensive pre-existing/concurrent uncommitted edits. Read current state, TODO, provenance README, publisher design/acceptance and current source/diff. Preserved all overlapping gameplay/AI/Bank edits and `.codex-godot-temp`; no canonical gameplay implementation, commit or push in this pass.

## Work completed

- Used Computer Use on the retained281-entry exported game, exact EXE/PCK hashes in the [finding](../findings/queue-completion-20261011-v1/PUBLISHER-MATRIX-2026-10-17.md). Isolated profiles and Dummy audio; no player-save changes or audible claim.
- Replayed Neon from the unmodified cycle15 ordinary-input Studio checkpoint. Captured1280 result and keyboard return, then fresh-process Continue. Exactly$1,560 once,20 Promotion and$5,402.44 final cash atcycle17.
- Replayed Starwave from the unmodified cycle34 Studio checkpoint. Captured1152 chooser/keyboard acceptance, switched to1280 through Settings, completed three hands and one legal four-card redraw, captured full result/keyboard return. Exactly$2,240 once on hand3, zero Starwave Promotion and$18,481.16 final cash atcycle37. Fresh-process Continue and completed browser/keyboard Back passed.
- Both new completed checkpoints survive cold Continue byte-for-byte. Original-versus-replay full payloads match after normalizing only the insertion order of exhausted-ID maps. Preserved the initial stricter comparison failure and explained the source-backed map interpretation.
- Reconciled prior education distress/recovery evidence in the previously stale evidence README. Updated TODO item23, C5, C5-next-pass, Starwave S4/S5 and B7; retained all newly queued foundation tasks. Added a bounded CURRENT_STATE entry.

## Files and artifacts

- `docs/codex/TODO.md`, `CURRENT_STATE.md`, this log.
- `docs/codex/findings/queue-completion-20261011-v1/README.md`, `PUBLISHER-MATRIX-2026-10-17.md`.
- New read-only audit `audit_publisher_matrix.py`; `publisher-matrix-audit-20261017.json`, retained `publisher-matrix-audit-20261017-order-sensitive.json`; refreshed `audit-export.json`.
- Capture323–335 PNGs and append-only `captures/index.jsonl` rows.
- `checkpoints/neon-resume-completed`, `neon-resume-cold-restored`, `starwave-matrix-completed`, `starwave-matrix-cold-restored`; isolated Neon resume and Starwave matrix profiles/logs.

## Exact checks

Python executable: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (commands from repo root).

```powershell
$python = 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $python docs/codex/findings/queue-completion-20261011-v1/capture_checkpoint.py neon-matrix-resume neon-resume-completed
& $python docs/codex/findings/queue-completion-20261011-v1/capture_checkpoint.py neon-matrix-resume neon-resume-cold-restored
& $python docs/codex/findings/queue-completion-20261011-v1/capture_checkpoint.py starwave-matrix starwave-matrix-completed
& $python docs/codex/findings/queue-completion-20261011-v1/capture_checkpoint.py starwave-matrix starwave-matrix-cold-restored
& $python docs/codex/findings/queue-completion-20261011-v1/audit_publisher_matrix.py
& $python docs/codex/findings/queue-completion-20261011-v1/audit_export.py
git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check
```

Results: all four archives pass payload SHA256 validation; publisher audit25/25; general audit15,434/15,434 with zero runtime errors. The tracked diff whitespace check passes. Initial publisher comparison19 checks/2 failures is retained; the only mismatches were exhausted-ID dictionary row order, not cash/RNG/result drift. No Godot source was edited, so no new full engine gate was run; the historical135-suite gate belongs to the retained binary only.

## Remaining work / limits

The shared source changed during this work. Contract/publisher module bytes match the retained export, but Gameplay, checkpoint coordinator/schema/hydration, development session and Bank UI differ; new rival scripts also exist. Do not close latest-source C5/S4/S5 from this binary. Rebuild/re-pin after integration settles, then run affected maintained and exported continuation/rollback acceptance. The finding enumerates unobserved Starwave-plus-Bank service, exported failed-launch Promotion preservation, B7 human/age/older-education-payoff cases and audible/clean-machine acceptance separately. Final balance and newly queued foundation adoption remain outside this check pass.

The temporary game windows were closed through the game's Quit control after the final captures. All evidence and isolated profiles remain available.
