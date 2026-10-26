# Store prerequisite links implementation plan — 2026-10-24

Direct user request: clicking the Missing prerequisite action reveals individual node buttons to its right, using the established button/menu entrance motion. Previous authorization to make routine choices without questions remains applicable.

**Design:** keep the compact detail panel unchanged in height. A separate horizontal row beside the Missing action contains one wrapping button per missing parent. A second click collapses it; a link selects its node. Use the existing44px/.24s cubic slide, with a short stagger and pointer/focus safety during entrance. Reserve enough camera/layout space for the row, including its animation; clamp the combined group within the Store body. Close, new selection, refresh, resize and Escape clear pending buttons/tweens. No acquisition/economy rule changes.

**Scope:** `ui/feature_store_map.gd`, shared entrance constants in `ui/menu_transitions.gd`, narrow source-only Continue compatibility if needed, one focused verifier and relevant existing suites. Preserve inherited worktree/`.codex-godot-temp`, player profiles and old evidence. Work in the current checkout with isolated frozen test copies; no commit/push.

- [x] Freeze branch/HEAD/current source and old editor/compiled identity; add and run the behavioral RED check.
- [x] Implement right-side links, shared motion, layout/input/lifecycle guards; run focused GREEN and relevant regressions.
- [x] Verify native themed rendering at1152×648/1280×720 plus narrow900×600 Store bounds, and exact previous-world cold restore where applicable.
- [x] Review, update Store design/TODO/current state and dated evidence log with exact scope/results.
