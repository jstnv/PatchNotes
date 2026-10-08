# Task2 Store comparison reproduction

Read-only comparison owned by the implementation chat. [Predeclared scope](PREDECLARATION.md) resolves the latest independent Sub-Areas pilot against the earlier handoff; candidate prices/fees/policies remain experimental. Runtime cards and economy rules are unchanged.

## Source and execution

- Pinned source: main `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`; gameplay identical to the prior `553d1a4` pilots. [Source manifest](source-manifest.json) hashes all1,046 tracked project files in both checkout and extracted archive. Native source is verified unchanged separately from generated analysis harnesses.
- Private project: `C:\Users\64jus\Downloads\Patch Notes Design Folder\store-comparison-20261006\patch-notes`; `source.zip` remains alongside it. Full raw traces, process logs and per-job records are in `store-comparison-20261006\raw`. Each job has a distinct APPDATA/LOCALAPPDATA profile inside that folder.
- Godot: `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`. Python: `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`.
- [Driver](driver.gd) registers only process-local candidate definitions and performs native UI/actions. [Fee subclass](trial_run_state.gd) adds the declared candidate cost to native hand preflight/debit. [Copied analysis base](task29_base.gd) removes duplicate full-finance trace capture overrides; native transaction code and lifespan per-title reconciliation are inherited unchanged. Harness hashes are in [manifest](manifest.json).

From repository root, use the bundled Python with `-B`:

```powershell
$task2Python = 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/build.py
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/run.py --pilot
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/run.py --workers 6
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/verify.py
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/audit.py
& $task2Python -B docs/codex/findings/task2-store-comparison-v1/analyze.py
```

Before the first route run, import the private project with Godot `--headless --path <private-project> --editor --import --quit`, redirecting APPDATA/LOCALAPPDATA to private writable profiles. The actual import log is retained here. `build.py` asserts a clean gameplay diff and equality with the archived native source; stop if those checks fail. It never resets the shared checkout. Its default archive path belongs to this versioned study on this host.

## Evidence layout

The final run index contains the exact command, job identity, source/harness association, exit/error results and SHA-256 hashes for each full and compact trace. `traces/*.json.gz` retains every action/selection, decision/quote, calendar/title observation and the complete final native finance journal; it removes only redundant per-action full-finance copies and duplicate visit/capture objects. Full unmodified route JSON remains compressed in the private raw folder.

`audit.py` verifies source/harness/trace hashes, exact journal cash, monthly profit/cash, typed rent conservation, settled-title reconciliation, native card costs including fees, finite committed Features, purchase-before-next-project supply/play, Contract exclusion, Store rejection rollback, settled-cash reserve/deferral, matching pre-purchase releases and abstainer equivalence. Twelve previously recorded Strategy controls are checked through their old five-release horizon. Partial audits during execution are diagnostic; only the complete matrix audit supports completion.

`analyze.py` emits paired routes, stratified aggregates, common-calendar cash/arrears/credit/earned/settled observations and equal-title-age realized sales. Missing stopped-route checkpoints remain null. Milestone cash deltas occur at different calendar times and are labeled separately. A clean played buyer adds no observed arrears and reaches at least as far as its matched control; this does not establish universal payback or human frequency.

The exact historical Alpha replay and maintained recovery verifier are separate from the matrix. The replay is a legal native $5,500 route. The recovery verifier uses disclosed constructed setup, then actual no-income and genuine $1000 Beta Insider actions. It proves the free transition/recovery boundary, not that the historical player's next natural draw supplied that receipt.

[Historical guard record](historical-alpha-before.json) is copied unchanged from the earlier local rebaseline (`alpha-exit-probe.json`), SHA-256 `75081037667907e4214102aefcaae28a8e1dc1b9301734e1fde428d0550055cb`. It is historical evidence, not a rerun of old gameplay. The repaired replay and recovery fixture commands/results are in [verification index](verification-index.json). Generated release IDs may vary across runs; matching uses project ordinal, seed, calendar and recorded numerical state, with IDs retained for each route's own native ledger.

`progress.py` reads completed current-harness records directly. The initial runner stopped advancing its console counter after a long-route exception while its worker pool continued queued jobs; the initial log is retained. The revised runner records process deadline failures explicitly, completes the index and fails the gate if any route is invalid. The final recovery command is `run.py --workers 6 --timeout 600`. Successful same-harness records are reused. Execution time limits do not change native cycle targets or route policy.

Recovery of the six missing slow-start jobs was started with `run.py --recover-slow --workers 2 --timeout 600` while the initial pool processed later paid-play jobs. This selects only the64 slow jobs, reuses58 successful records and writes `retry-slow-index.json`; it cannot replace the full556-route completion gate. Old unaccepted JSON from an interrupted attempt is preserved in the private raw folder before retrying. The subsequent complete runner command assembles the final index from accepted records.

After the final audit and analysis, `review.py` prints separate specialty/policy/startup/timing counts and fee pairs for the written findings. These reporting helpers do not execute gameplay or change the predeclared matrix.

## Limits

Automation uses only visible information and deterministic route seeds; it is not human choice evidence. Prices $1,700/$950 and fees $90/$50 are study inputs. Full-chain reserve is conservative and ignores future income/optional actions; the stronger-release threshold and Studio shopping opportunities are declared policies, not runtime rules. Source lacks live Fanbase, lending, employees and candidate cards. Headless routes and focused checks do not establish exported or visible UI acceptance. Existing certificate-store and case-path import diagnostics are retained in logs and separated from script failures.

A route stop is conditional on the declared QA-heavy Beta and Contract policy, not proof that every legal alternative income action is unavailable. Curtailed projects and free early launches are recorded as such. The historical replay and constructed genuine-income fixture separately show the difference between phase progress and cash recovery.
