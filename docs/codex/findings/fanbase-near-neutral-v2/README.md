# Fanbase near-neutral continuation v2 — 2026-10-08

**COMPLETE at the approved bounded read-only scope.** The single legal Game3 continuation reached Review **4.3**, inside `[4.0,5.0)`, with **93 launch Fans**. Both earning boundaries were affordable and reconciled. No additional attempt was run. The older v1 attempts remain historical misses.

## Source and policy

The [approved handoff](../../threads/fanbase/handoffs/2026-10-07-near-neutral-continuation-v2.md) and [predeclared plan](PLAN.md) fix Action / ordinary / seed1104 / available Contracts, genuine $5,700 creation and $500 rent. Source is isolated `codex/fanbase-quarter-trial` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` plus its existing two-file quarter-Awareness diff. [Source hashes](source.json), [branch diff](branch.patch) and [status](branch-status.txt) are retained. All gameplay remains unchanged. This branch predates current main's Genre, Banking, Employees, Traits and checkpoint integrations; the result is not an integrated-main balance test.

The first 35 actions / 32 cycles reproduce the verified prefix, normalizing release IDs only. Game1 launches at cycle12 with Review4.9 and zero Fans; Game2 launches at cycle32 with Review7.0 and zero Fans, then earns Fans during Game3. Game3 uses exactly four Design, four Alpha and four Beta hands plus departure, launching at cycle45. Native visible-card/redraw/QA choices and Review RNG are preserved. Actual Review is4.3, Scope29/30, launch Awareness129 (23 from frozen Fans), projected Month1 units505 and cash559,383 cents.

Normal Game4 departure reaches cycle46; two ordinary Design hands reach cycles47–48. Capture stops there, immediately after the second Game3 earning boundary. There is no Game4 launch, free wait, injected outcome or later-release projection. All actions succeeded; no financial or policy blocker occurred.

## Observed Fan accounting

Reach is the cumulative Review-neutral sales estimate, not unique buyers. The first boundary contains one earning cycle because Game3 launched on an odd cycle.

| Cycle | Newly earned units | Cumulative neutral reach | New capped exposure | Cumulative loss target | Game3 loss | Other-title gain | Starting → ending Fans |
|---:|---:|---:|---:|---:|---:|---:|---|
|46|252|293|93|9|9|1|93 → 85|
|48|325|671|0|9|0|1|85 → 86|

The provisional formula gives `floor(93 × 15 × 7 / 1000) = floor(9.765) = 9`. Rounding removes0.765 Fan from this cumulative target; it does not hide the loss. The weak title loses9 of93 launch Fans (about9.7%). The first boundary's net studio decline is8 because another title gains1. The exposure cap is already exhausted at the first boundary, so the second boundary adds no loss. Shared starting-Fan limits are93 and85; neither binds in this route. Separate focused fixtures verify the shared cap and exact5.0 neutrality.

This meets the commissioned target band. It does **not** directly observe Review4.8–4.9 or prove final fairness/balance near5.0. The [rounding screen](../../threads/fanbase/2026-10-08-near-neutral-rounding-screen-v1.md) remains a calculated sensitivity, and the accepted zero-minimum-loss rule remains unchanged. The15% loss coefficient,8% gain coefficient, reach/reserve proxy, overlap and final Awareness mapping retain their existing OPEN / ACTIVE/TRIAL statuses.

## Exact finance

| Cycle | Game3 cumulative units | Game3 net earned, cents | Game3 settled, cents | Unsettled, cents | Studio cash, cents |
|---:|---:|---:|---:|---:|---:|
|46|252|176,223|176,223|0|698,893|
|47|505|353,146|176,223|176,923|662,893|
|48|577|403,496|403,496|0|824,557|

At the endpoint, portfolio net earned and settled sales both total1,672,724 cents; rent due and paid both total1,200,000 cents. No unpaid rent remains. The observed cycle-state cash low point is148,000 cents. Complete direct costs, receipts, earning and settlement timing are retained in the raw action and finance journals.

## Verification and reproduction

- Import and existing `verify_studio_fanbase.gd` exit0; exact5.0, duplicate callback, quarter-Awareness and shared-loss-cap checks pass.
- Single native capture exits0, valid, no errors/blockers/discrepancies;55 native ledger checks and418 row checks.
- Recorded-journal reconstruction passes1,391 checks with zero failures, including repeated-boundary rejection and exact observed Fan/sales/cash parity. Its inherited log label says “Fan counterfactual,” but this version runs only the observed arm (`no_loss=false`); no counterfactual or additional playable route was run.
- [Independent audit](audit.json): **11,917 checks pass** for the full prefix against both earlier captures, accepted4/4/4 hands, two earning boundaries, integer targets, exposure/shared cap and exact cash/accrual. All597 captured files are unchanged;295 runtime files match both the prior archive and the preserved isolated branch. Branch HEAD/diff/status are unchanged.

Commands used with the bundled Python executable: `run.py prepare import verify_studio_fanbase`, then exactly once `run.py attempt reconstruction`, then `audit.py`. Each Godot command, isolated profile and exit/error result is in its `*.command.json`; raw native trace is `attempt.json.gz`, logs are adjacent. `attempt-started.txt` prevents accidental reuse of the one-attempt allowance. `run.py` verifies the prior archived source before preparing a disposable project; its analysis scripts are copied here for review.

Known inherited missing-artwork/scene-case warnings and the environment's root-certificate warning remain in logs. This is headless native evidence, not visible exported acceptance. No gameplay edit, merge, commit, push or release claim. Other TODO work remains on hold under the user's current instruction.
