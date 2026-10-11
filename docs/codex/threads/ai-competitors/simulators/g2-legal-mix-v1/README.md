# Candidate simulator: g2-legal-mix-v1

Owner: ai-competitors

Edit only `project/`. Baseline, creation manifest and metadata are hash-fenced; preserve them. Fork into a new version with `simulator_variant.py create --from-variant <this-folder>`. No Git commit is required.

Run through canonical `tools/simulate.py run --variant <this-folder> --config <experiment.json> --output <new-run-folder>`. Each run freezes its source and receives private cache/profile paths, so different threads can run concurrently. Keep run outputs outside this version. Never point candidate code at live saves or canonical paths. Trusted local GDScript can access the filesystem; isolation is not a security sandbox.

Before proposing adoption, run focused checks and exact replay, then use `simulator_variant.py handoff --variant <this-folder> --evidence <run-bundle> --output <new-handoff-folder>`. Reference that handoff and the design decision in an internal TODO entry for the implementation thread. Handoff generation never edits TODO or applies changes. A successful simulation is evidence, not design approval. Studio-only Continue remains the canonical boundary.

The handoff command also requires `--design-record <decision.md> --summary <concrete-addition> --acceptance <criterion>` (repeat acceptance as needed). It retains a hashed copy of the design decision for review.
