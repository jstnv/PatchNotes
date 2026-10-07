# Mature-studio weak-release loss screen v1

2026-10-06, America/Los_Angeles. **Read-only conditional sensitivity, not a played route or loss-rate approval.** The separate Fanbase branch at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` uses a provisional loss target `floor(min(launch Fans, cumulative Review-neutral estimated reach) × 0.15 × (5−Review))` for Review below 5.0, with the already approved incremental-exposure accounting and shared-boundary cap. The user selected `min(150, floor(Fans/4))` as a future Fan Awareness trial; that mapping has not yet been applied to the branch.

## Conditional full-exposure screen

Assume each weak title eventually reaches all of its launch Fans in the branch's Review-neutral estimate, no other release changes Fans, and the full cumulative loss target is available. This gives an upper bound for one weak title at the **provisional** 15%-per-Review-point rate, not a timing forecast. The next-launch column applies the user-selected quarter-Awareness trial to the before/after Fans, while holding next-title Review 7.0, organic Awareness 100, Marketing 11 and market 10,000 basis points fixed. It changes no runtime state.

| Launch Fans | Weak Review | Conditional cumulative Fans lost | Next-launch fan Awareness before → after | Conditional next-title Month 1 units change |
|---:|---:|---:|---:|---:|
| 96 | 4.9 | 1 | 24 → 23 | −2 |
| 96 | 4.0 | 14 | 24 → 20 | −10 |
| 96 | 3.0 | 28 | 24 → 17 | −17 |
| 149 | 4.9 | 2 | 37 → 36 | −3 |
| 149 | 4.0 | 22 | 37 → 31 | −15 |
| 149 | 3.0 | 44 | 37 → 26 | −28 |
| 267 | 4.9 | 4 | 66 → 65 | −2 |
| 267 | 4.0 | 40 | 66 → 56 | −25 |
| 267 | 3.0 | 80 | 66 → 46 | −50 |

Near-neutral 4.9 losses are small at these Fan counts; a 4.0–3.0 release is visibly more costly. This cannot establish whether the 15% rate feels fair: actual estimated reach may be lower, loss happens over monthly boundaries, other releases may gain Fans concurrently, and altered Awareness feeds later earned sales and cash. The table is an isolated upper-bound screen, not an observed recovery route.

## Evidence gap and next capture

The completed current Fanbase route has Reviews 4.9 / 7.0 / 6.1 / 7.0 / 6.9; its only weak title launched with zero Fans. A targeted read of Task32's 36 local route-summary rows found **no** row with a Review below 5.0 after an earlier Review of at least 6.0. The older Task17 strong and weak cases predate the current rent/trait/Fanbase branch and are not a substitute. [Bounded strong→weak→recovery handoff](handoffs/2026-10-06-strong-weak-recovery-capture-v1.md) requests a legal current-branch route after the quarter-Awareness trial exists. It will test real exposure timing, Fan losses, next-launch demand and ability to recover. Do not choose a final loss rate or merge from this sensitivity alone.
