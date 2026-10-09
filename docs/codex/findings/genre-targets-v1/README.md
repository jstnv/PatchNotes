# Genre target screen — 2026-10-08

## Result

The proposed Genre-specific base rating improves all eight Genre means in this bounded screen, but does not establish equal difficulty. Keep 33 as the average target (132 total); retain distinct distributions as candidates. Do not lock the table or implement it from this evidence alone.

| Genre | Current mean Review | Proposed mean Review | Moderated mean Review | Proposed mean production |
|---|---:|---:|---:|---:|
| Action | 6.08 | 6.58 | 6.38 | 7.04 |
| Adventure | 4.05 | 4.95 | 4.58 | 5.82 |
| Role-Playing | 4.36 | 5.12 | 4.84 | 5.88 |
| Strategy | 4.06 | 5.24 | 4.65 | 6.36 |
| Simulation | 3.71 | 4.63 | 4.31 | 6.11 |
| Puzzle | 3.79 | 4.98 | 4.34 | 5.82 |
| Sports | 4.44 | 5.03 | 4.86 | 6.32 |
| Racing | 4.82 | 5.81 | 5.32 | 6.83 |

Each row contains 18 first releases: three declared seeds, three policies, two schedules. Means describe this equal-weight sample, not expected human outcomes. Candidate Reviews are recomputed on the same native scores, Scope, Bugs and variance.

## Method and scope

- Current dirty `main` at `91ce539978b87ac0a6efe3a1e028cae5f1360f19`; source hashes in `source-sha256.json`. No production source, data, or scoring function changed by this study.
- 144 native first-release routes: eight matching project Genre/specialty pairs, seeds 1104/2208/3312, ordinary/synergy/target-deficit policies. Genuine current no-trait $5,700 startup, $500 rent, no purchases, loans, employees or Contracts.
- Early budgets: 3 Design + 4 Alpha + 4 Beta hands. Slow budgets: 5 + 6 + 6. Normal departure costs one additional cycle; affordability can curtail budgets. All 144 launched and their native finance ledgers validated.
- Existing visible-card heuristics choose legal hands and redraws; finite Features, native priorities/specialization, Bugs, Scope, costs and phase transitions remain live. Raw traces include draws, selections, redraws, production, transactions and failures/curtailment.
- The target-deficit extension changes the analysis policy's Core targets to 1.25 times the proposed targets. It affects visible-card selection/redraws and initial Alpha priorities; no free midphase priority changes, hidden-information search or optimal-play claim. It does not uniformly outperform the existing synergy policy: proposed early/slow means are 4.02/6.44 versus 4.39/6.61 for synergy.
- Comparison A is the current equal-33 production formula followed by Genre Fit. B uses the proposed integer targets below with the same normalized mean/deviation formula and removes the separate Genre Fit multiplier. C halves each exact target's distance from 33. A fourth arm uses unrounded current Genre percentages times 132 to isolate rounding.
- Scope, Bugs, variance and final one-decimal rounding remain identical within each fixed-action comparison. Candidate ratings do not feed back into native sales, publisher unlocks or subsequent play. No later-game economy conclusion follows.

Core order is Graphics / Sound / Technology / Design:

| Genre | Proposed targets |
|---|---|
| Action | 40 / 26 / 40 / 26 |
| Adventure | 33 / 26 / 20 / 53 |
| Role-Playing | 20 / 26 / 40 / 46 |
| Strategy | 20 / 13 / 53 / 46 |
| Simulation | 20 / 20 / 59 / 33 |
| Puzzle | 20 / 13 / 40 / 59 |
| Sports | 33 / 33 / 40 / 26 |
| Racing | 40 / 33 / 46 / 13 |

## Interpretation

1. Removing the conflict between equal-score production and uneven Genre Fit helps all eight sampled Genres. The moderated targets score lower across all eight means and do not eliminate the gap. This is not evidence to flatten Genre identity.
2. Action remains ahead: proposed mean Review 6.58 versus Simulation 4.63. Even before Scope/Bugs/variance, proposed production means span 5.82–7.04. Starting roster composition and visible-choice policies matter alongside target values.
3. Only one route meets all four proposed 8.0 production targets; this is not proof they are unreachable. Partial target completion, roster Scope below 30, finite supply, Bug outcomes, and schedule choice constrain this starter-only sample. Optional buying, mixed specialties and experienced play are untested.
4. Integer versus exact-percentage targets change final Review by at most 0.1 in this sample. Rounding is a smaller issue than roster/strategy effects.
5. A static cross-Genre re-score gives a higher Review for another Genre in 77/144 routes. This is a diagnostic only: it is not a legal late Genre switch or a matched alternate-Genre playthrough.
6. A target is a required score, not a per-point reward weight. All four normalized categories contribute equally. A low target is easier to fill, so high-priority categories require more production rather than making each raw point more valuable. Keep this distinction explicit in the eventual design.
7. The 1.25 cap does not prevent reaching a target; it caps credit for excess production. At exact targets the proposed production rating is 8.0; at 1.25 times each target it is 10.0. Simulation's 59 Technology target requires 74 integer Technology for full capped credit, but this screen does not prove a supply ceiling.

Recommendation: retain the Genre-dependent base-rating direction and 132 total. Before approving exact values, compare bounded affordable starter-purchase policies and a shared-owned-pool control to separate roster disadvantage from rating targets; test at least one subsequent release with candidate ratings feeding the economy in an isolated analysis model. Keep numeric targets OPEN.

## Verification and reproduction

Both native processes exited 0. No script errors; the environment's root-certificate warning is the sole ERROR line. Native UI validation emits expected invalid-selection warnings during refresh; these are recorded in full logs. Python independently reproduced every native production and final Review, audited finance cash chains, legal selected-hand membership/cost/cycles, and checked all target anchors: **15,144 checks passed**.

From repository root in PowerShell, using isolated APPDATA/LOCALAPPDATA directories:

```powershell
$env:APPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-screen/appdata'
$env:LOCALAPPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-screen/local'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path patch-notes --script res://analysis/genre_targets_v1.gd *> docs/codex/findings/genre-targets-v1/native.log
$env:APPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-screen-adaptive/appdata'
$env:LOCALAPPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre-screen-adaptive/local'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path patch-notes --script res://analysis/genre_targets_v1.gd -- --adaptive=1 *> docs/codex/findings/genre-targets-v1/adaptive.log
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/genre-targets-v1/analyze.py > docs/codex/findings/genre-targets-v1/analysis.log
```

`routes.json.gz` and `adaptive.json.gz` preserve raw traces losslessly. Analysis accepts raw or compressed traces; compression is roundtrip-checked. `counterfactuals.json` contains compact route results, `summary.json` aggregates and target anchors. Run identities can vary between captures; action RNG streams are seeded.
