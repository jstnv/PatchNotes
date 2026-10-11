# Outstanding expenses legacy fixture repair

2026-10-09; local `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with existing dirty work preserved.

## Finding and change

The combined education gate v3 stopped after 58 passing suites: `verify_outstanding_expenses` reported 85 checks and one failure in its explicit schema-1 migration equality check. Those original logs remain in `../release-gate-education-v3/`.

The verifier constructs its old ledger from a current ledger. Since education introduced finance schema 6, that construction retained `education: {}` while declaring schema 1. The real `upgrade_v1` helper correctly reconstructs the journal and compares its complete schema-1 projection, which has no education field. Accepting the mixed dictionary would weaken its provenance check.

Only `patch-notes/scripts/debug/verify_outstanding_expenses.gd` changed: remove the future education field from the schema-1 fixture, and add a negative check that a schema-1 payload containing even empty education state rejects. The equality check still verifies complete reconstructed cash, bills, original due dates, credit and empty current education state, without charging cash again. The baseline journal has 10000 cents initial cash, a 50000-cent rent bill with 10000 paid and 40000 unpaid at its original cycle-2 due date, zero remaining cash and credit 595. The altered-historical-due rejection remains intact.

No runtime helper, finance schema, supported checkpoint revision or gameplay rule changed. The helper check does not add support for old checkpoint content revisions. A bounded read-only search of maintained `verify*.gd` files found no other explicit old finance schema construction or `upgrade_v1` fixture requiring this correction; envelope-schema rejection checks are separate.

## Verification

| Inherited maintained suite | Result | Duration |
| --- | --- | --- |
| `verify_outstanding_expenses` | 86 checks, 0 failures, exit 0 | 1.141 seconds |
| `verify_studio_finance_ledger` | 172 checks, 0 failures, exit 0 | 0.844 seconds |

Both commands ran headlessly with unchanged source before/after and no unclassified errors. Only the exact platform diagnostic `ERROR: Failed to read the root certificate store.` is exempted. `git diff --check -- patch-notes/scripts/debug/verify_outstanding_expenses.gd` passed.

The runner uses the reviewed release-gate inherited wrapper and separate profiles configured for test port 47733. These component suites do not acquire a checkpoint writer; the result does not claim a lease was exercised. The existing user game and its production port 62741 were untouched. No Computer Use or visible launch occurred.

Reproduction from the repository root:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' 'docs/codex/findings/outstanding-expenses-gate-repair-v1/run.py'
```

`result.json` and each `*.command.json` retain exact commands, profiles, durations, source/log/wrapper hashes and summaries. Each command has its complete log and before/after source manifest. `verify_outstanding_expenses.before.gd` is the exact pre-repair verifier recovered by hash from the immutable education archive.

- Original verifier SHA-256: `92ab99f2cae5e7a8848d8f79781f03e13c3f5054939556d543f84ea97b088b8b`.
- Repaired verifier SHA-256: `6956410131a5088f8bc1bbcf24c5cba46d9fd211c2ae377d33be1fb9c80110a0`.
- Of the 676 education-pinned files, only the previously repaired `verify_card_motion.gd` and this verifier differ. Runtime, scenes and data remain unchanged. The accepted education audit and archives remain immutable; their reproduction uses their exact archived source.

## Handoff

All runtime/debug/UID/tool sources are frozen for the parent's fresh combined gate v4. No owned process remains. This bounded repair does not claim the full gate or exported/rendered acceptance passed. No commit or push was made.
