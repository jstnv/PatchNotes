# SideStreet P1-backed gate study

2026-10-23 America/Los_Angeles (execution spans2026-10-24 UTC). **Private candidate evidence; P2/P3 terms remain PROPOSED.** User authorized continued publisher design and private work after P1 completed. Canonical gameplay was not edited. [Predeclared plan](studies/sidestreet-p1-gate-20261023-v1/PLAN.md) · [proposal and acceptance requirements](SIDESTREET-P2-AND-FIRST-COMMISSION-PROPOSAL-2026-10-23-v1.md).

## Source identity and actual delta

- Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; current P1 completion and authoritative docs read before work. [Starting provenance](studies/sidestreet-p1-gate-20261023-v1/git-before.json).
- Canonical-derived [variant](simulators/sidestreet-p1-gate-v1/variant.json), owner Contracts; base/creation manifest identity `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`, matching P1's final audit. No historical candidate was used as its baseline.
- Candidate source manifest `544cb959ac35a6a121ad6e676b6494facb2ecd9e34b668aafb744c58b5a74244`; mechanics identity in completed cases `f1c9ffcc7ad5198c274c477c39145c2718b5f2b7843f55022b9377d32111210e`. `baseline_drift=false` in all four candidate bundles. Policies are additional frozen input files, not gameplay mutations.
- Policy SHA256 `ac5c87060d9e3dcd46f1b51ee64834c23dba7e560620fd2fc90df2d6a3023b5f`; runner `65bdf6c5eb4a47af829283a0b07d4b78ad45e8a95139607b96a613d6ffbf9193`; Godot4.7.1 SHA256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- Ten source paths: Contract definition/state/challenge grading; reference grade helper; P1 trusted producer; RunState offer ownership and settlement; typed Brief serialization/validation; Studio/Campaign observation and command adapters. P1's ledger itself is unchanged. No historical `_publisher_reputation_bp` or parallel reward-event dictionary was adopted. [Exact delta packet](handoffs/sidestreet-p1-gate-20261023-v1/HANDOFF.md).

The producer resolves completed Brief facts and the exact two zero-receipt productive actions, then credits the existing P1 ledger after finance/cycle commit and before notification. Save validation reconstructs standing and requires one event per completed Brief. Candidate assertions protect internal transaction assumptions; production adoption still needs review of precommit planning and failure handling. Named P1 predecessor migration, native Brief UI, commissioned games and support are not implemented by this private slice.

## Experiment

Canonical existing behavior ran first: Action1104 and Racing1104, legal fresh Studios through four releases and Ironclad, no Briefs. Both completed83 commands/cycle36. These controls match candidate skip outcomes and initial/final RNG exactly, while source/schema differences remain explicitly recorded.

Candidate screen: eight starter specialties at seed1104 plus predeclared Action1108 and Racing1112 witnesses; two arms per start,20 cases. Every pair has identical initial state and RNG and identical telemetry through completed Ironclad. No cards, cash, traits, Reputation or saves were injected. First release uses Features-first3/5/4 hands, later releases2/2/2. No purchases, borrowing or redraw. Each arm ends in Studio after release4, bounded160 commands and600seconds per process. Batches of five keep process bounds small.

- **Take:** choose only from visible quartets, balance Core deficits first hand and maximize actual final grade second. Finish partials. Take one available release-paced Brief until R20, then stop taking them.
- **Skip:** same ordinary development/Ironclad policy, ignore Briefs.

This is a strong visible-card test policy with deliberately short later games. It does not estimate average human play or a quality-seeking commission-delivery policy.

## Outcomes

All20 candidate cases completed,1,800 accepted commands and80 releases. The2 canonical controls add166 commands/eight releases. [Analysis:198 checks,0 failures](studies/sidestreet-p1-gate-20261023-v1/analysis.json).

