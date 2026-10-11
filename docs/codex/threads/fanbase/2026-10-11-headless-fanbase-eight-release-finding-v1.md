# Fanbase current-rules eight-release headless finding v1

2026-10-11, America/Los_Angeles. **BOUNDED CURRENT-RULES EVIDENCE; no balance approval.** The [first plan](2026-10-11-headless-eight-release-plan-v1.md) fixed 4/4/4 and 8/8/8 hands at seeds 1104/4417; after both eight-hand arms failed financially, the separately [preregistered intermediate-budget plan](2026-10-11-headless-accessible-budget-plan-v1.md) fixed 5/5/5 and 6/6/6 on those same recipes. The post-600 numerical taper stayed ON HOLD. No simulator variant or canonical gameplay was edited.

## Source and comparison validity

Both frozen bundles captured the dirty `main` checkout at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with identical mechanics identity `4162c70c12bf3d6af7587e5879759b54b127280c4ff224f4970ed7f8c2b895df`. The Fanbase source hash was `566846EBF61E4D1B944276D9AAEACB06ECD316C71D5B7A944412DB1247D06B36`; finite policy source `E168D3A6EA700EED8CAD3B02A276003A359048D0C04E620B9E285F19B5197A00`; runner `b7a8a414b255b4c7b9602372880680bafca25f6ccb15d3e732ea49134bd84ae1`; Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. The [first config](2026-10-11-headless-eight-release-v1.json) SHA-256 is `279C9A383F9B3B7F31B753D16119F5A14B9F5A75E45CE63F3ED67A8A2F80CE60`; the [follow-up config](2026-10-11-headless-accessible-budget-v1.json) is `0350CD86160D1331CF5BA00AED777D7026C516266972395958039B65BE2FA137`.

Within each seed, all completed or rejected cases share the exact initial state digest and initial RNG map, including across bundles: 1104 `fc931e17bd39fae2460bc83eeae6a9ee55528ff2619a01b537169ab3a8de3c74`; 4417 `4c83bb2caba5ff1d55ec2d85eecbc63f40e23e18a299bc012766cd797acaa0cb`. Policies then use different action counts and release calendars; later RNG and states are not paired. All starts are legal no-trait Action/Fantasy Studio recipes; no player saves, injected Reviews/Fans, Store, Contract or campaign actions. The runner copied the project, import cache and `user://` profile per invocation. Studio-only checkpoint rules were not bypassed.

## Outcomes, including censored cases

| Seed / hands | Status | Commands | Releases | Final cycle | Reviews in release order | Gained / lost Fans | Fans at eighth launch |
|---|---|---:|---:|---:|---|---:|---:|
|1104 / 4|complete|192|8|104|4.8, 5.5, 5.4, 3.7, 5.4, 4.5, 5.3, 4.0|60 / 9|51|
|4417 / 4|complete|192|8|104|4.0, 5.2, 4.0, 4.5, 4.3, 4.1, 3.7, 5.5|8 / 2|6|
|1104 / 8|rejected|31 (30 accepted)|0|22|none|0 / 0|unknown|
|4417 / 8|rejected|31 (30 accepted)|0|22|none|0 / 0|unknown|
|1104 / 5|complete|216|8|128|5.7, 6.7, 6.3, 4.9, 6.8, 6.6, 6.1, 5.4|451 / 2|449|
|1104 / 6|complete|240|8|152|6.6, 7.4, 6.0, 7.8, 6.9, 6.7, 7.0, 7.8|850 / 0|850|
|4417 / 5|complete|216|8|128|4.9, 5.7, 4.3, 5.1, 6.0, 4.9, 6.6, 6.2|179 / 4|175|
|4417 / 6|**timed out**|no completed case result|unknown|unknown|unknown|unknown|unknown|

The first batch exits nonzero because the 8-hand arms reject. Both reject at step31/cycle22 during first-project Beta with `$0` cash and `$160` sampled rent arrears: “The run calendar cannot advance safely.” [Seed1104 reduction](sims/eight-release-1104-h8-reduction-v1/reduction-run.json) reproduced the exact rejection signature in a fresh process; the shortest Studio-restorable suffix was still all31 commands because no later Studio checkpoint existed. This is an economic route blocker, not evidence of a Fanbase defect. The second batch exits nonzero on its declared 240-second process timeout after completing three cases; **4417/6 remains unknown**. The standard pair-report command refused the timed-out bundle because `experiment-report.json` was absent; it created no comparison artifact. No result was invented or timeout increased.

For completed 1104/4, 4417/4, 1104/5, 1104/6 and 4417/5, final cash was `$20,627.33`, `$14,289.87`, `$39,504.30`, `$56,566.17` and `$22,975.93`, respectively; sampled cash lows were `$2,340`, `$1,840`, `$1,340`, `$840` and `$1,340`. All five had zero sampled arrears. These are different action/calendar paths, not finance-controlled Fanbase effects.

## Fanbase observations

Two legal releases reached **Review 4.9 with an existing audience**, without targeting or injecting that score. In [1104/5](sims/eight-release-accessible-v1/cases/fan-1104-h5/studio_checkpoint.json), Game4 launched with161 Fans and40 Fan Awareness. Its monthly journal records month33 `161 + 1 − 2 = 160`, with the weak title responsible for **2** lost Fans. Its cumulative title loss remains2 thereafter. In [4417/5](sims/eight-release-accessible-v1/cases/fan-4417-h5/studio_checkpoint.json), Game6 launched with83 Fans and20 Fan Awareness. Month49 records `83 + 0 − 1 = 82`, with **1** title loss and no later repeated loss. Each title's neutral estimated earned units exceeded its launch-Fan cap, so the current trial's full-exposure targets `floor(161×0.015)=2` and `floor(83×0.015)=1` match. The earlier 4.9 Review in 4417/5's Game1 and the 4.8 Review in 1104/4's Game1 launched with zero Fans and cannot test established-audience loss. This supplies a played-by-policy near-neutral edge, not human fairness feedback or an exact5.0 natural route.

