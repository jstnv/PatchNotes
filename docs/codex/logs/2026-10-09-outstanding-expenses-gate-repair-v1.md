# Outstanding expenses gate repair — 2026-10-09

Local `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; existing dirty edits preserved. No commit/push, Computer Use, visible launch or user-process termination.

The parent's education combined gate v3 stopped after 58 passing suites at `verify_outstanding_expenses`: 85 checks, one failure. Source review confirmed its synthetic schema-1 fixture incorrectly retained schema-6 `education: {}`. The runtime migration helper correctly rejects that mixed schema.

Changed only `patch-notes/scripts/debug/verify_outstanding_expenses.gd`: erase education when constructing the old fixture and add explicit rejection of a schema-1 dictionary with the future field. Complete migrated-ledger equality and corrupt historical due-date rejection remain. No runtime, schema or checkpoint content-revision support changed. A bounded maintained-verifier scan found no other stale finance downgrade fixture.

Verification:

- Outstanding expenses: **86 checks, 0 failures**, exit 0, 1.141 seconds.
- Studio finance ledger: **172 checks, 0 failures**, exit 0, 0.844 seconds.
- Both inherited suites have exact command/log/source manifests, unchanged before/after hashes and no unclassified errors. Only the exact certificate-store platform diagnostic is exempted.
- Component suites used isolated profiles and the parent's test wrapper configured for 47733; no checkpoint writer was acquired by these suites. Existing user Godot PID 69180 and production port 62741 were untouched.
- Focused `git diff --check` passed.
- Among 676 education-pinned files, only the repaired card-motion and outstanding-expenses debug verifiers differ. Runtime/scenes/data are unchanged. Original education evidence and archives remain immutable.

Evidence: `docs/codex/findings/outstanding-expenses-gate-repair-v1/README.md` and `result.json`. Repaired verifier SHA-256 `6956410131a5088f8bc1bbcf24c5cba46d9fd211c2ae377d33be1fb9c80110a0`. Original gate v3 failure logs remain preserved.

All runtime/debug/UID/tool sources frozen and no owned process remains. Parent owns the fresh combined gate v4. Exported rendered acceptance remains deferred overnight; this repair does not close either broader gate.
