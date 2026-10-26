# Banking foundation scope audit — 2026-10-17

The user requested implementation of the Banking foundation and explicitly set balance tuning aside. At intake, branch `main` was at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` with a shared dirty worktree. Existing edits and `.codex-godot-temp` were preserved.

Current canonical source already contains `StudioFinanceLedger`, `OutstandingExpenses`, `BankLoan`, `StudioFinances`, cash-HUD access, credit history and typed checkpoint mapping. `StudioFinanceLedger` has quote, acceptance, scheduled bill and payoff operations; `StudioFinances` has amount/term inputs, schedule display and explicit confirmation. The relevant TODO marks B3–B5 and native Banking restore complete, and separately queues exported distressed-finance acceptance B7. The last local Banking design disposition deliberately carries no new mechanics or UI adoption delta. These source and record reads confirm implementation presence, not a fresh runtime pass or completion of B7.

No new deposit/account, savings, investment or other broader Bank product has an approved local design specification. Before editing canonical gameplay, the requested new foundation scope needs to be identified so it does not duplicate the existing loan/finance system or invent a new product. A concise user choice was requested: broader banking features, strengthening the existing Bank implementation, or another specified scope.

Changed files: this audit and the Banking thread README link. Checks: branch/HEAD/status/diff inspection, targeted current-source and design/TODO reads, and `git diff --check` on the README after the link edit. No gameplay code, simulator, export, test, TODO, commit or push changed in this audit.
