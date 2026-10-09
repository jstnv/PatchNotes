# Fanbase design thread

This is the dedicated local record for this Fanbase design thread. Other design threads use their own folders. Add new dated, versioned files here; do not append to another thread's log. The shared [documentation index](../../README.md) links here, and the [authoritative Fanbase design](../../design/fanbase.md) holds approved system rules.

## Find the work

- [Context and current questions, v2](2026-10-06-context-v2.md)
- [Local evidence summary, v1](2026-10-06-evidence-v1.md)
- [Drive handoffs and local queue reconciliation, v1](2026-10-06-drive-handoffs-v1.md)
- [Rent-era legal route fan-rule shadow, v1](2026-10-06-current-route-shadow-v1.md)
- [Buyer identity and fan gain options, v1](2026-10-06-buyer-model-options-v1.md)
- [Audience definition decision, v1](2026-10-06-buyer-definition-decision-v1.md)
- [Incremental weak-release loss decision, v1](2026-10-06-incremental-loss-decision-v1.md)
- [Gain-curve comparison and recommendation, v1](2026-10-06-gain-curve-review-v1.md)
- [Linear gain trial decision, v1](2026-10-06-linear-gain-trial-decision-v1.md)
- [Fan count and launch-sales proportionality question, v1](2026-10-06-fan-sales-proportionality-v1.md)
- [Proportional Fan Awareness direction, v1](2026-10-06-proportional-fan-awareness-decision-v1.md)
- [Proportional Fan Awareness candidate screen, v1](2026-10-06-proportional-awareness-screen-v1.md)
- [Quarter Fan Awareness trial decision, v1](2026-10-06-quarter-awareness-trial-decision-v1.md)
- [Mature weak-release loss sensitivity, v1](2026-10-06-mature-weak-loss-screen-v1.md)
- [Near-neutral loss rounding sensitivity, v1](2026-10-08-near-neutral-rounding-screen-v1.md)
- [Zero-minimum-loss decision, v1](2026-10-08-zero-minimum-loss-decision-v1.md)
- [Cross-title overlap screen, v1](2026-10-08-cross-title-overlap-screen-v1.md)
- [Quarter Awareness trial and legal recovery findings, v1](2026-10-07-quarter-trial-recovery-findings-v1.md)
- [Implementation handoffs](handoffs/README.md): the main implementing thread should read this index first, then only the handoffs marked ready.

## Boundaries

This thread records decisions, evidence, open questions, and handoffs. It does not edit gameplay or the internal [TODO](../../TODO.md), merge, or push. Update TODO only when the user explicitly prompts it. Use local evidence first; consult Drive only if essential authority is missing or demonstrably stale. Keep **LOCKED**, **ACTIVE/TRIAL**, **OBSERVED**, **OPEN**, and **SUPERSEDED** separate. Branch behavior and test results do not, by themselves, approve numerical tuning.

When the user approves a rule, record the decision and rationale in a new versioned file here and reconcile it into the authoritative design document. Cross-system decisions belong in [DECISIONS.md](../../DECISIONS.md). Give the main implementing thread a versioned handoff with source revision, exact behavior, dependencies, acceptance checks, and status. Do not duplicate work already present on its Fanbase branch.

- [Near-neutral v1 findings](2026-10-07-near-neutral-findings-v1.md): both initial bounded attempts exhausted; Reviews3.6/3.5 missed the target. The separately approved v2 result below supersedes this target status, while retaining the v1 observations. Runtime unchanged.
- [Separately approved v2 completion](../../findings/fanbase-near-neutral-v2/README.md),2026-10-08: exactly one4/4/4 capture reaches Review4.3 with93 launch Fans, losses9 then0, and reconciled two-boundary finance. Target band complete;4.8–4.9 and final tuning remain open. Runtime unchanged.
- [V2 design review](2026-10-08-near-neutral-v2-review-v1.md): retain the loss coefficient as a trial; immediate-neutral fairness and final tuning remain open.
- [15% loss trial decision](2026-10-08-loss-rate-trial-decision-v1.md): user accepted the observed Review4.3 severity for a playable trial; final rate remains open.
