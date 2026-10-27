# All Features + $2,000 + three Beta hands — one-case finding, 2026-10-26

**Result:** The same fresh Adventure stress case rose from **5.5 to 6.8 Review**, but three Beta plays did **not** clear the prior 11 remaining Bugs: **7 remained**. The new third hand found four and fixed four. The middle Beta hand fixed zero and added five Marketing. Merely allowing three Beta hands does not ensure three useful Search+Debug hands.

## Authority, case and source

- [Predeclared test](2026-10-26-all-features-plus-2000-three-beta-plan-v1.md) and [$2,000 trial decision](2026-10-26-starting-rival-plus-2000-trial-decision-v1.md). Reference is the frozen [v2 all-Features result](sims/all-features-fresh-studio-one-case-20261026-v2/cases/all-features-adventure-4417/result.json). This is a **single synthetic Studio**, not the real starting rival population or a legal new-save Store acquisition route.
- Adventure Studio/project, Fantasy Theme, no traits, seed `4417`, all 42 catalog Features owned; one release. The candidate changed only the private fresh test Studio's starting cash by **200,000 cents** through `RunState.add_cash_cents(..., financing_in, ...)` and the private trial `BETA_HANDS` value from **2 to 3**. The policy retains legal whole-supply Design/Alpha plays, full Scope, enabled synergy/QA selection and the same Review rules. No grant of Bugs/Core/Review, no loan, no player-save edit.
- Branch/HEAD at capture `main` / `087df09d653858b72c6e2dc344352237433dd3ac`, dirty shared checkout. Private child variant [metadata](simulators/all-features-cash2000-beta3-20261026-v3c/variant.json): original canonical base `882eaae93f3261756b191fddbef0d998d9dafec6d01f0388fef28aa7f86b77e9`, parent creation identity `0d5e3ead0b50cbade9063bf164194270f4ace9884146ecb2a6b135229d8f241f`, candidate identity `22d297d5ee66b846fda7ff8ae9c9473c2d48210df44aa3ef0db25bcae8890776`, runtime source identity `37c64984e717ec3b598cde584f3fc064126ea1ba0907ae2799681621dffa7c57`. Canonical baseline drift was **true** at this run because concurrent work changed other canonical files; those changes were not imported into this child.

| Measure | Prior 2 Beta hands | +$2,000 and 3 Beta hands |
| --- | ---: | ---: |
| Opening cash | $5,700 | **$7,700** |
| Design / Alpha / Beta plays | 7 / 6 / 2 | **7 / 6 / 3** |
| Scope | 65/30 | **65/30** |
| Core G/S/T/D | 40/32/56/61 | **40/32/56/61** |
| Production rating | 9.539 | **9.539** |
| Remaining Bugs | 11 | **7** |
| Review | 5.5 | **6.8** |
| Release cycle | 16 | **17** |
| Launch cash / overdue | $0 / $90 | **$1,910 / $0** |
| Commands | 26 accepted | **27 accepted** |

Initial RNG snapshots matched exactly, while initial state digests differed as expected because the candidate adds cash and a finance transaction (`341ad711…649` vs `7fad7215…eb4`). The first **24 command requests** matched exactly through the second Beta play. Thus this particular run preserved the same Design/Alpha/Core/Scope and first two Beta choices; the third Beta play accounts for the observed Bug change and extra cycle. Equal seed alone would not establish this; the prefix was checked. The Review formula gives `9.539 × (1 − 7/30) − 0.5 ≈ 6.8`; the earlier 11-Bug result was 5.5.

The frozen [run report](sims/all-features-cash2000-beta3-one-case-20261026-v1/run-report.json), [case result](sims/all-features-cash2000-beta3-one-case-20261026-v1/cases/all-features-adventure-4417/result.json), [telemetry](sims/all-features-cash2000-beta3-one-case-20261026-v1/cases/all-features-adventure-4417/telemetry.json), [Beta event extraction](sims/all-features-cash2000-beta3-one-case-20261026-v1/beta-trace.json) and [fresh-process replay](sims/all-features-cash2000-beta3-replay-20261026-v1/replay-report.json) are retained. Replay passed **27/27 commands**, all 28 telemetry samples and final state `25d5e98f…675`. The experiment log had no script error; it retained a six-ObjectDB-instance exit warning. The separate read-only tape extraction succeeded but its unisolated Godot invocation emitted editor-profile save errors after writing the JSON; it did not rerun or alter gameplay.

