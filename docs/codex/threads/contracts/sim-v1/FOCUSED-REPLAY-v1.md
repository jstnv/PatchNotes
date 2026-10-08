# Task 34 focused current-source replay, v1

2026-10-07 (America/Los_Angeles). **Read-only finding; no advance was simulated or approved.** Source: `main` at `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`. The [source manifest](SOURCE-MANIFEST.json) hashes 609 copied project files against the original checkout. Only two copied analysis files differ: the current Studio Traits start and the output/mode selection. The original `patch-notes` tree has no tracked changes from this run.

## Setup and checks

An isolated Godot 4.7.1 project under this folder used the current scripts, scenes, data, resources and assets. It ran the historical [`task32_strong_probe_v1.gd`](../../../../../patch-notes/analysis/task32_strong_probe_v1.gd) Action/synergy/seed-4417 route, including the existing `recorded_sounds` Store purchase and live Ironclad/SideStreet actions. Its copied parent analysis script now uses either genuine `set_studio_name` legacy creation or the current Studio Traits → Review → Confirm flow with one background and no secondary previews. Both modes use the same card policy, seed, $500 rent, live credit, sales settlement and finance code. The trait mode's `creation` snapshot confirms $5,500 base plus a separate once-only $200 `studio_trait_unspent_points_v1` financing transaction, with effects in `selection_only_preview` mode.

The [isolated import](isolated-import-legacy.command.json), [legacy route](legacy-strong-probe.command.json), [trait route](trait-strong-probe.command.json) and [comparison](compare_replay.py) all exited 0. Both native routes report `valid: true`, zero errors and zero discrepancies. The comparison independently checks every final finance transaction's exact-cent cash chain, then pairs action and release signatures. Its full [summary](REPLAY-SUMMARY.json) and [raw legacy](legacy-strong-probe.json) / [raw trait](trait-strong-probe.json) captures are retained here. The initial external-script crash and the switch to the isolated copy are recorded in [REPLAY-ATTEMPT.md](REPLAY-ATTEMPT.md).

## Results

| Route | Start | Game 1 | Game 2 | Cycle-32 state before next Beta action | Subsequent reach |
|---|---:|---|---|---|---|
| Historical Task 32 | $5,500 | Review 3.8, cycle 12, $1,420 | Review 9.0, cycle 32, $0 | $147.65 rent arrears; credit 598 | Beta production and then SideStreet hand blocked |
| Current-source legacy | $5,500 | Review 3.8, cycle 12, $1,420 | Review 9.0, cycle 32, $0 | $147.65 rent arrears; credit 598 | Same two blocks; two releases |
| Current Studio Traits | $5,700 | Review 3.8, cycle 12, $1,620 | Review 9.0, cycle 33, $52.35 | $52.35 cash, no arrears; credit 603 | Beta action and SideStreet hand proceed; four releases by cycle 73 |

The current legacy route reproduces all 38 historical action signatures and both release signatures (Review, Scope, Awareness, cycle and cash). The historical and current captures are not byte-identical because generated IDs and full nested snapshots differ. The two current runs have **33 matching finance actions through cycle 32** after excluding the trait run's separate startup financing row: kind, cash delta, productive flag, cycle, earned sales and settled sales all match. At cycle 32, rent month 16 saw $352.35 before payment in the legacy run and $552.35 in the trait run. The legacy run paid $352.35 of the $500 bill and owed $147.65; the trait run paid $500 and retained $52.35.

The first non-cash action divergence is **action 35**: the next Game-2 Beta action fails at cycle 32 for legacy and succeeds, reaching cycle 33, for the trait run. That extra productive action moves the Review-9.0 Game-2 launch from cycle 32 to 33. Both Game-2 snapshots unlock Crown; Awareness 107 does not unlock Neon. Neither publisher has a live offer. The observed paired difference is consistent with the separate $200 receipt, but the two creation paths also differ, so this small replay alone is not a full causal or balance study.

## Recommendation and limits

Task 34 should retain **separate real $5,500 legacy and $5,700 current-start arms**. The $147.65 block is reproduced for the former, while this matched current-start route reaches the same Review 9.0 without that block. A Crown advance cannot be selected by simply clearing the historical arrears; the later-offer trial still needs legal eligible hands, acceptance timing, two rent boundaries, the fixed-cap payout redistribution, and paired alternatives. Neon requires a separate Awareness-eligible route. No $0/$150/$200/$300 advance, Crown/Neon offer or Promotion was simulated here; all values remain OPEN candidates.
