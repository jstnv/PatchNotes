# Native Starwave matched continuation v13

This folder implements the [predeclared read-only comparison](PREDECLARATION.md) for Action 1104, Puzzle 4417 and Racing 1104. It uses the exact successful v12 before-Starwave payload bytes. The runner verifies the native-v3 source manifest and copies only playable runtime files to a new disposable Godot project. It never runs against the repository, the original native-v3 pin, or v12's project copy.

`cross_specialty_base.gd` is a frozen copy of the v12 native route helper; `matched_continuation.gd` hydrates each cohort checkpoint independently for each arm. The Starwave arm accepts and completes three actual hands; the skip arm starts Game 4 with the earned offer pending. Both use the same inherited synergy/mixed/QA card choice and redraw policy. Game 4 Design/Alpha/Beta deal and finalization RNGs are reseeded from `cohort_seed + 1,500,000` by the common native `_develop_game` helper in both arms; it also uses the same deterministic Review variance verifier hook. The [protocol clarification](PREDECLARATION.md#2026-10-09-protocol-clarification-after-adapter-failures) fixes Game 5's actual native entry at deal/finalization seeds `cohort_seed + 2,000,003` and `+ 2,000,004`, initial project priorities before draft commit, and no manual later priority change. Contract draws consume their own run stream in the Starwave arm. The same project hand seeds keep project card choices comparable, while the preserved run RNG/finance/identity traces expose any other divergence. No launch score, cash, debt or offer is directly set.

Run in order from the repository root with the bundled Python:

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py docs/codex/threads/contracts/sim-v13/run.py prepare
& $py docs/codex/threads/contracts/sim-v13/run.py import
& $py docs/codex/threads/contracts/sim-v13/run.py attempt action-1104 starwave
& $py docs/codex/threads/contracts/sim-v13/run.py attempt action-1104 skip
& $py docs/codex/threads/contracts/sim-v13/run.py attempt puzzle-4417 starwave
& $py docs/codex/threads/contracts/sim-v13/run.py attempt puzzle-4417 skip
& $py docs/codex/threads/contracts/sim-v13/run.py attempt racing-1104 starwave
& $py docs/codex/threads/contracts/sim-v13/run.py attempt racing-1104 skip
```

Each arm writes `matched-route.json`, `attempt.json`, `command.json`, `godot.log`, and `source-after.json`. The native route records complete initial typed checkpoint equality, initial RNG, actual actions, Starwave hands and cash, Game 4 release, Game 5 progress, original finance transactions and common-cycle 75/77/79 snapshots. An arm failure remains an immutable result with a stop reason. The independent audit and findings interpretation belong outside this raw harness, after all six results are inspected. The initial three v12 checkpoints have different cash, ratings and rosters; compare arms within each cohort only.

## Verified execution

The final [repair-v4](repair-v4/README.md) completed all six legal arms. Every arm reports a valid native route, empty stop, identical typed start within its pair, cycles 75/77/79, a valid finance ledger and clean source/driver checks. The [independent audit](repair-v4/audit-summary.json) passed 32,640 checks across the three matched pairs. The initial parser failure and the repair-v2/v3 Game 5 adapter failures remain separately recorded and excluded from balance interpretation.
