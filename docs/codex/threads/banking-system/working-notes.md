# Banking System working notes

Started 2026-10-06 (America/Los_Angeles). These notes stage this thread's design discussion; the [economy and banking design](../../design/economy-banking.md) remains the authoritative system summary. No new gameplay rule is approved by creating this file.

## Existing baseline

- **LOCKED:** Exact-cent cash accounting, $500 rent at each completed calendar month, typed obligation history, and one monthly credit update. Bank navigation is passive.
- **ACTIVE/TRIAL:** Current credit range, clean-profit gain, and typed penalty values are prototype defaults.
- **LOCKED direction / OPEN package:** A bank loan is at most $500 after the first actual sales settlement, with one active loan, capacity based on recurring surplus and existing installments, and unearned future interest waived on early payoff. Loans are not available in runtime.

## Questions to resolve in this thread

- **OPEN:** Interest rate, loan term, installment amount and rounding, and due-cycle convention.
- **OPEN:** Capacity calculation using actual settled portfolio cash, rent, and any existing installments.
- **OPEN:** Issuance, repayment, early payoff, and Bank screen behavior, including what players can inspect before committing.
- **OPEN:** Focused acceptance cases for affordability, arrears, credit, finance journals, and save/restore once the loan package is specified.

Record future discussion here in dated entries or new versioned files. Label observations separately from approved rules, and prepare a scoped handoff for the internal TODO only when the user requests it.

## 2026-10-06 candidate package

The [state note](2026-10-06-state-v1.md) and [first-loan proposal](2026-10-06-first-loan-proposal-v1.md) supply a concrete but unapproved $500 offer, exact payment math, capacity screen, and first-game pressure check. The [handoff](HANDOFF.md) holds proposed tasks for later review. No rule was promoted to LOCKED and no shared TODO entry was made.
