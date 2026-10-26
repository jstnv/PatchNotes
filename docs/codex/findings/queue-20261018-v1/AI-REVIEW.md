# AI active-market save candidate intake — 2026-10-18

**Bounded implementation review COMPLETE. Active effects remain DESIGN/OPEN; no canonical adoption.** This is the requested review of the [v29 handoff](../../threads/ai-competitors/handoffs/market-save-review-20261018-v1/HANDOFF.md), not approval of its test coefficients. `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared checkout preserved.

## Source and evidence audit

[Reproducible audit](audit_packets.py) verifies all sealed packet hashes, every entry in both source archives, the full source identities, and every referenced evidence file. [Exact report](packet-audit-final.json): base671 entries / `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`; candidate682 entries / `30508dba9e2d25cd701519defe814bc064759ceaf51eac4a59aa041ba1b932bd`. All23 changed paths were compared with canonical bytes. Current overlaps are now four: `rival_world_checkpoint.gd`, `checkpoint_schema.gd`, `studio_checkpoint.gd`, `run_state.gd`. The packet's original single-conflict count is historical. The report also preserves all non-overlapping paths and exact hashes.

The [companion](../../threads/ai-competitors/handoffs/market-save-review-20261018-v1-evidence.md) and [finding](../../threads/ai-competitors/2026-10-18-market-full-restore-migration-finding-v1.md) retain private results: historical Store73/0 and cold51/0, worldless26/0 and cold7/0, Coordinator90/0 and cold21/0,18 accepted player commands and18 exact replay steps. These are inspected prior evidence, **not rerun or current-canonical parity results**. The v27 false-valid Founder inspection and sequence-fixture failure remain retained.

## Assessment and recommended boundary

- The transaction shape is appropriate: preview one entering-month snapshot from the neutral real-release index, use it for player preflight, and commit once with the player/rivals. A rejected action must publish neither time nor snapshot. Freeze new-project Core standards and per-release age-month factors; never recompute already-earned cash, Fans or Reviews.
- The migration shape is appropriate: admit exact named source/revision/key families; independently validate raw old sales/Fanbase accounting; reconstruct the complete catalog-backed world before Store inspection reports valid. Continue uses the same conversion. A player-only save remains worldless. Pure reads retain original generation bytes; the next legal Studio commit publishes atomically.
- The candidate is **not a drop-in migration patch**. Its compatibility adapter, schema, RunState and world codec are coupled to active market ledgers. Copying them without the numerical ruling would activate new gameplay. Conversely, omitting those ledgers but widening source allowlists would weaken save validation.
- Current Store parent rules and `contracts4` challenge fields are newer than its baseline. Preserve the exact four parent gates, grandfathered research/grants, frozen challenge terms, successful-redraw count, once-only bonus receipts and banked Promotion. The candidate's old-shape gate cannot simply classify these newer saves as the original old shape.
- `market_transaction_trial.gd` contains a12-cycle window, Review7.0 gate, capped per-Core lift8, sales penalties600/300/1200 basis points and floor7000. These are **OPEN/TRIAL inputs**, not approved canonical values. No effect is enabled by this review.

## Required next handoff

1. Obtain the separate numerical/visible-explanation decision already required by item22. If only neutral migration infrastructure is desired first, supply a new narrowly separated candidate with no active coefficients and its own acceptance contract.
2. Rebase/reconcile against current canonical source and name every admitted old source/revision. Retain original archived fixtures; add real current branch/challenge saves with completed bonuses, pending Promotion, admitted Research and active rival projects. Do not edit source IDs to make fixtures pass.
3. Rerun normal Store/Coordinator coverage for the other named presentation source families (`200a…`, `fd7e…`, `ac944…`), original-old-executable generation, Founder finance mismatch, raw root/row corruption, unsupported/mixed source and missing active card. Compare all player/rival state and RNG before/after pure Continue.
4. Cover next legal Studio commit, injected write failure/retry, explicit backup recovery and fresh-process restoration; then supported-size Gameplay and exported Continue on that exact source. Measure CPU/save size and longer campaigns with explicit bounds.
5. Keep Store/Core planners, entrants/news, population policy, final balance and Review/earned-sales leaderboards as separate OPEN design work. This intake does not resolve those policies or imply release readiness.

## Disposition

No AI gameplay files changed for this review. The approved neutral index and current rival foundation remain in use. The next action is a revised, approved adoption handoff; no unanswered question was sent to the user and no trial coefficients were silently selected.
