# Employees comparison v1 — reproduction and evidence

Read [findings](../2026-10-06-benefit-payroll-comparison-v1.md) and [protocol](PREDECLARATION.md) before interpreting the outputs. These are completed read-only scene routes and financial/identity models. The recommendations were subsequently selected in the [user-approved trial package](../2026-10-06-trial-package-decision-v1.md); the [separate implementation task](../2026-10-06-production-specialist-implementation-v1.md) was completed locally on 2026-10-07. Alternative scenario inputs remain evidence, with final wages and course effects/amounts OPEN. Native employee gameplay is evidenced separately in the [implementation findings](../../../findings/2026-10-07-employees-implementation-v1.md).

## Evidence map

| File | Contents |
|---|---|
| `manifest.json`, `run-index.json` | Pinned archive/driver hashes, 76 primary inputs and exit/validity results |
| `native-routes.jsonl.gz` | Compact 76 primary traces: per-action draw/selection/redraw/priorities, state, releases, and one complete authoritative final finance journal |
| `optional-routes.jsonl.gz`, `after-hire-routes.jsonl.gz` | Four optional and four ownership-correct post-Game-1 traces |
| `reward-summary.json` | Reward/qualification/use counts, first-action pairs, release and common-calendar comparisons |
| `financial-arms.jsonl.gz` | 56,832 final payroll/course summaries, scenario inputs, first failure, cash low, bills/credit, settled/earned totals, release/Store access and common-calendar progress |
| `selected-finance-traces.json.gz` | Detailed representative per-month, bill, partial-payment and credit traces |
| `finance-summary.json` | All 46 primary source-journal reconciliations and factor aggregates |
| `assessment.json` | Optional choices, 96 ownership-correct financial shortlist arms, four additional finance reconciliations, monthly examples, boundary examples and final log scan |
| `native-bill-protocol.json`, `employee-model-results.json` | 46 native typed-hook and 36 constructed employee-model checks, with limits |
| `source-hashes.json`, `evidence-index.json`, `audit-results.json` | Source and original full-trace hashes, final audit/counts and artifact hashes |

Common-calendar `native_action_cycle` describes progress through the original productive action sequence. It distinguishes inserted Studio cycles from production progress. All cents are integers. Medians between two cent values may be half a cent.

Full original route JSON/logs, native financial timelines, source archive/import log, and the initially full compressed capture are retained outside the repository at:

`C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006`

The compact captures remove repeated full finance/menu snapshots while retaining actual decisions and one complete final journal. Original full JSON hashes are in the indexes. Native timeline inputs are regenerated from frozen launch records using `ReleasedGameSales`; no Python approximation of the sales curve is used.

## Exact local commands

The scripts use the fixed local `ROOT` above. Use an empty destination for a fresh reproduction; preserve existing evidence or copy the scripts and adjust their `ROOT` constants for another run. Commands below were run from the repository root. Godot profiles must stay within the writable trial folder.