In 1104/6, launch Fans by release were `0, 60, 188, 238, 434, 602, 728, 850`; frozen Fan Awareness was `0, 15, 47, 59, 108, 150, 150, 150`. The current trial hard cap is thus reached at Game6 and remains visible at Games7–8. This is **current behavior**, not approval to replace the cap. Across completed routes, Fans are sensitive to Review/hand policy and release timing: final observed Fans span6–850. Same-seed 1104/5 and 1104/6 begin identically, but their eighth launches occur at cycles128 and152. At matched cycle128, 1104/5 has8 releases/449 Fans and 1104/6 has6 releases/725 Fans. These are policy-and-calendar differences, not a clean marginal estimate for the 8% gain coefficient or Fan Awareness contribution. Eighth launches have not yet earned their own postlaunch Fan gains.

## Verification and limits

The [first bundle](sims/eight-release-current-v1/run-report.json) retains four result/tape/telemetry sets and two standard same-start [pair](sims/eight-release-1104-comparison-v1/comparison.md) [reports](sims/eight-release-4417-comparison-v1/comparison.md), both explicitly incomplete on the rejected arm. Fresh-process replays pass with exact state and verified telemetry for [1104/4](sims/eight-release-1104-h4-replay-v1/replay-report.json) (192 commands/193 samples) and [4417/4](sims/eight-release-4417-h4-replay-v1/replay-report.json) (192/193). The [follow-up bundle](sims/eight-release-accessible-v1/run-report.json) retains its three completed cases and timeout evidence. Fresh-process replays pass for [1104/5](sims/eight-release-1104-h5-replay-v1/replay-report.json) (216/217) and [1104/6](sims/eight-release-1104-h6-replay-v1/replay-report.json) (240/241). 4417/5 was not separately replayed; its immutable result and Studio checkpoint are retained. No maintained gameplay code or candidate variant changed, so these replay/telemetry checks are the focused verification; prior current-main Fanbase integration tests remain separate evidence.

Exact command arguments from the repository root are below in PowerShell form. `pythonExe` and `godotExe` resolve to the recorded absolute paths. The [first](sims/eight-release-current-v1/experiment.command.json) and [second](sims/eight-release-accessible-v1/experiment.command.json) bundles retain expanded Godot argv, process exits and logs.

```powershell
$pythonExe = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godotExe = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$first = 'docs/codex/threads/fanbase/sims/eight-release-current-v1'
$followup = 'docs/codex/threads/fanbase/sims/eight-release-accessible-v1'
& $pythonExe tools/simulate.py run --config docs/codex/threads/fanbase/2026-10-11-headless-eight-release-v1.json --output $first --godot $godotExe --timeout 240
& $pythonExe tools/simulate.py run --config docs/codex/threads/fanbase/2026-10-11-headless-accessible-budget-v1.json --output $followup --godot $godotExe --timeout 240
& $pythonExe tools/simulate.py replay --bundle $first --case fan-1104-h4 --output docs/codex/threads/fanbase/sims/eight-release-1104-h4-replay-v1 --godot $godotExe --timeout 240
& $pythonExe tools/simulate.py replay --bundle $first --case fan-4417-h4 --output docs/codex/threads/fanbase/sims/eight-release-4417-h4-replay-v1 --godot $godotExe --timeout 240
& $pythonExe tools/simulate.py replay --bundle $followup --case fan-1104-h5 --output docs/codex/threads/fanbase/sims/eight-release-1104-h5-replay-v1 --godot $godotExe --timeout 240
& $pythonExe tools/simulate.py replay --bundle $followup --case fan-1104-h6 --output docs/codex/threads/fanbase/sims/eight-release-1104-h6-replay-v1 --godot $godotExe --timeout 240
& $pythonExe tools/compare_simulations.py --bundle $first --left fan-1104-h4 --right fan-1104-h8 --output docs/codex/threads/fanbase/sims/eight-release-1104-comparison-v1
& $pythonExe tools/compare_simulations.py --bundle $first --left fan-4417-h4 --right fan-4417-h8 --output docs/codex/threads/fanbase/sims/eight-release-4417-comparison-v1
& $pythonExe tools/compare_simulations.py --bundle $followup --left fan-1104-h5 --right fan-1104-h6 --output docs/codex/threads/fanbase/sims/eight-release-accessible-1104-comparison-v1
& $pythonExe tools/reduce_simulation.py --bundle $first --case fan-1104-h8 --kind rejection --output docs/codex/threads/fanbase/sims/eight-release-1104-h8-reduction-v1 --godot $godotExe --timeout 240 --max-commands 1000
```

The commands above are historical reproduction instructions: the runner requires new output directories on rerun. The fixed policies omit strategic Store/Contracts/Marketing and are not representative of all players or a balanced Fan trajectory. Eight releases do not establish 20-release compounding, player feel, exact-5.0 natural rarity, concurrent audience uniqueness, final gain/loss rates or the post-600 taper.

**Recommendation:** retain the existing 8%/15%/quarter-to-150 rules as **ACTIVE/TRIAL** for now. Ask for a narrow **DESIGN review** of whether losing 1–2 Fans at Review4.9 from83/161 launch Fans matches the intended near-neutral feel; the user's prior zero-minimum and 15%-trial rulings are not a final numerical lock. Keep the post-600 taper **ON HOLD / OPEN**, although this study confirms that current legal routes can encounter its plateau. No implementation change is approved by these simulations.
