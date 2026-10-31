# Studio menus, contract recovery and cash feedback

**Goal:** Implement the user's 2026-10-31 detailed UI/payment request without routine questions.
**Architecture:** Keep authoritative RunState/ContractSession transactions separate from read-only presentation. Reuse FolderUI and existing actions. Root executes inline; one fresh review at completion. Preserve dirty main/HEAD3a61522, all existing edits and both .codex-godot-temp folders. Work in the authorized shared canonical project with an exact pre-edit archive; no worktree/commit/push/public build.
**Spec:** User screenshots and direct request in this chat; UI system/economy documents remain authority except the explicitly changed contract arrears rule.

## Design / rulings
- Dashboard has three centered vertical actions: Market Info, Studio Management, Start Production. Move root rivalry and trait text into their information pages.
- Market Info: Daily Chart (existing Market browser), Publisher List, Rival Info. Rival Info shows each actual owner, post-start live games/titles, Fans and actual cash; never count frozen historical games as live.
- Management retains Feature Store and Employees and adds Post Game Summaries, Bank, Studio Info. Keep existing unlocks. Bank opens the current Bank page and Back returns to Management. Studio Info holds specialty/traits.
- Production: Produce New Game is always first; Contracts second. Preserve release/acceptance/priorities rules and child Back/Escape/focus. Use existing folder theme and animations.
- Theme the existing Beta LaunchWarningDialog using the shared confirmation component, retaining text, confirm/cancel and launch rules.
- Subscribe hand affordability controls to cash/finance changes; disconnect on rebind/teardown and preserve selected instances. Future stocks automatically work through those same authoritative signals.
- Contract hands ignore spendable-cash/arrears gates but retain real one-cycle settlement, oldest bills, debt, payroll, Bank, exact payout and RNG. Use contract-specific financial provenance and preflight; keep ordinary production/Research expense gates intact. Never waive debt, forge cash or make stored cash negative.
- Display bankroll = actual cash minus total overdue. A zero/negative bankroll gradually tints button backgrounds red without persistent font tint. Spending remains based on real cash.
- Coalesce committed signals per frame into a net popup. Launch it from the Cash border with the existing score-style rise/settle/hop/fall feel; at contact update displayed balance, shake horizontally and flash text red/green. Preserve net changes arriving during a flight; no authority changes, input interception or animation during binding/Continue. Debug infinity stays isolated.
- Historical certificates remain source-bound. Final ruling: retain exact existing2e5 frozen input bytes and original generation provenance; allow only the two static raw-byte SHA256/path pins plus current strict validation and exact same-content predecessor. No relabeling, wildcard source or regenerated historical balance. This supersedes planned regeneration because concurrent Pass Budget changes alter prospective production. See final log for retained failed cohort attempt and OPEN career acceptance.

## Steps / acceptance
- [x] Record RED checks for menu grouping/live counts, themed warning, cash-driven selected-hand refresh, broke and overdue contract completion, debt HUD and net animation timing.
- [x] Implement three folder groups and information pages; verify every child Back/Escape, existing unlocks and passive state/RNG.
- [x] Implement contract recovery in shared kernel and live UI; test zero cash, partial overdue payout, full settlement, rejection/RNG rollback, cold journal reconstruction and ordinary-production rejection.
- [x] Implement event-driven affordability refresh and themed warning; retain selected hand and signals across rebind/teardown.
- [x] Implement cash feedback as an isolated presentation component with deterministic sampled motion; test batching, inflight changes, debt appearance/clear, no premature number update, supported viewport sizes, debug/Continue and no authority mutation. Pause processing is source-reviewed (Always), not a separate device acceptance.
- [x] Source freeze, focused regressions and native captures at1152/1280; exact previous save/Studio-only Continue. Verify both unchanged frozen opening inputs with exact2e5 raw-byte/path pins and full current validation; do not regenerate/relabel historical data. Fresh whole-change review; record exact results/failures in dated logs and TODO/state/design. No public package or Git publication.

Final scoped acceptance:317 checks PASS at source `5b253e0c999d11652782544266cdb222ad052cd01d49ab8969f9669b074a70c2`; see [dated log](../../logs/2026-10-31-studio-hub-bankroll-v1.md). Public packaging, Git operations and separate Pass Budget career/balance acceptance remain outside this completion.
