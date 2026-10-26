# Crown extra-hand utilization — findings v1

2026-10-24. **COMPLETE bounded private study; DESIGN review, no gameplay/default-AI adoption.**

## Recommendation

Keep Crown's Review 7 gate and publisher rewards. Retain the extra-hand Action witness as a reachable route, but do not adopt this stopping policy as universal player guidance or default AI. It changes pacing and cash unevenly and does not establish a general cure for remaining Crown-access misses. Next investigate the two misses separately: bounded visible-information QA stopping for Simulation, and selective Core-aware purchases against the original acquisition control for Puzzle. Preserve the favorable no-purchase Action witness; avoid making shopping mandatory.

## Authority and exact sources

User authorized the proposed CA1b follow-up with “Go ahead and cook.” [Predeclared plan](CROWN-EXTRA-HAND-PLAN-2026-10-24-v1.md), [audit amendment](CROWN-EXTRA-HAND-AMENDMENT-2026-10-24-v1.md), [proposed handoff](CROWN-EXTRA-HAND-HANDOFF-2026-10-24-v1.md), [intake](studies/crown-extra-hand-20261024-v1/intake.json), [source pins](studies/crown-extra-hand-20261024-v1/source-pins.json).

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty shared checkout, 158 tracked changed files at intake. Existing edits and `.codex-godot-temp` preserved.
- Contracts child variant `crown-extra-hand-v1`, parent `crown-acquisition-v1`; protected canonical baseline `1338299b4fc7b6e4462609b9458a6b39e2c205854705795fa9d7bd53427a62e2`; candidate project `5b3b6fac6ad5acb4a3006d3f4ef243e068c0bbac91f9006aeaeca5145f78bdbe`.
- Common actual mechanics `12fe049927a7e7fb0c953e74dfc0329112a801ea2946a9200bb95a5dc3db5ad3`; Godot `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; frozen external policy `51b197e068c6189f757fa53988338a4dcf9a52e3d65f24d9d69e911a07277f3e`.
- Only inherited private project delta is `scripts/debug/crown_access_legacy_v1.gd`, SHA-256 `1ee14d9a22b0cbfc58a80a16e2f68db06e20aad33ddf1cab5e60124b99936b55`. This study edits no private gameplay rule; [policy.diff](studies/crown-extra-hand-20261024-v1/policy.diff) records the external decision-policy delta. Original baseline and ancestry remain intact.
- Two host runners are explicitly accepted under the byte-exact `.ico` allowlist amendment, not described as identical. [All identities and compatibility proof](studies/crown-extra-hand-20261024-v1/runner-compatibility.json). Common frozen mechanics, runtime, policy and non-import source identities pass.

Canonical source matched the parent baseline at intake, then other work changed it during this frozen study. The following final drift is retained rather than overwritten. This is evidence on the recorded source, not final-current-source acceptance; regenerate legal prefixes on any new gameplay revision instead of patching checkpoint identities.

- `assets/branding/patch_notes.ico` (added)
- `assets/branding/patch_notes_logo.png` (added)
- `assets/branding/patch_notes_logo.png.import` (added)
- `project.godot` (modified)
- `scripts/debug/verify_market_density_trial.gd` (modified)
- `scripts/debug/verify_market_release_index.gd` (modified)
- `scripts/debug/verify_rival_feature_exhaustion.gd` (added)
- `scripts/debug/verify_rival_feature_exhaustion.gd.uid` (added)
- `scripts/debug/verify_rival_synergy.gd` (modified)
- `scripts/market/rival_trial.gd` (modified)
- `scripts/market/rival_world.gd` (modified)

## Setup and policies

Twelve fresh legal campaigns: seeds 4521/4522 × Action/Puzzle/Simulation × control/extra, no Traits/employees. Six releases and maximum 300 commands per case, six two-case batches, at most two runner processes concurrently, 600-second execution timeout per invocation. The bound explicitly increases CA1's 280 to accommodate extra hands. First Simulation 4522 pair was inspected before remaining batches. Both arms share exact initial state/RNG; all six controls reproduce the prior CA1 acquisition trajectory, including final state/RNG and every telemetry sample.

Control retains CA1's exact-quote acquisition strategy, $4,000 admission reserve, one purchase completion per release window/five overall, stopping at owned Scope 30; specialty/Fantasy, priorities, ordinary phase caps 3/2/3 then 6/4/6, one legal one-card redraw per phase and Beta QA/stopping stay fixed.

Candidate alone may play one extra four-card hand at the Design/Alpha policy ceiling while played Scope is below required Scope, if a visible positive-Scope Feature can be included and the entire hand fits cash after reserving four current monthly rents. Existing Core/Scope scoring ranks combinations. After that extra hand, exit normally. Ordinary hands reserve three rents. Later Store Features retain zero play fee; Primitive fees use current printed-score formula. Actual rent is due every second productive cycle, so the extra full-rent screen is conservative. No extra Beta hands/redraws, loans, hidden Bug/RNG reads, invented money/cards or rule changes.

Different subsequent purchases, draws, RNG, sales and calendar are downstream policy effects. Equal seeds do not imply identical later states. This is a strategy comparison, not a change to canonical hand limits.

## Outcomes

**12/12 finish six releases; 2,295 commands all accepted; no observed arrears.** Crown access is **4/6 → 4/6**. Actual full-Scope releases: **10/36 → 13/36**. Descriptive mean Review 5.464 → 5.681; mean remaining Bugs 2.444 → 2.639. Two seeds per specialty do not estimate population success rates.

| Start | Control first Crown access | Extra first Crown access | Extra hands used | End cycle | End cash |
|---|---|---|---:|---|---|
| action-4521 | Game 4, cycle 57 | Game 4, cycle 60 | 3 | 87 → 90 | $16,592.89 → $15,147.36 |
| action-4522 | Game 4, cycle 54 | Game 3, cycle 43 | 4 | 85 → 89 | $17,599.61 → $29,374.20 |
| puzzle-4521 | none by Game 6 | none by Game 6 | 1 | 84 → 85 | $11,078.37 → $11,253.06 |
| puzzle-4522 | Game 6, cycle 81 | Game 5, cycle 73 | 4 | 81 → 90 | $12,652.48 → $17,470.66 |
| simulation-4521 | Game 6, cycle 86 | Game 6, cycle 86 | 0 | 86 → 86 | $8,294.46 → $8,294.46 |
| simulation-4522 | none by Game 6 | none by Game 6 | 1 | 85 → 86 | $9,522.20 → $7,728.36 |

| Start | Control Reviews, Games 1–6 | Extra Reviews, Games 1–6 |
|---|---|---|
| action-4521 | 3.4, 6.5, 4.5, 7.4, 5.4, 7.0 | 4.8, 6.6, 4.4, 7.0, 4.3, 7.4 |
| action-4522 | 3.2, 4.9, 6.3, 7.2, 6.5, 6.1 | 5.8, 5.3, 7.8, 7.8, 6.8, 5.8 |
| puzzle-4521 | 2.9, 6.6, 4.6, 6.8, 4.7, 6.2 | 3.3, 6.8, 4.4, 6.6, 4.7, 6.5 |
| puzzle-4522 | 2.1, 4.3, 6.1, 6.6, 6.8, 7.5 | 4.2, 4.7, 6.6, 6.2, 7.8, 5.7 |
| simulation-4521 | 2.9, 6.0, 4.5, 6.6, 4.9, 7.1 | 2.9, 6.0, 4.5, 6.6, 4.9, 7.1 |
| simulation-4522 | 3.2, 4.2, 5.8, 6.0, 6.2, 5.7 | 3.8, 3.9, 5.6, 5.8, 5.9, 6.2 |

All 13 attempted extra hands are accepted and independently checked for phase, ceiling, incomplete Scope, visible four-card legality, Feature content, full-hand cash screen and post-hand three-rent reserve. Exposure by game: `{'1': 8, '4': 2, '3': 1, '5': 2}`. [Exact hand events and phase/redraw counts](studies/crown-extra-hand-20261024-v1/extra-audit.json). No-exposure cases: `['extra-simulation-4521']`; their full trajectories equal their controls.

The early extra hands alter later draw/RNG paths. Improved Game 6 Scope is not proof of a Game 6 extra-hand intervention. For Simulation 4522, the only extra hand is Game 1 Design (Controller); it ends with full Scope but still misses Crown and less cash. Action 4522's favorable outcome and Action 4521's adverse cash/pacing outcome are both retained. End cash combines sales, Contracts, purchases, rent and fees; it is not simply the cost of extra hands. [Per-case finance totals and components](studies/crown-extra-hand-20261024-v1/analysis.json).

### Remaining quality gaps

- `extra-simulation-4522`: best actual release Game 6, Review 6.2, Scope 30/30, 6 remaining Bugs, production 7.142; Cores [17, 23, 48, 34] against [20, 20, 59, 33]. Weakest normalized Core: Technology (0.814). Zero-variance diagnostic 5.7. These arithmetic diagnostics are not alternate simulated releases.
- `extra-puzzle-4521`: best actual release Game 2, Review 6.8, Scope 29/30, 0 remaining Bugs, production 7.242; Cores [20, 14, 37, 48] against [20, 13, 40, 59]. Weakest normalized Core: Design (0.814). Zero-variance diagnostic 7.0. These arithmetic diagnostics are not alternate simulated releases.

Core order is Graphics/Sound/Technology/Design, from the frozen ProjectState enum. Scope completion, Core coverage, remaining Bugs and Review variance interact. These observations support a separate targeted-acquisition investigation; they do not approve a purchase or demonstrate a hypothetical extra Core score is legally reachable.

Simulation 4522 Game 6 now has production 7.142 and full Scope, but six remaining Bugs. Its observed Beta exit has **0 known Bugs**, at cycle 86 with $7,728.36. The post-run bug-free, zero-variance diagnostic is 7.1. This makes bounded legal playtesting/QA a better next question for this route than assuming more purchases are required. That diagnostic does not prove another hand can discover/fix those Bugs; the next policy must use visible information and a predeclared stopping rule, never hidden Bug counts.

Puzzle's original acquisition control reaches full Scope in Game 4 but has Sound9/13 and production6.505. Existing Music remains a specific purchase hypothesis for that control. The extra-hand route's best Game2 instead has Scope29, no remaining Bugs, weak Design48/59 and zero-variance Review7.0 but actual6.8. Sound is therefore not a universal diagnosis of every Puzzle miss; draw paths, incomplete Scope and variance also matter. Keep these routes distinct in the next experiment.

### Matched calendar

| Pair | Last shared observed cycle | Extra minus control cash | Release-count delta |
|---|---:|---:|---:|
| action-4521 | 87 | -$522.45 | -1 |
| action-4522 | 85 | $12,250.12 | -1 |
| puzzle-4521 | 84 | $174.69 | -1 |
| puzzle-4522 | 81 | $6,108.96 | -1 |
| simulation-4521 | 86 | $0.00 | 0 |
| simulation-4522 | 85 | -$1,335.80 | -1 |

These are observed command boundaries at the same calendar cycle, not necessarily the same phase/title age. Paired reports also preserve release milestones. No interpolation, equal-sales-exposure assumption or pure card-stat causal claim is made.

## Verification and retained failures

- **PASS:** 4,490 study assertions and 3,529 extra-hand/control-reproduction assertions, plus maintained bundle/input/source/telemetry comparison. All six initial state/RNG pairs match; all six controls exactly reproduce CA1.
- **PASS:** predeclared policy/plan hashes and protected variant baseline/ancestry. [Verification](studies/crown-extra-hand-20261024-v1/verification.json).
- **PASS:** planned extra-Simulation-4522 fresh-process replay: 192 commands/193 telemetry samples; Studio-only cold Continue restores exact state/RNG and completes 30 commands to release 7/cycle 101. Cold mechanics equal study mechanics.
- **RETAINED audit failure, resolved explicitly:** initial three-batch aggregate stopped at `AssertionError: common runner`. The only code difference was adding `.ico` to the host snapshot allowlist. Both runners and failure record remain; byte-exact exception and identical frozen non-import source are checked. No run/policy/seed/budget was replaced to fix the audit.
- **NONE observed:** runtime rejected commands, incomplete campaigns, timeouts or recovery reruns. Failure reduction NOT APPLICABLE; no command rejected.
- [Manifest](studies/crown-extra-hand-20261024-v1/evidence-manifest.json): 301 hashed raw artifacts, frozen projects and private profiles retained at `C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-extra-hand-20261024-v1`.
- 4 retained log occurrences: ``WARNING: 6 ObjectDB instances were leaked at exit (run with `--verbose` for details).``. This warning is not claimed fixed.
- **NOT RUN / not established:** GUI/export/human/device acceptance, broad balance, alternate Traits/employees, later Store upgrades/discounts, default rival AI or Crown relationship migration/adoption. All measured releases use neutral market standards with zero recent competitors: `True`. Concurrent rival source changes are outside this study.

## Exact commands and evidence

Creation: `python tools/simulator_variant.py create --id crown-extra-hand-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-acquisition-v1 --output docs/codex/threads/contracts/simulators/crown-extra-hand-v1`. Study scripts: `setup.py`; `run.py first`; `run.py remaining`; `analyze_all.py`; `run_verification.py`; `verify.py`; `diagnostics.py`. The initially failing audit and repeated partial audits are distinguished from the final complete audit above. Every runner uses a unique output folder. Exact executable paths/argv/limits:

- [simulation-4522 command](studies/crown-extra-hand-20261024-v1/simulation-4522-command.json) · [config](studies/crown-extra-hand-20261024-v1/simulation-4522.json) · [paired report](studies/crown-extra-hand-20261024-v1/simulation-4522-comparison.md).
- [puzzle-4521 command](studies/crown-extra-hand-20261024-v1/puzzle-4521-command.json) · [config](studies/crown-extra-hand-20261024-v1/puzzle-4521.json) · [paired report](studies/crown-extra-hand-20261024-v1/puzzle-4521-comparison.md).
- [action-4521 command](studies/crown-extra-hand-20261024-v1/action-4521-command.json) · [config](studies/crown-extra-hand-20261024-v1/action-4521.json) · [paired report](studies/crown-extra-hand-20261024-v1/action-4521-comparison.md).
- [simulation-4521 command](studies/crown-extra-hand-20261024-v1/simulation-4521-command.json) · [config](studies/crown-extra-hand-20261024-v1/simulation-4521.json) · [paired report](studies/crown-extra-hand-20261024-v1/simulation-4521-comparison.md).
- [action-4522 command](studies/crown-extra-hand-20261024-v1/action-4522-command.json) · [config](studies/crown-extra-hand-20261024-v1/action-4522.json) · [paired report](studies/crown-extra-hand-20261024-v1/action-4522-comparison.md).
- [puzzle-4522 command](studies/crown-extra-hand-20261024-v1/puzzle-4522-command.json) · [config](studies/crown-extra-hand-20261024-v1/puzzle-4522.json) · [paired report](studies/crown-extra-hand-20261024-v1/puzzle-4522-comparison.md).
- [Replay](studies/crown-extra-hand-20261024-v1/replay-command.json), [prepare cold](studies/crown-extra-hand-20261024-v1/prepare-cold-command.json), [cold](studies/crown-extra-hand-20261024-v1/cold-command.json); corresponding driver logs/exit records and raw runner reports are retained.

## Next work and authority boundaries

CA1b is complete as bounded evidence. Proposed CA1d first: compare a bounded visible-information Beta playtesting/QA stopping policy against the retained extra-hand route, prioritizing Simulation4522; hold purchases/Design/Alpha/redraws/gates/rewards fixed, predeclare legal hands/reserve/budget and test actual Bug discovery/fixing, rent, cash, release timing and Crown access. Separately, CA1c compares existing exact-quote purchases aimed at weakest released Core coverage against unchanged CA1 acquisition, especially the original Puzzle Sound gap. Predeclare selection/reserve/purchase limits and actual acquired/drawn/played exposure. Keep the two interventions separate. Current-source drift requires a fresh source audit and legal starts.

Crown relationship terms, activation and supported predecessor migration remain OPEN. SideStreet P2/P3/P4 retain their separately accepted bounded ACTIVE/TRIAL scope; CP2 reward changes remain held. No user ruling is required to close this study. Canonical Crown relationship adoption still needs those separate design decisions and migration acceptance. No canonical gameplay, player save, commit, push, chat dispatch or release readiness is claimed.
