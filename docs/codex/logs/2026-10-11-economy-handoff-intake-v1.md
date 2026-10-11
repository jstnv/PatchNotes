# Economy handoff intake — 2026-10-11

Read-only intake of the new Contracts, Feature Pools and Banking design-review entries. **No gameplay adoption delta or new approval is supplied by these three handoffs.** Recommendations below retain LOCKED and ACTIVE/TRIAL rules and leave wider balance OPEN.

## Source and review method

- Branch `main`; HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. The shared checkout is dirty: `git status --porcelain` returned 460 entries immediately before this record was created. Existing work, concurrent implementation work and `.codex-godot-temp` were preserved.
- Read `docs/codex/CURRENT_STATE.md`, `docs/codex/TODO.md` and `docs/codex/README.md`; inspected branch, HEAD, status, diff statistics and the relevant design diffs. Consulted `docs/codex/design/publishers-contracts.md`, `feature-store-progression.md` and `economy-banking.md` for authority/status boundaries.
- Read the exact handoffs/findings and retained JSON reports listed below. Used PowerShell `Get-Content -Raw ... | ConvertFrom-Json` to inspect existing run completion, replay success, step counts, telemetry verification and recorded source identities. These are evidence-file checks, **not new simulation, replay, runtime or arithmetic verification**.
- Contracts records frozen source identity `2973b7d4c150a7e668c75c1de6e254a6fe8d1bd30036b6c1e095bb806738e994`. Store006/007 and Banking record `577f46fd83d5a1e2bd017c40eba0b20a543faf9c2301cd6316d48aa394533`. Their findings identify mechanics `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f` and Godot4.7.1. This intake did not recompute those manifests or assert that later canonical edits match them.
- This review record is the only file authored by this intake. No source, shared design, TODO or CURRENT_STATE edits; no simulator run, computer control, commit, push or cross-thread dispatch.

## Contracts — SideStreet take/skip

### Initial v21 intake — historical, superseded below

**Reviewed:** [HANDOFF-SIDESTREET-v1.md](../threads/contracts/HANDOFF-SIDESTREET-v1.md), [FINDINGS-v21-sidestreet-take-skip.md](../threads/contracts/FINDINGS-v21-sidestreet-take-skip.md), and these exact reports under `docs/codex/threads/contracts/sim-v20/`:

- `pair-v3-run-01/run-report.json`: both cases `completed`, 37 Take / 32 Skip commands; Game3 at cycles54/52.
- `pair-v3-sports-1104-take-replay-01/replay-report.json`: `ok=true`, 37 steps, 38 telemetry samples verified.
- `pair-v3-sports-1104-skip-replay-01/replay-report.json`: `ok=true`, 32 steps, 33 telemetry samples verified.

The finding retains failed plumbing/ineligible prefixes and only one eligible Sports/1104 pair from the declared two-seed search. Take earned $1,125 SideStreet and was $642.27 ahead at shared cycle52, but delayed Game3 two cycles and reduced its later Crown receipt/Promotion. Starwave became available but was not accepted. Game3 sales had not settled. These observations do not establish a generally superior choice, debt rescue or final payout balance.

The initial v21 recommendation was to retain current rules and consider an additional legal route plus Game3 settlement continuation. **V22 below now supplies that bounded extension; this earlier recommendation is not outstanding work.** No payout, cap, gate or Promotion change was recommended for adoption from v21.

### Current v22 intake — additional review later on 2026-10-11

Read the fresh TODO entry, [HANDOFF-SIDESTREET-v2.md](../threads/contracts/HANDOFF-SIDESTREET-v2.md) and [FINDINGS-v22-sidestreet-postsettlement.md](../threads/contracts/FINDINGS-v22-sidestreet-postsettlement.md). Read existing reports without rerunning them, under `docs/codex/threads/contracts/sim-v20/`:

- `study-v4-sports-1104-take-v4-replay-01/replay-report.json`, `study-v4-sports-1104-skip-v4-replay-01/replay-report.json`, `pair-v6-take-replay-01/replay-report.json`, `pair-v6-skip-replay-01/replay-report.json`: all `ok=true`, telemetry verified; 64/59/64/59 steps and65/60/65/60 samples.
- `study-v4-run-01/run-report.json`: overall `ok=false`, retaining the separate access-probe rejection. Its two successful paired arms are established by the finding and exact replay reports; do not describe the whole mixed run as passing.
- `pair-v6-run-01/run-report.json`: `ok=true`; both arms complete Game4, Take64 commands/cycle72 and Skip59 commands/cycle70.
- `study-v4-4417-reduction-02/reduction-run.json`: `ok=true`, fresh-process confirmation true; original23 commands reduce to20 by removing three prefix commands at a restorable Studio boundary. The retained rejection is “The run calendar cannot advance safely.” This is a reproduced legal rent-affordability block, not a newly found simulator defect or global-minimum reproducer. The finding reports cash$0 and$80 original rent overdue at cycle12; the first reduction attempt's missing Godot flag is retained separately as setup failure.

