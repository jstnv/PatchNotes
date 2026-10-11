# Fanbase integration evidence

See the [dated implementation record](../../logs/2026-10-09-fanbase-integration-v1.md) for scope, source, exact adaptations, verification and limits. [Native route audit](audit.json) passes5,089 checks; [eight-process restart result](restart-final.json) passes. The [predeclared native route](PLAN.md) and raw snapshots are retained.

Reproduction: bundled Python `run_checks.py <suite names>`, `restart.py`, and `audit.py`. The captured route command is `native-route.command.json`; its source is `patch-notes/scripts/debug/fanbase_native_route.gd` in the [pinned manifest](source-manifest.json). Do not rerun the route as a new balance search. Source-copy hashes allow further isolated read-only work while main advances.

All trial values remain provisional; Cult is not activated. Older pre-Fanbase saves remain preserved and unsupported. Full combined release gate/export interaction belongs to the parent implementation sequence.
