# Current-source Crown strategy comparison v24

2026-10-11 (America/Los_Angeles). **Completed bounded read-only comparison; both routes missed Crown.** The prospectively declared [v8 plan](PLAN-v8-current-crown-strategy.md) follows [v23's four-case general-policy miss](FINDINGS-v23-current-crown-gate-screen.md). No Contract number, code, save, or canonical project file changed.

## Source and run

Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; separate Feature Store design edit and Fanbase log were preserved. The [run report](sim-v22/current-crown-strategy-run-01/run-report.json) pins frozen project identity `942cd1240011b858112dbe513dc87c27dc30ba1f73442dcd8b360ccaad70281c`, supplied design-policy SHA-256 `0c1006f090a45e499af7764ff45fe0205c0b776ad85bed0e25f7367deba7f478`, input hashes and Godot 4.7.1 executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. The frozen project identity differs from v23 because this run copied a new external policy into its isolated debug folder; compare only within v24. No simulator variant or gameplay prototype was required.

Both cases used the exact [config](study-v8-current-crown-strategy.json): Sports/4417, Lean Production + Studio Buzz + Expensive Lease, Sports/Fantasy, 5/6/6 hands, no redraw/Store/borrow/Contract before the first release, 60-command bound, one-release target, 240-second timeout. The [thread-owned policy](current_crown_policy_v1.gd) chose either first-four visible cards or the declared public-observation synergy/QA score. It used current printed card fields and known bugs; it did not inspect hidden bugs, future draws or Run objects. The prior exported [Action/Cult40 route](../../findings/export-interaction-20261010-v2/README.md) had a different source/trait seed and Game-2 Store/redraw/QA/Marketing path, so it was not transplanted here.

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --config docs/codex/threads/contracts/study-v8-current-crown-strategy.json --output docs/codex/threads/contracts/sim-v22/current-crown-strategy-run-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

| Case | Result | First Review | Final cycle / accepted / productive commands | Cash after release | Crown pending? |
|---|---|---:|---:|---:|---|
| [Visible first four](sim-v22/current-crown-strategy-run-01/cases/sports-4417-visible/result.json) | completed | 4.9 | 18 / 29 / 18 | $975 | no |
| [Synergy/QA chooser](sim-v22/current-crown-strategy-run-01/cases/sports-4417-synergy-qa/result.json) | completed | 5.2 | 18 / 29 / 18 | $0 | no |

The Review, cash and pending-offer results are read from each [Studio checkpoint](sim-v22/current-crown-strategy-run-01/cases/sports-4417-synergy-qa/studio_checkpoint.json); both show Ironclad unlocked, no Crown offer, and a legal one-release completion. Neither case rejected or timed out. No success-triggered replay was required. A later representative [synergy/QA fresh-process replay](sim-v22/current-crown-strategy-replay-01/run-report.json) verified all 29 commands and the exact final state of that miss. The $0 cash endpoint is a measured liquidity limit; this one-release endpoint does not establish whether later settlement can cover rent.

## Recommendation and limits

Stop this seed/policy search as predeclared. Current C5 Crown exported acceptance remains PARTIAL, but the old [v17 7.1 slow-first result](FINDINGS-v17-crown-slow-first-screen.md) and [2026-10-10 exported 7.3 Game-2 route](../../findings/export-interaction-20261010-v2/README.md) demonstrate historical reachability under other legal strategies. Neither provides a source-matched current-build route automatically. The next targeted attempt should start from the prior exported Action Game-2 plan: genuine recorded-sounds research, larger Design supply, actual redraws, QA/Marketing decisions and real finance, with the current Cult20/Store/source changes explicit. Predeclare a finite route budget and preserve any miss. If a legal current route reaches Crown, replay and then test through ordinary exported UI at both sizes; keep headless and exported statuses separate. This evidence supplies no gate, advance, payout, Promotion or final-balance retune.
