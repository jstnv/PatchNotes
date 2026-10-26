# Crown CA1e — reserved Beta redraw findings v1

2026-10-24. **COMPLETE bounded private experiment. Candidate remains OPEN; do not adopt blanket reservation. Rewards unchanged.**

## Conclusion

Reserving the existing Beta redraw until a Search-starved exit found Search in **3 of7 attempts**. Across12 releases per arm, average remaining Bugs fell **1.75→1.50**, mean Review rose **5.417→5.467**, and Crown access stayed **0/2→0/2**. Only one paired release Review improved (seed4521 Game4,4.9→5.5). Both final games still score6.9. This does not establish a reliable Crown-access improvement.

Costs are mixed: seed4522 finishes one cycle later and **$360.15 poorer**;4521 finishes two cycles later and **$667.82 richer**. Each pays an additional$500 rent. Keep reservation as a situational candidate, not a blanket recommendation. The next useful question is whether Search-aware **first-hand** timing preserves early QA opportunity without adding budget. That follow-up is **proposed, not run** in this study.

## Authority, setup and provenance

User: “Go ahead and cook for reserving the Beta redraw when Search for Bugs is missing. Keep rewards unchanged.” [Pre-run plan](CROWN-BETA-REDRAW-PLAN-2026-10-24-v1.md), [handoff](CROWN-BETA-REDRAW-HANDOFF-2026-10-24-v1.md). Existing publisher rules remain ACTIVE/TRIAL where already approved; new policy success is not approval of balance or Crown relationship activation.

Fresh legal Simulation recipes, no Traits/employees/loans, seeds4522 then4521, each control first then candidate, six-release/320-command ceiling. Both arms use the prior CA1d QA-extension policy, optional extra Design/Alpha hand, ordinary Scope acquisition and no targeted Core purchase. Only `reserve_beta_redraw` differs (plus evidence labels). The maintained paired reporter verifies complete initial state/RNG, not seed equality alone. Commands and downstream RNG can differ after the policy branches.

- Control: generic early one-card Beta redraw.
- Candidate: hold it until an ordinary exit/extension entry lacks visible Search, with fewer than two extension hands, at least four monthly rents, unused policy allowance and runtime redraw remaining. Retain the best existing-scored four cards, requiring Debug if visible; discard the last index outside that set. Same QA Search/Debug rules follow. At most one redrawn card per phase; no hidden Bugs/future RNG, Host Playtest, new purchases, rewards or hand allowances.
- Runtime redraw itself consumes one redraw without a productive cycle or cash charge. Subsequent extra hands can cost rent/time. Actual Beta redraws are12 control versus7 candidate; equal ceilings do not mean equal realized use.
- The prior study's automatic QA extension remains unrecommended overall; it is the fixed comparison context here. These results are not a direct fresh comparison with the earlier no-extension route.

Branch `main`; HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared source. Fresh private variant `crown-beta-redraw-v2`:

| Identity | SHA-256 |
|---|---|
| Protected canonical baseline | `4e5fba8f4b76f677bd5e32d502cca383bc132c801a93bafa0544a7a89eda1a4f` |
| Helper-added private project | `b0096a682c0c6f632cf8c63c6f2ac9d4185732db7ba0f9c77e3b470ab9f671c7` |
| Executed mechanics | `900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c` |
| Frozen imported project | `6d5336bc269bb36f00b50ce1dd824cdbd4c7b084e33f719a44cd605bdd19f6f4` |
| External policy | `731ca2123a7179abe44342646324ca0277a0959c6aa6d9da955e78e5b3e6852f` |
| Pre-run plan | `9e006bd8c0218dbd3ca6262bcf6a207d1628605b06e600eebc0f5cd1a6e8bdc4` |
| Runner | `3a7db22dd14747bce423f5031f85d92bc8e0aa1d20155e106b6fa3601e57da0b` |
| Godot executable | `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef` |

[Full source pins](studies/crown-beta-redraw-20261024-v1/source-pins.json) retain the nine changed/added paths since the preceding QA/Core baseline, including tutorial/gameplay and rival checkpoint changes. Old-source checkpoints were not imported or identity-edited. Both new bundles have matching frozen mechanics/policy/runtime. The only private project addition is the unchanged legacy helper; the candidate policy is external. [Policy delta](studies/crown-beta-redraw-20261024-v1/policy.diff) and protected variant integrity were checked. Concurrent canonical drift after capture is retained in the [evidence manifest](studies/crown-beta-redraw-20261024-v1/evidence-manifest.json); results apply to the frozen revision.

