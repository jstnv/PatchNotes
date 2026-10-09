# Handoff: current-main Fanbase playable trial v1

**Status: QUEUED in the internal TODO on 2026-10-09; NOT DISPATCHED.** This is a design handoff for the separate implementing thread. The user approved retaining the 15% loss coefficient as **ACTIVE/TRIAL** after the Review 4.3 / 93-Fan capture, then authorized the internal TODO update. This design thread has not implemented gameplay, merged, pushed or messaged the implementing thread. Coordinate a nonoverlapping gameplay slot before starting.

## Requested behavior

Integrate the already built Fanbase trial with the current main systems when this handoff is dispatched. Reuse the published `codex/fanbase-on-main` work at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` and the isolated `codex/fanbase-quarter-trial` two-file quarter-Awareness change; compare against the then-current main source before transplanting anything. Preserve studio monthly Fans, per-release incremental gain/loss and shared pre-boundary loss cap, frozen Fan-derived launch Awareness, and Fans HUD/history. Review exactly 5.0 gives zero Fan gain/loss. Keep the linear gain shape with its provisional 8% coefficient and cap, the per-title eligible-unit/reach proxy, the 15% loss coefficient, and `min(150, floor(Fans/4))` launch Fan Awareness as **ACTIVE/TRIAL**. Total Awareness feeds the existing sales conversion once; no second Fan multiplier. A below-5.0 release may lose zero when its cumulative integer target is below one. Cult Following stays a selectable preview without an active Fan effect or price ruling.

Avoid duplicating branch code or changing the approved lifespan/settlement, Review, sales, Genre, Bank, Employees, Traits, Store, Contract or checkpoint rules. Resolve integration conflicts against current main behavior and record each necessary adaptation. No numerical value becomes final merely by integration.

## Source, dependencies and evidence

- **Design source:** [15% trial ruling](../2026-10-08-loss-rate-trial-decision-v1.md), [Fanbase design](../../../design/fanbase.md), [quarter trial finding](../2026-10-07-quarter-trial-recovery-findings-v1.md) and [near-neutral v2 capture](../../../findings/fanbase-near-neutral-v2/README.md).
- **Published branch:** `codex/fanbase-on-main` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce`, based on main `2b5717d0de737f77f1b1bc8c1a02da0db9f53942` at publication. Verify branch HEAD/status when work starts. The isolated quarter trial has the same HEAD plus two recorded uncommitted files; verify its exact diff/hashes from the near-neutral evidence bundle before use.
- **Current shared checkout at preparation:** `main` at `91ce539978b87ac0a6efe3a1e028cae5f1360f19`, with concurrent uncommitted gameplay/docs. Recheck HEAD, status and diff at dispatch. Coordinate one overlapping gameplay implementation slot and preserve `.codex-godot-temp`.
- **Gate:** Current-main checkpoint schema and saved state must carry Fan totals, per-release processed gain/exposure, shared boundary identity and frozen launch Awareness without replaying old monthly deltas. Keep the current economy and exact-cent settlement authoritative.

## Acceptance checks

1. Record exact source revisions and patch/diff; identify reused branch behavior and any integration-only changes. Confirm no duplicated Fan counter or overlapping monthly callback.
2. Focused checks for 5.0 neutrality; above-5 linear gains; below-5 cumulative incremental loss, zero-minimum behavior, repeated-boundary idempotence and shared pre-boundary cap; Fan count never negative.
3. At launch, freeze Fans and verify quarter-per-Fan Awareness including zero and cap; check sales convert total Awareness once. Check Fans HUD/history against the same journal.
4. Check current-main save/Continue across launch and two settlement boundaries, including exact Fan, release exposure, Awareness and finance reconstruction without duplicate accrual or loss.
5. Run one legal strong → weak → later-release route on the integrated source, with actual earned units, settled cash, other-title Fan changes and next-launch Awareness reconciled. Compare Review 4.3 / 93-Fan branch evidence as a historical reference, not an expected integrated-main outcome. Run relevant focused suites and native import; report their exact results and remaining exported or player-feel limits.

**Open after this handoff:** final 8% gain and 15% loss rates, reach/reserve and overlap assumptions, final Fan Awareness mapping, Review 4.8–4.9 player feel, longer compounding, Cult Following valuation, merge/push and release readiness. Add no new near-neutral route merely to satisfy this handoff.
