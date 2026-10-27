# Bank summary and separate payment breakdown — 2026-10-26

## Request and starting state

User reported excessive Bank text and asked to move the monthly interest log behind a separate button while keeping Financial history. Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; existing shared edits, prior Search-first/hover/employee fixes, export preset and `.codex-godot-temp` preserved. No Git index changes.

## Implementation

`patch-notes/scripts/ui/studio_finances.gd` now has a separate **Payment breakdown** view. The main Bank retains amount/term/rate, total interest/repayment, next scheduled payment and active principal/payoff; adjusted requests and actual overdue deductions remain visible when relevant. Financial history retains its existing credit/monthly finance contents on the main page. Active loans use readable labels instead of internal identifiers.

Monthly installment principal/interest and the prior detailed qualification calculations remain available on the separate page. Previous/Next retain the exact 12-payment page size with disabled bounds. Back/Escape use the existing navigation path to return to Bank and restore button focus. New input invalidates the preview and its details button. Rate copy is shortened without changing the actual rate.

No finance, repayment, rate, eligibility, overdue, Bank capacity or confirmation transaction changes. The existing quote and payoff dictionaries remain authoritative. Viewing details does not mutate finance or the displayed acceptance terms.

Changed support files: `patch-notes/scripts/debug/verify_bank_presentation.gd`, `docs/codex/design/economy-banking.md`, `docs/codex/TODO.md` and this session/evidence folder.

## Checks

Godot executable: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`, version `4.7.1.stable.official.a13da4feb`. Every process uses separate `APPDATA`/`LOCALAPPDATA` under `.codex-godot-temp/bank-presentation*-20261026/`.

Commands from repository root:

```
<godot> --headless --path patch-notes --script res://scripts/debug/verify_bank_presentation.gd
<godot> --path patch-notes --position 60,60 --resolution 1152x648 --script res://scripts/debug/verify_bank_presentation.gd -- --out=<absolute findings folder>
<godot> --headless --path patch-notes --script res://scripts/debug/verify_bank_integration.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_usability_bank.gd
```

- RED: old UI exits6 with six expected failures across both sizes: missing details button, monthly schedule on the main page, raw active-loan identifier.
- PASS: focused headless presentation exits0 with no failed checks at1152×648 and1280×720. Covers no-loan default, quote details access, both 12-payment pages/bounds, passive navigation, restored Financial history/focus, exact quote confirmation and one real loan acceptance.
- PASS: same focused native checks exit0 at both sizes, using OpenGL/NVIDIA. Four captures inspected: `bank-main-1152.png`, `bank-main-1280.png`, `payment-breakdown-1152.png`, `payment-breakdown-1280.png`. Captures are standalone menu fixtures; maintained integration separately verifies the existing gameplay sales header and overlay geometry.
- PASS: maintained Bank integration exits0 with `Bank integration: 0 failures`. Exact displayed-term acceptance, cancellation/reentry/stale payoff, education confirmation, active loan/payoff, financial history, HUD and midphase calendar preservation remain intact.
- PASS: lending/recovery usability exits0, **38 checks/0 failures**. Overdue deductions, adjusted maximum, first floor facility, shared commitments, anti-loop/no-millionaire subsidy and old quote replay remain intact.
- Maintained integration/usability fixtures retain existing six ObjectDB cleanup diagnostics; integration also retains intentional invalid-hand warnings. No script errors/failing checks. Focused final presentation logs contain no cleanup warnings.

These are frozen accounting/presentation fixtures, not a campaign balance or Bank age2+ accessibility study. [Raw receipts and source hashes](../findings/bank-presentation-20261026-v1/result.json).

## Limits

No new EXE/ZIP, commit/push, Drive synchronization or whole-release/human approval. Existing downloadable builds retain the previous Bank UI until rebuilt.
