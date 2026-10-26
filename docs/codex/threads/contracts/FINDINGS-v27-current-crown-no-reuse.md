# Crown second-launch Promotion no-reuse v27

2026-10-11 (America/Los_Angeles). **Completed bounded read-only headless check; C5 exported acceptance remains PARTIAL.** Crown's existing ACTIVE/TRIAL values were unchanged. [Predeclared plan](PLAN-v12-current-crown-no-reuse.md) extended the [v26 legal Crown route](FINDINGS-v26-current-crown-continuation.md) by one launch using the *same* private policy and legal fresh initial recipe.

## Identity and exact reproduction

- Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty documentation checkout; no canonical gameplay/test/asset/config change. Godot `4.7.1.stable.official.a13da4feb`, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- [Input](study-v12-current-crown-no-reuse.json): one Action/Cult Following20 seed4417 case, identical v11 recipe and `current_action_crown_policy_v4.gd`, four-release target, 125-command ceiling, 240-second timeout. Only the target and ceiling changed from v11. Policy SHA-256 `1ee14d9a22b0cbfc58a80a16e2f68db06e20aad33ddf1cab5e60124b99936b55`; [run report](sim-v26/current-crown-no-reuse-run-01/run-report.json) frozen project identity `dd5c1d293facc31fdc384ab13d22232e9c218d32737f15b7f13a6324e2d79c11`, matching v11. The run bundle retains exact input hashes, source manifest, tape, checkpoint and result.
- Run completed **85/85 accepted commands**, cycle34, four releases. [Fresh-process replay](sim-v26/current-crown-no-reuse-replay-01/replay-report.json) matched all 85 steps and final state `f1c475182a42f2130a422106eeb7f44edf843b85ade66677997e249fcada6871`. The first **70/70 accepted/state digests** match the [v11 exact replay](sim-v25/current-crown-continuation-replay-01/replay-report.json), including step70 state `68570602a7864982bf0fa9d57b2033caf4823dabae3bc9b10e2bb52452d6ba62`. Equal seeds alone were not used as compatibility proof.

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --config docs/codex/threads/contracts/study-v12-current-crown-no-reuse.json --output docs/codex/threads/contracts/sim-v26/current-crown-no-reuse-run-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sim-v26/current-crown-no-reuse-run-01 --case action-cult20-4417-crown-no-reuse --output docs/codex/threads/contracts/sim-v26/current-crown-no-reuse-replay-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

## Measured continuation

The [Studio checkpoint](sim-v26/current-crown-no-reuse-run-01/cases/action-cult20-4417-crown-no-reuse/studio_checkpoint.json) retains one Crown offer `contracts-v10-action-4417:crown_quill:first`, marked paid with two hands and the same full $1,920 direct result. The keyed `promotion_awards` entry remains **12**, while `promotion_consumed` points to **Game3** (`contracts-v10-action-4417:project:3`). A Neon offer is also pending; the policy did not accept it. Monthly finance shows publisher income only in months4/5 (Ironclad) and month13 ($1,920 Crown), with no later Crown publisher income.

Game3 froze Awareness **147 = 100 base + 30 Fan + 5 Marketing + 12 Crown Promotion** at cycle30. Game4 froze Awareness **115 = 100 base + 11 Fan + 4 Marketing + 0 Crown Promotion** at cycle34. Game4 was a deliberately minimal one-hand-per-phase release: Review0.4, Scope11/30, six bugs. Endpoint cash was **$10,043.56**, credit **613**, zero overdue and no financial block. These finance values are route observations, not a publisher-value comparison.

**Conclusion:** this legal source-pinned headless route supports once-only Crown Promotion through a second successful launch and no duplicate Crown payout/offer. It does not verify the exported UI, keyboard presentation, same-binary Continue, uncommitted acceptance rollback, source changes after the frozen copy, human understanding or final balance. Preserve C5 **PARTIAL** and use [handoff v3](HANDOFF-C5-CROWN-ROUTE-v3.md) for current-build acceptance.