## What the three Beta plays actually did

1. Beta hand 1: Search found **6**; three Debug cards fixed **2 + 2 + 2**.
2. Beta hand 2: Debug requested 2 but fixed **0**; Marketing added **5**. With no Known Bugs exposed, this hand did not improve Bug count.
3. Beta hand 3: Search found **4**; three Debug cards fixed **2 + 2 + 0**. The title launched with **7 remaining Bugs**.

The [tape reader](read_beta_tape_events.gd) decoded accepted command events, including actual Search/Debug counts; these are not invented QA estimates. The middle hand shows why a fixed three-hand count is weaker than a budget for **effective** QA opportunities. On this route, the remaining Bugs appear undiscovered after Debug exhausted Known Bugs. The current AI sees only public Known-Bug observations and cannot inspect hidden Bugs to decide with certainty.

## Failed preparation and exact commands

Two new variant-copy attempts (`...-v3`, `...-v3b`) failed with Python `MemoryError` during SHA/copy checks before any simulator run. Their partial folders were retained; neither is a valid variant or test. A later retry (`...-v3c`) succeeded as a fully checked child. The command wrapper used on that successful retry is retained; its outer SHA monkey patch did not alter the variant tool's independently loaded hash module. No seed, cash amount, hand count or timeout was changed because of these infrastructure failures.

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $py tools/simulator_variant.py create --id all-features-cash2000-beta3-20261026-v3 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v2 --output docs/codex/threads/ai-competitors/simulators/all-features-cash2000-beta3-20261026-v3
& $py tools/simulator_variant.py create --id all-features-cash2000-beta3-20261026-v3b --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v2 --output docs/codex/threads/ai-competitors/simulators/all-features-cash2000-beta3-20261026-v3b
& $py docs/codex/threads/ai-competitors/create_variant_low_memory.py create --id all-features-cash2000-beta3-20261026-v3c --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/all-features-fresh-studio-20261026-v2 --output docs/codex/threads/ai-competitors/simulators/all-features-cash2000-beta3-20261026-v3c
& $py tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/all-features-cash2000-beta3-20261026-v3c --config docs/codex/threads/ai-competitors/all-features-cash2000-beta3-one-case-20261026-v1.json --output docs/codex/threads/ai-competitors/sims/all-features-cash2000-beta3-one-case-20261026-v1 --godot $godot --timeout 240
& $py tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/all-features-cash2000-beta3-one-case-20261026-v1 --case all-features-adventure-4417 --output docs/codex/threads/ai-competitors/sims/all-features-cash2000-beta3-replay-20261026-v1 --godot $godot --timeout 240
$root = (Get-Location).Path
& $godot --headless --script (Join-Path $root 'docs/codex/threads/ai-competitors/read_beta_tape_events.gd') -- (Join-Path $root 'docs/codex/threads/ai-competitors/sims/all-features-cash2000-beta3-one-case-20261026-v1/cases/all-features-adventure-4417/replay.tape.json') (Join-Path $root 'docs/codex/threads/ai-competitors/sims/all-features-cash2000-beta3-one-case-20261026-v1/beta-trace.json')
```

## Recommendation and unresolved work

The **$2,000** candidate paid the additional cycle without arrears and improved this game's Review, but **6.8 is still below the 8+ challenge target**. Do not infer an all-rival score effect or a minimum affordable bankroll from one extreme all-Features Studio. Keep the $2,000 starting-rival increase **TRIAL**, and keep the exact Beta opportunity policy **OPEN**. Next study should require an affordable legal Search+Debug opportunity when hidden Bugs are still plausible, rather than merely counting three hands; it must respect draw legality, public observations, monthly bills and a finite stop. Test that policy on actual starting rival snapshots and more than one Genre/seed before an implementation handoff. No canonical gameplay or TODO edit was made here.
