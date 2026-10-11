# Exported Banking acceptance continuation — 2026-10-10

## State and scope

Design-thread acceptance only. Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; the shared dirty worktree was preserved. No gameplay, shared TODO, commit or push change. This continues the [2026-10-09 exported session](2026-10-09-export-acceptance-session-v1.md) on its hash-matched, dedicated-profile build. The earlier Computer Use stop ended that turn; the user explicitly requested this retry.

## Actual exported route

1. The previous isolated game process had exited. A clean launch showed `Continue — Education native route · 1982, Month 28`. Continue restored the genuine Studio at cycle 54 with $16,402.47 cash, active College Dropout education debt, active $500 Bank loan and credit 621. The prior unsaved Design hand had rolled back to the saved Studio checkpoint.
2. Finances quoted $4,412.86 remaining education principal, $0 due interest and $0 already-due rent/payroll/Bank bills. The confirmation quoted $4,412.86 total, one zero-cycle action and waiver of future education interest. Confirming left cycle 54 unchanged, cash $11,989.61, Education **Closed**, $0 principal remaining, $5,000 principal paid and $473.06 interest already paid. The Bank's $500/12-month loan remained active with first $46.67 installment due at cycle 56; credit remained 621.
3. Quit from the saved Studio exited normally. A fresh process launched, Continue restored cycle 54 and $11,989.61. Finances retained the $4,412.86 principal repayment in the partial month-28 report; Education remained Closed with the previous paid education bills and their original due dates/history visible. The separate Bank loan remained active with the same schedule and credit 621. The game was then closed from the saved Studio.

The dedicated profile's resulting [checkpoint generation 4](acceptance-evidence-v1/earned-cash-education-payoff.checkpoint.4.json) was copied byte-for-byte into this folder. File SHA-256: `719351867ADB8876F9B1B8B907F633A405C0BFFC5159AE6AD0ABB762BD83E3B6`; its envelope payload SHA-256 recomputes correctly. Payload sequence 4, content revision `19e79e7fdd6378fc80abfbade73f63943014e43ad88ef0441fe92ac217919127`, cycle 54, cash 1,198,961 cents, education `closed=true`, `early_payoff=true`, `closed_cycle=54`, `principal_paid_cents=500000`, and one Bank loan with `closed=false` and first due cycle 56. The earlier genuine pre-payoff checkpoint and fresh-test backups remain separately preserved.

## Result and limits

**Pinned exported Banking/Education route: passed.** The fresh Dropout setup/payoff/Continue and the genuine earned-cash Bank-plus-education installment/payoff/Continue have been exercised through actual exported controls. The second route's installment was observed in the prior session; its payoff and cold Continue completed here. The previous retry's save-slot message was not reproduced after a clean launch; in that retry the listener port was held by that same game process, so it does not establish a cross-process conflict or a source defect.

This does not certify the later whole-project source snapshot: seven included presentation/settings files drifted after this pinned export. It also does not close broader integrated Fanbase/Starwave/publisher acceptance or release readiness. The new process log contained startup lines only, with no runtime/script error. No automated suite was rerun. Follow-up for the implementing/release thread: build from the intended final source revision and run its integrated exported gate. No new Banking gameplay task arises from this bounded route.

Files changed by this continuation: this note, the checkpoint evidence copy, and Banking-folder index/status links. Checks: actual exported interaction, cold Continue, exact cash arithmetic, saved payload fields and payload/file hashes, then documentation link and diff checks.
