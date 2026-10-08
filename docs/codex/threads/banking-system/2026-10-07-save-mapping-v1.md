# Banking B5 state mapping

2026-10-07. Finance schema 3; BankLoan schedule schema 1. This is a typed value mapping and tested byte roundtrip, not a disk-restart claim.

## Run ownership

Persist RunState `_bank_run_id`, generated once with 16 OS-cryptographic random bytes at successful Studio creation, independently of gameplay RNG. Preserve it on checkpoint restore. Quotes are transient views; do not save pending modal confirmations. On resume require a fresh preview. The finance snapshot remains authoritative alongside RunState cash and cycle, and all three must agree before accepting any bank action.

## Ledger

Persist the entire schema-3 finance snapshot, including initial cash, actions, transactions, monthly rows, obligations, credit and `bank_loans`. Each loan retains its stable loan/run/quote identities, schema-1 compact schedule, issued installment count, principal/interest paid, closure flag/cycle and early-payoff flag. Schedule fields are principal, term, acceptance/first/last cycles, maximum installment, total interest and total payment. Future bills are derived individually, never materialized as a huge schedule array.

Each issued bank bill retains the ordinary typed-bill fields plus principal/interest due and paid components. Original due, payment events, late history and settled cycle survive payoff. Monthly `interest_cents` is expense in the original due month; `interest_paid_cents` is actual payment-month cash outflow. Principal repayment remains cash-only. Reports distinguish total overdue and rent-only overdue.

Acceptance and payoff are journal operations. Reconstruct from initial funding and replay every action; compare all derived fields before accepting loaded state. Acceptance rechecks the exact quote at its recorded revision; payoff rechecks exact unpaid principal and accrued unpaid interest. Never trust separately serialized balances, flags or credit.

## Encoding and limits

Native `var_to_bytes` / `bytes_to_var` roundtrip is covered by the focused verifier, including closed and late-paid loan history; object deserialization is not needed. Durable checkpoint JSON must encode 64-bit integers as canonical decimal strings under its reviewed DTO contract, and reconstruct StringName identity/kind fields explicitly. JSON numeric parsing is not a safe substitute for typed exact-cent records.

Schema-1 migration remains supported by the existing explicit provenance reconstruction. Schema-2 checkpoint migration needs explicit reconstruction/projection when durable historical files are supported; schema 3 must not be silently substituted into unknown old snapshots. The current game has no durable save runtime, so no existing player slot is upgraded here.

Checks: `verify_bank_loan.gd`, `verify_bank_finance.gd`, `verify_bank_integration.gd`, existing finance/typed-expense/UI suites. Separate-process restore, corrupt-file handling and checkpoint rollback remain on the checkpoint task.
