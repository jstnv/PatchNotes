# Release gate: isolated verifier writer

2026-10-09. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; prior dirty changes preserved. Parent explicitly assigned a test-only helper because pre-existing game PID69180 owns62741. The process was not closed or interacted with. Education writer confirmed runtime/debug source frozen.

Changed `tools/release_gate.py` and `docs/codex/findings/release-gate-writer-isolation-v1/`, plus this log. Preserved the prior graphical-startup deferral option. Added opt-in47733 instrumentation through findings-generated inherited verifier wrappers, real TCP ownership semantics, source/wrapper hash checks, resume-mode guards and explicit limitations. No runtime/debug/scene/data edits. The Genre verifier's deliberately pre-acquired lease is preserved through a narrow recorded exception; all other non-pristine stores reject.

Verification:

- `run.py`: four fresh headless verifier processes,97 assertions, exit0; default and explicit occupied-port controls both stop before import. All104 wrappers generated; no full gate run here.
- `audit.py`:902 independent source/driver/wrapper/raw-output/ownership-preflight checks, PASS. Its first diagnostic regex falsely matched a word in a PASS assertion; anchored diagnostic classification corrected this audit-only issue without native changes/reruns.
- Independent source/output review closed without a remaining tooling defect.
- `git diff --check -- tools/release_gate.py`: exit0.

All236 pinned source/tool/harness entries match before/after; native47733 released. Original blocked final gate-v1 and all existing application state preserved. Parent can run a new full gate with `--isolate-checkpoint-writer --defer-graphical-startup`. Instrumented verifiers do not test the production port; uninstrumented exported headless startup remains a main-menu-only check. No Computer Use, user save, commit, push or release-ready claim.

[Detailed findings and artifacts](../findings/release-gate-writer-isolation-v1/README.md).
