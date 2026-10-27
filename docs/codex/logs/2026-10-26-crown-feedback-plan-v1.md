# Crown feedback implementation plan

Date:2026-10-26. Branch main, HEAD087df09d653858b72c6e2dc344352237433dd3ac; shared dirty edits preserved.

Goal: complete approved GF2–GF6 at the private Brief scope specified by `threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v4.md`. Normal catalog activation remains gated. No reward, draw, economy or Bank changes.

Architecture: create an implementation-owned isolated simulator from current canonical source; reconcile only the sealed Crown runtime delta against its archived base. Add a pure feedback module reusing the exact planner/evaluator and validated relationship history. Bind it to existing Contract scores, expandable Details and Studio offer information. No durable streak field. No canonical gameplay adoption while the underlying path is private.

Tech: Godot4.7.1/GDScript; existing simulator version, isolated profile and replay/checkpoint tools.

Review focus: stale/invalid selection; final-hand-only all-zero warning; positive requested/cap-zero credit; incomplete/duplicate/out-of-order history; late save/finance and animation locks.

## Tasks / ledger

- [x] Create current-source private variant and source-pinned reconciliation record; retain original sealed candidate untouched.
- [x] Add failing native GDScript feedback tests for provisional/final projection, minimum-grade/rounding, ties, zero warning, cap behavior, history validation and query purity.
- [x] Implement feedback module and pass model/transaction/restore checks without changing rewards.
- [x] Integrate compact summary/Details, result and quiet Studio/offer reminder; test pointer/keyboard, both sizes, redraw/selection invalidation and animation/finance locks.
- [x] Run relevant maintained checks, bounded legal campaign/replay/cold restore and private exported UI checks. Keep human/device limits explicit.
- [x] Audit remaining TODO dispositions and update only demonstrated completion; write dated closeout/source hashes.

Ruling: use repository-authorized simulator isolation rather than a Git worktree because the approved underlying Crown path must stay private and the baseline must include current uncommitted runtime fixes. No commit/push is part of this pass.

Outcome: completed at the specified private automated scope. See the dated closeout for exact source, retained failures and canonical/human acceptance gates. No canonical gameplay adoption or commit/push.
