# Rival two-hand QA selector — bounded finding, 2026-10-25

**COMPLETE DESIGN experiment; candidate rejected; Beta selector remains ACTIVE/TRIAL.** A same-duration Search+Debug preference changed real legal rival hands in two matched worlds but did not improve rival Review or player challenge. Do not queue this selector or add Beta months from this result. The quality-versus-Marketing decision remains OPEN.

## Question, source and rules

The [pre-run plan](2026-10-25-two-hand-qa-study-plan-v1.md) follows the [extra-hand QA finding](2026-10-24-beta-qa-opportunity-finding-v1.md). The [v1 read-only audit](sims/rival-two-hand-qa-audit-4417-20261025-v1.json) faithfully mirrors the current selector and found 20 distinct first/second Beta decisions, 12 already selecting Search+Debug, and zero better public-proxy QA hands within its preferred `qa`/`balanced` patterns. The [declared v2 amendment](2026-10-25-two-hand-qa-audit-v2-plan.md) includes ordinary mixed hands, which the authoritative Beta command can also resolve. The [v2 audit](sims/rival-two-hand-qa-audit-4417-20261025-v2.json) found six lower-average-Bug Search+Debug alternatives; every one traded away one Marketing point and two also traded a $1,000 Insider payout. Four were worse at some plausible hidden-Bug counts, which explains part of the current selector's dominance veto. These are visible structural opportunities, not assured Bug reductions or legal acceptance until played.

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree and `.codex-godot-temp` preserved. The [private variant](simulators/rival-two-hand-qa-choice-20261025-v1/variant.json) forks the frozen [two-hand control](simulators/rival-proportional-beta-control-20261024-v1/variant.json), sharing original base identity `b208a690798577094d632eadaffec32dc42a0e4d02973b609b481411093aa0e5`. Only `scripts/market/rival_beta_synergy_choice.gd` differs (control SHA-256 `57b8e0f8d762f905a1a773cc99e37bf458e3b02c872d8fc0b36dcd895ec0769d`, candidate `44636d936a8ab8de77283fb040cd914ddeab9434a1db4ac75ffc000a5281838f`). The control gameplay source identity is `5da7bc70f45fc63d33e6f5293e77338992038810b84a2c964ff47aff7a2b1a64`; candidate `50ce0c8495a48de89529daf6ffddb7a1c7edf58f69b9d043ea7ea7b2051de588`. [Cross-version audit](sims/rival-two-hand-qa-comparison-20261025-v1.json) confirms the single source delta, equal initial full state/RNG for each seed, two accepted Beta hands for each completed project and identical release calendars. No old checkpoint was carried across revisions.

The private selector keeps the existing two Beta productive hands. It first makes the current choice, then tests every structurally eligible visible Search+Debug four-card mix, including `none` specialization. It replaces the choice only when the alternative has a smaller sum of public-proxy remaining Bugs over hidden counts `0..required_scope`; ties prefer Marketing, then payout, then tokens. It never reads actual hidden Bugs or changes card, Review, money, Market, Design/Alpha or player rules. Actual BetaHandCommand and RunState handle legality, effects, cash and RNG. This intentionally relaxes the current all-hidden-count dominance test; its hidden-range sum is an unapproved decision heuristic, not a calibrated Bug forecast.

## Matched cycle-56 outcomes

Each Action/Fantasy world legally played 144 player commands and eight player releases, ending at cycle56 inside the declared 210-command/eight-release/cycle64/twelve-zero-step/480-second bounds. Both seeds preserved the same ten rival publication cycles across control and candidate. These are two bounded worlds, not a general balance estimate.

| Seed | Current selector | Private mixed-QA selector |
| --- | ---: | ---: |
| 4417 rival titles / mean Review | 10 / 5.00 | 10 / 4.97 |
| 4417 titles ≥6.0 / ≥7.0 | 1 / 0 | 1 / 0 |
| 4417 player earned units / settled sales | 1,860 / $13,006.95 | 1,860 / $13,006.95 |
| 4417 changed matched Beta hands / Search+Debug selections | — / 12 | 9 / 13 |
| 4418 rival titles / mean Review | 10 / 4.54 | 10 / 4.53 |
| 4418 titles ≥6.0 / ≥7.0 | 0 / 0 | 0 / 0 |
| 4418 player earned units / settled sales | 1,819 / $12,720.25 | 1,819 / $12,720.25 |
| 4418 changed matched Beta hands / Search+Debug selections | — / 8 | 2 / 8 |

