# Private G1a correctness result — 2026-10-11

Completed the requested private correction from the [implementation intake](../../logs/2026-10-11-g1a-candidate-intake-v1.md). The original candidate and sealed handoff remain unchanged. The implementation-owned [corrected packet](g1a-corrected-handoff-v2/HANDOFF.md) has no overlapping canonical conflicts at sealing; its original baseline has drifted and is explicitly reported.

- Reserve the entire `:project:` ID namespace at bootstrap and restore, including future and other-studio serials.
- Reject empty incumbent archives consistently with the existing snapshot validation contract.
- Validate all Features and archive rows before mutating bootstrap ownership. Invalid recipes preserve cash, clock, ownership, archive, opening snapshot, finance and RNG.
- Increment only the private archive content revision to2. No old-save migration or canonical adoption is asserted.

Verification: `g1a_check.py g1a-unit-v1` clean-imported the private project and passed29 focused checks. Both declared seed4417/90210 routes completed two legal releases at cycle22,42/41 commands. Fresh-process replays matched83 commands and85 telemetry samples. Seed4417 continued from its unmodified Studio envelope through21 further commands to release3 at cycle33. `g1a_audit.py` passed112 checks, including exact archived rows and absence of archive IDs in live sales, launch, finance and Fanbase records. These are prototype results, not rival policy or balance approval.

Retained harness corrections: the audit initially read a nonexistent nested `replay` key; the report actually stores `steps` at its root. Corrected the audit reader, leaving evidence unchanged. Handoff v1 was rejected because replay folders are not accepted as direct `--evidence` run inputs; v2 seals the two originating run bundles. The replays and focused verifier remain linked above rather than mislabeled as runs.

Remaining adoption requirements: actual incumbent cohort/count/resources/titles/Reviews and familiarity provenance, trusted player-save migration, visible archive, shared-world persistence, native scene parity and G2–G5 policy/scale decisions. These remain DESIGN/OPEN; the corrected private packet grants no canonical gameplay approval.
