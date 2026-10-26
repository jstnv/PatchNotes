# Contract challenges private scorer, v1 finding (v3 candidate)

2026-10-17 (America/Los_Angeles). **CANDIDATE scorer only; no canonical challenge gameplay or reward.**

## Source and setup

- Repo `main` at HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty. The canonical source identity when captured was `9382c90ec435272f4caf577d3c8bcd4b59ab89b0d86086db7f4b776c2c0bd1be`.
- Private v1 candidate identity `81cf354068360fe96e726c73dd03c04037677296a272a4cd15cdd210a7c7a927`. Private clean [v2](simulators/contracts-challenges-v2/variant.json) forks it, preserves the original baseline and removes six unrelated import-generated UID files. Its tested candidate identity is `db0fb6983687daa7455e09b2b095cb400c0c91d36fc6ace3cdc7a8371ab6f240`; the three `.gd` files in the delta are byte-identical to v1.
- [v3](simulators/contracts-challenges-v3/variant.json) forks v2 and adds an input/specification bound of 1,000,000, keeping all multiplication and addition intermediates used by the scorer below signed 64-bit overflow. Its tested candidate identity is `bf2749717609ee3fb8903500265f50680a048526e82b4fa1998760dbd653835b` and its delta remains five paths. The trial scoring numbers themselves are unchanged from v2.
- Godot 4.7.1 stable, executable SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. The plan and assumptions are in [CHALLENGES-PLAN](CHALLENGES-PLAN-2026-10-17-v1.md). Legal route: `action-cult20-4417-crown-no-reuse`, seed 4417, Action/Cult20 Studio, no cross-revision checkpoint import, at most 125 commands/four releases/240 seconds.
- Candidate scoring is pure and integer-only. It attaches candidate specifications to publisher definitions but does not record successful redraws, compute a cash or Promotion bonus, change settlement, show UI, or persist challenge state.

## Exact commands and evidence

From repository root, with the bundled Python and Godot paths shown:

```powershell
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/contracts-challenges-v2 --config docs/codex/threads/contracts/study-v12-current-crown-no-reuse.json --output docs/codex/threads/contracts/sim-v28/challenge-v2-route-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sim-v28/challenge-v2-route-01 --case action-cult20-4417-crown-no-reuse --output docs/codex/threads/contracts/sim-v28/challenge-v2-replay-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --variant docs/codex/threads/contracts/simulators/contracts-challenges-v3 --config docs/codex/threads/contracts/study-v12-current-crown-no-reuse.json --output docs/codex/threads/contracts/sim-v28/challenge-v3-route-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py replay --bundle docs/codex/threads/contracts/sim-v28/challenge-v3-route-01 --case action-cult20-4417-crown-no-reuse --output docs/codex/threads/contracts/sim-v28/challenge-v3-replay-01 --godot 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```

For the v3 direct verifier, set each process environment variable `APPDATA`, `LOCALAPPDATA`, `HOME`, `USERPROFILE`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `TMP`, `TEMP`, `TMPDIR` to its newly created subdirectory under `sim-v28/challenge-v3-verifier-01/`, remove `GODOT_USER_HOME`, then run:

```powershell
& 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe' --headless --path docs/codex/threads/contracts/sim-v28/challenge-v3-route-01/project --script res://scripts/debug/verify_contract_challenges.gd
```

- [v2 run report](sim-v28/challenge-v2-route-01/run-report.json): PASS, 85 accepted commands, four releases, cycle 34. [Exact replay](sim-v28/challenge-v2-replay-01/replay-report.json): PASS, 85 steps, final digest `43432d962370b53535761dbc60432fa0602f971b343e550c6a0240b7932074c6`.
- [v3 run report](sim-v28/challenge-v3-route-01/run-report.json): PASS, 85 accepted commands, four releases, cycle 34. [Exact replay](sim-v28/challenge-v3-replay-01/replay-report.json): PASS, 85 steps, same final digest. [v3 scorer verifier](sim-v28/challenge-v3-verifier-01/verify.log): 31 PASS, zero failures, including rejected excessive inputs and safe bounded extreme.
- [Current-source control](sim-v28/challenge-control-route-01/run-report.json) and [control replay](sim-v28/challenge-control-replay-01/replay-report.json) used the same config and fresh legal start. Control, v2 and v3 have identical initial conditions and 85/85 accepted flags and state digests, including the final digest. Candidate definition metadata is not applied to settlement in this route.
- [v1 scorer log](sim-v28/challenge-scorer-02/verify_contract_challenges.log): 27 PASS, zero failures. It covers all five kinds, combined grade, and common malformed inputs. [Six v1 focused logs](sim-v28/challenge-regression-01/) contain 461 PASS, zero failures across balanced, SideStreet, publisher cash, Starwave, Publisher Connections and definition checks. The `.gd` candidate delta is byte-identical in v2, but these direct checks were run against v1.
- The first two direct v2 scorer launches crashed in Godot before any assertions with signal 11/exit 1. They used an incomplete hand-set `GODOT_USER_HOME` environment. Repeating with the runner's full isolated `APPDATA`, `LOCALAPPDATA`, `HOME`, `USERPROFILE`, `XDG_*` and temporary paths passed [v2's 27 assertions](sim-v28/challenge-v2-verifier-03/verify.log) and v3's 31 assertions. The initial launches remain failed setup attempts; no scorer assertion failed.

## Interpretation and limits

The private scorer can grade the requested shapes without changing the observed existing route. In that route the candidate Crown balance score would be zero: final four Core half-unit totals `[30,18,10,14]` differ by 20, beyond the candidate allowed gap 4 and fade width 8. One route does not show whether that challenge is attainable or enjoyable. No earned challenge cash or Promotion was tested. Successful-redraw tracking, finance posting, result UI, restart/rollback, old-save compatibility, and graphical/exported acceptance are **NOT RUN**. Candidate numerical terms and publisher assignments remain OPEN; these passing simulations do not approve them.

Recommendation: retain v3 as a structural scorer prototype. Build the separate reward and checkpoint path in a new private variant after the trial caps and assignment are reviewed, then test legal full/partial/missed Contract routes and restarts before preparing canonical adoption.
