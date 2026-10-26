# G4 current-hand benefit choice — finding, 2026-10-18

**Result: reject the tested printed-benefit proxy and cheapest-affordable as universal rival hand rules.** A fixed 2/2/2-hand, no-variance visible Review proxy did not improve average first Review over token-first across all current Genres; it had two regressions. Cheapest-affordable lowered Review in every matched Genre/seed case. All successful arms remained legal and solvent in the sampled openings, so the negative result concerns choice quality, not a command failure. No canonical rival policy, active market effect or numerical balance value changed.

## Source and declared boundary

The [first four-recipe plan](2026-10-18-g4-benefit-choice-plan-v1.md) and [cross-Genre follow-up declared after its result](2026-10-18-g4-benefit-cross-genre-plan-v1.md) specify the hypotheses, policies, starting recipes, measurements and stopping conditions. The same JSON cases and limits were used after the retained setup failure. Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python `3.12.14`.

The named private [v2 simulator](simulators/g4-benefit-choice-20261018-v2/variant.json) descends from the v5 exact-quote candidate. It adds only `scripts/debug/g4_benefit_choice_policy.gd` and its UID to v5; the quote and finance gameplay source are byte-identical to v5. V2 candidate identity `56941730121c6404f015a999d1296f79a3f3d4282a8ec0853fda1cdf985e5b6c`; mechanics identity in case results `d3f136ea2a8c880e7f09bacbea97d8f6b5f61594af170487a292ac7dbe62b2d8`; policy SHA-256 `dba05b9c58ea8508c60050dc150b26ae00415159bed6cc8b6a1ae9597e3a64f7`. The first and cross-Genre run frozen source identity is `b9ac377ff491cee4ae4d9a3ddf0881daf6a978cb069409ab970afa5b3c8903b5`. The different continuation bundle identity reflects a separate isolated import; candidate, mechanics and policy identity remain the same. V5 is itself a **DESIGN** candidate with unresolved unavailable-quote and population CPU gates.

Each fresh January Studio recipe used `family_funding` and `cult_following`, Fantasy Theme, project Genre matching Studio specialty, seeds `4417`/`90210`, no Store/redraw/Bank choices, at most 45 commands, one release, and a 240-second process limit. `reference` used finite features-first; `cheapest_quote` chose the lowest preflight-available exact price; `benefit_quote` ranked preflight-available hands by unrounded visible Genre-target Review proxy after printed Core/Scope additions, then exact next cash and stable tokens. All held two Design/Alpha/Beta hands and legal phase exits. The proxy held known Bugs constant and did not know hidden Bugs, exact production specialization, refill, future bills or future market standards. These are test policies, not AI authority.

## Retained setup failure and repair

The [v1 frozen run](sims/g4-benefit-choice-20261018-v1/run-report.json) retained **12 `invalid_policy` cases at command 0**. The policy compared integer hand counts against Godot's JSON-parsed `2.0` floats as raw Dictionaries, so every factory returned an invalid Callable. Its [failed audit](sims/g4-benefit-choice-audit-20261018-v1/audit.md) is retained. Before rerunning, the plan declared a v2 child revision that validates the three counts as finite integral numerics equal to two. No seed, case, horizon or gameplay rule was changed. This was a test setup failure, not a rival action or financial failure.

## Legal first-release evidence

The [corrected twelve-arm run](sims/g4-benefit-choice-20261018-v2/run-report.json) completed all 12 cases with 18 accepted commands each, one cycle-7 release each. Its [corrected audit](sims/g4-benefit-choice-audit-corrected-20261018-v2/audit.md) confirms matched initial full state/RNG within each three-arm group, 48 selected Design/Alpha quoted hands, exact quoted next cash at the accepted receipt, and no overdue balances. The original audit mislabeled launch `total_units` as actual sales; the corrected audit calls it **projected units** and reports earned/settled separately. The token-first v2 reference reproduced the earlier v5 control's initial/final state/RNG and 18-command count on all four recipes.

The first four recipes gave benefit-minus-reference Review `0.0`, `0.0`, `+0.1`, `0.0` (Action/4417, Action/90210, Adventure/4417, Adventure/90210). Benefit launch cash was equal in three and $40 higher in Adventure/90210. Cheapest-affordable lowered Review by 1.3–1.7 in these four, despite saving $480–$560 at launch. All three policies had **zero actual earned units and settled sales cents at their immediate first-release stop**; the projected launch-unit differences are forecasts, not sales.

The [48-arm all-Genre run](sims/g4-benefit-cross-genre-20261018-v2/run-report.json) covered eight Genre target profiles × two seeds × three policies, **864/864 accepted commands**, 48 cycle-7 releases, zero rejected/incomplete/timeouts, and no overdue balance. The [cross-Genre audit](sims/g4-benefit-cross-genre-audit-20261018-v2/audit.md) verifies all 16 matched initial full state/RNG groups, source/input hashes, 192 selected hand quotes against accepted next cash, and quote totals against monthly Feature-play finance rows; the lowest observed transaction cash was $3,190. The twelve Action/Adventure repeat cases matched the first panel's final state and command counts exactly. Its case rows retain all four Core values, Scope, Bugs, cash, Fans, projected units, zero-at-launch earned/settled sales, choices and policy/observation timings.

| Benefit Review minus token-first, 16 matched openings | Cases |
| --- | ---: |
| Higher by 0.1–0.2 | 4 |
| Equal | 10 |
| Lower by 0.1–0.4 | 2 |

