# Two-full-Brief route on the current-market private candidate — v2 plan

2026-10-22 (America/Los_Angeles). **PROPOSED read-only experiment, not rule approval or canonical implementation.** This is a separate current-market-source test of the [v1 route hypothesis](PUBLISHER-R20-PROGRESSION-PLAN-2026-10-22-v1.md). The current market rules differ from the v1 candidate's older base, so the same seed does not establish matched states or equal outcomes. The [current-market Brief matrix](sims/publisher-brief-market-20261022-v1/run-report.json) completed five declared first-Brief cases; this plan asks whether two *distinct* full Briefs can be earned through later releases without injections.

## Frozen comparison and bounds

- Candidate: [Contracts-owned current-market private variant](simulators/publisher-progression-market-v1/variant.json), base identity `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415`; exact candidate/runner/Godot/policy hashes must come from the run report. No canonical file or player save is an input.
- Input: the unchanged [one-case config](publisher-r20-progression-v1.json) and [observation-only policy](publisher_r20_progression_policy_v1.gd). Sports/1104, no traits, legal `sprites`, `general_combat`, `levels` starter purchases, Sports/Fantasy. First game Design/Alpha/Beta hands 3/5/4; Games 2–3 use 2/2/2. The shortened later games test access, not recommended pacing.
- Hypothesis: Ironclad completion yields Brief 1 tied to Game 1; one full two-hand result awards R1000 basis points. Game 2 later issues a distinct Brief, whose full result brings SideStreet to R2000; Game 3 then commits from a Studio state that retained that standing. The policy rejects missing offers/cards or mismatched IDs and uses only visible candidates, no redraw/hidden RNG/Bank loan/injected cash.
- One fresh case, target three releases at Studio, maximum 300 commands and 360 seconds for the run process. The outer design horizon is five releases. Stop on the first rejection, timeout, invalid save or completion; retain all results. Check each Brief's source release/offer identity, grade, event, Reputation, cash/rent/Credit, later release and checkpoint. A success needs a fresh-process exact tape replay and focused candidate checks.

Verify the output folder is unused, then run:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/publisher-progression-market-v1 --config docs/codex/threads/contracts/publisher-r20-progression-v1.json --output docs/codex/threads/contracts/sims/publisher-r20-market-20261022-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 360
```

Inspect the resulting frozen source manifest, output and exact tape. Do not silently revise the policy, seed, starting purchases or limits after a rejection. This route can test issuance and access only; it cannot validate commission/supported-game economics or approve proposed R20 terms. Keep the independent-client cash Brief as the first selected new-type implementation priority unless the user changes it.
