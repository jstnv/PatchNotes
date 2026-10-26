# Publisher commission private trial plan v6: policy identity repair

2026-10-22. **PROPOSED**. Continues [plan v5](PUBLISHER-COMMISSION-PRIVATE-PLAN-2026-10-22-v5.md) without changing its hypothesis, seed 1112, identical initial checkpoints, 5/7/6 hand limits, four-release target, 180 accepted-command limit per arm, 360-second process limit, or stopping conditions.

The v1 pair bundle at `sims/publisher-commission-1112-pair-20261022-v1/run-report.json` was a retained **setup failure**: the top-level and case policy declarations carried the prior R20 policy SHA-256 (`b760b9dc...`) while naming the new continuation policy. No campaign comparison ran. The new [v2 config](publisher-commission-1112-continuation-20261022-v2.json) changes only the policy identity fields to the actual SHA-256 of `publisher_commission_continuation_policy_v1.gd`, `6dad70ac5dea11a5c5c0dff62be1c3078dece0b75b9ad2e390c65a61edc17514`, and aligns the per-case id/version with the top-level declaration. Both initial checkpoint integrity strings still match. Preserve the v1 bundle and config.

Frozen candidate: `f64b1f8e46df066fe7587bc9ab2d22aec7a36e56874345a2c15022ab484da568`; private variant `simulators/publisher-progression-commission-market-v1`. The parent baseline has `baseline_drift=true` against later live canonical files; this is a same-candidate pair only. If the runner rejects again, retain its output and diagnose before any new version. If legal actions reject, retain the outcomes, including incomplete arms. Run exact fresh-process replays for completed arms before comparing.

Exact command from repository root:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/publisher-progression-commission-market-v1 --config docs/codex/threads/contracts/publisher-commission-1112-continuation-20261022-v2.json --output docs/codex/threads/contracts/sims/publisher-commission-1112-pair-20261022-v2 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
```
