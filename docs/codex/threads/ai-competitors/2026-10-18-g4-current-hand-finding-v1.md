# G4 current-hand quote study — finding, 2026-10-18

**Result: quote-only structural behavior passed the bounded checks; adoption remains DESIGN review.** The quote view is pure and agrees with the sampled legal play receipts, but it increased measured policy-plus-observation time by 2.14–3.50× on four matched routes. The AI population CPU budget is OPEN. The cheapest-affordable test policy kept more cash while producing much worse Reviews, so it is not a rival challenge policy. These are independent Studio routes and one short two-rival world check, not player challenge or balance approval.

## Source and comparison boundary

- Repository `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared working tree. Godot `4.7.1.stable.official.a13da4feb`, Python `3.12.14`; runner SHA-256 `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`. See the [predeclared plan](2026-10-18-g4-current-hand-study-plan-v1.md) and each bundle's `run-report.json` and command record.
- The first [canonical control capture](sims/g4-current-hand-control-20261018-v1/run-report.json) **failed before cases** because `scripts/ui/hand_presentation.gd` changed while copying. The same-input [retry](sims/g4-current-hand-control-20261018-v1b/run-report.json) completed 4/4 at frozen identity `3065f36c33c67fed9e4362af7d196db759d98f6cfcb4baf31804bb277c2cd285`.
- Because concurrent UI/debug edits separated that capture from private version creation, untouched `g4-current-hand-20261018-v1` is the valid same-source [frozen control](sims/g4-current-hand-frozen-control-20261018-v1/run-report.json), base `391cc6cf4bd6a7737ad73bd3d869c27516e79ae4f06da06efd138a03ea2ab0d6`, run identity `7802e997ce766e34c181346ff8b13962785c0ee38f4750c1b79c42c19a6a4ca3`. It completed 4/4.
- `v2` descends from v1. Its [8-case run](sims/g4-current-hand-candidate-20261018-v2/run-report.json) has candidate identity `6168f5bbd62e8c286b8691476aff1060f9c9716b46e65361d36cd8dc99c786f1`, frozen identity `a863c823dcc62f5e94963289b83625a9f7c883d2eb1ac7d9a6765ff6a79cbd16`, and adds `DevelopmentSession` quotes plus a test-only reference/cheapest policy. The policy is excluded from any structural handoff.
- Quote-only `v3` also descends directly from untouched v1; it changes just `scripts/simulation/development_session.gd` (before `d2613f664d1d867d8980b1f14e9882b4785509c34188d2ba63f31cfe1e3e45fd`, after `fccf926ac6cce6993c4d8a2f6c9259d7365460b6975c09004a94973900b2e2a6`). Its [4-case run](sims/g4-current-hand-quote-only-20261018-v3/run-report.json) has candidate identity `b91e6299220bbf4a9084ed3a6f8a9f5fbb421e0e949f250ffc82e88627a3b105`, frozen identity `34644123a5e97f1091b050ee48506df9cc4293955bb8cf5692516b279edecb1e`.
- At the v3 run, current canonical identity was `28264acd22dc1fb133f47ed95cdecd64a3778f1a764b1e2251a85848981dd667`. The four recorded changed canonical paths were `verify_how_to_play.gd`, `verify_pause_music.gd` and its UID, and `hand_presentation.gd`, with **no overlap** with the one-file quote delta. This is a time-specific drift statement; recheck before any future integration. The frozen candidate import also generated an unrelated `verify_pause_music.gd.uid`; the editable v3 delta remains one file. Do not replace the canonical project wholesale.
- The [sealed v3 packet](handoffs/g4-current-hand-quote-20261018-v1/HANDOFF.md) captured later canonical identity `94d35f3818cecb38b92d1acb58d0b313c14e5ef7587e7616ac3b0d52f0f0b169`, still with zero overlapping conflicts; see its [exact manifest](handoffs/g4-current-hand-quote-20261018-v1/handoff.json). The packet tool's `READY_FOR_IMPLEMENTATION_REVIEW` label means it generated a reviewable archive. Its copied decision says **DESIGN review**, `adopted=false`, `todo_updated=false`, and the CPU acceptance gate is unmet. It is not a TODO queue or implementation authorization.

All independent cases regenerated fresh legal Studio recipes from their own source revision: Action/Adventure × seeds 4417/90210, `family_funding` and `cult_following`, Fantasy project Theme, specialty-matched Genre, no Store/redraw/Bank. The current `RunFactory` ignores an `incumbent` recipe extension, so these are not exact live incumbent snapshots. The finite control and private policies each take two legal hands in Design, Alpha and Beta, then legal exits. Every route targeted one release with 45-command/240-second bounds; all completed in 18 accepted commands at cycle 7. Full initial state and RNG matched within each same-recipe comparison. The v1 control, v2 reference, and v3 quote-only arms also matched **final** state/RNG and action tape exactly in all four cases. Equal seeds alone were not used as proof.

## Route outcomes

| Fresh Studio recipe | Frozen control / v2 reference Review, cash | v2 cheapest Review, cash | Quote-only v3 versus frozen control |
| --- | ---: | ---: | --- |
| Action 4417 | 2.1; $4,190 | 0.4; $4,720 | exact state/RNG/action parity |
| Action 90210 | 2.3; $4,290 | 0.9; $4,770 | exact state/RNG/action parity |
| Adventure 4417 | 1.3; $4,450 | 0.0; $5,010 | exact state/RNG/action parity |
| Adventure 90210 | 2.0; $4,400 | 0.6; $4,960 | exact state/RNG/action parity |

The retained case results also record the four Core values in source enum order, Scope, remaining Bugs and transaction-low cash. All first launches had **zero sales entitlement and settlement at launch**; projected units are forecasts, not earned sales.

| Recipe and arm | Four Core values | Scope / 30 | Bugs | Transaction-low cash | Projected units |
| --- | --- | ---: | ---: | ---: | ---: |
| Action 4417 reference | 22, 8, 22, 16 | 25 | 4 | $3,190 | 229 |
| Action 4417 cheapest | 15, 4, 19, 7 | 14 | 1 | $3,720 | 43 |
| Action 90210 reference | 14, 11, 27, 10 | 23 | 1 | $3,790 | 253 |
| Action 90210 cheapest | 11, 15, 14, 4 | 13 | 0 | $4,270 | 99 |
| Adventure 4417 reference | 16, 6, 12, 22 | 20 | 3 | $3,450 | 142 |
| Adventure 4417 cheapest | 16, 7, 4, 9 | 8 | 0 | $4,010 | 0 |
| Adventure 90210 reference | 12, 8, 15, 22 | 21 | 1 | $3,900 | 220 |
| Adventure 90210 cheapest | 11, 9, 10, 7 | 9 | 0 | $4,460 | 66 |

The cheapest policy used the exact current quote but optimized direct cost alone. Its four launches saved $480–$560 while dropping Review by 1.3–1.7 points. All four had zero overdue expense at first launch; this does not make the cheaper policy good. The [Studio-only continuations](sims/g4-current-hand-continue-20261018-v2/run-report.json) took Action/4417 from each arm's **own** legal checkpoint to a second release in 18 additional accepted commands, cycle 14, with no overdue bills. Reference second Review was 2.6, ending cash $3,136.78 and 12 Fans; cheapest second Review was 1.0, ending cash $2,488.60 and 7 Fans. The first-release paths differ, so this continuation is an opportunity-cost observation, not a matched isolated second-project effect. These sampled Reviews are below a demonstrated player challenge.

## Quote semantics, focused checks and cost

The private observation enumerates all 35 four-of-seven visible Design/Alpha combinations. `cost_cents` calls `RunState.primitive_feature_hand_cost_cents(cards, project.release_id)`. For nonnegative cost and an advanceable project, the read-only `_plan_productive_cycle(-cost, empty_campaign_id, feature_play, project.release_id)` provides `cash_preflight_ok`, `next_cash_cents`, `settlement_cents` and `bills_paid_cents`. `next_cash_cents` is the cash **after this productive action's direct price, released-game settlement and due-bill service**, not cash after all future project actions. It is not a full hand legality/refill guarantee or a reserve for future costs; `-1` means no quote. Beta has no four-card quotes.

The analysis-only [v2 verifier](sims/g4-current-hand-quote-focused-20261018-v2/g4-quote-verifier.log) and [v3 verifier](sims/g4-current-hand-quote-focused-20261018-v3/g4-quote-verifier.log) each passed **207 checks, zero failures** on two Design and two Alpha hands: 35 unique combinations per hand, repeated observation deterministic with full state/RNG unchanged, and selected quote direct price and next cash equal the accepted productive-cycle receipt and RunState cash. On the sampled Action/4417 path the selected direct costs were 35000/23000/36000/22000 cents and next cash 500000/477000/391000/369000 cents. The first Design and Alpha actions each included $500 rent service. The verifier checked the selected quote's actual `play_cost_cents` event; it did not execute all 35 alternatives. Its external process exited zero and preserved frozen source. Godot emitted six ObjectDB leak warnings on exit; no runtime error was recorded.

The predeclared plan requested an explicit unavailable-quote **reason** field. V3 supplies `cash_preflight_ok` and `-1` sentinels but no reason code. The focused route sampled affordable selected hands, so unavailable cash/project states and every unselected alternative were not receipt-checked. This is another design/coverage gap before adoption.

The maintained `verify_rival_trial_activation.gd` ran sequentially on the frozen [v1 control](sims/g4-current-hand-world-control-20261018-v1/rival-verifier.log) and [v3 quote](sims/g4-current-hand-world-quote-20261018-v3/rival-verifier.log), with distinct profiles and checkpoint ports. Both completed **118 checks, zero failures**, 20 shared-world cycles and four live releases. Their 21 `RIVAL_TRIAL_CYCLE`/`ACTIVATION` trace lines match exactly. Process wall times were 104.125 and 69.125 seconds, respectively; concurrent host load and run order make that wall comparison unsuitable as a quote cost estimate.

The instrumented four-case `policy_and_observation_us` totals show substantial overhead from calculating 35 preflights per Design/Alpha observation:

| Case | Frozen v1 | Quote-only v3 | Ratio |
| --- | ---: | ---: | ---: |
| Action 4417 | 36,424 µs | 127,544 µs | 3.50× |
| Action 90210 | 40,591 µs | 128,877 µs | 3.18× |
| Adventure 4417 | 34,493 µs | 103,175 µs | 2.99× |
| Adventure 90210 | 47,109 µs | 100,603 µs | 2.14× |

The Godot process cumulative static-byte peak rose from 99,036,636 to 99,149,576 bytes in this small run; this is not a population memory test. Every repeated observation recomputes the 35 `_plan_productive_cycle` calls. An approved observation latency/world CPU budget and larger population scaling test are **OPEN**, so quote-only adoption is held at DESIGN. A future optimized shared preflight or selective quote strategy requires a new private version and fresh parity, receipt and world-cost checks.

## Reproducible commands and retained outputs

Run from the repository root in PowerShell. Paths below are relative to the repository root except `$py` and `$godot`. Each output folder is unique. The underlying exact process `argv`, source identity and exit are preserved by each linked `*.command.json` and `run-report.json`. The two Studio-only continuation inputs are retained [here](sims/g4-current-hand-continue-input-20261018-v2.json); their source checkpoints are the two v2 first-release cases. No checkpoint identity was edited.

```powershell
$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$t='docs/codex/threads/ai-competitors'
& $py tools/simulate.py run --config "$t/2026-10-18-g4-current-hand-control-v1.json" --output "$t/sims/g4-current-hand-control-20261018-v1" --godot $godot --timeout 240
& $py tools/simulate.py run --config "$t/2026-10-18-g4-current-hand-control-v1.json" --output "$t/sims/g4-current-hand-control-20261018-v1b" --godot $godot --timeout 240
& $py tools/simulator_variant.py create --id g4-current-hand-20261018-v1 --owner ai-competitors --output "$t/simulators/g4-current-hand-20261018-v1"
& $py tools/simulate.py run --variant "$t/simulators/g4-current-hand-20261018-v1" --config "$t/2026-10-18-g4-current-hand-control-v1.json" --output "$t/sims/g4-current-hand-frozen-control-20261018-v1" --godot $godot --timeout 240
& $py tools/simulator_variant.py create --id g4-current-hand-20261018-v2 --owner ai-competitors --from-variant "$t/simulators/g4-current-hand-20261018-v1" --output "$t/simulators/g4-current-hand-20261018-v2"
& $py tools/simulate.py run --variant "$t/simulators/g4-current-hand-20261018-v2" --config "$t/2026-10-18-g4-current-hand-candidate-v1.json" --output "$t/sims/g4-current-hand-candidate-20261018-v2" --godot $godot --timeout 240
& $py tools/simulate.py run --variant "$t/simulators/g4-current-hand-20261018-v2" --config "$t/sims/g4-current-hand-continue-input-20261018-v2.json" --output "$t/sims/g4-current-hand-continue-20261018-v2" --godot $godot --timeout 240
& $py tools/simulator_variant.py create --id g4-current-hand-20261018-v3 --owner ai-competitors --from-variant "$t/simulators/g4-current-hand-20261018-v1" --output "$t/simulators/g4-current-hand-20261018-v3"
& $py tools/simulate.py run --variant "$t/simulators/g4-current-hand-20261018-v3" --config "$t/2026-10-18-g4-current-hand-control-v1.json" --output "$t/sims/g4-current-hand-quote-only-20261018-v3" --godot $godot --timeout 240
& $py "$t/run_g4_quote_verifier_v1.py" --bundle "$t/sims/g4-current-hand-quote-only-20261018-v3" --output "$t/sims/g4-current-hand-quote-focused-20261018-v3" --godot $godot --timeout 120
& $py "$t/run_rival_verifier_v2.py" --bundle "$t/sims/g4-current-hand-frozen-control-20261018-v1" --output "$t/sims/g4-current-hand-world-control-20261018-v1" --godot $godot --script verify_rival_trial_activation.gd --test-port 48171 --timeout 120
& $py "$t/run_rival_verifier_v2.py" --bundle "$t/sims/g4-current-hand-quote-only-20261018-v3" --output "$t/sims/g4-current-hand-world-quote-20261018-v3" --godot $godot --script verify_rival_trial_activation.gd --test-port 48172 --timeout 120
```

The v2 focused verifier used the same command with bundle/output suffix `candidate-20261018-v2`/`quote-focused-20261018-v2`. Fresh-process `tools/simulate.py replay --bundle <run bundle> --case <case id> --output <unique replay folder> --godot $godot --timeout 240` passed for [v1 Action control](sims/g4-current-hand-control-action-replay-20261018-v1/replay-report.json), [v2 Action reference](sims/g4-current-hand-reference-replay-20261018-v2/replay-report.json), [v2 Action cheapest](sims/g4-current-hand-cheapest-replay-20261018-v2/replay-report.json), [v3 Action quote-only](sims/g4-current-hand-quote-only-replay-20261018-v3/replay-report.json), and both [reference](sims/g4-current-hand-reference-continue-replay-20261018-v2/replay-report.json) and [cheapest](sims/g4-current-hand-cheapest-continue-replay-20261018-v2/replay-report.json) continuations: each 18/18 steps, 19 telemetry samples, exit zero. There were no rejected, incomplete or timed-out cases after the retained initial capture failure; failure reduction was therefore inapplicable.

## Recommendation and remaining uncertainty

Retain the read-only quote shape as a **candidate interface** because it is exact and state/RNG-pure in these cases. **Do not queue this v3 implementation or the cheapest policy now.** First design a bounded quote-cost gate and an optimized implementation strategy, then test a new private version against the same parity/receipt checks and representative actual-world population. The quote field does not by itself make rivals competitive. Review/Scope/Bug benefit, reserve horizon, hand counts, entrant rules, AI choices, CPU limits, market coefficients, old-save behavior, and player challenge remain **OPEN**. The market's effect on Reviews stays a separate design slice within AI Competitors.
