# Central progression grid implementation plan

Goal: Feature Store-style grid trees growing from the center for Engine upgrades and Employee courses. User explicitly clarified Employee Courses alongside Engine Skill Tree. Contract jobs are outside this layout change.
Architecture: one presentation-only reusable progression_tree_view.gd and pure progression_tree_data.gd projection. Keep Feature Store unchanged. Reuse its212px lattice, existing theme, pan/zoom/Show all, inspectable nodes and parent connections. Engine owns four cardinal foundation->I->II branches. Employee center branches to Production/QA/Manager; two QA courses are independent siblings, Production/Manager retain sequential prerequisites. Never invent course/Skill mechanics or adopt proposed specialists.
Tech: current Godot4.7.1 GDScript/FolderUI. Spec: findings/central-progression-grid-20261102-v1/SPEC.md.

Global constraints: preserve all dirty work and .codex-godot-temp, one canonical writer. Existing shared canonical-integration workflow and no-input instruction select in-place edits with before copies and private-profile checks; do not replace this dirty baseline with HEAD. No commit/push/export. No balance, DTO, RNG, finance or Studio-only Continue changes. Purchases use fresh existing quotes/actions and enrollment confirmations. No expensive quotes/reports while panning or drawing.

- [x] Task1: failing meaningful geometry/projection/view tests and genuine preceding pair capture; implement pure engine/course rows and reusable grid view. Check cell uniqueness, independent QA, sequential courses/Skills, inspect-only selection, camera/focus/resize and no model mutation.
- [x] Task2: integrate Engine Skill page and Employee Courses tab while retaining navigation, roster/progress/footer and transaction handlers. Meaningful actual purchase/enrollment tests, stale-quote rejection, locked/complete status and per-engine/employee isolation.
- [x] Task3: focused native1152/1280/1920 visuals/input and real Studio route/back/tour targets; strict exact-source/whole paired-save preservation. One fresh read-only review at end. Resolve failures, persist design/current/TODO/log and exact acceptance limits.

Review: QA course edges must not add a prerequisite; inspecting/panning never pays or saves; overlapping headers/footer/detail panes remain usable at1152; late signal refresh preserves selected node/camera/focus; stale state uses authoritative action validation. Log each task here on completion.

User clarification received: Employee Courses (Recommended). Contract jobs are outside this layout change.

All three tasks COMPLETE at scoped local acceptance. Exact receipts and retained failures: [RESULT](../findings/central-progression-grid-20261102-v1/RESULT.md). One fresh read-only review completed; no commit/push/export.