```powershell
$trialRoot = 'C:\Users\64jus\Downloads\Patch Notes Design Folder\employees-comparison-20261006'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$python = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$evidence = 'docs/codex/threads/employees-challenges/comparison-v1'
$env:APPDATA = "$trialRoot\profile"
$env:LOCALAPPDATA = $env:APPDATA

git archive --format=zip --output="$trialRoot\source.zip" 553d1a46f33d59641efa4c2e4ff141f958c1230d patch-notes/project.godot patch-notes/icon.svg patch-notes/assets patch-notes/data patch-notes/resources patch-notes/scenes patch-notes/scripts patch-notes/analysis
Expand-Archive -LiteralPath "$trialRoot\source.zip" -DestinationPath $trialRoot
& $python "$evidence/build_driver.py" "$trialRoot\patch-notes"
& $godot --headless --path "$trialRoot\patch-notes" --editor --import --quit
& $python "$evidence/run_routes.py"

Copy-Item -LiteralPath "$evidence/optional-driver.gd" -Destination "$trialRoot\patch-notes\analysis\employee_optional_v1.gd"
Copy-Item -LiteralPath "$evidence/after-hire-driver.gd" -Destination "$trialRoot\patch-notes\analysis\employee_after_hire_v1.gd"
Copy-Item -LiteralPath "$evidence/timelines.gd" -Destination "$trialRoot\patch-notes\analysis\employee_timelines_v1.gd"
Copy-Item -LiteralPath "$evidence/protocol.gd" -Destination "$trialRoot\patch-notes\analysis\employee_protocol_v1.gd"
& $python "$evidence/run_optional.py"
& $python "$evidence/run_optional.py" --after-hire

& $godot --headless --path "$trialRoot\patch-notes" --script res://analysis/employee_timelines_v1.gd -- "--input=$trialRoot/results" "--out=$trialRoot/timelines.json"
& $godot --headless --path "$trialRoot\patch-notes" --script res://analysis/employee_timelines_v1.gd -- "--input=$trialRoot/results" "--out=$trialRoot/timelines.json" --supplement=1
& $godot --headless --path "$trialRoot\patch-notes" --script res://analysis/employee_timelines_v1.gd -- "--input=$trialRoot/results-after-hire" "--out=$trialRoot/after-hire-timelines.json" --shortlist=1
& $python "$evidence/rewards.py"
& $python "$evidence/analyze.py"
& $python "$evidence/assess.py"
& $python "$evidence/employee_model.py"
& $godot --headless --path "$trialRoot\patch-notes" --script res://analysis/employee_protocol_v1.gd -- "--out=$PWD/$evidence/native-bill-protocol.json"
& $python "$evidence/audit.py"
```

`analyze.py --finance-only` reuses the compact native captures to avoid repeatedly reading gigabytes of duplicated full snapshots. The initial `analyze.py` creates those compact captures. `assess.py` reads raw supplemental traces and validates their four complete native finance journals. `audit.py` expects this study's final counts and checks the pinned source against the shared checkout, ignoring only line-ending differences.

Existing focused checks, all exit 0:

```powershell
& $godot --headless --path "$trialRoot\patch-notes" --script res://scripts/debug/verify_shared_redraw_and_priority_adjustment.gd
& $godot --headless --path "$trialRoot\patch-notes" --script res://scripts/debug/verify_atomic_selected_redraw.gd
& $godot --headless --path "$trialRoot\patch-notes" --script res://scripts/debug/verify_outstanding_expenses.gd
git diff --check
```

## Harness repairs and superseded data

- Initial public active-phase priority setter returned false. The pilot `route_base_middle_synergy_1104_bundle_1.json` is retained in Downloads and explicitly excluded. Analysis uses a labeled allocation shadow; no native employee hook is implied.
- Initial timeline reconstruction expected an absent `forecast_bp` key. The final version uses the native frozen sales record's exact fields. Failed `timelines.log` is historical debugging output, not a passing check. `timelines-final.log`, `timelines-studio.log` and `after-hire-timelines.log` show final passing runs.
- A protocol inferred-number type error was repaired before the final 46-check run.
- `superseded-first-shortfall-arms.jsonl.gz` is the initial censored study, retained for provenance. It stopped before demonstrated native pre-hire recovery and supplies no final conclusions. Final overlays preserve that legal prefix and stop at the first post-hire shortfall.
- Course following-month timing was made explicit using the native expense-month convention; an ambiguous next-boundary shorthand was superseded. Final scenario outputs use `course_due()` and the boundary examples in `assessment.json`.
- Root-certificate errors arise in this sandbox; final route scans explicitly exclude that diagnostic. Missing snapshot artwork gives warnings. Script/other error scans and actual check completion establish each pass.

No gameplay or maintained test file was edited. No commit, push, durable-save, native employee atomicity or export-readiness claim.
