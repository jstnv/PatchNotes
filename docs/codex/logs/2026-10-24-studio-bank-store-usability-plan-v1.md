# Studio, Store, priorities and Bank usability implementation plan

> Execute sequentially with superpowers:executing-plans. Preserve the shared checkout, inherited edits and `.codex-godot-temp`; no commit or push in this task.

**Goal:** implement the user's 2026-10-24 creation, Overview, persistent tips, Store, priority and Bank recovery request.

**Architecture:** retain the existing state/command/ledger boundaries. UI drafts remain separate from committed rules. Version new Trait selections and Bank quotes, preserve historical ledger replay, and explicitly admit the accepted predecessor checkpoint/source pair.

**Tech stack:** Godot 4.7.1 GDScript, isolated Python verifier orchestration, native rendered layout checks.

## Rulings and bounded implementation choices

- Traits have no count cap for new Studios. Names alone are clickable; hover explains effects and point price. Selected/Available scroll independently, positives before negatives. The balance and cash bonus stay outside scrolling. Negative draft balances are visible; Play is blocked and Overview directs the player to Traits. Existing Trait versions retain their original meaning. Graduate and College Dropout remain mutually exclusive education histories (one education account).
- Overview shows selected positive/negative Traits in two scrollable columns. Contextual tips persist until dismissed with the existing close button, and Tip reopens current guidance; ordinary hover descriptions still behave as hover descriptions.
- New priority controls use 10–50%, five-point steps, exact 100 total. Invalid drafts may exceed 100 so the whole set can pulse red, starting at zero tint; corrected drafts clear the pulse. Contract uses sliders and the existing pie chart. Historic saved allocations remain readable without silently changing their weights or RNG.
- Store detail copy shows Core/Scope and play cost; acquisition amounts live on action buttons. Familiarity explanation is on purchase hover. Missing named parents have wrapped navigable buttons; other non-node gates retain honest disabled explanations. Remove category cone fills/borders, retain connecting paths and arrows. Research admission confirmation retains its irreversible down-payment warning.
- Bank keeps exact schedules, positive interest, original-due recovery order and credit rules. New quotes automatically fit requested principal to qualified bounds; the starting floor is three actual monthly rents. Cash-poor Studios may use a three-rent floor facility **once per Studio**, including with active debt, when ordinary sales capacity is insufficient. Existing Bank commitments consume ordinary underwriting capacity. Arrears are serviced from financing by the existing ledger recovery path and quoted as deductions/net proceeds. Borrowed money is never settled sales; wealthy Studios receive no floor-facility subsidy. Old quotes remain exactly replayable.

Ruling: use one lifetime recovery facility rather than forbidding all active debt — the latter reproduced the user's Bank-overdue recovery dead end; the lifetime limit prevents recursive emergency stacking. This is a bounded ACTIVE/TRIAL implementation choice, not final economy tuning.
- Continue remains Studio-only. No AI policy, scoring, prices, publisher progression or market balance adoption is included.

## Review focus

1. Historical/current saves and active rival weights: exact old state/RNG retained; malformed version mixtures rejected.
2. Negative Trait draft and education conflict: visible actionable error, no invalid Studio creation.
3. Over-budget pulse: starts at zero, smooth shared phase, no stacking tweens after reopen/reset.
4. Missing multi-parent navigation and narrow layouts: all names readable, no accidental purchase.
5. Bank refinance/wealth loop: no fabricated income, duplicate quote, overflow or free principal.

## Sequential tasks

- [x] Freeze source, branch/HEAD and existing change inventory; record meaningful failing checks.
- [x] Traits v9, Selected/Available layout, Overview columns, fixed balance; persistent contextual tips. Verify creation, effects and predecessor Traits.
- [x] Shared priority feedback and Contract sliders/pie; enforce new 10% commands while preserving saved historical allocations. Verify drafts, commits and runtime/headless parity.
- [x] Simplify Store details/navigation and remove cone backgrounds. Verify owned/affordable/blocked/multi-parent states and supported view sizes.
- [x] Version Bank quotes, cap/floor eligibility, arrears recovery and anti-cycling; update quote UI and strict save compatibility. Verify historical journals, fresh-process restore and legal recovery cases.
- [x] Run focused/required regression and rendered checks, review results, repair defects, update system docs/TODO/current state and dated result log with exact evidence and remaining human checks.