Player cash/Fans likewise match by seed: 4417 $2,196.95/2; 4418 $2,730.25/2. Within 4417, Arcade project4 improved Review4.2→4.5 and remaining Bugs7→5, but Wayfinder project4 fell5.5→5.1 and Bugs2→4, and Arcade project5 fell4.8→4.6 and Bugs3→4. In 4418 Arcade project2 fell4.8→4.7 with Bugs4→5. Later hands can diverge after an earlier selection, so these project deltas are whole-project outcomes, not isolated causal effects of one card. The candidate raises total Search+Debug-selected hands only once across 4417 and not at all across 4418, despite choosing more mixed hands. The public hidden-range proxy did not predict an aggregate Review gain.

Checkpoint sizes were 714,916→714,769 bytes in 4417 and 728,783→728,772 in 4418. World wall times were 48.55→62.13 seconds and 131.03→63.42 seconds, respectively, on a shared host; process CPU counters are unreliable, so this does not establish a CPU cost or saving. The second-seed control's longer wall time is retained, not discarded.

## Commands, verification and limits

Python: `C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`; Godot console: `C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe` (SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`). The exact expanded argv, source hashes, timeout, exit and logs are retained in each linked run's `world.command.json`/`world-run.json`; the following are the study invocations from the repository root:

```powershell
& $pnPython docs/codex/threads/ai-competitors/2026-10-25-two-hand-qa-audit-v1.py
& $pnPython docs/codex/threads/ai-competitors/2026-10-25-two-hand-qa-audit-v2.py
& $pnPython tools/simulator_variant.py create --id rival-two-hand-qa-choice-20261025-v1 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/rival-proportional-beta-control-20261024-v1 --output docs/codex/threads/ai-competitors/simulators/rival-two-hand-qa-choice-20261025-v1
& $pnPython tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-two-hand-qa-choice-20261025-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-two-hand-qa-smoke-20261025-v1 --godot $pnGodot --timeout 240
& $pnPython docs/codex/threads/ai-competitors/2026-10-25-two-hand-qa-comparison-v1.py
```

Here `$pnPython` and `$pnGodot` are the exact executable paths above. [Candidate smoke](sims/rival-two-hand-qa-smoke-20261025-v1/run-report.json) passes 18 commands/one legal release. [Seed4417 candidate](sims/rival-two-hand-qa-4417-candidate-20261025-v1/world-run.json) passes 11,015 checks; [seed4418 control](sims/rival-two-hand-qa-4418-control-20261025-v1/world-run.json) and [candidate](sims/rival-two-hand-qa-4418-candidate-20261025-v1/world-run.json) each pass 11,518 checks. The pre-existing [seed4417 control](sims/rival-proportional-beta-control-4417-20261024-v1/world-run.json) passes 11,015. Each world used `six-hand-phase-study-20261023-v1/run_world.py --bundle <arm's smoke bundle> --output <linked unique folder> --godot $pnGodot --source <arm's source identity above> --route action-fantasy --seed <4417 or 4418> --candidate 0 --arm B`; the retained receipts specify every substituted value. No world had a rejected command, source drift, failure or timeout.

Fresh-process exact [4417 replay](sims/rival-two-hand-qa-4417-replay-20261025-v1/world-run.json) and [4418 replay](sims/rival-two-hand-qa-4418-replay-20261025-v1/world-run.json) pass 11,099/11,602 checks with exact final state/RNG. [4417 Studio-only Continue](sims/rival-two-hand-qa-4417-restore-20261025-v1/world-run.json) and [4418 Continue](sims/rival-two-hand-qa-4418-restore-20261025-v1/world-run.json) pass eight checks each. They use the same world command with `--replay-input` set to that seed's candidate `world-report.json.tape.json` or `--restore-input` to its Studio `world-report.json.checkpoint.json`; exact arguments are in their receipts. The [read-only cross-version comparison](sims/rival-two-hand-qa-comparison-20261025-v1.json) passes nine checks. The maintained `verify_rival_synergy.gd` suite is **NOT RUN** on this private candidate: it asserts the existing selector's decision rule, which this experiment intentionally changes. The current-source world legality, exact replay and Studio Continue supply the relevant candidate checks; the maintained suite must be revised and run if a selector is ever approved for adoption.

## Disposition

The declared design screen fails: rival title density and player sales hold, but Review does not improve in either seed. Reject this mixed-QA preference, retain the current two-hand Beta selector, and do not create an adoption packet or TODO implementation entry. The next design question is how to estimate likely *actual* remaining Bugs and the Review value of a QA card against Marketing and Insider cash at the same calendar cost. More Search+Debug selections or a lower unweighted hidden-range sum alone are not a sufficient success criterion. Exact estimator, any Review/Marketing tradeoff, cash-risk gate, richer pools and CPU limits stay **OPEN**. Passing these simulations does not approve balance.
