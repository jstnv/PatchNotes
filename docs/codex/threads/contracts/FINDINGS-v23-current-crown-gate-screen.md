# Current-source Crown gate screen v23

2026-10-11 (America/Los_Angeles). **Completed bounded read-only screen; Crown access not demonstrated.** This tests the [prospective v7 plan](PLAN-v7-current-crown-gate.md), not a new Contract rule. Existing Crown terms remain approved ACTIVE/TRIAL; C5 exported acceptance and final publisher balance remain OPEN.

## Source, setup and command

- Repository `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; dirty tracked `docs/codex/design/feature-store-progression.md` belonged to another thread and was preserved. The isolated [run report](sim-v21/current-crown-gate-run-01/run-report.json) pins frozen project identity `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`, policy identity `de20fc6f9ea48542e0596ac2794865df06bc1bc65021baf517cfd8361db83be0`, input hashes, complete [source manifest](sim-v21/current-crown-gate-run-01/snapshot-manifest.json) and Godot 4.7.1 executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Import reported no source changes. No candidate gameplay project was needed because existing behavior was tested.
- Four independent legal fresh Sports Studios: seeds 4417/1104, no traits, fantasy theme, 5/6/6 Design/Alpha/Beta hands, existing `features_first` policy, either configured or independently seeded shuffle card order. `policy_seed` was 4917/1604 respectively. [Exact config](study-v7-current-crown-gate.json) and [predeclaration](PLAN-v7-current-crown-gate.md) fix all inputs. Maximum 60 commands, target one release and 240-second process timeout per documented runner. No seed or bound was changed after observing results.
- JSON validation and the isolated run used the bundled Python at `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` and `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --config docs/codex/threads/contracts/study-v7-current-crown-gate.json --output docs/codex/threads/contracts/sim-v21/current-crown-gate-run-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

The initial attempt used `python` from PATH and failed because that command was unavailable in this shell. It created no run folder. The command above used the bundled Python and completed; the tool failure was setup, not a route result.

## Results

| Case | Status | First Review | Cycle / productive commands | Cash after release | Crown pending? |
|---|---|---:|---:|---:|---|
| [Sports/4417 configured](sim-v21/current-crown-gate-run-01/cases/sports-4417-configured/result.json) | completed, 29 accepted commands | 4.9 | 18 / 18 | $1,060 | no |
| [Sports/4417 shuffle](sim-v21/current-crown-gate-run-01/cases/sports-4417-shuffle/result.json) | completed, 29 accepted commands | 4.6 | 18 / 18 | $1,110 | no |
| [Sports/1104 configured](sim-v21/current-crown-gate-run-01/cases/sports-1104-configured/result.json) | completed, 29 accepted commands | 5.1 | 18 / 18 | $1,060 | no |
| [Sports/1104 shuffle](sim-v21/current-crown-gate-run-01/cases/sports-1104-shuffle/result.json) | completed, 29 accepted commands | 5.6 | 18 / 18 | $1,060 | no |

The released-game Review and cash figures above are from each source-pinned `studio_checkpoint.json`; all four show an Ironclad unlock and no Crown offer. All cases completed within bounds, with no rejected or timed-out case. No success-triggered replay was required. A later representative [Sports/1104 shuffle fresh-process replay](sim-v21/current-crown-gate-replay-01/run-report.json) verified all 29 commands and the exact final state of that miss. These four strategies cannot serve as a Crown C5 exported-input recipe.

## Interpretation and recommendation

The [historical v17 Sports/4417 route](FINDINGS-v17-crown-slow-first-screen.md) reached 7.1 with **Lean Production + Studio Buzz + Expensive Lease**, a synergy/mixed/QA card policy and an older pre-Education source. V23 deliberately used no traits and the current general stress policy. The difference in Review is therefore confounded by source, traits and card choices; it is not evidence that Crown's gate became unreachable or that its number should change.

For a current-source route, prepare a *new* bounded policy that uses only public hand observations and explicitly reproduces a player-feasible synergy/mixed/QA choice plan, plus the historical trait bundle. Predeclare seeds, hand count, draw/redraw and exit rules, route budget and stopping conditions before running. Preserve misses, replay any successful route and hand its exact choices to the implementing/release thread for ordinary-input exported Crown acceptance. If no legal route emerges within the declared scope, leave C5 PARTIAL with its exact access blocker. Do not treat headless reachability as exported presentation, input, receipt, Promotion or Continue acceptance.
