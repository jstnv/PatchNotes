# Integrated Education headless gate

2026-10-09. Local `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with uncommitted shared changes. **HEADLESS AUTOMATED PASS**; graphical/exported interaction and release acceptance remain separate.

- All **104 maintained suites** passed, each exit0 with no unclassified errors.
- Project import, clean copied-project import and release export passed.
- **214 PCK entries**: every payload checksum valid, all required runtime resources retained, excluded development material absent.
- Unmodified exported EXE headless Main Menu startup: exit0, errors[].
- Source and helper/wrapper hashes stayed unchanged through the gate. No Computer Use or visible application startup.

## Reproduction and evidence

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/release_gate.py --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --output docs/codex/findings/<fresh-gate-directory> --defer-graphical-startup --isolate-checkpoint-writer
```

Run from the repository root. Each suite's command JSON and log remain alongside [gate-result.json](gate-result.json), [source.json](source.json), [build-manifest.json](build-manifest.json), [package inspection](pack-manifest-verified.json) and [headless startup](headless-startup.command.json). Use a fresh directory for a changed source.

The optional inherited verifier wrappers use isolated profiles and the real TCP writer lease on47733. Production62741 acquisition is not exercised by these wrapped Coordinators; the already-running project process is untouched. Runtime/package code is unmodified by instrumentation. Exported smoke reaches Main Menu only and does not establish save/Continue or gameplay interaction. [Isolation scope](../release-gate-writer-isolation-v1/result.json).

`headless_automated_pass=true`, `automated_pass=false`, `release_ready=false`. The runner intentionally returns remaining-acceptance exit2 (the shell wrapper reports1); there is no recorded failure. No commit, push or release readiness is claimed.

## Artifact pin

Directory: `C:\Users\64jus\AppData\Local\Temp\patch-notes-demo-20261007-rkpwiocp\demo`.

- EXE SHA256: `7c3e92d9c175dc8754947c93f2ad6d9514091e51cf542407b7595e2bbbd20257`
- PCK SHA256: `b413b7718c6c1a6f911a860623cf50bea93cf02098682ec47a62113bf445736c`

## Preserved failures and remaining acceptance

The first attempt stopped before testing on occupied production62741. The v2 gate stopped on a timer-dependent Store intermediate-motion assertion; the v3 gate stopped on an invalid synthetic schema1 fixture retaining a future education field. Both repairs changed only debug verifiers. Original failures and exact limits: [Store timing](../card-motion-gate-repair-v1/README.md), [legacy fixture](../outstanding-expenses-gate-repair-v1/README.md). The original Education source pins/audits remain immutable; their two old verifier versions differ from this final gate, while gameplay matches.

Actual current Fanbase/Starwave/Education exported controls, Continue, installments/payoff and next-launch Promotion remain deferred to the [overnight acceptance plan](../export-fanbase-starwave-v1/PLAN.md). Approved audio/credits/audible playback and human balance evidence remain separate. No overnight task or automation was scheduled.
