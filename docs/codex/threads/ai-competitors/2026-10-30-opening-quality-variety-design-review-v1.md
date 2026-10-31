# Opening rival quality and variety — independent design review, 2026-10-30

**Status: DESIGN review / OPEN recommendations.** This read-only review covers private candidate evidence while the PN Implementation thread is still working. It approves no Review target, Market coefficient, Genre quota, gameplay adoption or release. The player's Review playtests remain user-owned.

## Source and limits

- Shared `main` HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100` was dirty with concurrent documentation, UI, simulator and rival edits; those edits and `.codex-godot-temp` were preserved. Canonical gameplay still has the two-rival trial. Current TODO marks the eight-studio rollout **IN PROGRESS** in a private candidate.
- Historical cohort evidence: [seed 5607](sims/quality-shared-5607-20261030-v12/cohort.json) and [seed 5613](sims/quality-shared-5613-20261030-v12/cohort.json), both private source identity `0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99`, with [sealed certificate index](sims/quality-seal-20261030-v12/seal.json). These are two selected, legal, source-matched 1977–79 shared-world careers; they are not a random population estimate.
- First live fixture: [v13b result](sims/quality-scope-green-20261030-v13b/result.json) and [16-cycle trace](sims/quality-scope-green-20261030-v13b/live.json), private source `0fa97d585cd860d1ea0036c105ca1323c10866c8497f6137bcd56cac72e0c580`. Its script drives two legal player releases solely to advance the eight-owner world and checks Studio-only Continue; it is **not** a player-Review challenge study. It imports a preceding certified fixture through a narrow test-only path; production new-save loading does not permit that override.
- [v12b failure](sims/quality-scope-red-20261030-v12b/live.json) is retained: seven owners reached exhausted, under-Scope Alpha by c16. V13b has no such issue through c16, but this does not prove later liveness. The two revisions have different source identities; these observations are diagnostic, not a matched causal estimate from equal seeds alone.

## What the candidate actually produces

| Measure | Seed 5607 | Seed 5613 |
| --- | ---: | ---: |
| Historical releases by January 1980 | 24; exactly 3 per rival | 24; exactly 3 per rival |
| First release Review | 6.5–6.6 | 6.5–6.7 |
| Later historical Review | 9.0–9.3 | 8.8–9.6 |
| Historical 8.0+ titles | 16; all 8 studios represented | 16; all 8 studios represented |
| Under-required-Scope / Buggy historical releases | 0 / 0 | 0 / 0 |
| January owned future Scope | 35 per rival | 35 per rival |

The candidate clears the user's earlier desire for an 8+ title from every rival. It exceeds the later legal-opening review's **provisional** 3–5 historical 8+ screen; that screen was a desired shape, not a scripted quota. The near-identical first and later Review bands follow a planner that aims for 6.5 on the first project and 8.75 thereafter. This is an inference from the [private policy](simulators/rival-quality-1977-20261030-v13/project/scripts/market/rival_career_policy.gd) and observed results; there is no result clamp. The first actual Core vector becomes the next historical benchmark under this candidate. For seed 5607 those eight first-Core totals range 107–131 against original per-Genre total 132, which may help later titles score higher. The effect needs a source-matched benchmark counterfactual before changing the transform.

The v13b live trace publishes **eight 1980 titles by player cycle 9**, one per rival: seven Reviews are 8.5 and one is 8.8. Five are Sports, with Action, Adventure and Simulation supplying the other three; six Themes appear. At c16 the trace reports no exhausted-under-Scope error and all eight owners remain solvent. That is a promising opening challenge, but it shows a **Sports attractor** in the current funded four-Core Genre planner and synchronized Review outcomes. The candidate's existing 12-cycle Market rule implies that a hypothetical new Sports title with a previously unused Theme at c10 would quote the 7,000bp sales-factor floor from five recent Sports titles (`10,000 − 5 × 600`); this is a formula inference, **not** an observed sale or approved change. The trace covers only one certified opening and 16 cycles. Frozen history remains separate from the eight active Market facts in this fixture.

## Design recommendation and next evidence gate

1. **Finish legal liveness before tuning.** The implementation thread should complete its already planned longer live campaign with real rival finance, second/third 1980 releases, exact cold Continue, save/input CPU and rejected blocked cases. A first-release-only pass does not resolve the v12b failure mode. No score floor, under-Scope launch or speculative next-month authority is acceptable recovery.
2. **Retain strong Reviews provisionally, but measure spread.** Do not lower Review targets or alter Market coefficients solely because 16 historical titles reach 8+. The user's one-8+-per-rival direction and the provisional 3–5 screen point to different desired densities; the current candidate is a concrete comparison for human Market review. Record each studio's Review, Core vector, Scope, Bugs, cash/debt and release date through at least two post-start projects. Distinct careers should emerge from legal resources, available cards and decisions, not injected scores or a Genre-specific exception beyond Racing.
3. **Test Market-aware Genre value as the next isolated policy arm if Sports crowding persists.** Preserve the funded four-Core fit gate and first-Genre founding coverage. At later project Begins, compare the current attainable-Review/hand-cost planner with one that also uses the *current legal Genre/Theme sales quote* and dated crowding when choosing among funded close-fit Genres. Keep the active Market quote separate from frozen historical Reviews. Measure Review, actual units/net receipts, Genre/Theme mix, release cadence, cash/debt, CPU and replay under identical legal starts. This is **OPEN** design, not authorization to add a diversity quota or reduce Sports ratings.

**Stop condition for this review:** no additional private run here while another thread is revising the same candidate. Reassess against its final source identity and longer campaign evidence. The user will judge player challenge in the actual game.

## Read-only checks performed

From repo root, PowerShell decoded the retained evidence with these read-only commands (abbreviated output selectors shown exactly):

```powershell
$x=Get-Content docs/codex/threads/ai-competitors/sims/quality-shared-5607-20261030-v12/cohort.json -Raw | ConvertFrom-Json
$x.rows | ForEach-Object { $_.releases | ForEach-Object { $_.metadata.review.final_review } }
$x=Get-Content docs/codex/threads/ai-competitors/sims/quality-shared-5613-20261030-v12/cohort.json -Raw | ConvertFrom-Json
$x.rows | ForEach-Object { $_.releases | ForEach-Object { $_.metadata.review.final_review } }
$x=Get-Content docs/codex/threads/ai-competitors/sims/quality-scope-green-20261030-v13b/live.json -Raw | ConvertFrom-Json
$x.reports | ForEach-Object { $_.new_releases } | Select-Object release_cycle,studio_id,genre,theme,review_tenths
Get-Content docs/codex/threads/ai-competitors/sims/quality-scope-green-20261030-v13b/result.json -Raw
Get-Content docs/codex/threads/ai-competitors/sims/quality-scope-red-20261030-v12b/result.json -Raw
```

The v13b result exits 0 with no engine errors and `source_unchanged=true`; v12b exits 1. The source, policy, legal design and shared worktree were inspected with `rg`, `Get-Content`, `git branch --show-current`, `git rev-parse HEAD`, `git status --short -uno` and scoped `git diff --stat`. The two new notes and their relative links passed existence/readback and whitespace checks. No simulator run, canonical gameplay edit, TODO edit, commit, push or computer control was performed.
