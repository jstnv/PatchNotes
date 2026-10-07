# Fan count and launch-sales proportionality v1

2026-10-06, America/Los_Angeles. **Mechanism clarified by the later [decision](2026-10-06-proportional-fan-awareness-decision-v1.md); numbers remain OPEN.** The user wants launch Awareness's effectiveness with sales to be proportionate to the current Fan count. This note preserves the two mechanisms considered without selecting a rate, cap or gameplay change.

## Current branch behavior

At `bd450a9e4e8d83ece1478cdf5a16526432e36cce`, launch freezes the studio Fan count and computes a fan-derived Awareness contribution as `floor(150 × Fans / (Fans + 300))`. Total launch Awareness is organic 100 plus Marketing plus that fan contribution. Month 1 unit demand then multiplies by `1 + total Awareness / 200`, alongside Review and market demand. Thus Fan Awareness already converts linearly into Month 1 sales, but its *amount* rises with diminishing returns as Fans grow. The measured legal route had 96→36, 149→49 and 267→70 fan Awareness at successive launches. These values are observed branch behavior, not approved tuning.

## Choice needing the user's intended meaning

1. **Proportional fan contribution to Awareness (recommended interpretation):** Use the frozen at-launch Fan count to set fan-derived launch Awareness proportionately, with any cap or later taper decided separately. The existing Awareness-to-sales multiplier then carries the effect once. This changes the branch's saturating Fan-to-Awareness mapping while preserving the established sales formula. Exact ratio, cap, integer rounding and later-month carryover remain OPEN.
2. **Fan-dependent effectiveness of all launch Awareness:** Keep or change the fan-derived contribution, then also scale the Awareness-to-sales conversion by Fans. This makes Marketing and organic Awareness more potent for a large studio and compounds the fan effect already in total Awareness. It changes the accepted sales formula and would need a separate cross-system ruling and matched economy analysis. The user may intend this, but the wording does not yet establish whether that additional multiplier is desired.

For either option, keep a launch snapshot so later monthly fan gains/losses do not retroactively alter that title's frozen launch sales inputs; changing ongoing sales would be a separate decision. A zero-Fan studio must still receive the existing organic and Marketing sales benefit. Review exactly 5.0 remains neutral for fan gain/loss, not zero sales. Preserve the current legal-route capture and do not treat its conditional square-root gain overlay as a played sales outcome.

No numerical value is locked, and no TODO, branch, runtime source, merge or push action follows from this note. Once the mechanism is clarified, compare the smallest few launch Fan counts on captured Review/Market/Marketing inputs, including zero Fans, before preparing any implementation handoff.
