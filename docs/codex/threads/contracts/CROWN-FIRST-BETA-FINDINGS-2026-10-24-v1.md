# Crown CA1f — first-hand Beta redraw findings v1

2026-10-24. **COMPLETE bounded private experiment; candidate policy OPEN. Rewards unchanged.**

## Result and recommendation

The first-hand candidate did not improve Crown access: all three policies remain 0/2 seeds by Game6. Its six first-hand redraws produced zero immediate Search hits; four retained late attempts produced one. Mean remaining Bugs were 2.25, versus 1.75 for generic early control and 1.50 for late reservation; mean Review was 5.317 versus 5.417 and 5.467. The candidate has no paired release with a higher Review than either comparator. It finishes $524.48 below generic control on4522 at the same cycle93, and $395.12 below on4521 one cycle earlier at89. These are bounded outcomes, not an estimate that first-hand Search can never work.

Do not adopt this first-hand policy or blanket late reservation. Park redraw-timing experiments at this bounded result; leave canonical rewards, Review7, player rules and default AI unchanged. A future QA-policy study would need a new substantive hypothesis, rather than more seeds or extra redraw/hand budget to rescue this candidate.

## Setup, authority and exact scope

User: “Go ahead and cook for the first-hand Beta redraw test. Keep rewards unchanged.” [Pre-run plan](CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md) specifies six legal Simulation cases: seeds4522 then4521, each generic early control, CA1e late-reserved control and new first-hand candidate. Six releases/320commands per case, no Traits/employees/loans or invented starting awards. Each triple has identical full Studio recipes and verified initial state/RNG; equal seeds alone were not relied upon.

The candidate checks before the first productive Beta hand: Search absent, unused one-card policy allowance, runtime redraw available, cash at least four monthly rents. Preserve the unchanged best-scored four cards with Debug required if visible; discard the last index outside that set. If Search is present or this guard is unavailable, retain the allowance for the unchanged late Search-starved exit guard. A miss consumes the allowance. Normal hand scoring/selection remains unchanged, so this experiment does not force a particular post-redraw hand.

Both controls and candidate retain CA1d's optional Design/Alpha extra hand, two QA extension hands maximum, ordinary Scope acquisition and no targeted Core purchase. Total policy limit remains one redrawn card per phase; actual usage can differ. No rewards, gate, card scores, player hand limits, priorities, purchases or reserve changes. Candidate decisions use detached visible candidates/known Bugs; hidden Bugs, future RNG and post-release diagnostics are not inputs. Runtime source delta contains only the existing private legacy helper; [external policy diff](studies/crown-first-beta-20261024-v1/policy.diff) is the treatment.

## Source identities

