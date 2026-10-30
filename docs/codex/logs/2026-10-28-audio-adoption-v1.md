# Audio branch adoption and lag regression — 2026-10-28

## Scope and source

User approved all five proposed Audio trial rows, their zero direct play fees and no added year/release gate, then requested lag verification. Branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`; inherited edits, concurrent documentation and `.codex-godot-temp` preserved. Inline implementation with one read-only focused reviewer. No commit/push/export, Drive change, player save modification or scheduled follow-up.

Baseline runtime `8f88b96a3f39b7de4c6d3af3e6886c6168bfd749cbc6beb6b45671e67e5eeeb6`; final `c15b025cf78073ccbed099f6d6df522279ead2a413de4636b8b37bd3a6714409`. [Owned ten-file delta](../findings/audio-adoption-20261028-v1/owned-source.json), byte-exact before snapshots, owned diffs, [actual commands/source copies/results](../findings/audio-adoption-20261028-v1/verification.json), [plan](../findings/audio-adoption-20261028-v1/PLAN.md) and [review](../findings/audio-adoption-20261028-v1/REVIEW.md) are retained. Debug fixtures/probes and focused maintained-test updates are separate from runtime identity.

## Adopted behavior

- Exact seven-node Audio graph/phases/positions and five approved trial values in [Audio ruling](../design/audio-feature-branch-2026-10-28.md) and [value table](../design/audio-feature-values-trial-v1.md). 8-Bit Sound is the Design root; 16-Bit Sound is the only explicit upgrade; Dynamic Sequencing requires both named parents. No additional calendar/release lock; existing first-game research window remains unchanged.
- Retired Music, Sound Effects, 8-Bit Music and16-Bit Music disappear from active acquisition/map and future Studio-project draws. Original definitions, owned IDs, history and paid FIFO entries remain. Already-begun projects retain their exact frozen supply. Retired paid entries finish through the real Research button into their original owned ID, without re-entering future draws. Fixed Contract/tutorial definitions are retained; no broad Contract rebalance.
- `replaces_id` on new16-Bit Sound filters8-Bit Sound from future-project supply and prospective spending advice only. Ownership/prerequisite/familiarity facts remain. Details and admission confirmation explain replacement. No free legacy upgrades/refunds/grants.
- Founder roster v5 replaces Sound Effects with8-Bit Sound and Sports Music with Main Theme; keeps12 Scope by dropping one1-Scope card per new specialty: Action Exploration; Adventure Character Backstories; RPG Score System; Strategy/Simulation Lives System; Puzzle Score System; Sports Power-Ups; Racing Controller. This is the documented implementation choice for preserving12 Scope and parent paths. Historical v1–v4 pools remain exact.
- Exact previous catalog upgrade and known source/content pairing preserve old player/rival histories, active hands and RNG; unknown/mixed pairs reject. Current Store has47 active nodes and39 local arrows; cross-category requirements remain enforced without arrows. Other trees, Bank/finance formulas, Core standards, AI policy and Studio-only Continue boundary unchanged.

## Focused verification

Commands use `python docs/codex/findings/audio-adoption-20261028-v1/run.py <fresh label> <script> [args]`, with private profiles/writer ports. Every receipt records exact command and immutable probe source. Runtime hashes are checked before/after. No full-release gate claim.

- `verify_audio_branch.gd`: **143 checks/0** for exact rows/parents/phases,8 new12-Scope grants, historical v1–v4, legal research, forgery rejection, upgrade/frozen supply, exact retired paid queue restore/real-UI completion and spending-advice regression.
- `verify_audio_campaign.gd`: **58 checks/0**, funded mechanics fixture,46 accepted commands, every new card actually played/exhausted in its proper phase; independent exact replay. Not solvency evidence.
- Same verifier `--fresh`: **38 checks/0**, unfunded36-command/two-release route, exact replay, final$1,503.70. Fixed-policy coverage, not final balance.
- Maintained seeded live/headless campaign: **138 boundaries/3 routes**, two releases per route and exact replays; no failures. Existing invalid-Alpha-action fixture warnings retained.
- Research integration PASS; current-roster creation181 PASS assertions; historical roster220 checks/0; checkpoint95 PASS assertions; Store77 PASS assertions; spending advice59 PASS assertions; navigation86 PASS assertions; coalesced refresh12 checks/0.
- Common grid **68 checks/0** on the preceding details-only source; final native map **243 PASS assertions**, actual900×600/1152×648/1280×720, including upgrade copy and both fully animated parent buttons inside viewport. Final-source cold prior-world **7 checks/0**, exact player/rival finance/history/RNG/active state and mismatched revision rejection.
- Native captures retained in native-links-final/; inspected final Audio upgrade at1280 and two-parent chooser at900, plus preceding1152 upgrade/1280 chooser and two overview/detail captures. At900 long detail text uses the existing bounded scroll; narrow link text wraps without ellipses. No claim of all screenshots inspected or human playtest acceptance.
- CRLF-aware owned `git diff --check` PASS. Known six ObjectDB-instance fixture warnings and artwork fallbacks retained; no leak/artwork correction claimed.

## Lag result — FAIL / remains OPEN

**Cannot verify that late-save lag is gone.** Original native player action sequence is identical for all8 baseline/final sampled operations; outcomes/AI forward history may differ under new future supply rules. Native production-button measurements, not a physical stopwatch:

| Case | Before Audio | Final Audio |
| --- | ---: | ---: |
| Cycle1928-Color Palette Research handler |526.060ms|593.966ms|
| Cycle192 maximum observed frame gap |553.963ms|624.877ms|
| Cycle192 wait until final save durable |33.725s|62.443s|

Both sources **fail the unchanged500ms synchronous Research limit** at cycle192. The final run is slower at this sampled boundary; no no-regression/never-lag guarantee. All six c96–98 queue/research handlers stay below500ms in the production final run. The earlier preliminary new-card selection reached552.409ms; it selected16-Bit Sound rather than the original8-Color Palette and is not the matched comparator. Instrumented split diagnostics also failed atcycle98, with444.226ms rival-calendar work out of470.596ms core, versus53.681ms Store refresh; this altered diagnostic path is not a production acceptance pass.

A separate funded no-rival CPU probe atcycles0/12/24/48/96 measures Store refresh9.049–27.706ms and full standalone quote scans26.595–43.724ms. It does not represent a full live rival campaign. Refresh-coalescing tests prove one Store rebuild and no hidden Summary rebuild; they cannot eliminate the remaining rival/world/background-durability bottleneck.

Required follow-up: profile and repair the remaining late-history rival/calendar/save work while retaining full validation, legal actions, exact RNG/history/finance, old saves and Studio-only Continue. Keep failed receipts and500ms bound. Audio functional adoption is complete locally; **performance acceptance is incomplete**. No public build or release-readiness claim.

## Retained failures and review

Initial Audio RED49 checks/29 expected failures; initial value comparison needed explicit String/integer normalization for JSON definitions. Upgrade-copy RED and review's obsolete-fee advice RED are retained and fixed. Maintained UI tests were updated from46/36 to47/39 and skip retired map IDs; invalid roster version moved from newly valid5 to unknown6. Current creation fixture uses independent v5 membership and private checkpoint writer/wait rather than racing another process's writer. Initial missing-link capture checked during animation; final test waits for both opacity and viewport bounds, with original captures retained. Failed relative script path and Python-path launch retained in tool history. No baseline failure erased or budget weakened.

Reviewer found one P2 (spending advice); RED→GREEN and follow-up resolved it, with no other specific issue found in scoped graph/roster/FIFO/frozen supply/source pairing. Review did not run tests and does not certify performance.