| Measure | Observed |
|---|---|
| Take routes reaching proposed R20 |10/10 |
| Stop after2 Briefs |2/10: Action1108 and Racing1112 |
| Stop after3 Briefs |8/10 |
| Gate cycle |26 after2;35 after3 |
| Brief results |28 total:14 full,14 positive partial,0 zero |
| Final standing |20.00–29.06 |
| Added productive cycles versus skip |4 or6 |
| Release4 cash difference versus skip |−$1,000.00 to−$1,472.03; median−$1,461.535 (display−$1,461.54) |
| Cash at gate |$3,250.19–$9,021.35 |
| Final overdue balances |0 across all20 cases |
| Pending future Brief |One per case, no backlog or same-release completion refill |

The cost is a net same-release comparison, including shifted sales timing and finance. It is not a direct fee or pure rent charge. These runs estimate the declared stop-at-gate route, not the globally cheapest route to R20. We did not run an alternative SideStreet cash-Contract strategy. Old forced-three results are historical context, not a same-source controlled arm; the current two-brief route visibly spends four cycles rather than six.

## Access is not delivery readiness

The12 self-published releases after R20 had Scope18–25 and Review1.8–3.2. **0/12 met the proposed commissioned-game delivery condition.** All sampled legal projects required Scope30, but the offer service must freeze its actual positive project requirement. The [pre-outcome metric clarification](studies/sidestreet-p1-gate-20261023-v1/READINESS-CLARIFICATION.md) retains the literal30 illustration separately from actual required Scope.

These are shadow eligibility/delivery observations on real self-published outcomes. No commission was accepted, no title ownership changed, and no fee, salvage, sales forfeiture or Investment was simulated here. The failure of this short policy does not establish that the commission is impossible: [older legal commission evidence](PUBLISHER-COMMISSION-PRIVATE-FINDINGS-2026-10-22-v1.md) includes Scope30/Review8.8 under a different source and production route. It requires regeneration against current P1 before adoption.

Recommendation: keep partial Brief credit and distinguish the trust gate from delivery requirements. Provide an enabled, clearly quoted first commission before activating Reputation-only play; do not lower the delivery target merely to fit this short policy. The proposed first tier remains R20, up to$6,000 on launch, Review6 and the frozen project-required Scope, publisher-owned sales, proportional fee for underdelivery and standing only for full delivery. Values remain pending a trial ruling.

## Checks and exact replays

- **PASS** private codec/producer audit:38 checks,0 failures. Nonzero standing roundtrips in a fresh process; duplicate event retry is inert; forged event/source/publisher/kind/cycle/amount reject; detached observations do not mutate totals; wrong owner, missing/duplicate event, tampered grade/payment/terms/cycle reject; one active Contract and Studio-only Continue remain enforced. [Report](studies/sidestreet-p1-gate-20261023-v1/checks-v1/audit.json).
- **PASS** actual publication/reentry audit:18 checks,0 failures across a full98-command legal replay. Three notifications see coherent committed cycle/finance/standing, reject reentrant producer/Contract acceptance and preserve state/RNG. [Report](studies/sidestreet-p1-gate-20261023-v1/observer-v1/result.json).
- **PASS** unchanged maintained challenge matrix:259 assertions,0 failures; existing publisher challenge rewards remain checked. [Log](studies/sidestreet-p1-gate-20261023-v1/checks-v1/challenge-matrix/challenge-matrix.log). Its inherited Neon partial/miss impossibility is an explicit existing authored-pool limitation.
- **PASS** representative isolated fresh replays: Action1108 (93 commands,94 telemetry samples) and Adventure1104 (98 commands,99 samples), exact final state and independently recomputed telemetry. [Replay1](sims/sidestreet-p1-replay-1-20261023-v1/run-report.json) · [Replay2](sims/sidestreet-p1-replay-2-20261023-v1/run-report.json). [Selection note](studies/sidestreet-p1-gate-20261023-v1/REPLAY-SELECTION.md) explains replacing a duplicate selector with the lowest-standing three-brief route before replay.
- Maintained Contract extraction live/headless suite: final status recorded in the verification addendum below; never infer its result from campaign success.

## Reproduction