## Complete outcomes

| Seed / arm | Reviews G1–G6 | Final cycle | Final cash | Commands | Crown unlocked |
|---|---|---:|---:|---:|---|
| 4522 control | 3.8, 4.6, 5.6, 5.8, 5.7, 6.9 | 93 | $7,494.09 | 199 | no |
| 4522 candidate | 3.8, 4.6, 5.6, 5.8, 5.7, 6.9 | 94 | $7,133.94 | 197 | no |
| 4521 control | 3.2, 6.0, 5.5, 4.9, 6.1, 6.9 | 90 | $8,079.86 | 196 | no |
| 4521 candidate | 3.2, 6.0, 5.5, 5.5, 6.1, 6.9 | 92 | $8,747.68 | 196 | no |

All four cases completed: **24 releases,788 accepted commands**, zero recorded rejection/incomplete/timeout cases and no observed arrears. Each acquires Music, General Combat and Maps through legal current quotes; no targeted Core intervention. Publisher receipts match within each pair ($2,066.66 on4522 and$2,233.33 on4521); reward source is unchanged. Store and Feature-play totals also match within pairs. End-cash differences reflect actual route/settlement/rent effects, not a reward change.

The candidate spends15 QA extension hands versus11 control, with19 discoveries/18 fixes versus11/12 during those extensions. Both have four extension hands that neither discover nor fix Bugs. These counts describe extension exposure, not net causal benefit: ordinary-hand QA differs too. Full-Scope releases stay2/12 per arm.

### Every reserved redraw, including misses

| Seed / release | Cycle | Known Bugs | Discard → replacement | Search | Next action |
|---|---:|---:|---|---|---|
| 4522 / G1 | 11 | 0 | posters → debug | miss | request_exit |
| 4522 / G4 | 61 | 0 | sign_flippers → debug | miss | request_exit |
| 4522 / G6 | 93 | 0 | debug → search_for_bugs | hit | play |
| 4521 / G3 | 42 | 0 | debug → search_for_bugs | hit | play |
| 4521 / G4 | 58 | 0 | debug → search_for_bugs | hit | play |
| 4521 / G5 | 76 | 2 | sign_flippers → posters | miss | play |
| 4521 / G6 | 92 | 0 | posters → debug | miss | request_exit |

The seed4521 Game5 miss still permits a Debug hand because two Bugs are already known. A miss does not always mean immediate exit. [Independent trigger/discard/resource audit](studies/crown-beta-redraw-20261024-v1/policy-audit.json) covers every action, including non-trigger opportunities.

### Why a Search hit did not guarantee improvement

On seed4522 Game6 both arms enter Beta at cycle90 with matching Cores/Scope and nine total generated Bugs (post-run reconciliation). The control uses its early redraw and fixes six Bugs over three hands. The reserved candidate first plays four Debugs with zero known Bugs, producing no discovery/fixing; it later finds Search and ultimately fixes the same six Bugs over four hands. Its late successful redraw and two fixes merely catch up with lost early progress. Both release with three Bugs/Review6.9. No hidden Bug total was available to the policy.

Seed4521 Game4 is the useful witness: both enter Beta at cycle55 with matching Cores/Scope and eight generated Bugs; control fixes zero, candidate fixes three. Remaining Bugs8→5, Review4.9→5.5, zero-variance diagnostic4.4→5.0. Its Game3 Search hit does not improve final Review/Bugs, and its Game6 redraw misses. This supports further timing investigation, not a universal late-redraw rule.

### Matched time and finance

At seed4522's last common cycle93, control has six released games; candidate has five and is still in Beta. Candidate cash is$104.89 higher at that moment, but by its own sixth release at94 it is$360.15 lower. Seed4521 at common cycle90 similarly has six versus five releases; candidate has$1,111.87 more cash then, versus$667.82 more at its own Game6/c92. The paired reports retain both horizons: [4522](studies/crown-beta-redraw-20261024-v1/qa-simulation-4522-comparison.md), [4521](studies/crown-beta-redraw-20261024-v1/qa-simulation-4521-comparison.md). A cash-at-later-release result is not an equal-time income-rate claim.