V22 keeps two distinct source strata at the same Git HEAD:

| Stratum | Mechanics identity | Frozen source identity |
|---|---|---|
| V4 Sports/1104 | `13980fdeb9efabaeb070c8dddddcd8137982e3e073aa43ab87f7fdd1a57c4c4f` | `8df0a86961a062e6b9f98a87701b9d67a0df05b1b966d6756ea565db2004cdae` |
| V6 Sports/1106 | `62cfd4f1686a6cc6302616d98aab421f2db511971fc5655cf5b6d9e743f612c4` | `7d4b78b85fdbe6ebc9dd1a976d590c77ec833c09481e0c4c26ca3933661a1aae` |

Concurrent Studio Traits/checkpoint changes separate these bytes. The source fence rejected the old checkpoint identity before the v6 pair was prepared against its own prefix. Compare Take/Skip within each source; neither a cross-source dollar average nor checkpoint equivalence follows. The finding retains Adventure/1104 and Sports/1105 access misses, Sports/4417 rent rejection, and successful Sports/1106 eligibility. This intake read their summarized finding and reduction record, not every prefix tape.

Both eligible pairs continue through Game3 settlements to Game4. Take earns$1,125 SideStreet and makes Starwave available, while Games3–4 launch two cycles later. At shared cycle70, Take minus Skip is+$418.50 on v4 and+$992.14 on v6. V4 has lower Crown receipt/Promotion and$125.87 lower equal-age Game3 settled sales; v6 reaches the same Crown cap/Promotion and equal same-age Game3 sales. Game3 titles have at least two actual settlement boundaries by the compared later cycles; the finding expressly does not claim separately audited amounts for their first two individual title payments. Neither arm accepts Starwave, accrues paired arrears or settles Game4. Common-calendar cash still compares different project progress.

**Current recommendation: retain current behavior and resolve this bounded strategic review at its measured scope when that ruling is recorded.** Final publisher balance remains OPEN; this intake grants no new approval or task closure. Do not commission the already-completed Game3 post-settlement extension again. Any optional further study should pose a new cross-specialty, actual low-cash or player-understanding question with predeclared bounds. No gameplay, UI, payout, cap, gate or Promotion adoption delta exists; C5/export acceptance remains separate.

## Feature Pools — Handoffs006–007

**Reviewed:** the historical [Handoff006](../../../patch-notes/design-logs/feature-pools/handoff-006-delay-admission-design-review.md) and [Study006 finding](../../../patch-notes/design-logs/feature-pools/experiment-006-delay-admission-2026-10-11/FINDING.md); then the freshly updated TODO entry, [current Handoff007](../../../patch-notes/design-logs/feature-pools/handoff-007-postsettlement-store-review.md) and [Study007 finding](../../../patch-notes/design-logs/feature-pools/experiment-007-postsettlement-admission-2026-10-11/FINDING.md).

Existing JSON checks under `docs/codex/threads/feature-pools/sims/study006/`:

- `pair-4417-run-01/run-report.json` and `pair-90210-run-01/run-report.json`: four completed arms, 20 Research / 18 Defer commands per seed.
- `replay-4417-research-01/replay-report.json`, `replay-4417-defer-01/replay-report.json`, `replay-90210-research-01/replay-report.json`, `replay-90210-defer-01/replay-report.json`: all `ok=true`, telemetry verified; 20/18/20/18 steps and21/19/21/19 samples.

Existing JSON checks under `docs/codex/threads/feature-pools/sims/study007/`:

- `stageA-4417-run-01/run-report.json`, `stageA-90210-run-01/run-report.json`, `stageB-4417-run-01/run-report.json`, `stageB-90210-run-01/run-report.json`: eight completed arms. StageA uses38 Research /36 Defer commands; StageB uses20 Research /18 Defer commands per seed. All four bundles record the same frozen source identity above.
- `stageA-4417-defer-replay-01/replay-report.json`, `stageA-90210-defer-replay-01/replay-report.json`, `stageB-4417-research-replay-01/replay-report.json`, `stageB-90210-research-replay-01/replay-report.json`: all `ok=true`, telemetry verified; 36/36/20/20 steps. The other four arms were not independently replayed in that study.
- `stageA-4417-comparison-01/comparison.json`, `stageA-90210-comparison-01/comparison.json`, `stageB-4417-comparison-01/comparison.json`, `stageB-90210-comparison-01/comparison.json` exist and parse. This intake did not rerun the paired reporter or independently re-audit all comparison fields; the finding records its four successful checks.