`main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout. Fresh variant `crown-first-beta-v1`, protected baseline/ancestry. [Source pins](studies/crown-first-beta-20261024-v1/source-pins.json) list the two verifier-only differences from CA1e. No old checkpoints were transplanted or identity-edited.

| Identity | SHA-256 |
|---|---|
| Protected canonical baseline | `3a657520108df3a42efca0abf7347c43a3068bf6e47074016772072b1c1483d3` |
| Helper-added private project | `da3efbe3c902ceb1778e7fe12304fb002ba5b013819a2b7001b03713cbfebb02` |
| Executed mechanics | `900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c` |
| External policy | `86f8088b00f48de903ef3f0b93927cba94ac9745889ea48f1a30ec08466cc10d` |
| Pre-run plan | `68d42da706a02e964e4c840cc4c97b881d5ab8095e5efaff98af279078014935` |
| Runner | `3a7db22dd14747bce423f5031f85d92bc8e0aa1d20155e106b6fa3601e57da0b` |
| Godot | `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` |

Both seed bundles have matching mechanics, policy, runner and runtime identities. All four freshly rerun control cases match CA1e in initial/final state, RNG, commands, final cycle and entire outcome: [control continuity](studies/crown-first-beta-20261024-v1/control-continuity.json). This is a checked continuity result, not substitution of old evidence for fresh runs. [Evidence manifest](studies/crown-first-beta-20261024-v1/evidence-manifest.json) also retains any canonical drift after capture.

## All six cases

| Seed / arm | Reviews G1–G6 | Final cycle | Final cash | Commands | Crown unlocked |
|---|---|---:|---:|---:|---|
| 4522 / control | 3.8, 4.6, 5.6, 5.8, 5.7, 6.9 | 93 | $7,494.09 | 199 | no |
| 4522 / reserved | 3.8, 4.6, 5.6, 5.8, 5.7, 6.9 | 94 | $7,133.94 | 197 | no |
| 4522 / candidate | 3.8, 4.6, 5.6, 5.8, 5.3, 6.5 | 93 | $6,969.61 | 198 | no |
| 4521 / control | 3.2, 6.0, 5.5, 4.9, 6.1, 6.9 | 90 | $8,079.86 | 196 | no |
| 4521 / reserved | 3.2, 6.0, 5.5, 5.5, 6.1, 6.9 | 92 | $8,747.68 | 196 | no |
| 4521 / candidate | 3.2, 6.0, 5.5, 4.9, 5.7, 6.9 | 89 | $7,684.74 | 194 | no |

**36 releases / 1180 accepted commands**, no runtime rejections, incomplete or timed-out cases and no observed arrears. Each route legally acquires Music, General Combat and Maps; quotes/ownership/use remain audited. Publisher reward rules and private-project reward source are unchanged. Detailed actual finance totals, lows and purchases are retained in [analysis](studies/crown-first-beta-20261024-v1/analysis.json).

| Policy | Crown access | Mean Review | Mean Bugs | Extra QA hands | Beta redraws | No-effect all-Debug openers |
|---|---:|---:|---:|---:|---:|---:|
| control | 0/2 | 5.417 | 1.750 | 11 | 12 | 1 |
| reserved | 0/2 | 5.467 | 1.500 | 15 | 7 | 2 |
| candidate | 0/2 | 5.317 | 2.250 | 10 | 10 | 2 |

Counts cover12 releases per policy; a no-effect opener means its selected four cards are Debug and the hand discovers/fixes zero Bugs. Full per-game discovery/fixing, first-hand selections, components and final exits are retained in [summary](studies/crown-first-beta-20261024-v1/summary.json). Neither equal ceilings nor a Search hit implies equal downstream card draws or a net improvement.

### Every candidate targeted redraw

| Seed / release | Timing | Cycle | Discard → replacement | Search | Next action |
|---|---|---:|---|---|---|
| 4522 / G1 | late | 11 | posters → debug | miss | request_exit |
| 4522 / G2 | first | 25 | debug → posters | miss | play |
| 4522 / G3 | late | 42 | posters → search_for_bugs | hit | play |
| 4522 / G5 | first | 73 | study_competition → debug | miss | play |
| 4522 / G6 | first | 90 | sign_flippers → debug | miss | play |
| 4521 / G1 | first | 6 | study_competition → debug | miss | play |
| 4521 / G3 | late | 44 | posters → press_release | miss | request_exit |
| 4521 / G4 | first | 55 | sign_flippers → debug | miss | play |
| 4521 / G5 | first | 70 | sign_flippers → posters | miss | play |
| 4521 / G6 | late | 89 | sign_flippers → debug | miss | request_exit |

All attempts and misses remain in the [policy audit](studies/crown-first-beta-20261024-v1/policy-audit.json). Its inherited `reserved_redraws` array contains targeted events from both reserved and candidate arms; each explicitly labels `timing: first/late`. No second redraw is granted after a first-hand miss.

### Interpretation

On4522 the candidate's Game5 and Game6 first-hand redraws miss Search and still lead to four-Debug openers with zero known Bugs and no discovery/fixing. It therefore fails its intended local objective. Game6 fixes four Bugs and releases with five remaining/Review6.5, versus six fixed and three remaining/Review6.9 in both controls. The zero-variance component diagnostic also drops6.4→6.0, so the difference is not solely a favorable/unfavorable Review roll. On4521 its Game5 Review falls6.1→5.7 relative to both controls; final Game6 remains6.9. Its first-hand misses and spent allowance also change later draw opportunities: none of these full-route comparisons holds every downstream RNG draw constant. Across12 releases there are two no-effect all-Debug openers for the candidate, versus one generic and two late-reserved. Search availability, pairing with Debug and remaining hand budget all matter; the present test changes timing only and does not establish a solution to hand-scoring choices.

### Calendar and cash tradeoffs

All deltas below are candidate minus comparator. Same-release cash and same-calendar cash are distinct; the latter can compare different release counts.

| Seed / comparator | Game6 cycle delta | Game6 cash delta | Rent paid delta | Last common calendar: comparator vs candidate |
|---|---:|---:|---:|---|
| 4522 vs control | +0 | $-524.48 | $+0.00 | 93: 6 vs 6 releases; $-524.48 |
| 4522 vs reserved | -1 | $-164.33 | $-500.00 | 93: 5 vs 6 releases; $-629.37 |
| 4521 vs control | -1 | $-395.12 | $-500.00 | 89: 5 vs 6 releases; $-839.17 |
| 4521 vs reserved | -3 | $-1,062.94 | $-1,000.00 | 89: 5 vs 6 releases; $-1,909.09 |

Full paired reports: [4522 control](studies/crown-first-beta-20261024-v1/qa-simulation-4522-comparison.md), [4522 reserved](studies/crown-first-beta-20261024-v1/qa-simulation-4522-reserved-comparison.md), [4521 control](studies/crown-first-beta-20261024-v1/qa-simulation-4521-comparison.md), [4521 reserved](studies/crown-first-beta-20261024-v1/qa-simulation-4521-reserved-comparison.md). No extrapolation beyond shared observed cycles or claim of a general income-rate improvement.

## Exact execution and validation

Raw evidence root: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-first-beta-20261024-v1`. Keep source snapshots, caches/profiles, logs, results and tapes. Exact argv: [create](studies/crown-first-beta-20261024-v1/create-command.json), [4522 triple](studies/crown-first-beta-20261024-v1/qa-simulation-4522-command.json), [4521 triple](studies/crown-first-beta-20261024-v1/qa-simulation-4521-command.json), [replay](studies/crown-first-beta-20261024-v1/replay-command.json), [prepare cold](studies/crown-first-beta-20261024-v1/prepare-cold-command.json), [cold](studies/crown-first-beta-20261024-v1/cold-command.json).