Command-boundary cash lows:4522 $1,809.87 control/$1,886.79 candidate;4521 $1,895.63/$1,916.61. Raw finance-boundary lows and all matched milestones are in the paired JSON reports. No overdraft/arrears observed.

## Commands, checks and retained failures

All commands run from repository root with the Python/Godot paths frozen in [setup.py](studies/crown-beta-redraw-20261024-v1/setup.py). Exact create argv/outcomes are in [capture attempts](studies/crown-beta-redraw-20261024-v1/capture-attempts.json). Runner argv: [4522](studies/crown-beta-redraw-20261024-v1/qa-simulation-4522-command.json), [4521](studies/crown-beta-redraw-20261024-v1/qa-simulation-4521-command.json), [replay](studies/crown-beta-redraw-20261024-v1/replay-command.json), [prepare cold](studies/crown-beta-redraw-20261024-v1/prepare-cold-command.json), [cold run](studies/crown-beta-redraw-20261024-v1/cold-command.json). All simulation/replay invocations use `--timeout 600`; each receives a fresh project/cache/profile/output folder, maximum two concurrent runners.

Sequence: create attemptv1, fresh createv2, `setup.py`, `run.py first`, first-pair `analyze.py`/`audit_policy.py`, `run.py remaining` alongside `run_verification.py`, final `analyze.py`/`audit_policy.py`/`summarize.py`, `verify.py`, documentation write/publish checks. Seeds, budgets and frozen policy were never changed after outcomes.

- **PASS:** 1586 study assertions and3368 independent policy assertions, paired state/RNG/source/input/telemetry validity, legal quotes/cards, trigger/tie rule, exact one-card consumption, no redraw cash/time/score award, Debug retention, unchanged caps/reserves, observed Search/Debug exposure.
- **PASS:** fresh-process candidate4522 exact197-command/198-sample replay including all telemetry; no GUI involved.
- **PASS:** cold Studio-only Continue starts at exact original state/RNG,35 commands to release7/cycle114 within80-command bound. This is one further release, excluded from the four-case numerical study. It does not prove arbitrary mid-project policy-local-state persistence.
- **PASS:** protected baseline and unchanged plan/policy, only helper addition; 133 retained raw artifact hashes. [Verification receipt](studies/crown-beta-redraw-20261024-v1/verification.json).
- **RETAINED CAPTURE FAILURE:** v1 creation rejected because `scripts/market/rival_world_checkpoint.gd` changed while copying. Its partial folder remains; no cases ran. Fresh v2 succeeded. No guard was bypassed.
- **RETAINED WARNING:** three log occurrences of `6 ObjectDB instances were leaked at exit`; no fix or leak-free claim. No gameplay rejection required failure reduction. One PowerShell `rg` glob diagnostic failed with Windows path error during inspection; direct-file source reads supplied the evidence, with no policy/input changes.

Raw evidence root: `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-beta-redraw-20261024-v1`. Keep the immutable source, profile logs, results, tapes and failed capture alongside compact [summary](studies/crown-beta-redraw-20261024-v1/summary.json), [analysis](studies/crown-beta-redraw-20261024-v1/analysis.json) and hashes.

## Limitations and next decision

Two Simulation seeds, one purchasing/priority/scoring policy and six releases are a bounded diagnostic, not a balance estimate. All24 study releases have neutral-market/zero-recent-competitor observations; updated rival source does not establish active-world coverage. Final6.9 reviews include variance; zero-variance values remain6.4 (4522) and6.6 (4521), unchanged between arms. No Crown relationship access/standing/support behavior was reached or tested here.

Do not adopt blanket reservation or broaden QA/redraw budgets. Proposed next investigation: a Search-aware first-hand redraw with unchanged rewards and total allowance, avoiding needless postponement of early discovery. Keep the earlier QA/Core results available; this study does not supersede the optional Music witness or rehabilitate automatic QA extension generally. Crown relationship terms/activation/migration remain OPEN; SideStreet approved pilots and CP2 reward hold remain unchanged. No genuine execution blocker remains; future canonical adoption still needs a design ruling and source reconciliation. GUI/native/export/human/device acceptance and broad balance were NOT RUN.
