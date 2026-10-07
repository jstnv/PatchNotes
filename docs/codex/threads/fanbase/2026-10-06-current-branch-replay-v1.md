# Current-branch Fanbase replay v1

2026-10-06, America/Los_Angeles. **Read-only evidence; no numerical ruling or gameplay change.** Responds to [handoff v2](handoffs/2026-10-06-current-branch-replay-v2.md).

## Source and route

- Shared checkout: `main` at `553d1a46f33d59641efa4c2e4ff141f958c1230d`, with concurrent uncommitted documentation/evidence left untouched. Source snapshot: `origin/codex/fanbase-on-main` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce`; archive SHA-256 `B2E3F2488B66F9182EE35B73FF83B8445C748292900E7A6CD24AF8CAEB3A4F65`. `studio_fanbase.gd` SHA-256 `AC6634B7691D5F5C58267368277CCDD60D20331E41889FBEAADFFCA414EF8B6A`. The managed worktree stayed clean. A disposable archive copy in `C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006` held import output and the replay adapter.
- Godot `4.7.1.stable.official.a13da4feb` import exited 0 with no script parse errors. The first unchanged Task 32 attempt failed at Studio creation: the branch requires background selection, traits review and confirmation. Its output contained zero releases and no valid Studio cash. The [disposable adapter](current-branch-replay-v1-adapter.md) added only those UI actions, choosing the first listed preview background and no secondary trait. Startup was genuinely $5,500 base plus a once-only $200 unused-point financing receipt, or $5,700; the historical Task 32 trace began at $5,500. This is the first source-era divergence, so the run is a **nearby legal route**, not an exact historical replay.
- The adapted policy used Action specialty, ordinary policy, seed 1104, early alignment, available Contracts, no Neon overlay. It reached five releases at cycles 12/32/50/68/86. All 92 action signatures (phase, game, success and card ID) matched the frozen Task 32 trace; every claimed played action was accepted, the route reported no errors or accounting discrepancies, and the Reviews matched 4.9/7.0/6.1/7.0/6.9. The historical and new source environments still differ in startup finance and fan effects.

## Observed branch and read-only comparison

The [compact trace](current-branch-replay-v1-trace.json) retains action order, per-cycle cash and sales totals, releases and all 43 monthly fan entries; SHA-256 `2CDFA591F29318314B7092BF16C4BD4C2804390279056437B9F91703FA7C65B0`. The complete 30,811,119-byte native JSON is in the disposable archive copy at `patch-notes/design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json` (SHA-256 `62F6744CD69881136E85851A7D235E4DE601C76B24A76E0C1F0582EB8D8B6BE8`), with `route.log`, `route2.log` and `import.log` beside the project. This local raw file is outside Git; preserve it if deeper action review is needed.

| Event | Observed branch linear Fans | Square-root on captured earned units, fixed-sales only | Fan Awareness linear → square-root |
|---|---:|---:|---:|
| Game 3 launch, cycle 50, Review 6.1 | 96 | 96 | 36 → 36 |
| First Game 3 monthly boundary, cycle 52 | 124 (Game 3 gains 28) | 135 (Game 3 gains 39) | next launch not yet reached |
| Game 4 launch, cycle 68, Review 7.0 | 149 | 167 | 49 → 53 |
| Game 5 launch, cycle 86, Review 6.9 | 267 | 285 | 70 → 73 |

The [counterfactual script](replay-counterfactual-v1.ps1) recomputes cumulative per-title gain targets from captured monthly earned units and each arm's launch-Fan reserve. Its linear arm matched all 43 branch `ending` totals exactly. The square-root arm is a fixed-sales shadow. At cycle 68, the unchanged organic/Marketing portion gives conditional Game 4 total Awareness **164** rather than observed **160**. Reapplying the current Month 1 sales formula at the same Review 7.0 and market basis points 10,000 gives **910 versus 900 units**. That is a **conditional +10 units**, not a played sale: changed Game 4 sales would feed later Fans and settlement, so the cycle-86 fixed-sales line is not a fully propagated forecast.

Per-title monthly earned units sum to the branch sales records: Game 1 `619`, Game 2 `1,214`, Game 3 `1,294`, Game 4 `1,630`, Game 5 `0` (launched at capture end). Earned entitlement and settled cash match exactly for these records, in cents: `432,866`, `848,950`, `904,894`, `1,139,859`, `0`. The route's own ledger checks report zero discrepancies. Branch Game 3/4/5 Awareness is `147/160/172`, versus historical no-Fan `111/111/102`; Reviews remain unchanged. Cash after cycle 52/68/86 is `981,424/859,046/1,416,402` cents on the observed branch, not counterfactual cash.

## Decision boundary and commands

The capture supports retaining both gain curves as distinguishable near 5: at the first positive 6.1 boundary they differ by 11 Fans, and by Game 4 launch they differ by 4 integer Awareness points on captured sales. It does not choose a conversion rate or curve. Sales records count copies, not unique buyers; they cannot identify returning Fans or overlap between titles. The 4.9 first title launched with zero Fans, so this route also cannot test weak-release loss.

Commands, using the disposable source snapshot and writable `APPDATA`/`LOCALAPPDATA` inside it:

```powershell
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes' --editor --import
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path 'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes' --script res://analysis/fanbase_task32_replay_v1.gd -- --policy=ordinary --band=early --seed=1104 --specialty=action --contracts=available --alignment=0 --neon=0
& 'C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/docs/codex/threads/fanbase/replay-counterfactual-v1.ps1' -TracePath 'C:/Users/64jus/Downloads/Patch Notes Design Folder/fanbase-replay-20261006/patch-notes/design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json'
```

No TODO edit, merge, push or runtime implementation followed. Next design question: whether the measured +11 Fans and +4 next-launch Awareness near 5 warrant the gentler curve, with a separate weak-release route before deciding loss or buyer-overlap behavior.
