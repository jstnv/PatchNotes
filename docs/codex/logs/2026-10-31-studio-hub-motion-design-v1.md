# 2026-10-31 Studio hub motion direction

- Branch/HEAD at review: `main` / `3a61522f`; shared worktree already contains active Engine Marketplace and other gameplay/UI changes.
- User selected a left root panel for the three existing Studio groups, a right-revealing companion panel, quick slide-back/slide-out group switching, bottom-entry destination screens, downward Back exit, and one consistent top-left Back position.
- Changed initially: `docs/codex/design/ui-design-system.md` and this log. After the user's explicit follow-up, the implementation item was added to `docs/codex/TODO.md` and the design status changed to QUEUED. Gameplay/UI source was not edited.
- Current source inspected: `patch-notes/scripts/phases/studio_phase.gd` builds three root buttons in a centered container and opens full-screen group folder pages; destinations use separate UI paths. The new motion is design authority, not current behavior.
- Verification: documentation diff/whitespace check only. No runtime checks because runtime source was not changed.
- Follow-up: coordinated UI implementation should reconcile the active Studio/Engine edits, shared transition controller, destination ownership, Back position, focus/rapid-switch behavior and native 1152×648/1280×720 layouts.
