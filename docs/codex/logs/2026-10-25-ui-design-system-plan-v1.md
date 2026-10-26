# UI design system implementation plan

> Execute inline with superpowers:executing-plans; one fresh read-only review at the end. Preserve inherited dirty work and use isolated immutable test snapshots. No commit/push or unsolicited export.

**Goal:** reusable identity/folder navigation and complete Main Menu/Studio Creation reference screens.
**Architecture:** shared Theme and folder helpers; extend existing MenuTransitions; retain MainMenu validation/data bindings and optional overlay APIs.
**Stack:** Godot4.7.1/GDScript, licensed bundled TTFs, existing isolated verifier runner.
**Spec:** `docs/codex/design/ui-design-system.md` and the user's2026-10-25 pasted implementation brief.

## Constraints / review focus

One overlapping canonical implementation. Preserve `.codex-godot-temp`, saves, existing edits and all gameplay rules. No new unapproved numbers. Root Back must preserve drafts; explicit discard must confirm. Resizing/long names/negative Traits must not move fixed actions offscreen. Rapid input, overlay close and teardown must not corrupt stack/input lock. Creation remains once-only. Current Studio-only Continue and exact world/RNG restoration remain intact.

## Tasks

- [x] 1. Pin prior source/world; add a RED verifier for retained draft/full-screen setup and navigation. Acquire licensed fonts with source hashes. Create shared palette/font Theme variations and folder components. Verify font/resource loading.
- [x] 2. Extend MenuTransitions root/push/pop/focus/lock/bypass, optional Guide/Settings integration, Main Menu logo/left actions, full-screen setup header/name/tabs/body/footer. Keep trait/Genre evaluator and attention gates. Verify RED becomes GREEN, duplicate/Back/Esc/discard/commit and ordinary overlay behavior.
- [x] 3. Update only stale presentation fixtures; run affected existing suites and exact cold-world restore. Native pointer/keyboard captures at both supported sizes and all tabs; inspect and fix clipping. Read-only independent review, focused follow-up checks, source hashes/receipts, design/TODO/CURRENT_STATE and dated session log.

Outcome: [completed findings/receipts](../findings/ui-design-system-20261025-v1/README.md) and [session log](2026-10-25-ui-design-system-v1.md). Scope complete locally; export/human/device acceptance remain separate.

Ruling: work in the shared checkout under its existing single-implementation ownership; a fresh worktree would omit inherited authorized gameplay changes. Verifiers/imports use isolated copies/profiles. User has explicitly directed implementation from a detailed approved brief and delegated routine decisions; execute without an additional design approval round.
