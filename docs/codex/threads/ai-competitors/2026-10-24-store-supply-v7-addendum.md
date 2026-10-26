# Store supply parser repair — 2026-10-24

Private v6's declared B world failed at the first rival action with a GDScript typed-array assignment error: the ternary literal produced `Array`, which cannot be assigned to `Array[StringName]`. The retained [failed run/log](sims/rival-store-supply-4417-B-20261024-v1/world-run.json) shows the source location and downstream calendar assertions. This is a fixture construction failure, not a Store legality or balance result. A completed on v6 before the failure.

Fork v7 from v6; replace only the array assignment/append construction with explicit typed `append` calls. Do not change target Features, cash reserve, policies, seeds, command/release/cycle/time bounds or stop conditions in the [original pre-run plan](2026-10-24-store-supply-plan-v1.md). Run a new isolated smoke and fresh v7 A/B/C worlds; do not mix v6 A with v7 B/C as a same-source comparison. Retain the v6 failure and its original inputs. No numerical approval follows a parser fix.
