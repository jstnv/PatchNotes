# Task 34 Promotion sensitivity (sim-v4)

Read [predeclaration](PREDECLARATION.md) for the fixed source, native routes and cap grid; [findings](FINDINGS.md) for the design interpretation and limits. All work and new evidence for this sweep stay in this Contracts thread folder. Crown/Neon offers and Promotion remain absent from playable source.

The exact Godot commands, paths and exit codes are in [Crown](crown.command.json) and [Neon](neon.command.json). The [runner](run.py) repeats those commands using isolated user-data profiles and then runs the [independent audit](audit.py). On this Windows host, invoke the bundled Python executable with `run.py`; it requires the preserved Task 34 copied project and typed captures at the predeclared paths. The script refuses a passing result when pinned capture/harness hashes, native checks, Task 34 current-cap parity or copied gameplay source identity fail.

Raw [Crown](crown.json) and [Neon](neon.json) files retain each fixed Contract, legal hand pair, native continuation, launch and finance result. [Summary](summary.csv) has the 16 exact-cent rows. [Audit](audit.json) reports 3,200 native and 1,205 independent passing checks. [Session log](SESSION-LOG-v1.md) records local state. Godot logs are [Crown](crown.log) and [Neon](neon.log).
