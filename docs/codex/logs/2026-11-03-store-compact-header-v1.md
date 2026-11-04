# Feature Store compact header — 2026-11-03

Branch `main`, starting HEAD `df2448cc7a1c9490aa2880b5d413a3ba73ab588a`. The tracked worktree had no pre-existing changes. This is a local UI-only change; Feature terms and game state are unchanged.

The engine title and Implementation queue/action share the header between Back and the right-aligned available-library summary. The queue and action align to Back's bottom; the summary fills its height, with a smaller font at narrower widths. The queue may shrink to make room for the summary and the full action price. Floating-control map input remains guarded.

- `patch-notes/scripts/ui/feature_store.gd` implements the layout.
- `patch-notes/scripts/debug/verify_store_compact_header.gd` checks 900×600, 1152×648 and 1280×720, including empty and real queued Features, long prices, bounds, map input protection, and mouse activation that completes an implementation.
- Before the change the original two-size check had 12 failures out of 54, covering the two requested alignment conditions. The final current-source run passed 93/0 headless and 96/0 native; native captures were inspected. `git -c core.whitespace=cr-at-eol diff --check` passed with the existing CRLF line endings.
- Two earlier native attempts using a simulated press and release on separate frames produced intermittent click failures. Dispatching the paired synthetic events together passed two successive native runs (96/0 each), and the current headless run passed (93/0). This does not replace a human physical-device input check.
- A separate maintained radial verifier did not reach Studio during isolated new-save setup and was stopped after its assertion; it was not counted as a pass. No player save was used. Retained logs are under `.codex-godot-temp/store-header-*`.
