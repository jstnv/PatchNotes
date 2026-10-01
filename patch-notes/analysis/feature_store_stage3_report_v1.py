"""Render the Stage 3 read-only findings from verified summary outputs."""
from pathlib import Path
import json

OUT=Path(__file__).resolve().parents[1]/'design-logs/feature-store-staged-v1'
d=json.loads((OUT/'stage3_summary_v1.json').read_text())
money=lambda v:f'${v/100:,.2f}'
normal_table=[]
for p,s in d['normal'].items():
    normal_table.append(f"| {p} | {s['n']} | {min(s['ending_cycles'])}–{max(s['ending_cycles'])} | {min(s['releases'])}–{max(s['releases'])} | {money(min(s['end_cash_cents']))}–{money(max(s['end_cash_cents']))} | 0 |")
long_table=[]
for s in d['long_ordinary']:
    if not s['reached']:continue
    long_table.append(f"| {s['year']} | {s['cycle']} | {s['releases_at_boundary'][0]} | {s['first_studio_cycles'][0] if s['first_studio_cycles'] else 'unobserved'} | {money(s['first_studio_spendable_cents'][0]) if s['first_studio_spendable_cents'] else 'unobserved'} | {s['owned_counts'][0]} | {s['played_counts'][0]} |")
loop=d['loop_summary']
text=f'''# Patch Notes — Feature Store Stage 3: era reachability v1

2026-09-29. Read-only current-build analysis; no gameplay, Store data, numerical authority, or calendar rule changed.

## Sources and baseline

User-dispatched Feature Store Test Handoff v1 and full Multi-Era Feature Store Design v1; fresh cumulative authority and execution-queue snapshots in `sources/`; current Godot source at main `608a2c62ab0850cf607f7ff627b042a49b5d2dfb` with the five pre-existing tutorial modifications retained. Parent baseline status passed editor import and all 43 verifiers before simulation. Named local records read: Playable_Game_Lifespan_Trial_v1, Studio_Trait_Post_Integration_Recheck_v1, Current_Integration_Baseline_Status_v1, and current SideStreet/redraw sections of the cumulative authority. Their historical status statements were reconciled against live RunState, phase, sales and card code.

Live origin is January 1980. Thus the proposed literal calendar checkpoints are **96, 240, 480, 720, 960 and 1,104 cycles**, for 1984, 1990, 2000, 2010, 2020 and 2026. Existing 1981–83 Store nodes already have no implemented year gate. This test applies proposed later-year labels only to observed checkpoints.

## Method and limits

Primary sample: four paired seeds under each cautious, ordinary and optimizer-labelled heuristic, **12 policy/seed routes**. Six matched stress routes and one matched long continuation bring the accepted execution count to **19**, covering **373 releases, 389 Contracts and 7,680 central productive cycles**. These totals include shared starting states and overlapping prefixes; they are not 19 independent sampled policies. Replay/smoke executions are excluded. Seeds are 270927000 + 97 × case, cases 0–3. Starter pools have 20/21/22/23 total printed Scope and spend at most $4,000, using the current Store transaction and six free starters. Each first game follows both actual scripted tutorial opportunities, including its single guaranteed redraw. No below-20 pool is mixed into this sample.

After the tutorial, cautious uses 2 Design / 2 Alpha / 1 Beta hands and first visible legal cards; ordinary uses 4/4/3 hands and a visible-card Scope/Core production heuristic; optimizer uses 6/6/5 and a stronger specialization preference. Redraw/changed-priority choices are inherited from the explicitly versioned feature_pair_game3 driver. **The ordinary/optimizer Beta selector reads ProjectState's exact hidden-Bug count when valuing Search versus Debug. Its QA decisions are internal-state-informed, not a faithful first-time player's visible-information policy.** The inherited Review variance input is the fixed verification-roll schedule `(phase seed / 97) % 100`; market snapshot rolls are also disclosed deterministic fixtures. Final Reviews still run through actual scoring, Genre Fit, Bugs and the Review calculator; no final score or high-Review proxy is injected. This small scheduled sample is not a probability estimate over uniformly random Review rolls.

Cases alternate Sound/QA and mixed/Marketing, and cycle action/adventure/strategy Genres. These bundles confound their subchoices and are not an isolated causal comparison of Beta or Sound strategy. The optimizer label describes this heuristic, not an optimal human policy. Human later-game Reviews above 9 remain separate player evidence; these automated policies cannot establish a human ceiling.

Every release is followed by its legally eligible SideStreet offer; first release also completes Ironclad. After Game 2, the route attempts at most one affordable, parent-unlocked live Store node after each release, sorted by quoted price then ID, while preserving a fixed **$1,500 analysis liquidity reserve**. This holdback is neither an expense nor an approved gameplay rule. Current bills, payroll, employees, traits and platform selection do not exist and add no fabricated action or payment. Campaigns are off. Later Store play prices remain unresolved; the current source's zero charge for these existing nodes is observed, not approved here.

All actions use instantiated Godot scenes, real candidate construction, legal selections, finite exhaustion, actual scoring/Review, real exact-cent cash and central productive-cycle transactions. Godot RNG streams and snapshot inputs are explicitly controlled. Contract initial pools are rebuilt once through the real pure weighted candidate builder after assigning its seed, then published; this is initial-deal instrumentation, not a user redraw or a native mouse interaction. New assertions verify cash/date/redraw/Core/Scope/exhaustion are unchanged by that rebuild. Earlier production cohorts predate only this observation field; their identical action algorithm was already seeded. A normalized replay check matches the original two-release route exactly after aliasing random immutable release UUIDs and ignoring the added observation field. The 1,115-cycle extension also reproduces every one of the primary route's first 248 cycle snapshots exactly.

An audit found unseeded Design finalization variance in the preliminary empty-release/priority stress helpers. Both were corrected in the analysis harness and **all six accepted stress routes were rerun with explicit Design finalization seeds**. Preliminary stress outputs are superseded. That gap affected hidden-Bug trace reproducibility, not the zero-production cash-loop finding. An additional case-0 replay of each final stress arm matches its full trace exactly after aliasing random immutable release UUIDs: 1,104 cycles for the priority route and 97 cycles/30 releases for the minimal route. Thus all four recorded replay checks pass. The final normal, stress and continuation commands all exit 0 without script/parse errors. The summary checks exact cash identity, consecutive central cycles, finite production Features, redraw bounds, passive initial Contract setup/dismissal and payouts once. Independent source review confirms the rebuilt initial Contract pool changes no authoritative state.

This is **headless scene-control evidence**, not graphical input or human playtesting. Normal runs stop after completing the release/Contract/Store block crossing the 240-cycle cap, so they may finish a few cycles beyond it. Unreached later checkpoints are right-censored, not proof of impossibility.

## Normal bounded production

| Policy | Routes | Final cycles | Releases per route | Final actual cash | Blocked actions |
| --- | ---: | ---: | ---: | ---: | ---: |
{chr(10).join(normal_table)}

All 12 reached 1984 and 1990; none encountered an unaffordable or invalid selected action. Their 2000–2026 opportunities were unmeasured at this cap. They completed 338 all-Pass production hands in total (8 cautious, 105 ordinary, 225 optimizer), with real renewable definitions and normal one-cycle commits. Thus finite Feature exhaustion did not itself end the available loop.

At the first actual Studio opportunity after 1984, cash less the disclosed $1,500 reserve ranged **$5,415.85–$17,862.38**. After 1990 it ranged **$33,832.31–$51,475.50**. These are spendable already-settled balances, not projected sales. Studio opportunities include a release dashboard or a committed Contract dismissal; actual Store browse visits are separately retained. A calendar boundary reached during development is not itself a Store visit.

Normal cash contains several real sources: older and new-game settled sales, actual Contract payout, and any **$1,000 Playtest Rival Games Beta reward**. Cautious routes earned $8,000–$14,000 from that Beta source; ordinary and optimizer primary cases earned zero from it. The complete exact-cent identity is verified per route: $5,500 minus successful acquisitions minus paid Feature play costs plus Beta direct reward plus exact Contract payouts plus settled sales equals final cash, with **zero residual cents**. Pending entitlement is never spendable until settled.

The month-boundary CSV includes a cash/calendar row with empty release-specific fields before a run's first launch; later boundaries retain one row per release. A gzip read-back check verifies coverage of all **{d['month_boundary_export_coverage']['even_boundaries']:,} completed even-cycle boundaries** across all 19 accepted route executions, including **{d['month_boundary_export_coverage']['pre_release_cash_calendar_rows']} pre-release cash/calendar rows**. Exported cash, year and release count match the raw cycle snapshots. Evidence: `stage3_month_boundary_coverage_v1.json`.

## One continued ordinary route

One matched ordinary case-0 continuation goes beyond the primary cap. It is not an independent extra first-game seed and provides only one sample for later normal-era reachability.

| Year | Cycle | Releases at boundary | First later Studio cycle | Cash after reserve at Studio | Owned existing nodes | Distinct production-played Features |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
{chr(10).join(long_table) if long_table else '| Pending | — | — | — | — | — | — |'}

Owned and played counts refer only to the current implemented catalog. Every owned current card is eligible in its printed phase of a later project; no synthetic platform is silently granted. The 46 proposed cards remain absent, so this is not proof of their effects, access chains, platform support, prices, or ROI.

## Two explicit degenerate route tests

**Alternating priorities:** three matched ordinary first games then begin Game 2. The actual Design priority commit alternates 30/20/25/25 and 25/25/25/25, each a changed legal allocation, until cycle 1,104. All three reach every literal checkpoint, without adding a cash cost or free Wait action. Old sales finish and become dormant; cash does not compound indefinitely from the priority changes. Game 2 has no production hands, then uses existing phase transitions, the under-Scope confirmation and launch to return to Studio at 1,104. The first subsequent Studio observation for every crossed era in these routes is therefore cycle 1,104, not its mid-Design boundary. This demonstrates that elapsed date alone can be manufactured through legal no-cash actions; it does not measure enjoyable pacing or later-card balance.

**Empty-release/SideStreet loop:** three cautious first-game starts continue with zero production/QA/Marketing hands on later games. Each new Pre-Development costs one real cycle; current phase transitions and confirmed under-Scope launch cost zero; the new release grants its distinct SideStreet entitlement; two actual Contract hands cost two more cycles. The **{loop['n']} measured post-first-game segments all cost three cycles** and each produced positive direct Contract cash: **{money(loop['payout_min_cents'])}–{money(loop['payout_max_cents'])}, median {money(loop['payout_median_cents'])}**, after excluding *all* sales settlements. No callback or offer is paid twice. The three runs reach cycle 97 with 30 releases each. Empty releases have Scope 0 and production rating 0, but existing variance sometimes yields a small positive Review, so some also earn sales. Raw segment rows separate the current empty release's settled cash from older-release settlement and from the exact SideStreet payout. Do not attribute the entire balance increase to the Contract.

This is a profitable release-grinding loop under today's absent-expense model. Raising late Feature prices would not resolve its cause. SideStreet cannot be repeated forever without new release IDs; the repeatable economic route is the legally empty new game plus its distinct offer.

## Illustrative release milestones, not a proposed lock

Both alternatives are labels applied to the same unchanged primary traces, with no inserted cards or changed player decisions. The matched route-weighted median inter-release cadence is **{d['cadence_median']} cycles**. SHORT uses one release step after the first: **2/3/4/5/6/7 releases** for the six later tiers. All 12 reach its last tier; median access cycles are 34/52/70/88/106/124, with final-tier range 61–173.

LONG uses a stride of ceil(96 / {d['cadence_median']}) = **{d['long_tier_stride']} releases**, anchoring its first tier roughly to the first literal era: **{'/'.join(map(str,d['tier_rules']['long']))}**. Within the primary cap, reached counts are **12/8/4/4/0/0 out of 12**, with the remaining cells right-censored. Conditional medians across later tiers must not be read as faster pacing: only the faster-release cautious policies remain in those denominators. On the single continued ordinary route, SHORT's final tier occurs at cycle **124** and LONG's at **619**, compared with literal calendar cycle **1,104**. The changed gates have no card-access or behavioral feedback in this post-processing comparison. These milestone schedules also reward empty-release spam unless a qualifying-release design rule is chosen. No such rule is invented or implemented here.

## Recommendation and deferred boundaries

Independent cross-check of Stage 2's completed platform rows: 48/48 conditional purchases remained owned. All had zero candidate eligibility, draws and plays in incompatible Game 2. The 24 NONE controls remained excluded in Game 3. All 24 NONE→ALL rows became eligible and drew the candidate in Game 3; 22 played it (Color Cycling was selected in two of its four routes). This is the explicit analysis-only direct-tag fixture, not a live platform selector, hardware support matrix or Store warning UI. Ownership, eligibility and actual play remain distinct. The cross-check source and per-card denominators are saved as `feature_store_stage3_platform_crosscheck_v1.py` and `stage3_platform_crosscheck_v1.json`; no Stage 2 source or output was changed.

1. Retain the source comparison and exact cycle origin; do not treat the draft's conditional January 1981 assumption as current code.
2. Resolve what should qualify as meaningful era progress before selecting calendar or release gates. Both literal years and bare release counts admit a demonstrated degenerate route. The decision about empty-release SideStreet entitlement is more consequential than tuning late Feature prices.
3. Defer economic tuning of the proposed later cards. One continued normal path and three deliberate time-grinding paths do not establish a useful population affordability target; AND/schema/platform rules remain separate unresolved capabilities. No synthetic high-Review, platform, payroll, or later price case is presented as current play.

No normal policy stall was observed in this finite sample. Longer populations, human pacing, actual >9-Review action traces, the capability catalog, supported platforms and future finance obligations remain unmeasured. No permanent balance rule is inferred from absent systems.

## Reproduction and artifacts

From the repository, use the bundled Python executable and `-B patch-notes/analysis/feature_store_stage3_v1.py` with:

- `--policy=<cautious|ordinary|optimizer> --route=production --count=4 --cap=240`
- `--policy=ordinary --route=production --count=1 --cap=1104`
- `--policy=ordinary --route=priority --count=3 --cap=1104`
- `--policy=cautious --route=minimal --count=3 --cap=96`
- `--policy=ordinary --route=production --count=1 --cap=30` for replay verification.

Then run `feature_store_stage3_analyze_v1.py`, `feature_store_stage3_replay_v1.py` (with saved reference) and `feature_store_stage3_report_v1.py`. The runner records exact executable arguments, isolated APPDATA/LOCALAPPDATA profile, elapsed time, exit status and parse-error markers. Initial direct PowerShell engine launch crashed before startup; the isolated-profile Python launch succeeds. The first harness smoke also exposed a missing frame between removed scene cleanup and subsequent automated Contract action; adding a process-frame boundary in the analysis adapter removed those errors. These failed exploratory launches are not accepted simulation cases.

Source: `analysis/feature_store_stage3_v1.gd`, runner, analyzer, replay verifier and report generator; inherited unchanged helper `analysis/feature_pair_game3_trial_v1.gd`. Results: `stage3_<policy>_<route>_<start>_<cap>.json`, command JSONs and logs; `stage3_summary_v1.json`; exact per-release month-boundary table `stage3_month_boundaries_v1.csv.gz`; `stage3_replay_check_v1.json`; `stage3_harness_manifest_v1.json`. Report all primary and matched continuation/stress denominators separately. New analysis files only; gameplay, existing worktree changes and `.codex-godot-temp` remain preserved.
'''
(OUT/'stage3_findings_v1.md').write_text(text,encoding='utf-8')
print(OUT/'stage3_findings_v1.md')