Sequence: create, setup, prepare checks, first triple, first audit, second triple alongside representative verification, final analyze/audit/summarize/control continuity/verify, write records and publish. Each runner uses `--timeout 600` separately for import/execution, new output/cache/profile and no more than two concurrent processes. Policy/plan/seed/budget remain frozen after first execution.

- **PASS:** 2370 study assertions and6153 independent policy assertions; four maintained pair comparisons validate input/source/telemetry/state/RNG. Guards include both trigger timing and absence of unjustified triggers, exact discard/tie rule, one redraw consumption, no redraw cash/time/score grant, Debug retention, same phase/QA/purchase ceilings and legal quotes/cards.
- **PASS:** representative candidate4522 fresh-process replay: 198 commands/199 exact telemetry samples.
- **PASS:** Studio-only cold Continue preserves exact initial state/RNG from the original final state, then35 commands to total release7/cycle113, within80-command bound. Verification is excluded from the six-case comparison; no arbitrary active-phase policy-state persistence claim.
- **PASS:** protected baseline/ancestry, unchanged plan/policy hashes, helper-only project delta; 151 raw evidence hashes. [Verification](studies/crown-first-beta-20261024-v1/verification.json).
- **RETAINED diagnostics:** {"WARNING: 6 ObjectDB instances were leaked at exit (run with `--verbose` for details).": 3}. No warning fix claimed. No gameplay rejection needed failure reduction. A progress display initially mistook the runner's initial `ok:false` placeholder for final status; it now waits for the driver completion receipt. An early inspection of the still-unwritten driver log failed harmlessly. A premature verifier invocation rejected still-partial analysis; after the pipeline finished, the unchanged verifier passed. [Tooling check record](studies/crown-first-beta-20261024-v1/tooling-checks.json). No simulation retry, policy, input or assertion change resulted.

## Limits and next work

This is two Simulation seeds and one six-release purchasing/priority/scoring route. All36 releases are neutral-market/zero-recent-competitor observations, so active-rival pressure and relationship producers were not covered. Review variance and downstream RNG/card-path changes remain visible; post-run component diagnostics are not additional interventions. No graphical/native/export/human/device acceptance or broad balance claim.

Return to Crown reputation-brief and progression design using the existing successful access witnesses, rather than requiring this failed QA branch to unlock Crown first. Reconcile current approved framework/authority, then prepare a concrete brief acceptance matrix: challenge promise, successful/partial/missed outcomes, owner-scoped standing, release-paced availability and persistence requirements. Keep proposed terms distinct from approved rules; this experiment supplies no authority to change rewards, unlocks or activate Crown relationships.

No execution blocker remains. Candidate simulation evidence does not approve gameplay, default AI, Crown terms or balance. SideStreet P2/P3/P4 approved ACTIVE/TRIAL scope remains unchanged; Crown relationship terms/activation/migration OPEN, CP2 rewards held. Canonical gameplay, player saves, `.codex-godot-temp`, commits and pushes were untouched by this work. [Versioned handoff](CROWN-FIRST-BETA-HANDOFF-2026-10-24-v1.md).
