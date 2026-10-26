# Independent exposure-study review — 2026-10-22

## Scope and conclusion

Reviewed `PLAN.md`, `exposure.gd`, `run.py` and `summarize.py` against the current production Review, market, sales and Fanbase formulas. No concrete formula, double-counting or missing-month defect was found in the intended four-route/six-release protocol. The original-versus-counterfactual comparison is valid **at its fixed factual inputs**, subject to the boundaries below.

Gameplay source identity is `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536`; the repaired harness's actual file-byte SHA-256 is `70a2417de4e1223fd059e9929cdc23098950d60bfe7c362b7326a3c3e8c3add1`. The provenance record distinguishes its normalized-LF hash from its actual Windows file bytes and retains the failed parse version. No gameplay or Bank changes were made by this review. The final arithmetic audit covers all eight completed v2 record reports. Fresh-process replay acceptance is separate evidence and is not included in this audit's check count.

## Formula and attribution assessment

- **Review:** `_fixed_review` matches the production category-ratio cap1.25, mean minus half the population standard deviation, scale8, Scope and Bug multipliers, fixed variance modifier and half-up one-decimal rounding. The harness first reproduces the actual completed Review, then substitutes only Genre-base standards. It does not also change launch units, Awareness, decisions or later projects when comparing sales.
- **Sales:** each replay starts from the actual launch inputs and iterates every earned cycle. It supplies the saved factor for the factual branch, recomputes exclusive buckets after retaining only the player's own facts for the second branch, and supplies neutral factors for the third. `Market.sales_factor` excludes the earning title itself. Original monthly snapshots determine inclusion and expiry; the second earning half reuses its age-month factor. The factual replay must equal every authoritative sales-record field, including cumulative units, entitlement, settlement and factor history.
- **No cumulative double-counting:** summary totals sum each title's final cumulative record once. They do not sum cumulative observations across months. Per-age-month counts are exposure counts, including partial final months and dormant titles; they are not months with positive sales or separate unique publications.
- **Floor interaction:** actual versus own-title-only is the marginal effect of removing rival facts while preserving own-title pressure. Own-title-only versus fully neutral is the remaining marginal effect. These telescope to the total fixed-input difference, but the70% floor means this ordered decomposition is not a unique allocation of causal shares. Rival presence can have zero marginal effect when own-title pressure alone already reaches the floor.
- **Fan gains:** the cumulative target uses `floor(max(0, earned_units - actual_launch_fans) * 8 * clamp(review_tenths - 50, 0, 30) / 2000)` at actual even calendar boundaries. Keeping the last such target correctly excludes uncommitted odd-half gains. Each factual target must equal the production Fan ledger. The title's launch reserve is applied once cumulatively, not once per month.
- **Fan losses:** the factual loss shadow remains Review-neutral and market-neutral. Under the study's fixed actual launch inputs and Review, crowding does not change its exposure calculation. The study does not simulate alternative Studio starting Fans, shared-loss availability, later launch Fans or Awareness; it must not describe its gain targets as an alternative final Studio Fan count.
- **State/source integrity:** counterfactuals operate on returned value records, and the harness checks live state/RNG before and after them. Every process requires the declared mechanical source and asserts equal start/end identities. Fresh-process tapes compare actual player/rival results and complete replay state. Different recipe IDs create different worlds; equal numerical seeds across routes are not treated as paired RNG experiments.

## Independent arithmetic check

[review-arithmetic-audit.json](review-arithmetic-audit.json) retains the initial 432-check, two-record audit unchanged. After all eight records completed, the reusable checker produced a separate [review-arithmetic-final-v1.json](review-arithmetic-final-v1.json):

| Record | Independent checks | Failures |
| --- | ---: | ---: |
| Action/War seed4417 v2 |216|0|
| Action/War seed4418 v2 |216|0|
| Action/Fantasy seed4417 v2 |216|0|
| Action/Fantasy seed4418 v2 |216|0|
| Puzzle/War seed4417 v2 |216|0|
| Puzzle/War seed4418 v2 |216|0|
| Puzzle/Fantasy seed4417 v2 |216|0|
| Puzzle/Fantasy seed4418 v2 |216|0|
| Total |1728|0|

The Python calculation independently derives Scope completion, Bug multiplier and variance from raw recorded inputs; reproduces both actual and Genre-base Reviews; counts own-only exclusive factors; verifies every earned age month exists; and rebuilds all three branches' cumulative units, exact entitlement/settled cents and settled Fan-gain targets with integer arithmetic. This is arithmetic verification of eight source-pinned reports, not another gameplay run. The final checker exited 0 with zero arithmetic failures and zero input errors. Each record's corresponding run file was inspected first: exit 0, no timeout and no parsed errors.

The final output pins each input report and checker by SHA-256; checker identity is `59eebab6d5ce299b4f7272c1fbb8829da88549f7f59f03a3832a3899e7f8866a`. All eight reports declare the same expected starting/ending mechanical source and no drift. Post-audit readback confirmed all eight report hashes, the actual harness bytes and checker bytes remained unchanged. The two original report hashes still match the retained initial audit.

Across all eight route/seed cases, the 48 actual Reviews range from 1.3 to 2.4; all 144 settled Fan-gain targets across the three branches are zero. This establishes no observed positive-gain exposure in this sample. It does **not** establish that market crowding cannot reduce Fan gains in higher-quality releases. The study still has no alternate Studio Fan trajectory or policy/campaign counterfactual.

### Reproducing the arithmetic audit

The reusable [audit.py](audit.py) accepts explicit completed report paths and an expected mechanical source identity. Run from this finding folder, choosing a new output filename:

```text
python audit.py --source 5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536 --output review-arithmetic-repeat-v1.json action-war-4417-v2.json action-war-4418-v2.json action-fantasy-4417-v2.json action-fantasy-4418-v2.json puzzle-war-4417-v2.json puzzle-war-4418-v2.json puzzle-fantasy-4417-v2.json puzzle-fantasy-4418-v2.json
```

Inputs are read-only; the checker rejects duplicate inputs and creates its output exclusively, preserving earlier evidence. The result pins the checker and every input's SHA-256. This persisted version passed Python syntax parsing and `--help`, then the final eight-record audit above. No Godot process was started by this independent review.

## Reporting limits

CPU covers the whole process, including inspection/replay/checkpoint work. Per-command/world timings are separately recorded. Godot's reported peak static allocation is not total OS working-set memory; the per-step samples also precede the final counterfactual pass. Save-byte measurements serialize the checkpoint pair and its digest, not a standalone on-disk envelope or complete profile size. None establishes a stable rival-population budget.

This is bounded design evidence. It does not approve final coefficients, an optimized policy, new Store planning, entrants, leaderboard rules, player challenge targets or release readiness. Ordinary old-save/graphical Continue remains separately cited adoption evidence rather than an outcome of this fresh-campaign study.
