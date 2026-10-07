# Fanbase incremental loss decision v1

2026-10-06, America/Los_Angeles. Source: the user's direct “Yes pls” to the proposed incremental weak-release loss rule.

## Ruling

- **LOCKED structure:** A release below Review 5.0 may cause further fan losses at later monthly boundaries only as its cumulative estimated reach grows. Charge only the newly reached portion for that title; repeated callbacks, reconstruction, and later months without new reach cannot charge the same title's prior exposure again.
- **LOCKED concurrency bound:** At one monthly boundary, calculate all active releases against one pre-boundary studio fan count. Aggregate losses cannot exceed that starting count; gains earned at the same boundary do not enlarge its loss pool.
- **LOCKED neutrality:** Review exactly 5.0 remains gain/loss neutral, consistent with the prior rule.
- **ACTIVE/TRIAL:** The `bd450a9` branch's Review-neutral shadow reach and per-title launch-fan cap are working estimates of exposure, not approved buyer identity or final reach policy.
- **OPEN:** Loss percentage, exact reach estimate and cap, rounding, and cross-title audience overlap. This ruling does not identify unique buyers or require cross-title deduplication.

The branch already contains cumulative `loss_exposure_accounted` accounting and a shared starting fan count. [Focused handoff](handoffs/2026-10-06-incremental-loss-verification-v1.md) asks the implementing thread to verify this behavior before creating any new gameplay task. No TODO edit, gameplay change, merge, or push is authorized by this record.
