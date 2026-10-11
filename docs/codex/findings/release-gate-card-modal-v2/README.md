# Card-frame and checkpoint-modal integrated gate — 2026-10-09

HEADLESS AUTOMATED PASS: **105 maintained suites**, clean project import, clean release export, **225-entry PCK audit**, and unmodified exported headless Main Menu startup (exit0, errors[]). Source remained pinned through the run. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, shared uncommitted work preserved.

## Reproduction

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/release_gate.py --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --output docs/codex/findings/release-gate-card-modal-v2 --defer-graphical-startup --isolate-checkpoint-writer
```

Use a fresh output directory for a repeat. Exact per-suite commands, results/logs, source/wrapper hashes, artifact hashes and package inventory are retained here. The runner deliberately reports remaining acceptance (exit2; shell reported1), not full release readiness: `headless_automated_pass=true`, `automated_pass=false`, `release_ready=false`.

## Failure and repair

The preceding immutable v1 attempt stopped at `verify_beta_planning`:18 presentation assertions expected the old mixed-case/unwrapped names, full Marketing category, and lifecycle wording inside Department. The user-approved frame instead uses fitted uppercase names, MKTG and a lifecycle icon. Only that verifier changed: complete normalized name plus original tooltip, explicit category abbreviation, correct visible non-null lifecycle texture and full tooltip explanation. Existing value, finite-depletion, Scope/secondary and zero-cycle assertions remain. No gameplay/scoring change was needed. The v2 full run passes, including all1,708 card-frame assertions across51 cards with zero truncated catalog fields.

## Limits and retained artifacts

Fresh verifier profiles and inherited wrappers exercise the real TCP writer lease on47733. They do not test production62741 acquisition; existing user game windows/saves were untouched. Headless Controls checks are not desktop playthroughs. The prior desktop launch access-denied blocker remains. Current exported Fanbase/Starwave/Education, Bank/Continue and next-launch Promotion interaction, approved audio and human balance acceptance remain open. AI G1 still needs its explicit ruling. No commit or push.

Artifact directory: `C:\Users\64jus\AppData\Local\Temp\patch-notes-demo-20261007-mhjr_ky4\demo`.

EXE SHA256: `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`.

PCK SHA256: `19445eb2e8ce9ac52d9287000ccca6f097e319cfc9ae0ef03c54267116482382`.
