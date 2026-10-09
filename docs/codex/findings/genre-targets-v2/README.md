# Genre starter purchases and shared-card controls — 2026-10-08

## Result

Keep the proposed 132-total Genre targets as trial candidates. These results do not support flattening Genre distributions or singling out Action for a rating nerf. Starting-card access explains a substantial part of the initial gap; cash and unfinished QA become important after buying.

192 new native first-release routes passed. Reused 96 ordinary/synergy no-buy routes from v1 after verifying matching gameplay script, scene and data hashes. The prior target-deficit extension is excluded from this paired comparison.

| Genre | No purchases | Starter-purchase policy | Starting purchase spend | Available roster Scope after buying |
|---|---:|---:|---:|---:|
| Action | 6.475 | 6.617 | $1,050 | 33 |
| Adventure | 4.975 | 6.167 | $1,350 | 32 |
| Role-Playing | 5.200 | 5.767 | $1,350 | 33 |
| Strategy | 5.417 | 6.400 | $1,350 | 32 |
| Simulation | 4.833 | 6.100 | $1,350 | 30 |
| Puzzle | 5.100 | 5.883 | $1,350 | 33 |
| Sports | 4.975 | 6.117 | $1,350 | 30 |
| Racing | 5.625 | 6.092 | $1,500 | 32 |

Reviews above use the proposed formula, with 12 equally weighted routes per cell. Exact differences between highest/lowest Genre means shrink from approximately1.642 to0.850. These are sample means, not confidence estimates or human balance targets.

## Declared experiment

- Matching-specialty purchase arm: eight Genres × ordinary/synergy × early/slow × seeds1104/2208/3312 =96 routes. Genuine no-trait $5,700 startup, $500 rent, no loans/employees/Contracts. Buy toward33 available roster Scope with a $1,500 total cap, descending Scope per dollar and stable-ID tie break. Skip purchases exceeding the cap; stop when the target is reached. All purchases use native live quotes and zero-cycle starter transactions.
- This is a bounded shopping policy, not an approved reserve/spending rule or optimal shopper. It does not equalize purchased Scope or spending. Purchased IDs and exact quotes/cash appear in raw traces and `summary.json` paired records.
- Shared controls: one legal Action-specialty roster and one legal Adventure-specialty roster, each used across eight independently selected project Genres × two schedules × three seeds =96 routes. No purchases. Ordinary priorities and a fixed33 analysis selection target keep choices independent of project Genre. No free cards or extra cash granted.
- Early budgets3 Design/4 Alpha/4 Beta; slow5/6/6. Native productive costs and affordability apply; failed work curtails the schedule, followed by native launch. Every attempted route is retained, including failures; all192 actually launched and validated their native finance ledgers.
- Candidate formula remains an external fixed-action recalculation: category score/Genre target, cap1.25, normalized mean minus0.5 population deviation, times8. Remove separate Genre Fit; preserve Scope/Bugs/variance/rounding. The live game still uses its current formula. No candidate rating feeds sales or later-release decisions.

## Findings

1. Purchases lift all eight pooled means. Simulation's average completed Scope factor rises from0.747 to0.956, while its proposed production rating rises6.352→7.317. Action Scope rises0.939→0.992, with production6.871→6.971. Thus both playable Scope and Core supply contribute; this is not exclusively a rating-formula effect.
2. The cost tradeoff is substantial. All48 slow purchase routes curtailed productive work, versus0/48 paired no-buy controls. All48 early purchase routes completed their budgets. Native Bug multipliers also decline with the purchase policy, consistent with more production and less available cleanup; no hidden-Bug information guided decisions.
3. Paired Review gains by cohort: ordinary early+1.400; ordinary slow+0.000; synergy early+1.4875; synergy slow+0.3833. Reviews fell in13/24 ordinary slow and9/24 synergy slow routes, plus2/24 synergy early routes. Buying is not a universal improvement.
4. Every shared-control group passed exact equality of owned IDs, draws/redraws/selections/priorities, final Core scores, Scope factor, Bugs factor, variance, cycles and final cash across all eight project Genres. Action is not consistently best under identical output. With the shared Action roster, Puzzle averaged6.267, Strategy6.233, Simulation6.183 and Action5.900. With the shared Adventure roster, Puzzle averaged5.067, Strategy5.050, Adventure4.717 and Action4.300. These fixed-policy controls are intentionally not Genre-adapted optimal strategies.
5. Both shared rosters give the same ranking conclusion, but neither is a neutral universal card pool. They demonstrate that Action's initial advantage is not an unconditional benefit in the formula; they do not prove identical difficulty across all rosters or Genres.

**Recommendation:** preserve the candidate Genre identities and average33 target. Evaluate the table as an ACTIVE/TRIAL candidate for eventual implementation rather than tune individual Genre difficulty from starter-only averages. Before final balance approval, check subsequent releases with candidate ratings feeding native economic outcomes in an isolated model. Starter affordability/supply and Genre targets remain separate design decisions; no roster, price, Scope requirement or rating change is authorized by these findings.

## Verification and limits

- **37,504 independent checks passed**: native rating reconstruction; purchase prices/ownership/zero cycles/cap; selected-card multiplicity and ownership; independently derived printed Feature play costs; productive cycles; finance transaction cash chains; exact shared-control matching. Full summaries and route-level pairs are in `summary.json`; compact candidate results are in `counterfactuals.json`.
- Three final Godot runs exit0; only known root-certificate ERROR. Expected UI invalid-selection refresh warnings retained. Initial analysis-harness parse failure was fixed by explicitly typing a bool; `parse-attempt.log` preserves that failed attempt. No gameplay repair was needed.
- Source manifests captured at analysis time match each other and all v1 runtime hashes. They describe the dirty integrated build on `main` at `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, not just committed HEAD. No production file was edited by this task.
- Independent review checked policy isolation, purchase legality, cohort matching and interpretation. The target formula gives equal anchors rather than equal per-point rewards or exact optimal allocations; higher targets require more production. Numeric targets remain OPEN.
- First releases only, three seeds, deterministic heuristic policies, matching specialties for purchase arms. Different purchases, Traits, future Store research, later content and economic feedback remain untested. No confidence interval, human-play validation, final balance, commit/push or export claim.

## Reproduction

Use Godot4.7.1 and the same source manifest. From repo root, run each arm with its own isolated APPDATA/LOCALAPPDATA profile:

```powershell
$env:APPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre2-buy/appdata'
$env:LOCALAPPDATA='C:/Users/64jus/Downloads/Patch Notes Design Folder/genre2-buy/local'
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path patch-notes --script res://analysis/genre_targets_v2.gd -- --arm=buy *> docs/codex/findings/genre-targets-v2/buy.log
```

Repeat with `--arm=action` and `--arm=adventure`, changing profile and log suffix accordingly. Then run:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/genre-targets-v2/analyze.py --snapshot
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/findings/genre-targets-v2/analyze.py > docs/codex/findings/genre-targets-v2/analysis.log
```

Native raw traces are compressed losslessly into `buy.json.gz`, `action.json.gz`, `adventure.json.gz`; analyzer accepts raw or compressed files. No player saves are used. IDs may vary; action RNG streams are seeded.
