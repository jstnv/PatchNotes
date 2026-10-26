# Current-source Crown second-release screen v25

2026-10-11 (America/Los_Angeles). **Completed bounded read-only screen; Crown gate still missed.** Four [predeclared v9 cases](PLAN-v9-current-crown-second-release.md) extended the v7-style current-source Sports starters through Game 2 under the existing bounded stress policy. This is not an exported C5 pass or a balance ruling.

## Source and exact run

`main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared documentation was concurrently dirty and preserved. [Run report](sim-v23/current-crown-second-release-run-01/run-report.json) pins frozen project identity `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`, policy identity `de20fc6f9ea48542e0596ac2794865df06bc1bc65021baf517cfd8361db83be0`, the [source manifest](sim-v23/current-crown-second-release-run-01/snapshot-manifest.json), input hashes and Godot 4.7.1 executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. This canonical/policy identity matches v23's v7 run, but these are fresh legal starts and not a checkpoint continuation. The [exact input](study-v9-current-crown-second-release.json) fixes seeds, card orders and 110-command/two-release/240-second bounds.

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --config docs/codex/threads/contracts/study-v9-current-crown-second-release.json --output docs/codex/threads/contracts/sim-v23/current-crown-second-release-run-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

| Sports case | Game 1 / 2 Review | Endpoint | Cash | Crown offer |
|---|---:|---|---:|---|
| 4417 configured | 4.9 / 5.1 | completed 66 commands, cycle39 | $2,168.39 | absent |
| 4417 shuffle | 4.6 / 5.0 | completed 66 commands, cycle39 | $2,379.21 | absent |
| 1104 configured | 5.1 / 5.4 | completed 66 commands, cycle39 | $1,760.27 | absent |
| 1104 shuffle | 5.6 / 5.4 | completed 66 commands, cycle39 | $2,458.98 | absent |

Each case's `result.json` and `studio_checkpoint.json` under [the retained run](sim-v23/current-crown-second-release-run-01/) contain exact commands, release metadata, finance, owned cards, RNG and offer state. All four legally completed, unlocked Ironclad and SideStreet, hired one Production Specialist and gained one later researched Feature; that Feature was not Recorded Sounds in any case. No case rejected or timed out; no Crown offer appeared. The [1104/shuffle representative fresh-process replay](sim-v23/current-crown-second-release-replay-01/run-report.json) passed all 66 commands and exact final state. The predeclared replay trigger for a Crown success was unmet; this extra miss replay checks reproducibility only.

The general stress policy neither targets the old exported route's Recorded Sounds research nor its specific Design, QA/Marketing and redraw choices. The result is a policy access miss, not proof that the Crown gate is unreachable or too high. Keep Crown ACTIVE/TRIAL terms unchanged and C5 PARTIAL. Next attempt, if pursued, must prospectively declare an Action Game-2 route using actual current quotes and available observations; preserve finance/rejections and stop at a fixed bound. Headless success would only provide an input recipe for separate source-matched exported acceptance.
