# M4 testing foundation evidence

2026-10-11. This directory records the bounded campaign-parity and independent-batch implementation. See the [dated implementation assessment](../2026-10-11-extraction-m4.md) for results and limits. This is a partial M4 foundation; it does not complete the architecture's AI policy gates or M5 shared world.

## Contents and reproduction

- `before-source.zip`, `before-hashes.json`, `status-before.txt`, `diff-before.patch`, `head.txt`: preserved turn baseline from dirty `main` before implementation.
- `run_checks.py focused`: native Gameplay comparison, batch failure/determinism checks, campaign/development/Contract and checkpoint regressions. Each run uses the existing isolated `card-presentation-v2/run.py` harness.
- `run_checks.py fresh`: separate-process replay of six native-comparison campaign segments and six batch success/failure prefixes. Requires the focused artifacts first.
- `run_pilot.py <new-label> <cohort> <release-horizon>`: explicit independent fresh-Studio fixture campaigns, one warmup and three repeated measurements. It saves the exact declared configuration and verifies the fixed fixture policy source hash. All processes have an external 240-second timeout.
- `audit.py`: verifies accepted run exits, errors, current source hashes, exact state/RNG/signal comparisons, repeated batch identities, TODO/data preservation and the seven-script turn scope. Generates `acceptance.json`, `source-after.json`, `turn.patch` and `results.json`.

Run Python tools from this checkout with the bundled Python runtime. Evidence folders are deliberately exclusive: use new labels for reruns and adapt the recorded label list rather than overwriting earlier evidence. Existing replay tapes enforce exact mechanics source and runtime; source changes require regeneration from recorded initial cases, not bypassing the fence.

Individual process logs and artifacts are under `docs/codex/findings/card-presentation-v2/m4-*`. `results.json` includes failed preliminary attempts as well as accepted checks. Accepted checks are listed explicitly in `acceptance.json`.

## Evidence semantics

Native comparison drives real Gameplay handlers and the actual checkpoint coordinator in isolated profiles. Hand animations are canceled after their already-committed mechanics; this is an automated mechanics comparison, not visual or audible acceptance. Scene-only tutorial acknowledgments and the two coordinator callback bindings are the only Run exclusions. Native phase transitions are compared against the equivalent completed headless action sequence.

Batch `case.variant.json` and `replay.tape.json` preserve exact object-disabled Variant values. `case.json`/`initial.json` are readable companions. Use `CampaignBatch.load_case()` for exact input reconstruction; ordinary JSON parsing can change numeric and key types. Results contain deterministic identities; separate metrics contain nondeterministic clocks and Godot allocation counters.

The injected policy factory and catalog are trusted code. Detached observations prevent ordinary observation edits from changing mechanics; they do not sandbox arbitrary code. Command budgets bound returned policy decisions. A policy that never returns still requires the external process timeout. Recorded policy metadata is declared by the caller; the provided fixture CLI separately checks the specific fixture ID, version and source hash.

Throughput includes exact trace hashing and artifact persistence. Godot static allocation counters are not operating-system resident memory. Independent campaigns have separate calendars: this pilot does not measure a shared-calendar rival world or approve competitor population, strategy or balance values.
