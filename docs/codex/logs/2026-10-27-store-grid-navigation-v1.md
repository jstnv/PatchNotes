# Store overhaul022 — navigation slice, 2026-10-27

Status: **IN PROGRESS overall**, only the independent navigation slice implemented. Follow-up authorization covers approved queued tasks without routine input. Handoff022/Proposal028/source identity and current Store design were read; Handoff023's unresolved new rules/values remain DESIGN. AI item22 has no new approved adoption packet in this check.

Branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; dirty inherited worktree and `.codex-godot-temp` preserved. In-place execution retains the existing uncommitted canonical fixes. Baseline runtime `98e0b0926f13b8cf207ef375ff41bf2d8d9a82f6e7ac26d63aa447dc0fb50083`; resulting runtime `a5c5d543474d24a1dc6ee2c901f4446380b1d0e572ddb414fe63e5d173439328`.

## Delta

- `patch-notes/scripts/ui/feature_store_map.gd`: one missing parent invokes the existing node focus path immediately. Zero missing still uses the ordinary action; multiple missing still expand the animated chooser.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: exact baseline source admitted only with the unchanged current player/rival rules. Unknown sources and old-rule pairings still reject. This is a presentation compatibility entry, not the later graph migration.
- `verify_store_prerequisite_links.gd`: actual pointer and Enter activation, target details bounds, state/RNG preservation, retained multi-parent chooser/toggle and Escape at three sizes.
- `verify_world_restore_file.gd`: exact new predecessor also exercises mismatched player/rival revision rejection.
- New prior-world fixture/provenance `tools/fixtures/store_grid_predecessor.*`, copied byte-exactly before runtime edits from the verified startup-prompt cold output. Findings retain baseline manifest, before-source copies, owned diffs, full commands, probe copies, logs, six captures and the serial [remaining implementation plan](../findings/store-grid-20261027-v1/PLAN.md). TODO/current-state/design changed minimally to IN PROGRESS.

## Exact checks and outcomes

Command prefix: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe docs/codex/findings/store-grid-20261027-v1/run.py`. Each invocation uses a fresh private profile/writer port; receipt JSON records exact Godot arguments and exit status.

| Label / script and arguments | Result |
| --- | --- |
| `direct-parent-red res://scripts/debug/verify_store_prerequisite_links.gd` | RED:48 checks/3 intended failures, one at each viewport |
| `direct-parent-headless-final res://scripts/debug/verify_store_prerequisite_links.gd` | PASS57/0, exit0 |
| `direct-parent-utf8 res://scripts/debug/verify_store_prerequisite_links.gd --native --out=C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/findings/store-grid-20261027-v1` | PASS57/0, exit0; actual900×600,1152×648,1280×720 captures |
| `focus-final res://scripts/debug/verify_store_focus_lifecycle.gd` | PASS9/0, exit0 |
| `cold-utf8 res://scripts/debug/verify_world_restore_file.gd C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/tools/fixtures/store_grid_predecessor.json C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/findings/store-grid-20261027-v1/cold-utf8.json` | PASS7/0, exact persisted player/world/history/finance/RNG; unknown source and both bad-rule pairs rejected |
| `git -c core.whitespace=cr-at-eol diff --check -- <four owned runtime/debug paths>` | PASS exit0 |

All six final native images were inspected. Direct target and chooser actions fit their Store body at all three sizes. These are controlled absent-ownership UI fixtures, not funded campaigns. Background cards can still appear behind the floating toolbar in these focused views; full lattice/edge/overview acceptance has not occurred.

Retained failures: the initial cold helper invocation supplied an extra `--` and exited2; corrected invocation passes. Initial Python locale decoding altered non-ASCII presentation; reverted only owned production edits from their byte-exact snapshots and reapplied with explicit UTF-8/CRLF. Owned production diff now contains only the three-line navigation branch and exact predecessor handling. All final checks above use corrected source. Intermediate runs and receipts remain. Some processes report six ObjectDB instances at exit, also seen in earlier fixtures; no claim to have repaired that warning.

## Remaining work

Next: version the exact acquisition graph and previous-catalog adapter, preserve paid queues/grants/frozen supplies, then implement the global integer-cell layout, obstacle-safe arrows and full overview/focus/pan/zoom acceptance. Reconcile the two requested left-of-Sprites placements as documented in PLAN. No new prices, Scope/Core, roster, phases, Bank or AI policy values were adopted. No full regression gate, campaign, performance result, public build, commit or push is claimed. Keep the existing follow-up active while022 and the forthcoming AI packet remain outstanding.
