# G4 exact hand quote performance — finding, 2026-10-18

**Result: v5 is a reviewable private structural candidate; population CPU acceptance remains DESIGN/OPEN.** A price cache and shared sales/Fan preflight preserved all 560 compared current-hand quotes, actual selected receipts, legal actions, full state and RNG in the sampled routes. V5 reduced first-release policy-plus-observation work below the frozen no-quote control in all four cases. The eight-rival elapsed-time fixture improved markedly over quote-only v3, but its repeated paired population screen gave one marginal pass and one failure against the provisional 1.5-times target. No rival choice, player challenge, market effect, balance, or canonical gameplay changed.

## Source and experiment boundary

[Predeclared plan and population addendum](2026-10-18-g4-quote-performance-plan-v1.md). Repository `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree; canonical drift was recorded separately by every bundle. Python `3.12.14`; Godot `4.7.1.stable.official.a13da4feb` at SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. No canonical source, player saves, `.codex-godot-temp`, commit or push was changed.

| Private version | Origin / exact change | Candidate identity | Frozen run identity |
| --- | --- | --- | --- |
| [v1 control](sims/g4-quote-perf-control-20261018-v1/run-report.json) | Original unchanged baseline `391cc6cf4bd6a7737ad73bd3d869c27516e79ae4f06da06efd138a03ea2ab0d6` | same as baseline | `7802e997ce766e34c181346ff8b13962785c0ee38f4750c1b79c42c19a6a4ca3` |
| [v3 full quote](sims/g4-quote-perf-full-20261018-v3/run-report.json) | v1 descendant; 35 exact full preflights per visible Design/Alpha hand | `b91e6299220bbf4a9084ed3a6f8a9f5fbb421e0e949f250ffc82e88627a3b105` | `34644123a5e97f1091b050ee48506df9cc4293955bb8cf5692516b279edecb1e` |
| [v4 price cache](sims/g4-quote-perf-cost-cache-20261018-v4/run-report.json) | v3 descendant; memoize full preflight by identical exact price inside one observation; one DevelopmentSession file | `dd06da7521f5fd83ada78662ac5a3dcb5b4ca769ebc0749ace8a3aa2129f8b14` | `19477189170e202e924348453b20fc0eefd1f873551e1d1af2e86e290f56f231` |
| [v5 shared preflight](sims/g4-quote-perf-shared-20261018-v5/run-report.json) | v4 descendant; compute release sales/Fan plan once per observation, retain distinct price-specific finance plans and the normal commit path; RunState plus DevelopmentSession | `8e1e475d3b99395f3d46c71fc9619fca5889faa90eccdb5fbff50f835442bb17` | `cf287378583d6b8740d42fda930a784a318b1ba9eec1f7d4efa51d5d6289410c` |

All four versions regenerated their own legal January Studio recipes: Action/Adventure × seeds `4417`/`90210`, `family_funding` and `cult_following`, Fantasy project Theme, specialty-matched Genre, current finite `features_first` policy, two Design/Alpha/Beta hands, ordinary exits, no Store/redraw/Bank action. Each route had a 45-command, one-release and 240-second process bound. This is a Studio policy fixture, not the current authored two-rival incumbent snapshot or an AI challenge policy. Initial state/RNG, all 18 accepted commands, first-release Review, final state/RNG and cycle 7 matched across revisions in all four cases; the [cross-variant capture](sims/g4-quote-cross-v3-v5-20261018-v1/result.json) independently compared 72 steps between v3 and v5. Reviews remained Action `2.1`/`2.3`, Adventure `1.3`/`2.0` by seed order.

## Quote and behavior checks

- The [v3-to-v4 capture](sims/g4-quote-cross-v3-v4-20261018-v1/result.json) and [v3-to-v5 capture](sims/g4-quote-cross-v3-v5-20261018-v1/result.json) each passed four cases, 72 matched steps, 16 Design/Alpha hands and **560/560 exact, ordered, full-field quotes**. Repeated observations left full state/RNG unchanged, and the selected four-card price and next-cycle cash matched actual accepted receipts. Across the 16 hands, only **122 distinct prices** appeared among 560 combinations (range 3–18 per hand), explaining v4's fewer full preflights. The wrapper labels its second arm `v4` even when given a v5 bundle; the recorded variant ID and frozen identity identify v5 precisely.
- The [v4 focused verifier](sims/g4-quote-focused-cost-cache-20261018-v4/g4-quote-verifier.log) and [v5 focused verifier](sims/g4-quote-focused-shared-20261018-v5/g4-quote-verifier.log) each passed **207 checks, zero failures** on two Design and two Alpha hands, including selected quote-to-receipt exact cents.
- The maintained two-rival [v4](sims/g4-quote-world-cost-cache-20261018-v4/rival-verifier.log) and [v5](sims/g4-quote-world-shared-20261018-v5/rival-verifier.log) actual-world checks each passed **118/0**, 20 cycles and four live releases. V5's 21 cycle/activation trace lines match the frozen v1 control exactly. The v5 [Studio checkpoint/Bank/settlement check](sims/g4-quote-studio-checkpoint-20261018-v5/rival-verifier.log) passed 93 reported PASS lines and zero failures; the [campaign session check](sims/g4-quote-campaign-session-20261018-v5/rival-verifier.log) reported zero failures, 81 steps and 55 reentrant checks.
- Fresh-process v5 [Action/4417](sims/g4-quote-shared-replay-action-4417-20261018-v5/run-report.json) and [Adventure/90210](sims/g4-quote-shared-replay-adventure-90210-20261018-v5/run-report.json) each replayed all 18 accepted commands with telemetry verified and the expected final state. No current-study command was rejected or timed out; no failure reduction was applicable.

The quote remains a **current-cycle cash preflight**, not a promise of legal production/refill or future solvency. The 560 quoted hands were checked against v3, while only the selected hands were checked against actual receipts. These fixtures did not reach an unavailable low-cash/arrears quote; v3/v5 still lack the predeclared unavailable reason field. That edge and every alternative actual receipt remain unverified.

## Performance, with the noise retained

Instrumented `policy_and_observation_us` for each 18-command first-release route:

| Recipe | v1 no quote | v3 full quote | v4 price cache | v5 shared preflight | v5 / v1 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Action/4417 | 57,908 | 118,496 | 62,383 | 40,881 | 0.71× |
| Action/90210 | 89,181 | 270,838 | 63,842 | 44,386 | 0.50× |
| Adventure/4417 | 73,835 | 308,543 | 59,946 | 45,135 | 0.61× |
| Adventure/90210 | 55,648 | 387,047 | 60,346 | 47,781 | 0.86× |

V4 and v5 each passed the predeclared four-case **≤1.5× v1** private observation screen. These are instrumented elapsed microseconds, not approved CPU budgets. The eight-rival fixture uses eight fresh legal trial-policy sessions with valid test-only pre-1980 archives, 12 committed player/world cycles, no Store/redraw/Bank actions, and an isolated source-fenced frozen bundle. It measures only `advance_committed_player_cycle`, excluding player action, state digests and save capture. Its synthetic roster is a scaling probe, not an approved entrant cohort.

| Frozen arm / run | 12-cycle world total | Median cycle | p95 cycle | Eight live releases / final world-RNG parity | Encoded world bytes |
| --- | ---: | ---: | ---: | --- | ---: |
| [v1 A](sims/g4-quote-eight-rival-control-20261018-v1/result.json) | 1.950 s | 0.098 s | 0.525 s | yes | 223,661 |
| [v1 B](sims/g4-quote-eight-rival-control-20261018-v1b/result.json) | 4.069 s | 0.231 s | 1.118 s | yes | 223,661 |
| [v1 C](sims/g4-quote-eight-rival-control-20261018-v1c/result.json) | 1.389 s | 0.083 s | 0.408 s | yes | 223,661 |
| [v3 A](sims/g4-quote-eight-rival-full-20261018-v3/result.json) | 7.744 s | 0.662 s | 1.179 s | yes | 223,661 |
| [v4 A/B](sims/g4-quote-eight-rival-cost-cache-20261018-v4/result.json) · [B](sims/g4-quote-eight-rival-cost-cache-20261018-v4b/result.json) | 6.198 / 6.561 s | 0.515 / 0.558 s | 1.181 / 1.261 s | yes | 223,661 |
| [v5 A/B](sims/g4-quote-eight-rival-shared-20261018-v5/result.json) · [B](sims/g4-quote-eight-rival-shared-20261018-v5b/result.json) | 1.957 / 2.435 s | 0.147 / 0.154 s | 0.379 / 0.696 s | yes | 223,661 |

All eight-rival runs produced the same final state/RNG digests and eight releases, and each final saved world validated with the player Studio checkpoint. V5 peak Godot static bytes were about 99.87 MB versus v1's 99.52 MB; this fixture does not measure a long-run memory ceiling. V5's first population run was about equal to v1 A. The nearby v1 C → v5 B pair was **1.75× total and 1.71× p95**, exceeding the provisional 1.5× screen. The v1 control itself varied 2.9× in total across three runs, so these process timings cannot justify a final CPU/population limit. Report the screen as mixed rather than selecting the favorable pair.

## Reproduction commands and retained outputs

PowerShell from repository root (`$py` and `$godot` are exact paths used):

```powershell
$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$t='docs/codex/threads/ai-competitors'
& $py tools/simulator_variant.py create --id g4-current-hand-20261018-v4 --owner ai-competitors --from-variant "$t/simulators/g4-current-hand-20261018-v3" --output "$t/simulators/g4-current-hand-20261018-v4"
& $py tools/simulator_variant.py create --id g4-current-hand-20261018-v5 --owner ai-competitors --from-variant "$t/simulators/g4-current-hand-20261018-v4" --output "$t/simulators/g4-current-hand-20261018-v5"
& $py tools/simulate.py run --variant "$t/simulators/g4-current-hand-20261018-v5" --config "$t/2026-10-18-g4-current-hand-control-v1.json" --output "$t/sims/g4-quote-perf-shared-20261018-v5" --godot $godot --timeout 240
& $py "$t/run_g4_quote_cross_variant_v1.py" --v3-bundle "$t/sims/g4-quote-perf-full-20261018-v3" --v4-bundle "$t/sims/g4-quote-perf-shared-20261018-v5" --output "$t/sims/g4-quote-cross-v3-v5-20261018-v1" --godot $godot --timeout 240
& $py "$t/run_g4_quote_verifier_v1.py" --bundle "$t/sims/g4-quote-perf-shared-20261018-v5" --output "$t/sims/g4-quote-focused-shared-20261018-v5" --godot $godot --timeout 120
& $py "$t/run_g4_eight_rival_cpu_v1.py" --bundle "$t/sims/g4-quote-perf-shared-20261018-v5" --output "$t/sims/g4-quote-eight-rival-shared-20261018-v5" --godot $godot --timeout 240
& $py "$t/run_rival_verifier_v2.py" --bundle "$t/sims/g4-quote-perf-shared-20261018-v5" --output "$t/sims/g4-quote-world-shared-20261018-v5" --godot $godot --timeout 180 --script verify_rival_trial_activation.gd --test-port 48975
& $py tools/simulate.py replay --bundle "$t/sims/g4-quote-perf-shared-20261018-v5" --case action-4417-control --output "$t/sims/g4-quote-shared-replay-action-4417-20261018-v5" --godot $godot --timeout 240
```

V1, v3 and v4 `simulate.py run` invocations used the same `--config`, `--godot` and `--timeout` with their respective variant/output names in the table. Every frozen bundle retains its exact `experiment.command.json`, `run-report.json`, full case results and source manifest. The cross-quote, focused, world, checkpoint and replay folders retain exact command JSON, raw logs and result JSON. The two v5 replays, eight-rival repeated runs and extra maintained checks used distinct output folders shown above; no output was overwritten. The earlier G4 study's failed canonical capture remains in its [prior finding](2026-10-18-g4-current-hand-finding-v1.md), not counted as a current-study success.

## Disposition

Retain **v5 as the best exact-quote private candidate for DESIGN review**. Its two-file refactor and quoted semantics are reviewable; v3's 35 full preflights and v4's price cache alone are slower population candidates. Do not queue v5 for canonical gameplay yet: the CPU screen is mixed, unavailable quote reasons and negative-state parity remain untested, and canonical source has continued to drift. A next bounded study should fix the unavailable-reason contract and test legal low-cash/arrears observations, then isolate cost-dependent finance work with controlled population timing before an approval decision. Once the quote is accepted, test a separate benefit-aware legal rival hand policy against the token-first and cheapest negative controls. **OPEN:** final rival objective/thresholds, cash reserves, hand counts, Store/Core math, entrants, news, CPU/memory/save limits, player challenge and active market coefficients/migration. Passing simulations do not approve balance.
