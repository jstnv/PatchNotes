# Annual awards pure rules implementation — 2026-10-31

Task2 only, coordinated canonical implementation. Intake branch `main`, HEAD `49d769235474a880a73d996499cefa72beec63e5`. Existing tracked/untracked work was inspected and preserved; other disjoint awards owners were concurrently editing. No claim of whole-source immutability, commit, push, export or release acceptance.

## Owned changes

- `patch-notes/scripts/awards/annual_awards_rules.gd`: pure `rank(year,cutoff_cycle,studios,games)` and typed `schema()`, constants VERSION/NOMINEE_FANS/WINNER_FANS/WINNER_AWARENESS.
- `patch-notes/scripts/debug/verify_annual_awards_rules.gd`: maintained focused behavioral verifier.
- This `rules-*` evidence only. Shared design/state/TODO/session-closeout records remain the primary owner's responsibility.

The seven IDs are graphics, sound, technology, design, rising_studio, studio_of_the_year, game_of_the_year. The first four metric_kind values are native `&"core"`; others are gained_fans, fans, review_tenths. Studio nominees have empty native release ID/title. Every output array uses stable ordering. All supplied valid Studio inputs are frozen; only eligible current-year games committed by the inclusive cutoff are frozen. Studio awards require at least one eligible game. Sales extras are ignored and never enter frozen scoring input. Malformed required fields, duplicate textual identities (including cross-owner duplicate release IDs), orphan games, negative/float scoring inputs, invalid Review bounds and post-gift Fan overflow reject the entire plan as `{}`. Awareness-bank addition is intentionally the owner receipt/world preflight responsibility because it is absent from this pure input contract.

## Checks and commands

For each invocation, APPDATA and LOCALAPPDATA were redirected into the corresponding evidence directory's own `profile/APPDATA` and `profile/LOCALAPPDATA`. No test reads or writes player saves.

Canonical command (PowerShell, repository cwd):

```powershell
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe' --headless --path patch-notes --script res://scripts/debug/verify_annual_awards_rules.gd
```

- `rules-red/output.log`: initial test-first RED before the rules implementation existed, expected missing-ranking assertion, checks1/failures1, exit1. No parse failure. Retained exit warning:10 ObjectDB instances from autoload startup.
- `rules-green-v1/output.log`: implementation GREEN, checks49/failures0, exit0; same10-instance startup/exit warning retained.
- `rules-red-behavior/`: additional verifier sensitivity experiment. A detached copy of the already-written verifier points at the included no-op `missing_rules.gd` (`rank` returns `{}`). Invoked with the same command except `--script` uses the absolute path to `rules-red-behavior/verify_missing_rules.gd`. Expected failures concern absent seven empty awards and absent sole-game winners: checks3/failures2, exit1. No canonical source changed for this experiment. This additional RED is a sensitivity experiment after implementation, distinct from the initial test-first RED.
- `rules-final/output.log`: fresh isolated final canonical invocation, checks49/failures0, exit0, no script/engine errors or leak warnings in this run.

Coverage:0/1/2/3+ nominee counts; no fabricated entries; exact category Core; exact Review tenths; textual Studio/release ties; Studio eligibility; cutoff equality/prior/future years; multiple nominations/wins; hand-counted350/400/70/20 Fan gifts and35 Awareness; input order independence; no caller mutation/alias; maximum integer scores and exact post-gift balance bound;14 malformed/duplicate cases; unsupported year/cutoff; sales independence; typed checkpoint codec round trip.

## Source pins and limits

Final SHA256:

- annual_awards_rules.gd: `13dcd8b36e5fe63fd3d51000c03f4b255721dce85a55139a5eb611d2f30bc998`
- verify_annual_awards_rules.gd: `de74acc4290becb793b7b81e81eb1cece27591a0e34d7cb8934e8542e3214b57`

PASS applies to pure rules and native result-codec behavior only. Global committed cutoff extraction, all-owner payout atomicity, save migration, replay, first-ceremony progression, actual career flow and native presentation are primary/other-owner integration gates. The complete `tools/release_gate.py` suite was not run by this subtask while canonical integration was concurrent; primary owns coordinated maintained regressions and final acceptance. Reward values remain ACTIVE/TRIAL.
