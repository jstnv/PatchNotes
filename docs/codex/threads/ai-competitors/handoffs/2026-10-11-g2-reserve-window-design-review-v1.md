# AI Competitors G2/G3 reserve-window review packet v1 — 2026-10-11

**Later disposition:** The user delegated the review choice to this thread's recommendation. The [dated rulings](../2026-10-11-design-review-rulings-v1.md) LOCK the qualitative Research-completion `B` boundary and known-liability scope. This packet remains DESIGN review needed for the actual allowance, hands, due calculation, F5/F6 and source reconciliation; no simulator code is approved for adoption.

**Queue state: DESIGN review needed. This is not an implementation handoff or approval to adopt a simulator file.**

## Decision to make

Review the [candidate qualitative rule and alternatives](../2026-10-11-g2-reserve-window-review-decision-v1.md): should a fixed F1/F5 development allowance `B` be required at the **Research-completion** cash boundary before a new rival Store admission, with later project solvency checked as actual cycles occur? The [locked minimum admission rule](../2026-10-09-admission-liquidity-decision-v1.md) already covers the conditional completed quote plus known Research-window dues. The separate eight-cycle hard reserve is a measured alternative, not the selected rule. Keep the common owned-pool baseline and plan frozen across candidates under the [existing F1/F3 clarification](../2026-10-11-g2-held-plan-candidate-decision-v1.md).

## Exact prototype delta and source pin

- Private `g2-pre-admission-v1` → v2 → v3, with original baseline identity `577f46fd83d5a1e2bd21d017c40eba0b20a543faf9c2301cd6316d48aa394533`; parent `g2-held-plan-v1` identity `4bfe30024c03460e50ea9dea9c30ea08407d7c70c9bc915464ed7d890ee4d191`. Completed v2 identity `c3fb31a2ec26e3bc4bce6216c2a920e066a40149a1456a9b2f1d6442ee1abd15`; v3 identity `2e9a4cf5e8e4ac0bd642c226f39c92cd45f0bfa9279f23d38c57be44ccdc1f53`. Both retain a true drift flag from the current canonical identity `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`.
- The **only new candidate project path** relative to the held-plan parent is `project/scripts/debug/verify_g2_legal_mix.gd`. Its `pre_admission` mode loads a legal Studio checkpoint, obtains the actual current conditional Store quote and rent-only known-dues snapshot, calculates `completed quote + dues + B`, and either returns unchanged-state/RNG `reserve_rejected` or executes real `admit_research` and `research` commands with an exact tape. V2 uses eight cycles; v3 changes that declared horizon to one cycle. V1 parse failure and its v2 type repair are retained. No rival runtime adapter, Store transaction, production rule or canonical `patch-notes/` file was edited. [Version metadata and full diff list](../sims/g2-pre-admission-prefix-v3/run-report.json).
- The thread-owned probe scripts only orchestrate frozen-source verifier and fresh-process acquisition replay with per-case profiles. The candidate verifier's v3 SHA-256 is `f90c4dc11ebe6a24767a539cc9fdde1262b3fbd81d6f4b5756f64ad75cfc0b39`. The exact predeclared cases, commands, identities, outcomes and limitations are in the [finding](../2026-10-11-g2-reserve-window-finding-v1.md).

## Matching evidence

- [V1 retained parse failure](../sims/g2-pre-admission-checks-v1/summary.json) (eight incomplete probes), then [v2 eight-cycle checks](../sims/g2-pre-admission-checks-v2/summary.json) (32 assertions, six unchanged-state rejections) and [v3 Research-cycle checks](../sims/g2-pre-admission-checks-v3/summary.json) (44 assertions, six legal admissions, four exact acquisition replays/eight commands). Both seeds' v2/v3 Studio state and RNG hashes match; each version has two 18-command fresh prefix replays and 19 verified telemetry samples per case.
- The [prior after-Research negative control](../2026-10-11-g2-held-plan-unfunded-control-finding-v1.md) shows why the Research-only guard is not a launch-funding guarantee. Source inspection identifies overdue, rent, payroll, Bank and education schedules; only rent/overdue is executable in this variant.

## Acceptance before implementation queue

1. Explicit qualitative ruling on the `B` reserve horizon and on whether future earned-but-unsettled sales ever count. Keep `B` and hand counts OPEN until selected against current-source economy routes.
2. Current-canonical reconciliation of the G2 planner and a typed all-liability G3 due calculator. Demonstrate no duplicate overdue/scheduled bill and rejection atomicity before the down payment.
3. Legal F5 ordering and F6 prerequisite/defer route under the selected policy, followed by a funded and an unfunded project continuation with legal phase exits/launch. Record search/CPU bounds and source/RNG-compatible fresh-process replays.

If these gates are met, create a **new** source-pinned adoption handoff and move the minimal TODO item to QUEUED approved scope. This review packet itself remains DESIGN review needed; G1a cohort, G4/G5 AI choices, market influence on Reviews and final balance stay OPEN.
