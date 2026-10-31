# Engines browser and project/Contract selection

Execute inline with executing-plans/TDD and a final read-only reviewer. User explicitly requests a left button list and engine selection at production/Contract setup; standing no-input preference applies. Work in the shared canonical checkout as instructed; preserve dirty edits and both temp folders. No commit/push/export.

Approach: dedicated full-width FolderUI browser, left scrollable engine buttons and right scrollable details/action. This replaces the narrow CenterContainer used by short folder menus. A reusable owned/licensed Engine picker in project and Contract setup calls existing free selection, and displays configured supply. Marketplace browsing does not select or license automatically. Project setup and Contract acceptance use the existing selected-engine freeze; no new fees, bonuses, capacity rules or Contract scoring. Existing projects/accepted Contract pools stay frozen. Unlicensed engines stay in the browser and out of setup pickers. Cancelling setup retains the explicitly selected Studio default (same existing selection semantics).

- [x] RED nodes/layout/picker assertions, snapshot affected source.
- [x] Engine browser component and shared owned/licensed picker; integrate Studio, predevelopment and Contract quote refresh.
- [x] Test exact selection/frozen pools, stale/invalid inputs, finance/RNG neutrality, Back/focus and two native viewport captures. Existing purchase/Continue/predevelopment/Contract regressions.
- [x] Preserve exact previous d7295bdcea8bd5093115b42ddba4913f4d7125ff6f697bf5945dc8c62fca0e09 world compatibility with current typed schema, no broad source bypass. Review, dated log/design/state/queue updates.

Completed at the requested browser/picker scope. Older predevelopment/Contract regression fixtures remain explicitly OPEN after equal baseline failures; see the session log.