The average difference was **0.0 Review**. Puzzle/4417 fell from `1.6` to `1.2`: its benefit choice finished at Core `[10,8,10,22]`, Scope `19/30`, two remaining Bugs and $4,510 cash, versus reference `[10,6,14,27]`, `22/30`, four Bugs and $4,360. Sports/90210 fell `2.4` to `2.3`, with one less Scope and $50 more cash. These are direct outcomes, not proof of a single causal component; the changed hand alters later deal/RNG paths. Cheapest-affordable Review was below token-first in **all 16** by 1.3–2.0 (mean −1.54375). Benefit beat cheapest in all 16 by 1.2–2.0, but that negative control is not a sufficient adoption target.

## Second project, replay and timing

Using each Action/4417 arm's **own source-compatible Studio-only checkpoint**, the [three-arm continuation](sims/g4-benefit-action-4417-continuation-20261018-v2/run-report.json) completed a second release at cycle 14 after 18 additional accepted commands per arm. Initial continuation state/RNG matched the corresponding first-run final state/RNG; all had zero overdue cents. Second Reviews were reference `2.6`, cheapest `1.0`, benefit `2.6`. Final cash was $3,136.78, $2,488.60 and $3,186.78 respectively; Fans were 12, 7 and 12. By that stop, **actual earned/settled sales from the first release** were reference and benefit 317 units / $2,216.78, cheapest 57 units / $398.60. The new second releases had not earned or settled sales yet. This is a bounded opportunity-cost signal on one opening, not a general two-game policy result.

Fresh-process exact replay passed [Action/4417 benefit](sims/g4-benefit-replay-action-4417-20261018-v2/run-report.json), [Adventure/90210 benefit](sims/g4-benefit-replay-adventure-90210-20261018-v2/run-report.json), [Action/4417 benefit second release](sims/g4-benefit-replay-action-4417-second-20261018-v2/run-report.json), and the preselected [Strategy/4417 benefit](sims/g4-benefit-cross-genre-replay-strategy-4417-20261018-v2/run-report.json): each matched 18 accepted commands, final state and all telemetry samples. No successful study route needed failure reduction; v1's command-zero invalid factory has no action prefix to reduce.

The all-Genre `policy_and_observation_us` range was 43,310–181,114 μs across modes/cases; means were reference 75,058, cheapest 95,964 and benefit 86,819 μs. Shared-host elapsed timings are noisy and include observation cost, so this does not settle rival population CPU. The existing v5 eight-rival population screen remains mixed.

## Reproduction and disposition

PowerShell from repository root, using the exact Python and Godot executables above (`$py`, `$godot`) and `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulator_variant.py create --id g4-benefit-choice-20261018-v1 --owner ai-competitors --from-variant "$t/simulators/g4-current-hand-20261018-v5" --output "$t/simulators/g4-benefit-choice-20261018-v1"
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v1" --config "$t/2026-10-18-g4-benefit-choice-study-v1.json" --output "$t/sims/g4-benefit-choice-20261018-v1" --godot $godot --timeout 240
& $py tools/simulator_variant.py create --id g4-benefit-choice-20261018-v2 --owner ai-competitors --from-variant "$t/simulators/g4-benefit-choice-20261018-v1" --output "$t/simulators/g4-benefit-choice-20261018-v2"
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v2" --config "$t/2026-10-18-g4-benefit-choice-study-v1.json" --output "$t/sims/g4-benefit-choice-20261018-v2" --godot $godot --timeout 240
& $py "$t/audit_g4_benefit_choice_v2.py" --bundle "$t/sims/g4-benefit-choice-20261018-v2" --output "$t/sims/g4-benefit-choice-audit-corrected-20261018-v2"
& $py "$t/prepare_g4_benefit_cross_genre_v1.py" --base "$t/2026-10-18-g4-benefit-choice-study-v1.json" --output "$t/2026-10-18-g4-benefit-cross-genre-study-v1.json"
& $py tools/simulate.py run --variant "$t/simulators/g4-benefit-choice-20261018-v2" --config "$t/2026-10-18-g4-benefit-cross-genre-study-v1.json" --output "$t/sims/g4-benefit-cross-genre-20261018-v2" --godot $godot --timeout 240
& $py "$t/audit_g4_benefit_cross_genre_v1.py" --bundle "$t/sims/g4-benefit-cross-genre-20261018-v2" --output "$t/sims/g4-benefit-cross-genre-audit-20261018-v2"
& $py tools/simulate.py replay --bundle "$t/sims/g4-benefit-cross-genre-20261018-v2" --case strategy-4417-benefit --output "$t/sims/g4-benefit-cross-genre-replay-strategy-4417-20261018-v2" --godot $godot --timeout 240
```

The continuation used the documented `prepare-continuation.py` once per Action/4417 arm with absolute target **two releases** and 45 additional commands; [the thread helper](prepare_g4_benefit_continuations_v1.py) combined the three source-pinned case configs without editing their Studio envelopes. Its input and commands are frozen in the continuation bundle. The first-panel and second-project replays used the same `tools/simulate.py replay` form with unique output folders. Every run bundle retains `experiment.command.json`, logs, case results, telemetry, original/frozen manifests and Git provenance; none was overwritten.

**Recommendation:** do not adopt either tested hand-choice policy. Keep token-first as the current ACTIVE/TRIAL fixture while the detailed G4 objective stays **OPEN**. A next candidate should account for actual production specialization/Scope/Bug effects and the cost of *future* hands and exits; it should be judged in legal incumbent world and Store scenarios, not solely first-game Studio starts. The exact quote itself still needs unavailable reasons, low-cash receipts and a stable population budget before a canonical handoff. Wider campaign results, market pressure on Review/sales, AI entrant behavior and player challenge remain **OPEN**. Passing headless simulations do not approve balance.
