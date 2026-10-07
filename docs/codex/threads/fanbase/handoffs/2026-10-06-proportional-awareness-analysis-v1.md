# Handoff: proportional Fan Awareness analysis v1

**Status:** PARTIAL read-only analysis: the [fixed-launch and scale screen](../2026-10-06-proportional-awareness-screen-v1.md) is complete; propagated next-release feedback and a legal mature-studio weak-release route remain untested. Not an implementation request or numerical approval.

**Decision/open question:** [Proportional Fan Awareness only](../2026-10-06-proportional-fan-awareness-decision-v1.md). At launch, freeze Fans and map them proportionally into the fan-derived Awareness component, then use the existing Awareness-to-sales multiplier once. Determine a candidate ratio and whether a cap/taper is necessary; do not add a Fan multiplier to all Awareness or sales.

**Source revision:** Use the captured legal branch route at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` or record an exact newer SHA. [Route evidence](../2026-10-06-current-branch-replay-v1.md) includes launches at 96, 149 and 267 Fans and full Review, market, Marketing and settlement context. The branch's current fan mapping is saturating and provisional. Keep any later economy/source changes separate.

**Dependencies:** Existing locked 5.0 neutrality, linear gain trial, per-title launch snapshot, accepted current Month 1 sales formula and lifespan coefficients. Reuse the recorded route; do not repeat it or edit gameplay. Keep played branch sales distinct from read-only alternative projections.

**Acceptance checks:** Compare zero Fans and the recorded 96/149/267 launch counts under a small, explicitly candidate set of proportional ratios; include a higher-Fan stress point to expose runaway launch Awareness. Hold each launch's Review, Marketing, market demand and nonfan Awareness fixed. Report incremental fan Awareness, Month 1 units and exact-cent entitlement/settlement implication, then the conditional next-release feedback separately. Check monotonicity, integer rounding at small Fan counts, and whether any candidate needs a cap or later taper. State the intended range for proportionality and preserve the zero-Fan baseline. Do not call counterfactual sales playable cash.

**Output:** A dated, versioned evidence summary in this Fanbase folder with exact source SHA, formula, candidate inputs, arithmetic and smallest recommendation. The user must approve the ratio/cap/rounding before a gameplay implementation handoff or TODO addition; the existing fan counter, HUD and sales calculator must not be duplicated.
