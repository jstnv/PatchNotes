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
- [Current-main implementation review](2026-10-09-current-main-integration-review-v1.md): local trial integration verified; source, exact checks and remaining player-facing limits recorded without numerical promotion.
- [Exported interaction and balance review plan](2026-10-09-export-and-balance-plan-v1.md): smallest player-facing capture, current desktop-launch blocker, and open tuning questions.
- [Player screenshot review](2026-10-10-player-capture-review-v1.md): preserved Fans history and title “3” sales captures, reconciled visible totals, and bounded the remaining provenance/launch questions.
- [0.4 Review player-feel review](2026-10-10-weak-release-player-feel-v1.md): four monthly loss rows reconcile to617 lost Fans; the player says the severity feels right for this no-Cult run.
- [10.0 Review recovery player-feel review](2026-10-10-10-review-recovery-player-feel-v1.md): the same studio rises from367 to597 across two shown surge months; the player says recovery feels about right.
- [10.0 Review launch-benefit capture](2026-10-10-10-review-launch-benefit-v1.md): frozen367 Fans give91 Fan Awareness; Month1 projected/actual sales and both visible monthly rows reconcile.
- [Current player-trial feel disposition](2026-10-10-player-trial-feel-disposition-v1.md): the player says the launch sales benefit feels right; retain existing Fanbase numbers as ACTIVE/TRIAL without a tuning task or final lock.
- [Post-600 Fan Awareness question](2026-10-10-post-600-awareness-question-v1.md): current trial reaches its150 Awareness cap at600 Fans; the direction chosen afterward is recorded below.
- [Post-600 direction decision](2026-10-10-post-600-awareness-direction-decision-v1.md): future launches should keep benefiting from Fans above600 with diminishing returns; exact tail is OPEN and current trial is unchanged.
- [Post-600 taper arithmetic screen](2026-10-10-post-600-taper-screen-v1.md): two candidate tail strengths at fixed Fans and launch inputs, with no playable or numerical approval.
- [Post-600 comparison on the player's five-release route](2026-10-10-post-600-player-route-comparison-v1.md): read-only checkpoint-derived 895-Fan weak launch and fixed-input strong-title screen; no played strong launch above600 yet.
- [Same 10.0 title's later Fan growth](2026-10-10-player-10-review-later-growth-v1.md): month74–79 shows597→869 Studio Fans and feels about right to the player; the title's367-Fan launch snapshot is unchanged.
- [First strong above-600 launch taper comparison](2026-10-10-post-600-strong-launch-comparison-v1.md): saved sixth release freezes940 Fans, scores10.0 and supports a read-only mild/moderate candidate screen with per-title Fan attribution.
- [Early/midgame near-close assessment](2026-10-10-early-mid-growth-assessment-v1.md): user considers early/mid growth almost done; trial numbers remain provisional and post600 taper is the next design focus.
- [Post-600 taper trial recommendation](2026-10-11-post-600-taper-recommendation-v1.md): recommends mild as the first bounded candidate from the played 940-Fan launch; numerical choice and implementation remain OPEN.
- [Post-600 hold and exact-5.0 capture disposition](2026-10-11-post-600-hold-and-neutrality-v1.md): user puts the numerical taper choice on hold; existing checks cover exact 5.0 neutrality, so no new simulation is needed now.
- [Current trial closeout assessment](2026-10-11-fanbase-trial-closeout-assessment-v1.md): no further Fanbase design decision blocks the playable trial; final numbers and the post600 taper remain open.
- [Headless eight-release Fanbase finding](2026-10-11-headless-fanbase-eight-release-finding-v1.md): same-start legal routes record two Review4.9 losses with existing Fans, one 600-Fan cap crossing, financial rejections and a retained timeout; no numerical approval.
