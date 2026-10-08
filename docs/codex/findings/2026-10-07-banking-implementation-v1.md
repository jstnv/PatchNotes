# Banking B3–B5 implementation

2026-10-07. Local `main`, HEAD `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`; uncommitted work preserved. No commit, push, export or disk-restore claim.

## Delivered

- Exact cent amount input (minimum $500), whole-month term and derived maximum eligible principal; no fixed menu or arbitrary economic cap. [Payment mechanics](../threads/banking-system/2026-10-07-implementation-math-v1.md) were documented before gameplay edits. Equal principal with remainder cents first, declining interest at 1% of scheduled opening principal, half-up rounding, compact bounded-time total/schedule math.
- Native two-positive-settlement gate and conservative capacity, one active loan, overdue exclusion. Acceptance is financing, zero cycles, run/revision bound and replay protected. Changing cash invalidates a prior quote.
- Native first-full-month installment bills, rent-first service, interest-before-principal partial payments, preserved original dues/payment/late history and once-per-category credit. Due interest expense is distinct from actual interest-payment cash. Principal never reduces operating profit.
- Exact early payoff of unpaid principal and already-due interest; future interest waived. Closed loans retain history. Insufficient funds, stale actions and reentrant callbacks reject before publishing changes.
- Cash HUD → Finances → Bank offers exact inputs, paged dated preview, explicit confirmation, active balance and payoff. Reports distinguish total overdue from unpaid rent, retain paid bank bill history and identify payments. Both supported resolutions and Design/Alpha/Beta access are checked.
- Finance schema3 and Bank schedule schema1, full action-journal reconstruction, typed byte roundtrip and tamper rejection. [Checkpoint mapping](../threads/banking-system/2026-10-07-save-mapping-v1.md) specifies run identity and canonical integer/identity fields. Durable restart remains a separate task.

## Evidence

Reproduction from repository root using Python `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`:

```text
PY docs/codex/findings/banking-implementation-v1/run_checks.py import verify_bank_loan verify_bank_finance verify_bank_integration verify_studio_finance_ledger verify_outstanding_expenses verify_studio_finance_integration verify_studio_finances
PY docs/codex/findings/banking-implementation-v1/run_full.py
PY docs/codex/findings/banking-implementation-v1/render.py
git diff --check
```

[Logs and commands](banking-implementation-v1/) use Godot4.7.1 with isolated APPDATA/LOCALAPPDATA. Arithmetic:14,112 checks; loan journal:207 checks; existing finance172 and typed credit85; existing finance UI118. Full maintained gate:67 suites pass,13,633 PASS markers (some suites aggregate instead). Additional phase and render checks followed that full gate. The final label-layout correction was followed by focused Bank integration, existing finance UI and rendered checks; runtime ledger/RunState were unchanged after the full gate. The [full manifest](banking-implementation-v1/full/gate.json) identifies the exact full-gate files.

Independent iterative amortization checks cover odd cents, short/long terms, maximum capacity/next-cent rejection, representability and malformed inputs. Finance tests include both5500/5700 starts, even/odd acceptance, before/at/after due payoff, zero/weak second sales months, partial interest payment after rent, original-month expense versus payment, blocked production, duplicate/stale operations and changed derived fields. Integration uses native settled sales from explicitly frozen release fixtures, not claimed human or played balance routes.

The first arithmetic run exposed a wrong expected long-term total in the test fixture; independent cent-by-cent enumeration corrected it to12,500,500 cents. UI render exposed vertically wrapped input labels; fixed unwrapped labels and added readable-height checks. A phase fixture initially omitted priority initialization; corrected the fixture before successful Design/Alpha/Beta checks. No test failure was treated as success. A direct nonisolated Godot check-only invocation crashed during startup; maintained isolated-profile checks and rendering passed.

## Limits and next work

This implements the accepted trial rules; it does not settle the final surrounding economy. No new score pricing, fees, bankruptcy behavior, education debt, payroll producer or automatic bailout was added. Payroll and Lease rent changes must feed actual required obligations/rent into quotes when their separately approved slices activate. Disk restore, schema2 historical file migration, checkpoints and exported interaction acceptance remain separate. The native byte test is not a durable save test.