**Study007 supersedes the after-settlement follow-up recommended during the initial Study006 intake. Do not repeat that recommendation as outstanding work.** StageA continued early purchase/deferral through Game3. StageB paired later purchase/continued deferral from each deferred Game3 Studio after positive Game2 settlement. The stages have different origins; they are not one identical-state counterfactual. Actual second-title settlements were $2,405.59/$1,853.14; only seed4417's second Review exceeded its first. Later familiarity reduced observed acquisition quotes by $170 in both lineages. All late acquisitions succeeded without blocks/arrears; Game4 Review improved in one seed and fell in the other. Its sales were unsettled at the endpoint.

**Recommendation: record retention of current queue/payment rules at their existing statuses and defer additional broad simulations.** This is a recommendation for the design ruling, not a new approval or closure by this intake. The remaining choice is that retention ruling versus a separately declared wider study of other Genres, genuine $5,500 starts, synergy policies or parent-chain reserves. Human Store comprehension remains separate: observed confusion and exact proposed copy/layout are needed before a UI handoff. No mandatory reserve, universal buying trigger, price, duration or UI delta follows from these studies.

## Banking — education grace boundary

**Reviewed:** [HANDOFF-EDUCATION-GRACE-v1.md](../threads/banking-system/HANDOFF-EDUCATION-GRACE-v1.md), [2026-10-11-education-grace-finding-v1.md](../threads/banking-system/2026-10-11-education-grace-finding-v1.md), and these exact reports under `docs/codex/threads/banking-system/simulations/`:

- `education-grace-run-v1/run-report.json`: six completed cases, each72 accepted commands/three releases, ending cycle39.
- `education-grace-replay-control-4417-v1/replay-report.json`, `education-grace-replay-dropout-4417-v1/replay-report.json`, `education-grace-replay-graduate-4417-v1/replay-report.json`: all `ok=true`, each72 steps/73 verified telemetry samples.

The finding observes first dues at cycle26 and seven paid dues through cycle38, with no arrears/block. The policy made no Store purchases, Bank loans or payroll commitments; 89 of96 dues were outside coverage. Graduate's $1,679.11 lower cycle39 cash versus no-trait includes distinct legal startup receipts and scheduled payments. Same-seed cross-trait traces are not identical-state counterfactuals, and endpoint cash excludes remaining principal when assessing wealth.

**Recommendation: retain existing education/Bank terms and leave a spending-sensitive study as optional DESIGN work.** If pressure under paid acquisition is the design objective, predeclare a legal paid-Feature/low-cash Graduate route; compare no loan with an actually eligible $500/24-month quote from the same within-trait Studio checkpoint. The proposed amount/term is an experimental case only. Retain rejected quotes and missing eligible routes, then measure original due/partial history, education reserve, debt, cash lows, credit and first block through early education dues. Do not infer an arrears target or change LOCKED terms/ACTIVE/TRIAL credit from the existing six-case screen. Exported late/partial debt and Graduate presentation acceptance remain separate.

## Disposition

All three packets have **zero proposed canonical gameplay delta**. They can inform a recorded design ruling; none is an implementation adoption task. Store Study007 already answers the narrower delayed-admission question that was open in006; Contracts v22 supersedes the earlier Game3 settlement/additional-route recommendation from v21. Other optional expansions need a new question and explicit experimental bounds, retaining OPEN design status. No evidence here establishes final balance or release readiness.

### Closeout refresh by PN Implementation

The TODO changed again during this work. Its Banking entry now assigns an eligible-quote follow-up to the Banking design thread and explicitly gives PN Implementation no action. Read [HANDOFF-SPENDING-BANK-v1](../threads/banking-system/HANDOFF-SPENDING-BANK-v1.md): its two attempted quotes remain ineligible; the observation-only private variant is not an adoption candidate. This closeout classified that handoff but did not rerun or independently audit its newer numerical results. The separately owned study supersedes the earlier optional recommendation above as the current work assignment.

The Store entry now says human testing is user-deferred until a later game stage. [Proposal008](../../../patch-notes/design-logs/feature-pools/proposal-008-pool-state-language.md) and its linked copy audit remain OPEN design work with no approved implementation task. Preserve those assignments and decisions; do not start duplicate simulations or computer control from this intake.
