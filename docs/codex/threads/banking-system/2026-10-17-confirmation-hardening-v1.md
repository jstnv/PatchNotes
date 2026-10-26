# Bank confirmation hardening — 2026-10-17

## Source and scope

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the shared worktree was already dirty with unrelated AI, Store, audio and documentation work. The Bank finance domain files were clean before this edit. The user chose to strengthen the existing Bank implementation and set balance tuning aside. This change does not alter qualification, capacity, rate, term, bill service, credit, cash or save rules.

## Change

`patch-notes/scripts/ui/studio_finances.gd` now binds a deep copy of the displayed Bank acceptance, Bank payoff or education payoff quote to its confirmation dialog. Confirmation consumes that payload once. Canceling the dialog, closing Finances, changing pages, editing an amount/term or refreshing finance state clears the pending action. A dismissed or duplicate confirmation signal cannot use a later quote or execute a stale payoff. RunState still independently validates the quote/revision and rejects stale or unaffordable transactions atomically.

`patch-notes/scripts/debug/verify_bank_integration.gd` now exercises a different valid quote arriving after the acceptance dialog is shown, canceling a Bank payoff dialog, a dismissed Bank payoff followed by reopening Finances, a changed education payoff preview, and a repeated education confirmation signal. The tested action commits only the terms shown in its dialog; dismissal and repetition leave finance state unchanged.

## Checks

Godot 4.7.1 console: `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`. Each command used an isolated `APPDATA`/`LOCALAPPDATA` under this thread's `checks/` directory and the canonical `patch-notes` project. From repository root, the command pattern was:

```powershell
& $bankGodot --headless --path patch-notes --script res://scripts/debug/<verifier>.gd
```

- Before edit, `verify_bank_loan` passed 14,112 checks, `verify_bank_finance` passed 207, `verify_outstanding_expenses` passed 86, `verify_studio_finances` passed 118, and `verify_bank_integration` exited 0. Logs: `checks/2026-10-17-bank-hardening-baseline-v1/`.
- After edit, `verify_bank_integration` exited 0 at both supported UI sizes and explicitly passed the displayed-quote and dismissed-payoff checks. The first expanded education fixture failed because it omitted the existing `initialize_cash(0)` prerequisite, then raised a script error when reading the absent account. That failed run is retained as `verify_bank_integration-education.log`; the corrected fixture is `verify_bank_integration-corrected.log`, exit 0. A final run after wiring the dialog's cancel signal is `verify_bank_integration-final.log`, exit 0 with zero failures at both sizes, including the canceled-payoff and one-shot checks. Logs: `checks/2026-10-17-bank-confirmation-v1/`.
- After edit, `verify_studio_finances` passed 118 checks and `verify_education_atomicity` passed 36 checks. `git diff --check` passed for the two edited source files and this thread's README. Godot's existing ObjectDB exit warning appears in focused logs; no verifier failure remains.

No full maintained suite, rebuilt export, visible B7 distressed-finance route, human quote-comprehension review, commit or push is claimed. B7 remains queued. The unrelated dirty files and `.codex-godot-temp` were preserved.
