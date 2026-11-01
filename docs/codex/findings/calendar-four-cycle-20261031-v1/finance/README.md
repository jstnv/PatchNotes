# Finance calendar integration — 2026-10-31

Scoped worker record on shared `main`, baseline `2d5c8df152cd40eb827117270f13fed20af69498`. Existing Public Action Phase2A work and temporary Godot directories were preserved. Owned canonical changes are only `patch-notes/scripts/finance/{studio_finance_ledger,bank_loan,education_debt,outstanding_expenses,feature_spending_guidance}.gd`. No commit, push, build, player-save read/write, or canonical source-fenced harness run.

## APIs and saved shapes

- `StudioFinanceLedger.create(cash,rent=...,calendar={})`: omitted calendar retains exact historical2 timing; fresh profiles must have anchor0.
- `StudioFinanceLedger.adopt_calendar(ledger,profile)`: detached metadata-only conversion at `ledger.last_cycle`; returns empty on invalid/mismatched/repeated-different conversion. Identical adoption is idempotent. Adds `calendar:{version:uint,legacy_until:uint}` and `calendar_cutover_actions:uint` together. Historical actions before that index replay under their original calendar, including zero-cycle operations at the anchor.
- `BankLoan.schedule(principal,months,accepted_cycle=0,calendar={})`, `EducationDebt.schedule(trait,calendar={})` and `EducationDebt.create(owner,trait,calendar={})`: nonlegacy schedules retain optional `calendar` issuing context. Original `installment(schedule,number)` returns the frozen issuing-context timestamp. `effective_installment(schedule,number,target_calendar={})` returns a detached installment with mapped actual `due_cycle`. Use effective queries for future dues; issued bills remain untouched.
- `StudioFinanceLedger.payroll_due_cycle(employee,issued,target_calendar={})`: `issued` is the zero-based number already issued. New payroll records retain optional `calendar`. New `wage_changes` entries also retain optional `calendar`, independent of the hire's context. `payroll_wage(employee,cycle,target_calendar={})` maps prospective raise dates before comparing.
- `OutstandingExpenses.create_bill`, `service`, `valid_bill`, `describe` and `close_month` accept an optional trailing calendar. Calendar credit tiers use elapsed quarter-month units; original raw `recovery_overdue_cycles`, bill/payment timestamps and history remain unchanged. Standalone `tier(raw_cycles)` remains the historical2 fixture API through Clock.

Typed schema work belongs to root: admit the paired ledger fields, optional calendar in Bank quote/loan schedules and education schedules, optional payroll record calendar and optional wage-change calendar. Hire, course and payroll-schedule action shapes, bill/payment shapes, financial values and finance schema6 are otherwise unchanged. Missing metadata means historical2. Active save revision/migration validation must prevent arbitrary unsupported predecessor adoption.

## Evidence and limits

`project/` is a private source snapshot with scripts/data/queries and a minimal project; canonical source is not its import/cache/profile. AppData is redirected to this folder's `profile/`; normal Studio saves are not accessed. Only owned finance sources and the central Clock were refreshed after the initial snapshot. Initial missing-query/AppData setup failures are retained separately from the clean behavioral RED.

- `red-expected.log`: **RED**, fresh-profile productive action1 rejected by legacy journal validation;2 checks/2 failures, exit1.
- `expanded-final.log`: **PASS**,186 checks/0 failures, exit0. Covers fresh rent4, monthly Bank dates and unchanged arithmetic, even/odd adoption, unchanged typed financial records, old/new loans and hires at the same raw anchor, pending raises, education grace, overdue calendar tiers, recovery exclusion, guidance and complete replay.
- `green-complete.log`: **PASS**,568 checks/0 failures, exit0. Adds all96 new-calendar education installments through cycle432 and full cold replay; principal$5,000 and total interest$1,785.71 remain exact.
- `legacy-baseline.log` / `legacy-current.log`:121 typed ledger/report/payoff snapshots across40 legacy actions with payroll, prospective raise, Bank and education. `legacy-baseline.bin` and `legacy-current.bin` have identical SHA256 `E7074C3EE5DCA7EDA170932FC4169BD2D9A2F008A8B6C21D041D94AA49C7F33E`.
- `verify_bank_loan.log`: **PASS**,14,112 checks/0 failures. `verify_bank_finance.log`: **PASS**,207 checks/0 failures (frozen Bank1 journal oracle).
- `verify_outstanding_expenses.log`: **FAIL**,86 checks/6 failures; `outstanding-baseline.log` reproduces identical86/6 using untouched HEAD finance. Fixtures assume default$500 rent, while HEAD already uses$300. Calendar work does not change that value.
- `verify_education_debt.log`: **FAIL**,1,163 checks/13 failures; stale$500 rent expectations and missing retained checkpoint-fixture JSON in the private snapshot. This is not a passing maintained suite.
- `verify_feature_spending_guidance.log`: **BLOCKED**, minimal snapshot omits UI theme/autoload CardDatabase dependencies; process terminated. Focused direct guidance behavior is covered by the private finance check.

Full canonical save/schema/UI/world acceptance is root-owned and not established by these isolated checks. Broad balance and device/export acceptance remain separate.
