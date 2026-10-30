# Gameplay restoration implementation plan —2026-10-28

Inline under executing-plans; one final focused read-only review. Baseline main HEAD f3e0f2b5d35270c879327bc297b389748571feb4, runtime39413580c9c5addc58d5ed5e3b60de49be3e2a77c2ebc6fa4bb65c4c8a2add9d. Preserve inherited edits, concurrent records and `.codex-godot-temp`; no commit/push/export.

User requested the missing Gameplay slice and approved three finite non-upgrade Design Features, no added year/release gate and$0 direct fees: Timer System T2→D1/Scope1/$950; Inventory System T3→D2/Scope2/$1,700; Categorized Scores D7→T2/Scope3/$2,400. Categorized Scores requires ordered Timer System AND Score System AND Lives System; existing Alpha Power-Ups becomes its child, with existing stats/Scope/price/fee. Inventory→Score System remains pending clarification, so no dependent change until selected; current root behavior is retained meanwhile. Other prior Gameplay dependencies remain.

- Capture exact old paid Power-Ups/Score queues and current active rival world; RED exact new definitions/three-parent AND/finite/cost tests.
- Extend exact named-parent count from1–2 to1–3. Reject duplicates/missing/self/cycles/count surrogates as before; share one50% familiarity cap across all parents. Use actual admission/Research and atomic rejection paths.
- Add only the three approved rows, then Power-Ups acquisition parent. Preserve historical ownership/payments/frozen supply, no retroactive parent grant. Do not implement the separate general Alpha Design-ancestor draw gate.
- Reorganize Gameplay into combat top, Timer/Categorized Scores/Power-Ups middle, Score/leaderboards below and Controls/Scripted AI/Difficulty in their own band. Keep inward roots centralized, full common grid, obstacle-safe local arrows and existing other categories.
- Reconcile exact previous catalog revision plus known source/content pairs for both player and every active rival; unknown/mixed pairs reject. No finance, Core standards, Bank or AI policy changes.
- Test each of three missing-parent arms, admitted parents vs ownership, shared familiarity, new finite phase plays, paid old queues/current saves, actual three-link map navigation at900/1152/1280, live/headless rules/RNG parity and fresh legal replay. Keep late Research failure OPEN; use coalesced refresh regression, no blanket performance claim.
- Focused review, failures retained, source-pinned log/current-doc/TODO updates. Pending Inventory/Score choice stays explicit.

Layout ruling: put the independent Inventory root on row8 and Controls on row9, instead of extending to11. This preserves the previous overall map-height envelope while keeping five roots inward-aligned; Score remains its existing root pending an optional parent selection.