Use Python `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` and Godot `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` from the repository root. All outputs must be new names; original evidence is immutable.

```text
python tools/simulate.py run --config docs/codex/threads/contracts/studies/sidestreet-p1-gate-20261023-v1/baseline.json --output docs/codex/threads/contracts/sims/sidestreet-p1-baseline-20261023-v1 --godot <above executable> --timeout 600
python tools/simulator_variant.py create --id sidestreet-p1-gate-v1 --owner contracts --output docs/codex/threads/contracts/simulators/sidestreet-p1-gate-v1
python docs/codex/threads/contracts/studies/sidestreet-p1-gate-20261023-v1/build_candidate.py
python tools/simulate.py run --variant docs/codex/threads/contracts/simulators/sidestreet-p1-gate-v1 --config docs/codex/threads/contracts/studies/sidestreet-p1-gate-20261023-v1/<arm>-<batch>.json --output docs/codex/threads/contracts/sims/sidestreet-p1-<arm>-<batch>-20261023-v1 --godot <above executable> --timeout 600
```

The last command ran for each of `balanced-1`, `balanced-2`, `skip-1`, `skip-2`. Exact internal process argv/runtime/source pins are preserved in each bundle's `*.command.json` and run report. External audit orchestration uses the runner's snapshot/import/process/profile helpers, distinct copied projects and private profiles: [checks.py](studies/sidestreet-p1-gate-20261023-v1/checks.py), [observer_check.py](studies/sidestreet-p1-gate-20261023-v1/observer_check.py). [replays.py](studies/sidestreet-p1-gate-20261023-v1/replays.py) records complete exact replay argv in two command records. [analyze.py](studies/sidestreet-p1-gate-20261023-v1/analyze.py) regenerates the measured analysis.

## Verification addendum: retained harness failure and corrected pass

The first maintained Contract extraction invocation **TIMED OUT at600seconds** after a missing external historical oracle caused a null-script exception. Its20 preceding assertions do not constitute a suite pass. The original failed process/log/source copy remains in [checks-v1](studies/sidestreet-p1-gate-20261023-v1/checks-v1/contract-extraction/contract-extraction.command.json).

The [documented harness correction](studies/sidestreet-p1-gate-20261023-v1/EXTRACTION-HARNESS-CORRECTION.md) copies that exact historical oracle into the expected private sibling path in a new isolated source copy. No candidate gameplay, seed, oracle or verifier was changed. The [corrected full suite](studies/sidestreet-p1-gate-20261023-v1/extraction-v2/result.json) **PASSES with52 live/headless comparisons and0 failures**. Its [exact command](studies/sidestreet-p1-gate-20261023-v1/extraction-v2/extraction.command.json) and [oracle hashes](studies/sidestreet-p1-gate-20261023-v1/extraction-v2/oracle-identity.json) preserve provenance. This covers existing Contract paths, not a native player-facing Brief flow.

All22 ordinary campaign cases completed and both selected exact replays passed. No candidate gameplay revision or seed change was needed. The retained failed invocation is not relabeled successful. There is no unresolved gameplay blocker established by this bounded study; adoption and numerical design gates below remain open.

## Limits and adoption requirements

Three fixed seeds, mostly one seed per specialty, granted starter pools and one strong Brief policy; no confidence interval or human accessibility rate. No purchased-pool, trait, extreme arrears, capped standing, successful redraw or zero-grade legal campaign in this screen. Threshold grading was checked separately; no general coverage claim. Six ObjectDB shutdown warnings recur in passing processes and remain unattributed baseline warnings.

No P1 predecessor migration, real disk/native Continue, native Brief presentation, export, commissioned settlement/rights, support or human comprehension acceptance. Observer replay and DTO roundtrip do not substitute for those gates. Research source retains assert-based internal commit assumptions for adoption review and includes a historical grading helper unused by the new resolver; do not blindly transplant the full tree. Proposal, exact packet and review queue must keep these gaps explicit. No canonical gameplay, player saves, commit or push.
