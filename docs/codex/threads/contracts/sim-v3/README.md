# Task34 v3 reproduction and evidence

Read [findings](../FINDINGS-v3-task34-advances.md), [initial gate protocol](PREDECLARATION.md) and [cohort protocol](COHORT-PREDECLARATION.md). Gameplay source is pinned to main `b84d1a5`; `source-manifest.json` records all 1,046 copied project files. Evidence does not approve candidate values.

Run with the bundled Python executable from the repository root. `prepare.py` creates a fresh isolated Downloads project and refuses to overwrite one. `run.py import`, `run.py legacy`, `run.py trait`, then `parity.py` establish 34A. `advance.gd` run through `run.run()` on each `capture-*.bin` supplies 34B; exact commands are retained in `34B-*.command.json`.

`build_cohort.py` installs analysis hooks; `run_cohort.py` captures the 16 native routes. `run_no_contracts.py` captures the eight supplemental controls. The two `sidestreet-*.command.json` commands recapture the historical route with native availability flags; their exact financial/release parity was checked against 34A.

`run_advances.py crown`, `run_supplement.py`, then the two historical inputs through `run_advances.execute` supply Crown evidence; `crown-sidestreet-index.json` identifies those two files. `run_advances.py neon` supplies Neon. Each result has a command, log and hash stamp for its two advance harnesses. Completed outputs are reused only when those hashes match. `audit.py` independently checks rational arithmetic, finance, paired inputs and actual common calendars, and writes `audit-results.json`, `summary.csv` and `common-calendar.csv`.

Typed `.bin` files preserve native integer/StringName state and contain no serialized Objects. JSON captures are display/evidence only and must not be loaded as a live typed finance ledger. Compact `.json.gz` files preserve complete raw results. Large uncompressed duplicates may be archived under the isolated Downloads experiment; use compressed artifacts for portable review. The old `.failure.json` preserves the rejected metadata-parity attempt and is not a successful result.

Source archive location: `C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-20261007-v3`. Godot executable, arguments, isolated profiles and exits are in each `.command.json`; no system user profile or runtime source was changed. Five `verify_*.log` files record focused current-source passes. `audit.py` is intended for this pinned study and checks shared source hashes before claiming parity; after gameplay changes, compare against the archived pinned project instead of silently treating a different source as the same experiment.
